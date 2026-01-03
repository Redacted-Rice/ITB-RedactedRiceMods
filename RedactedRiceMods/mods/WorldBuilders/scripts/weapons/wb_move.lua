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
WorldBuilders_Passive_Move.boardUtils = mod_loader.mods[modApi.currentMod].libs.boardUtils

Weapon_Texts.WorldBuilders_Passive_Move_Upgrade1 = "Hover"
WorldBuilders_Passive_Move_A = WorldBuilders_Passive_Move:new
{
	UpgradeDescription = "Mechs become flying",
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
		self.boardUtils.addReachableTiles(p1, targetArea)
	end
end

function WorldBuilders_Passive_Move:GetPassiveSkillEffect_SkillBuildHook(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" and pawn:IsMech() then
		local path = self.boardUtils.getDirectPath(p1, p2)
		self.boardUtils.addForcedMove(skillEffect, path)
	end
end


function WorldBuilders_Passive_Move:SetTemporarilyFlyingIfNeeded(pawn)
	if pawn:IsMech() and self.Flying and not pawn:IsFlying() then
		pawn:SetFlying(true)
		self.MadeFlying[pawn:GetId()] = true
	end
end

function WorldBuilders_Passive_Move:UnsetFlyingIfTemporarilyAdded(pawn)
	if pawn:IsMech() and self.MadeFlying[pawn:GetId()] then
		pawn:SetFlying(false)
		self.MadeFlying[pawn:GetId()] = nil
	end
end

-- On start and load, make them flying
function WorldBuilders_Passive_Move:GetPassiveSkillEffect_MissionStartHook(mission)
	for idx = 0,2 do
		self:SetTemporarilyFlyingIfNeeded(Board:GetPawn(idx))
	end
end	

function WorldBuilders_Passive_Move:GetPassiveSkillEffect_PostLoadGameHook(mission)
	for idx = 0,2 do
		self:SetTemporarilyFlyingIfNeeded(Board:GetPawn(idx))
	end
end	

-- unset everything on end
function WorldBuilders_Passive_Move:GetPassiveSkillEffect_MissionEndHook(...)
	for idx = 0,2 do
		self:UnsetFlyingIfTemporarilyAdded(Board:GetPawn(idx))
	end
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



--only a preview for passive skills
function WorldBuilders_Passive_Move:GetSkillEffect(p1, p2)
	Board:GetPawn(p1):SetFlying(true)
	local ret = SkillEffect()
	self.addForcedMove(ret, p1, p2)
	return ret
end

WorldBuilders_Passive_Move.passiveEffect:addPassiveEffect("WorldBuilders_Passive_Move",
		{"targetAreaBuildHook", "skillBuildHook", 
		"missionStartHook", "postLoadGameHook", "missionEndHook",
		"postLoadGameHook", "saveGameHook"})