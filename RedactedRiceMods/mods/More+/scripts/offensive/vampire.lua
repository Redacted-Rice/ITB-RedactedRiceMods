local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrVampire",
	name = "Vampire",
	description = "Repair (regardless of pilot repair skill) piloted mech when you kill a vek.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	-- Zoltan only has 1 health
	constraints = {
		pilotExclusions = {"Pilot_Zoltan"},
	},
	priority = 180, -- go after kill shot
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Vampire", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

-- Track heals per pawn ID for aggregation
customSkill.pendingHeals = {}

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	if source == self.SOURCE_ATTACKER and targetPawn and
			targetPawn:IsEnemy() and spaceDamage.iDamage > 0 and
			spaceDamage.iDamage ~= DAMAGE_ZERO then
		local wouldKill = false
		if spaceDamage.iDamage == DAMAGE_DEATH then
			wouldKill = true
			logger.logDebug(SUBMODULE, "Instakill vek at %s",
					spaceDamage.loc:GetString())
		else
			local currentHealth = targetPawn:GetHealth()
			local baseDamage = spaceDamage.iDamage
			local hasBoosted = attackingPawn:IsBoosted()
			local hasAcid = targetPawn:IsAcid()
			local hasArmor = targetPawn:IsArmor()
			local resultDamage = baseDamage

			if hasBoosted then
				resultDamage = resultDamage + 1
			end
			if hasAcid then
				-- Acid doubles ALL damage
				resultDamage = resultDamage * 2
			-- Armor only applies if not acid
			elseif hasArmor then
				resultDamage = resultDamage - 1
			end

			if currentHealth <= resultDamage then
				wouldKill = true
				logger.logDebug(SUBMODULE, "Will kill vek at %s ("..
						"health: %d, base damage: %d, final %d, boost: %s, armor: %s, acid: %s)",
						spaceDamage.loc:GetString(), currentHealth, baseDamage, resultDamage, tostring(hasBoosted), tostring(hasArmor), tostring(hasAcid))
			else
				logger.logDebug(SUBMODULE, "Vek at %s would survive ("..
						"health: %d, base damage: %d, final %d, boost: %s, armor: %s, acid: %s)",
						spaceDamage.loc:GetString(), currentHealth, baseDamage, resultDamage, tostring(hasBoosted), tostring(hasArmor), tostring(hasAcid))
			end
		end

		if wouldKill then
			local pawnId = attackingPawn:GetId()
			local targetLoc = self:getPawnSpace(targetPawn)
			local attackerLoc = self:getPawnSpace(attackingPawn)

			-- Track this heal for aggregation (by pawn ID)
			if not self.pendingHeals[pawnId] then
				self.pendingHeals[pawnId] = {
					pawnId = pawnId,
					count = 0
				}
			end
			self.pendingHeals[pawnId].count = self.pendingHeals[pawnId].count + 1

			-- Add vampire icons with group ID for automatic consolidation
			more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
				function()
					more_plus.libs.weaponPreview:AddAnimation(attackerLoc, more_plus.commonIcons.vampire.key, nil,  -- delay
							more_plus.WEAPON_PREVIEW_GROUP_ID)
					more_plus.libs.weaponPreview:AddAnimation(targetLoc, more_plus.commonIcons.vampire.key, nil,  -- delay
							more_plus.WEAPON_PREVIEW_GROUP_ID)
				end, pawnId
			)

			logger.logDebug(SUBMODULE, "Added vampire icons at attacker %s and target %s (heal #%d for pawn %d)",
					attackerLoc:GetString(), targetLoc:GetString(),
					self.pendingHeals[pawnId].count, pawnId)
		end
	end
end

function customSkill:SkillEffectEvaluated(phase)
	if not next(self.pendingHeals) then
		return nil
	end
	local results = {}

	-- Add a delay before applying heals
	local delayDamage = SpaceDamage(Point(0, 0), 0)
	delayDamage.bHide = true
	delayDamage.fDelay = 0.5
	table.insert(results, delayDamage)

	-- Loop through all pawn IDs and apply the summed heal
	for pawnId, healData in pairs(self.pendingHeals) do
		local pawn = Board:GetPawn(pawnId)
		if pawn then
			-- Get pawn's current location
			local currentLoc = self:getPawnSpace(pawn)

			logger.logDebug(SUBMODULE, "Creating aggregated heal (%d kills) for pawn %d at current location %s",
					healData.count, pawnId, currentLoc:GetString())

			-- Adding an alert doesn't work and seems to be overriden by
			-- the repair alert

			-- Create a single aggregated heal for all kills
			local repairDamage = SpaceDamage(currentLoc, -healData.count)
			repairDamage.iFire = EFFECT_REMOVE
			repairDamage.iAcid = EFFECT_REMOVE
			table.insert(results, repairDamage)
			logger.logDebug(SUBMODULE, "Added aggregated repair effect (x%d) at %s",
					healData.count, currentLoc:GetString())
		else
			logger.logWarn(SUBMODULE, "Pawn %d not found when applying vampire heal", pawnId)
		end
	end

	-- Clear for next evaluation
	self.pendingHeals = {}

	if #results > 0 then
		return results
	end
end

return customSkill
