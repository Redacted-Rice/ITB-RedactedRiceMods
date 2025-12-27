WorldBuilders_Passive_Move = PassiveSkill:new{
	Name = "All Terrain",
	Description = "Mechs can move through and on buildings and mountains and can move over pawns and holes",
	Icon = "weapons/passives/passive_wb_move.png",
	Rarity = 2,

	PowerCost = 1,
	Damage = 0,

	Upgrades = 1,
	UpgradeCost = {1},

	-- custom options
	Flying = false,
	MadeFlying = {},

	TipImage = {
		CustomPawn = "WorldBuilders_ShaperMech",
		Unit = Point(2, 1),
		Mountain = Point(2, 2),
		Target = Point(2,2),
	}
}
WorldBuilders_Passive_Move.passiveEffect = mod_loader.mods[modApi.currentMod].libs.passiveEffect

Weapon_Texts.WorldBuilders_Passive_Move_Upgrade1 = "Hover"
WorldBuilders_Passive_Move_A = WorldBuilders_Passive_Move:new
{
	UpgradeDescription = "Mechs can move onto hole tiles (holes created under will still cause death)",
	TipImage = {
		CustomPawn = "WorldBuilders_ShaperMech",
		Unit = Point(2, 3),
		Hole = Point(2, 2),
		Target = Point(2,2),
	},

	Flying = true,
}


function WorldBuilders_Passive_Move:GetPassiveSkillEffect_TargetAreaBuildHook(mission, pawn, weaponId, p1, targetArea)
	if weaponId == "Move" and pawn:IsMech() then
		-- Remove the other points
		while not targetArea:empty() do
		    targetArea:erase(0)
		end
		-- Add the new points
		self.addReachableTiles(p1, targetArea)
	end
end

