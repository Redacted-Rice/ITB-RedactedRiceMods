WorldBuilders_Passive_Move = PassiveSkill:new{
	Name = "All Terrain",
	Description = "Mechs can move through and on buildings and mountains and can move through units",
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
WorldBuilders_Passive_Move.boardUtils = mod_loader.mods[modApi.currentMod].libs.boardUtils
WorldBuilders_Passive_Move.passiveEffect = mod_loader.mods[modApi.currentMod].libs.passiveEffect
WorldBuilders_Passive_Move.trait = mod_loader.mods[modApi.currentMod].libs.trait

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

local function IsAllTerrainActive(trait, pawn)
	if pawn:IsMech() then
		return WorldBuilders_Passive_Move.passiveEffect:countAnyVersionOfPassiveActive("WorldBuilders_Passive_Move") > 0
	end
	return false
end

WorldBuilders_Passive_Move.trait:add{
	func = IsAllTerrainActive,
	icon = "img/combat/icons/icon_wb_all_terrain.png",
	icon_offset = Point(0,9),
	desc_title = "All Terrain",
	desc_text = "This unit can move past units and over/on buildings and mountains",
}

function WorldBuilders_Passive_Move:GetPassiveSkillEffect_TargetAreaBuildHook(mission, pawn, weaponId, p1, targetArea)
	if weaponId == "Move" and pawn:IsMech() then
		-- Remove the other points
		while not targetArea:empty() do
		    targetArea:erase(0)
		end
		-- Add the new points
		self.boardUtils.getReachableInRange(targetArea, pawn:GetMoveSpeed(), p1, self.boardUtils.makeAllTerrainMatcher(pawn, true), self.boardUtils.makeAllTerrainMatcher(pawn, false))
	end
end

function WorldBuilders_Passive_Move:GetPassiveSkillEffect_SkillBuildHook(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" and pawn:IsMech() then
		-- true == as point list
		local path = self.boardUtils.findBfsPath(p1, p2, self.boardUtils.makeAllTerrainMatcher(pawn, true), true)
		self.boardUtils.addForcedMove(skillEffect, path)
	end
end


function WorldBuilders_Passive_Move:SetTemporarilyFlyingIfNeeded(pawn)
	if pawn and pawn:IsMech() and self.Flying and not pawn:IsFlying() then
		pawn:SetFlying(true)
		self.MadeFlying[pawn:GetId()] = true
	end
end

function WorldBuilders_Passive_Move:UnsetFlyingIfTemporarilyAdded(pawn)
	if pawn and pawn:IsMech() and self.MadeFlying[pawn:GetId()] then
		pawn:SetFlying(false)
		self.MadeFlying[pawn:GetId()] = nil
	end
end

-- MissionStartHook seems better to use the onGameSave but it does not
-- fire on final mission. The on next phase fires too early before
-- pawns/board is made so it won't work right on that mission. For ease
-- I just use on save which will fire after mission starts anyways

-- MissionEndHook has issues too - its too early and mechs will fall to
-- to their death... instead just tie into save game hook and do it based
-- on if we are in a mission or not

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

	-- if we are set to flying and there is a mission, add flying
	if self.Flying and GetCurrentMission() then
		for idx = 0,2 do
			self:SetTemporarilyFlyingIfNeeded(Game:GetPawn(idx))
		end
	-- Otherwise try to unset in case its no longer enabled
	else
		for idx = 0,2 do
			self:UnsetFlyingIfTemporarilyAdded(Game:GetPawn(idx))
		end
	end
end

--only a preview for passive skills
function WorldBuilders_Passive_Move:GetSkillEffect(p1, p2)
	Board:GetPawn(p1):SetFlying(true)
	local ret = SkillEffect()
    local path = PointList()
	path:push_back(p1)
	path:push_back(p2)
	self.boardUtils.addForcedMove(ret, path)
	return ret
end

WorldBuilders_Passive_Move.passiveEffect:addPassiveEffect("WorldBuilders_Passive_Move",
		{"targetAreaBuildHook", "skillBuildHook",
		"postLoadGameHook", "saveGameHook"})