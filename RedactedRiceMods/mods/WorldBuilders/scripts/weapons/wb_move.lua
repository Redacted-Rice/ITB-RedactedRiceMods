WorldBuilders_Passive_Move = PassiveSkill:new
{
	Name = "All Terrain Mechs",
	Description = "Mechs can move through and on buildings and mountains and can move over pawns and holes",
	Icon = "weapons/passive_wb_move.png",
	Rarity = 2,

	PowerCost = 1,
	Damage = 0,

	Upgrades = 1,
	UpgradeCost = {1},

	-- custom options: TODO
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

-- TODO: Implement this
Weapon_Texts.WorldBuilders_Passive_Move_Upgrade1 = "Flying"
WorldBuilders_Passive_Move_A = WorldBuilders_Passive_Move:new
{
	UpgradeDescription = "Mechs all become flying",
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
		LOG("HERE 1")
		-- Remove the other points
		while not targetArea:empty() do
		    targetArea:erase(0)
		end
		LOG("HERE 2")
		-- Add the new points
		self.addReachableTiles(p1, skillFx)
		LOG("HERE 3")
	end

	LOG("HERE 0")
end

function WorldBuilders_Passive_Move:GetPassiveSkillEffect_SkillBuildHook(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" and pawn:IsMech() then
		self.addForcedMove(skillEffect, p1, p2)
	end
	LOG("HERE 6")
end

function WorldBuilders_Passive_Move:GetPassiveSkillEffect_PawnSelectedHook(mission, pawn)
	if pawn:IsMech() then
		if self.Flying and not pawn:IsFlying() then
			LOG("Set pawn " .. pawn:GetId() .. " to flying")
			pawn:SetFlying(true)
			MadeFlying[pawn:GetId()] = true
		elseif not self.Flying and MadeFlying[pawn:GetId()] then
			LOG("Set pawn " .. pawn:GetId() .. " to not flying")
			pawn:SetFlying(false)
			MadeFlying[pawn:GetId()] = nil
		end
	end
end

function WorldBuilders_Passive_Move.addForcedMove(skillEffect, p1, p2)
	LOG("HERE 4")
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
	LOG("HERE 5")
end

-- Generic pathfinder
function WorldBuilders_Passive_Move.addReachableTiles(start, skillFx)
	-- "borrowed" from general_DiamondTarget and modified to not
	-- include point
	local pawn = Board:GetPawn(start)
	local isFlying = _G[Pawn:GetType()].Flying
	local size = pawn:GetBaseMove()
	local corner = start - Point(size, size)

	local p = Point(corner)

	for i = 0, ((size*2+1)*(size*2+1)) do
		local diff = start - p
		local dist = math.abs(diff.x) + math.abs(diff.y)
		-- If its a valid, unoccupied space, allow it
		if Board:IsValid(p) and dist <= size and not Board:IsPawnSpace(p) and (isFlying or Board:GetTerrain(p) ~= TERRAIN_HOLE) then
			skillFx:push_back(p)
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
	local ret = SkillEffect()
	self.addForcedMove(ret, p1, p2)
	return ret
end

WorldBuilders_Passive_Move.passiveEffect:addPassiveEffect("WorldBuilders_Passive_Move",
		{"targetAreaBuildHook", "skillBuildHook"})