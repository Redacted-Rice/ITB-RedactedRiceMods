StarWars_Stomp = Skill:new{
	Name = "Stomp",
	Description = "Instead of moving, stomp across the battlefield pushing up to move speed times per turn."
			.. " Free action but must be used before other actions",
	Class = "Ranged",
	Damage = 0,
	PowerCost = 1,
	Upgrades = 2,
	UpgradeCost = {2, 1},
	Limited = 1,
	ExtraUses = 0,
	Icon = "weapons/artillery_sw_stomp.png",
	LaunchSound = "/impact/generic/mech",
	ImpactSound = "/impact/generic/explosion",
	TipImage = {
		Unit = Point(2, 2),
		Enemy = Point(2, 1),
		Target = Point(2, 1),
	},
}

local mod = mod_loader.mods[modApi.currentMod]

Weapon_Texts.StarWars_Stomp_Upgrade1 = "Spikes"
Weapon_Texts.StarWars_Stomp_A_UpgradeDescription = "+1 damage"
StarWars_Stomp_A = StarWars_Stomp:new{
	Damage = 1,
}

Weapon_Texts.StarWars_Stomp_Upgrade2 = "+ Use"
Weapon_Texts.StarWars_Stomp_B_UpgradeDescription = "+1 Stomp use per turn"
StarWars_Stomp_B = StarWars_Stomp:new{
	ExtraUses = 1,
}

StarWars_Stomp_AB = StarWars_Stomp_A:new{
	ExtraUses = 1,
}

function StarWars_Stomp:getStompUsesForPawn(pawn, weaponId)
	local move = pawn:GetMoveSpeed()
	if move < 0 then
		move = 0
	end
	-- Pull the extra uses based on the full weapon id to get the right value
	-- Guard it with a 0 fallback just to be safe
	local weapon = _G[weaponId]
	local extraUses = (weapon and weapon.ExtraUses) or 0
	return move + extraUses
end

function StarWars_Stomp:syncStompForPawn(pawn)
	if not pawn or pawn:IsDead() or not pawn:IsMech() then
		return
	end

	local weapons = pawn:GetPoweredWeaponTypes()
	for wIdx = 1, 2 do
		local weaponId = weapons[wIdx]
		if weaponId and weaponId:find("StarWars_Stomp") and pawn:IsWeaponPowered(weaponId) then
			
			if Game:GetTeamTurn() == TEAM_ENEMY then
				local uses = self:getStompUsesForPawn(pawn, weaponId)
				pawn:SetWeaponLimitedRemaining(wIdx, uses)
			else
				pawn:SetMovementSpent(true)
			end
		end
	end
end

function StarWars_Stomp:syncStompForAllPlayerMechs()
	if not Game or not Board or Board:IsTipImage() then
		return
	end
	for pId = 0, 2 do
		local pawn = Game:GetPawn(pId)
		self:syncStompForPawn(pawn)
	end
end

function StarWars_Stomp:reactivateAfter(pawn)
	if not pawn or pawn:IsDead() then
		return
	end

	-- Set it to active so it can attack again and re-select it for convinence
	pawn:SetActive(true)
	Game:SetSelectedPawn(pawn)

	-- If we have more uses left, set it to the active weapon too so we can easily
	-- chain move + attack
	local weapons = pawn:GetBaseWeaponTypes()
	for wIdx = 1, 2 do
		local weaponId = weapons[wIdx]
		if weaponId and weaponId:find("StarWars_Stomp") then
			if pawn:GetWeaponLimitedRemaining(wIdx) > 0 then
				pawn:SetArmedWeaponId(wIdx)
			end
		end
	end
end

function StarWars_Stomp:GetTargetArea(point)
	local ret = PointList()
	for dir = DIR_START, DIR_END do
		local target = point + DIR_VECTORS[dir]
		if Board:IsValid(target) then
			ret:push_back(target)
		end
	end
	return ret
end

function StarWars_Stomp:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	ret:AddBounce(p1, 3)
	ret:AddDelay(0.2)

	-- Damage and push the target tile
	local dir = GetDirection(p2 - p1)
	if Board:IsValid(p2) then
		local damage = SpaceDamage(p2, self.Damage)
		damage.sAnimation = "airpush_" .. dir
		damage.iPush = dir
		ret:AddDamage(damage)
		ret:AddBounce(p2, -1)
	end

	ret:AddDelay(0.5)


	-- Move into the target if empty
	if not Board:IsTipImage() then
		local refund = SpaceDamage(p2)
		refund.sScript = string.format([[
			local p1 = %s
			local p2 = %s

			local pawn = Board:GetPawn(p1)
			modApi:runLater(function()
				StarWars_Stomp:reactivateAfter(pawn)
			end)

			local effect = SkillEffect()
			local path = PointList()
			path:push_back(p1)
			path:push_back(p2)
			effect:AddMove(path, FULL_DELAY)
			Board:AddEffect(effect)

		]], p1:GetString(), p2:GetString())
		ret:AddDamage(refund)
	end

	return ret
end

function StarWars_Stomp:GetPassiveSkillEffect_MissionStartHook(mission)
	self:syncStompForAllPlayerMechs()
end

function StarWars_Stomp:GetPassiveSkillEffect_OnMissionNextPhaseCreated(prevMission, nextMission)
	modApi:runLater(function()
		StarWars_Stomp:syncStompForAllPlayerMechs()
	end)
end

function StarWars_Stomp:GetPassiveSkillEffect_NextTurnHook(mission)
	self:syncStompForAllPlayerMechs()
end

-- Register the passive effect
local passiveEffect = mod.libs.passiveEffect
passiveEffect:addPassiveEffect(
	"StarWars_Stomp",
	{
		"missionStartHook",
		"onMissionNextPhaseCreated",
		"nextTurnHook",
	},
	true  -- Not passive only
)