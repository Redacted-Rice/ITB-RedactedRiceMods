local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrReflect",
	name = "Reflect",
	description = "If damaged by an enemy, deals half (rounded up) damage back to the attacker.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	priority = 180, -- go after kill shot
	constraints = {
		pilotExclusions = {"Pilot_Zoltan"},
	},
}

customSkill.DEBUG = true
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Reflect", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

-- Track reflects by attacker pawn ID
customSkill.pendingReflects = {} -- [attackerPawnId] = {totalDamage, hasInstakill}
customSkill.reflectorPawns = {} -- Set of pawn IDs that are reflecting

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	-- Check if this is damage from an enemy to a mech
	if source == self.SOURCE_TARGET and attackingPawn and
			attackingPawn:IsEnemy() and spaceDamage.iDamage > 0 and
			spaceDamage.iDamage ~= DAMAGE_ZERO then
		local attackerId = attackingPawn:GetId()
		local reflectorId = targetPawn:GetId()

		-- Display icons at pawns starting position
		local attackerStartLoc = attackingPawn:GetSpace()
		local targetStartLoc = targetPawn:GetSpace()

		-- Calculate reflect damage
		local reflectDamage = 0
		if spaceDamage.iDamage == DAMAGE_DEATH then
			reflectDamage = DAMAGE_DEATH
			logger.logDebug(SUBMODULE, "Reflecting DAMAGE_DEATH back to attacker %d", attackerId)
		else
			reflectDamage = math.ceil(spaceDamage.iDamage / 2)
			logger.logDebug(SUBMODULE, "Reflecting %d damage back to attacker %d (original: %d)",
					reflectDamage, attackerId, spaceDamage.iDamage)
		end

		-- Track reflect damage by attacker ID
		if not self.pendingReflects[attackerId] then
			self.pendingReflects[attackerId] = {
				attackerId = attackerId,
				totalDamage = 0,
				hasInstakill = false
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
						more_plus.WEAPON_PREVIEW_GROUP_ID, customSkill.name .. ": " .. customSkill.description)
				more_plus.libs.weaponPreview:AddAnimation(targetStartLoc, more_plus.commonIcons.reflect.key, nil,  -- delay
						more_plus.WEAPON_PREVIEW_GROUP_ID, customSkill.name .. ": " .. customSkill.description)
			end, attackerId
		)

		logger.logDebug(SUBMODULE, "Tracked reflect to attacker %d (damage: %s)",
				attackerId, reflectDamage == DAMAGE_DEATH and "DEATH" or tostring(reflectDamage))
	end
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

			-- Create aggregated reflect damage
			local finalDamage = reflectData.hasInstakill and DAMAGE_DEATH or reflectData.totalDamage
			local reflectSd = SpaceDamage(currentLoc, finalDamage)
			table.insert(results, reflectSd)

			logger.logDebug(SUBMODULE, "Created aggregated reflect damage to attacker %d at %s (damage: %s)",
					attackerId, currentLoc:GetString(),
					finalDamage == DAMAGE_DEATH and "DEATH" or tostring(finalDamage))
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
