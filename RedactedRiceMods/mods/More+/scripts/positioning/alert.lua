local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrAlert",
	name = "Alert",
	description = "Reduce damage taken from enemies by 1 while adjacent to an enemy.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Alert", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:setupEffect()
	-- Call parent's setupEffect to register with SkillEffectModifier system
	more_plus.SkillEffectModifier.setupEffect(self)

	-- Track move skill builds to show icons when moving adjacent to vek
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
end

-- Check if a location is adjacent to any vek
function customSkill.isAdjacentToVek(loc)
	return more_plus.libs.boardUtils.isAdjacent(loc, function(adjacentLoc)
			local adjacentPawn = Board:GetPawn(adjacentLoc)
			return adjacentPawn and adjacentPawn:IsEnemy()
	end)
end

-- Reduce damage by 1 if target is adjacent to vek
-- We don't have a setArmor so I took this approach instead which
-- is different than vanilla armor
function customSkill:modifySpaceDamage(attackingPawn, previewState, spaceDamage, indexes, targetPawn)
	-- Check if the target pawn is taking damage and is adjacent to a vek
	if attackingPawn and attackingPawn:IsEnemy() and spaceDamage.iDamage > 0 and 
			spaceDamage.iDamage ~= DAMAGE_ZERO and spaceDamage.iDamage ~= DAMAGE_DEATH then
		local targetLoc = spaceDamage.loc

		if customSkill.isAdjacentToVek(targetLoc) then
			-- Reduce damage by 1
			local oldDamage = spaceDamage.iDamage
			spaceDamage.iDamage = math.max(oldDamage - 1, 0)
			-- Replace 0 with DAMAGE_ZERO to display right
			if spaceDamage.iDamage == 0 then
				spaceDamage.iDamage = DAMAGE_ZERO
			end

			-- TODO: Need to make a different armor icon since this won't behave as vanilla
			-- Show damage reduction icon
			for _, idx in ipairs(indexes) do
				logger.logDebug(SUBMODULE, "Adding damage reduction icon for %s with idx %d",
						spaceDamage.loc:GetString(), idx)
				more_plus.libs.weaponPreview.ExecuteWithState(previewState,
						function()
							more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
									more_plus.commonIcons.armor.key.."_"..idx)
						end)
			end

			logger.logDebug(SUBMODULE, "Alert reduced damage for pawn %d at %s from %d to %d (adjacent to vek)",
					targetPawn:GetId(), targetLoc:GetString(), oldDamage, spaceDamage.iDamage)
		end
	end
	return nil
end

-- Show icon when moving to a location adjacent to vek
function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			local willBeAdjacentToVek = customSkill.isAdjacentToVek(p2)

			-- Show icon if will be adjacent to vek
			if willBeAdjacentToVek then
				more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
						function()
							more_plus.libs.weaponPreview:AddAnimation(p2,
									more_plus.commonIcons.armor.key.."_1")
						end)
				logger.logDebug(SUBMODULE, "Pawn %d moving to %s adjacent to vek, showing damage reduction icon",
						pawn:GetId(), p2:GetString())
			end
		end
	end
end

return customSkill
