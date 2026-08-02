local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrReflect",
	name = "Reflect",
	description = "If damaged by an enemy, deals half (rounded up) damage back to the attacker.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	priority = 180, -- go after kill shot
	constraints = {
		pilotExclusions = {"Pilot_Zoltan"},
	},
	modifiesKillDamage = false,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Reflect", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

-- Track reflects by attacker pawn ID
customSkill.pendingReflects = {} -- [attackerPawnId] = {totalDamage, hasInstakill, reflectorId}
customSkill.reflectorPawns = {} -- Set of pawn IDs that are reflecting

-- Boost needs to be manually handled since its added after by the game
local function getReflectDamage(attackingPawn, damage)
	if damage == DAMAGE_DEATH then
		logger.logDebug(SUBMODULE, "Reflecting DAMAGE_DEATH back to attacker %d", attackingPawn:GetId())
		return DAMAGE_DEATH
	end

	local incoming = damage
	if attackingPawn:IsBoosted() then
		incoming = incoming + 1
	end
	logger.logDebug(SUBMODULE, "Reflecting %d damage back to attacker %d (incoming: %d, base: %d, boost: %s)",
			math.ceil(incoming / 2), attackingPawn:GetId(), incoming, damage,
			tostring(attackingPawn:IsBoosted()))
	return math.ceil(incoming / 2)
end

-- Reflect damage must not be appended to the enemy attack SkillEffect or Vek
-- Hormones treats it as enemy to enemy damage. Use a separate effect
-- owned by the reflecting mech instead and we will need to use weapon
-- preview for the damage
function RrReflect_ApplyDamage(reflectorId, attackerId, damage)
	local attacker = Board:GetPawn(attackerId)
	if not attacker then
		return
	end

	local effect = SkillEffect()
	effect.iOwner = reflectorId
	effect:AddDamage(SpaceDamage(attacker:GetSpace(), damage))
	Board:AddEffect(effect)
end

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	-- Check if this is damage from an enemy to a mech
	if source ~= self.SOURCE_TARGET or not attackingPawn or not attackingPawn:IsEnemy() or
			not (spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO) then
		return
	end

	local attackerId = attackingPawn:GetId()
	local reflectorId = targetPawn:GetId()

	-- Display icons at pawns starting position
	local attackerStartLoc = attackingPawn:GetSpace()
	local targetStartLoc = targetPawn:GetSpace()

	-- Calculate reflect damage from incoming damage
	local reflectDamage = getReflectDamage(attackingPawn, spaceDamage.iDamage)
	-- Track reflect damage by attacker ID
	if not self.pendingReflects[attackerId] then
		self.pendingReflects[attackerId] = {
			attackerId = attackerId,
			totalDamage = 0,
			hasInstakill = false,
			reflectorId = reflectorId,
		}
	end

	if reflectDamage == DAMAGE_DEATH then
		self.pendingReflects[attackerId].hasInstakill = true
	else
		self.pendingReflects[attackerId].totalDamage =
				self.pendingReflects[attackerId].totalDamage + reflectDamage
	end

	-- Track reflector pawns
	self.reflectorPawns[reflectorId] = true

	-- Add reflect icons at start locations with group ID
	logger.logDebug(SUBMODULE, "Adding reflect damage icon from %s to attacker %s",
			targetStartLoc:GetString(), attackerStartLoc:GetString())
	more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
		function()
			more_plus.libs.weaponPreview:AddAnimation(attackerStartLoc, more_plus.commonIcons.reflect.key, nil,  -- delay
					more_plus.WEAPON_PREVIEW_GROUP_ID, GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
			more_plus.libs.weaponPreview:AddAnimation(targetStartLoc, more_plus.commonIcons.reflect.key, nil,  -- delay
					more_plus.WEAPON_PREVIEW_GROUP_ID, GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
		end, attackerId
	)

	logger.logDebug(SUBMODULE, "Tracked reflect to attacker %d (damage: %s)",
			attackerId, reflectDamage == DAMAGE_DEATH and "DEATH" or tostring(reflectDamage))
end

function customSkill:SkillEffectEvaluated(phase)
	if not next(self.pendingReflects) then
		return nil
	end
	local results = {}
	local pauseDamage = SpaceDamage()
	pauseDamage.fDelay = 0.1
	table.insert(results, pauseDamage)

	-- First loop: ping all reflector pawns at their current location
	for reflectorId, _ in pairs(self.reflectorPawns) do
		local reflector = Board:GetPawn(reflectorId)
		if reflector then
			local currentLoc = self:getPawnSpace(reflector)
			local pingDamage = SpaceDamage(currentLoc)
			pingDamage.sScript = [[Board:Ping(]]..currentLoc:GetString()..[[, GL_Color(175, 175, 255))
					Board:AddAlert(]]..currentLoc:GetString()..[[,"REFLECT")]]
			pingDamage.bHide = true
			-- Add a delay
			pingDamage.fDelay = 0.3
			table.insert(results, pingDamage)
			logger.logDebug(SUBMODULE, "Added ping for reflector pawn %d at %s",
					reflectorId, currentLoc:GetString())
		end
	end

	-- Second loop: deal damage to all attackers at their CURRENT location
	for attackerId, reflectData in pairs(self.pendingReflects) do
		local attacker = Board:GetPawn(attackerId)
		if attacker then
			local currentLoc = self:getPawnSpace(attacker)

			-- Apply via script so damage is not part of the enemy attack effect
			-- We need to use weapon preview to apply the damage preview since
			-- we use a script
			more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
				function()
					more_plus.libs.weaponPreview:AddDamage(SpaceDamage(currentLoc, reflectData.totalDamage))
				end, attackerId
			)
			local reflectDamage = SpaceDamage(currentLoc, 0)
			reflectDamage.bHide = true
			reflectDamage.sScript = string.format(
				"RrReflect_ApplyDamage(%d, %d, %s)",
				reflectData.reflectorId,
				attackerId,
				reflectData.totalDamage
			)
			table.insert(results, reflectDamage)

			logger.logDebug(SUBMODULE, "Queued reflect damage to attacker %d at %s via reflector %d (damage: %s)",
					attackerId, currentLoc:GetString(), reflectData.reflectorId,
					tostring(reflectData.totalDamage))
		else
			logger.logWarn(SUBMODULE, "Attacker pawn %d not found when applying reflect", attackerId)
		end
	end

	-- Clear for next evaluation
	self.pendingReflects = {}
	self.reflectorPawns = {}

	if #results > 0 then
		return results
	end
end

return customSkill
