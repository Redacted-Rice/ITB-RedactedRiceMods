StarWars_Stomp = Skill:new{
	Name = "Stomp",
	Description = "Instead of normal movement, stomps across the battlefield up to move speed times per turn pushing the target space."
			.. " Free action and doesn't consume boosted but must be used before other actions",
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

function StarWars_Stomp:pawnHasPoweredStomp(pawn)
	if not pawn or pawn:IsDead() or not pawn:IsMech() then
		return false
	end
	local weapons = pawn:GetPoweredWeaponTypes()
	for wIdx = 1, 2 do
		local weaponId = weapons[wIdx]
		if weaponId and weaponId:find("StarWars_Stomp") and pawn:IsWeaponPowered(weaponId) then
			return true
		end
	end
	return false
end

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

function StarWars_Stomp:clearBonusMoveIfAny(pawn)
	if not pawn or pawn:IsDead() then
		return false
	end
	local bonusMove = pawn:GetBonusMove()
	if bonusMove and bonusMove > 0 then
		pawn:SetBonusMove(0)
		return true
	end
	return false
end

function StarWars_Stomp:syncStompForPawn(pawn, override)
	if not pawn or pawn:IsDead() or not pawn:IsMech() then
		return
	end

	local weapons = pawn:GetPoweredWeaponTypes()
	for wIdx = 1, 2 do
		local weaponId = weapons[wIdx]
		if weaponId and weaponId:find("StarWars_Stomp") and pawn:IsWeaponPowered(weaponId) then
			if override or Game:GetTeamTurn() == TEAM_PLAYER then
				local uses = self:getStompUsesForPawn(pawn, weaponId)
				pawn:SetWeaponLimitedRemaining(wIdx, uses)
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

function StarWars_Stomp:syncStompForTestMech()
	if not IsTestMechScenario() or not Game or not Board or Board:IsTipImage() then
		return
	end

	local pawn = Game:GetPawn(0) or Game:GetPawn(1) or Game:GetPawn(2)
	if not pawn or not StarWars_ATATMech.isATATPawnType(pawn:GetType()) then
		return
	end
	local weapons = pawn:GetBaseWeaponTypes()
	for wIdx = 1, 2 do
		local weaponId = weapons[wIdx]
		if weaponId and weaponId:find("StarWars_Stomp") then
			pawn:AddMoveBonus(-99)
			break
		end
	end
end

function StarWars_Stomp:restoreBoostAfterStomp(pawn)
	if not pawn or pawn:IsDead() then
		return
	end
	StarWars_Stomp.initBoostRestoreSave()
	local pawnId = pawn:GetId()
	if GAME.starwars.stomp_restore_boost[pawnId] then
		pawn:SetBoosted(true)
		GAME.starwars.stomp_restore_boost[pawnId] = nil
	end
end

function StarWars_Stomp.initBoostRestoreSave()
	GAME = GAME or {}
	GAME.starwars = GAME.starwars or {}
	GAME.starwars.stomp_restore_boost = GAME.starwars.stomp_restore_boost or {}
end

function StarWars_Stomp:reactivateAfter(pawn)
	if not pawn or pawn:IsDead() then
		return
	end

	self:restoreBoostAfterStomp(pawn)
	local clearedBonusMove = self:clearBonusMoveIfAny(pawn)

	-- Set it to active so it can attack again and re-select it for convinence
	pawn:SetActive(true)
	Game:SetSelectedPawn(pawn)

	-- If we have more uses left, set it to the active weapon too so we can easily
	-- chain move + attack
	local setArmed = false
	local weapons = pawn:GetBaseWeaponTypes()
	for wIdx = 1, 2 do
		local weaponId = weapons[wIdx]
		if weaponId and weaponId:find("StarWars_Stomp") then
			if pawn:GetWeaponLimitedRemaining(wIdx) > 0 then
				pawn:SetArmedWeaponId(wIdx)
				setArmed = true
			end
		end
	end
	-- if we cleared the bonus move and didn't set an armed weapon, set it
	-- to unarmed to prevent vanilla autoselecting and allowing a move
	if clearedBonusMove and not setArmed then
		pawn:SetArmedWeaponId(-1)
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

	if not Board:IsTipImage() then
		local pawn = Board:GetPawn(p1)
		local pawnId = pawn and pawn:GetId()
		if pawnId then
			local stripBoost = SpaceDamage(p1, DAMAGE_ZERO)
			stripBoost.bHide = true
			stripBoost.sScript = string.format([[
				local pawn = Board:GetPawn(%d)
				if pawn and pawn:IsBoosted() then
					StarWars_Stomp.initBoostRestoreSave()
					GAME.starwars.stomp_restore_boost[%d] = true
				end
			]], pawnId, pawnId)
			ret:AddDamage(stripBoost)
		end
	end

	ret:AddBounce(p1, 3)
	ret:AddDelay(0.2)

	-- Damage and push the target tile
	local dir = GetDirection(p2 - p1)
	if Board:IsValid(p2) then
		local damage = SpaceDamage(p2, self.Damage, dir)
		damage.sAnimation = "airpush_" .. dir
		ret:AddDamage(damage)
		ret:AddBounce(p2, -1)
	end

	ret:AddDelay(0.5)


	-- Move into the target if empty
	local refund = SpaceDamage(p2)
	refund.bHide = true
	-- Note we don't reactivate in the tool tip because it will select the
	-- tool tip pawn which is very confusing and annoying
	refund.sScript = string.format([[
		local p1 = %s
		local p2 = %s

		local pawn = Board:GetPawn(p1)
		if not Board:IsTipImage() then
			modApi:runLater(function()
				StarWars_Stomp:reactivateAfter(pawn)
			end)
		end

		local effect = SkillEffect()
		local path = PointList()
		path:push_back(p1)
		path:push_back(p2)
		effect:AddMove(path, FULL_DELAY)
		Board:AddEffect(effect)

	]], p1:GetString(), p2:GetString())
	ret:AddDamage(refund)

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

function StarWars_Stomp:GetPassiveSkillEffect_OnPawnIsGrappled(mission, pawn, isGrappled)
	if not isGrappled then
		return
	end
	if StarWars_Stomp:pawnHasPoweredStomp(pawn) then
		BoardUtils.breakGrapple(pawn)
	end
end

-- Register the passive effect
local passiveEffect = mod.libs.passiveEffect
passiveEffect:addPassiveEffect(
	"StarWars_Stomp",
	{
		"missionStartHook",
		"onMissionNextPhaseCreated",
		"nextTurnHook",
		"onPawnIsGrappled",
	},
	true  -- Not passive only
)

modApi.events.onTestMechEntered:subscribe(function()
	modApi:runLater(function()
		StarWars_Stomp:syncStompForTestMech()
	end)
end)