function WorldBuilders_Passive_Move:GetPassiveSkillEffect_SkillBuildHook(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" and pawn:IsMech() then
		self.addForcedMove(skillEffect, p1, p2)
	end
end


function WorldBuilders_Passive_Move:SetTemporarilyFlyingIfNeeded(pawn)
	if pawn:IsMech() and self.Flying and not pawn:IsFlying() then
		LOG("SETTING FLYING!")
		pawn:SetFlying(true)
		self.MadeFlying[pawn:GetId()] = true
		return true
	end
	return false
end

function WorldBuilders_Passive_Move:UnsetFlyingIfTemporarilyAdded(pawn)
	if pawn:IsMech() and self.MadeFlying[pawn:GetId()] then
		LOG("UNSETTING FLYING!")
		pawn:SetFlying(false)
		self.MadeFlying[pawn:GetId()] = nil
	end
end

-- When they select, make flying so pathing shows holes as pathable
function WorldBuilders_Passive_Move:GetPassiveSkillEffect_PawnSelectedHook(mission, pawn)
	if not self:SetTemporarilyFlyingIfNeeded(pawn) then
		self:UnsetFlyingIfTemporarilyAdded(pawn)
	end
end

-- But after move only keep flying if on a hole (so they can't attack from water)
function WorldBuilders_Passive_Move:GetPassiveSkillEffect_PawnMoveEndHook(mission, pawn, p1, p2)
	if Board:GetTerrain(p2) ~= TERRAIN_HOLE then
		self:UnsetFlyingIfTemporarilyAdded(pawn)
	end
end

function WorldBuilders_Passive_Move:GetPassiveSkillEffect_PawnDeselectedHook(mission, pawn, p1, p2)
	self:UnsetFlyingIfTemporarilyAdded(pawn)
end

--[[function WorldBuilders_Passive_Move:GetPassiveSkillEffect_SkillEndHook(mission, pawn, skill, p1, p2)
	if p1 == TERRAIN_HOLE and Board:IsPawnSpace(p1) then
		self:SetTemporarilyFlyingIfNeeded(Board:GetPawn(p1))
	end
	if p2 == TERRAIN_HOLE and Board:IsPawnSpace(p2) then
		self:SetTemporarilyFlyingIfNeeded(Board:GetPawn(p2))
	end
end--]]

-- This is ugly but this is the only hacky way I could find to get resets
-- and loads to work because the hooks are either before board is created
-- or too late to keep the pawn from falling. What I do is I search for the
-- pawn types in play and temporarily set them to Flying and then shortly
-- after unset after pawn creation
WorldBuilders_Passive_Move.loadHackedPawns = {}
function WorldBuilders_Passive_Move:GetPassiveSkillEffect_PostLoadGameHook(...)
	if self.Flying then
		local region = modapiext.board:getCurrentRegion()
		if region ~= nil then
			for k,v in pairs(region.player.map_data) do
				if type(v) == "table" and v.mech and v.type then
					local pawnClass = _G[v.type]
					if not pawnClass.Flying then
						LOG("Set pawn type ".. k .." to flying")
						self.loadHackedPawns[v.type] = true
						pawnClass.Flying = true
					end
				end
			end
		end
	end
end

-- I just chose this because its frequently and reliably run but not run too often
function WorldBuilders_Passive_Move:GetPassiveSkillEffect_SaveGameHook(...)
	for k,_ in pairs(self.loadHackedPawns) do
		_G[k].Flying = nil
		for idx = 0, 2 do
			if Board:GetPawn(idx):GetType() == k then
				self.MadeFlying[idx] = true
			end
		end
	end
	self.loadHackedPawns = {}
end

function WorldBuilders_Passive_Move.addForcedMove(skillEffect, p1, p2)
	-- Clear the existing move from the skilleffect
	skillEffect.effect = SkillEffect().effect
	
	local path = WorldBuilders_Passive_Move.getManhattanPath(p1, p2)
	-- Add move for display purposes. This won't let us move onto unmovable spaces
	-- reliably
	skillEffect:AddMove(path, FULL_DELAY)

	local pawnId = Board:GetPawn(p1):GetId()
	local secondToLastSpace = path:index(path:size() - 1)
	local lastSpace = path:index(path:size())
	local moveDamage = SpaceDamage(secondToLastSpace, 0)
	moveDamage.sScript = [[Board:GetPawn(]] .. pawnId .. [[):SetSpace(]] .. lastSpace:GetString() .. [[)]]
	skillEffect:AddDamage(moveDamage)
end

-- Generic pathfinder
function WorldBuilders_Passive_Move.addReachableTiles(start, targetArea)
	-- "borrowed" from general_DiamondTarget and modified to not
	-- include point
	local pawn = Board:GetPawn(start)
	local isFlying = pawn:IsFlying()
	local size = pawn:GetBaseMove()
	local corner = start - Point(size, size)

	local p = Point(corner)

	for i = 0, ((size*2+1)*(size*2+1)) do
		local diff = start - p
		local dist = math.abs(diff.x) + math.abs(diff.y)
		-- If its a valid, unoccupied space, allow it
		if Board:IsValid(p) and dist <= size and not Board:IsPawnSpace(p) and (isFlying or Board:GetTerrain(p) ~= TERRAIN_HOLE) then
			targetArea:push_back(p)
		end
		p = p + VEC_RIGHT
		if math.abs(p.x - corner.x) == (size*2+1) then
			p.x = p.x - (size*2+1)
			p = p + VEC_DOWN
		end
	end
end

function WorldBuilders_Passive_Move.getManhattanPath(start, target)
    local path = PointList()
	path:push_back(start)
    local current = Point(start.x, start.y)

    local dx = target.x - start.x
    local dy = target.y - start.y

    local stepX = dx > 0 and 1 or -1
    for i = 1, math.abs(dx) do
        current = Point(current.x + stepX, current.y)
        path:push_back(current)
    end

    local stepY = dy > 0 and 1 or -1
    for i = 1, math.abs(dy) do
        current = Point(current.x, current.y + stepY)
        path:push_back(current)
    end

    return path
end

--only a preview for passive skills
function WorldBuilders_Passive_Move:GetSkillEffect(p1, p2)
	Board:GetPawn(p1):SetFlying(true)
	local ret = SkillEffect()
	self.addForcedMove(ret, p1, p2)
	return ret
end

WorldBuilders_Passive_Move.passiveEffect:addPassiveEffect("WorldBuilders_Passive_Move",
		{"targetAreaBuildHook", "skillBuildHook", 
		"pawnSelectedHook", "pawnMoveEndHook", "pawnDeselectedHook",
		"postLoadGameHook", "saveGameHook"})