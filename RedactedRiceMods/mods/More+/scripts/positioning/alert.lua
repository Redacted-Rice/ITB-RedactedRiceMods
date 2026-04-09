local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrAlert",
	name = "Alert",
	description = "Reduce damage taken by 1 while adjacent to a vek.",
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

-- SkillEffectModifier implementation: reduce damage by 1 if target is adjacent to vek
function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes, spacePawn)
	-- Check if the target pawn is taking damage and is adjacent to a vek
	if spacePawn and spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_ZERO and spaceDamage.iDamage ~= DAMAGE_DEATH then
		local targetLoc = spaceDamage.loc

		if customSkill.isAdjacentToVek(targetLoc) then
			-- Reduce damage by 1
			spaceDamage.iDamage = math.max(0, spaceDamage.iDamage - 1)

			-- TODO: Need to make a different armor icon since this won't behave as vanilla

			-- Show damage reduction icon
			local previewState = isFinalEffect and more_plus.libs.weaponPreview.STATE_FINAL_EFFECT or
					more_plus.libs.weaponPreview.STATE_SKILL_EFFECT

			for _, idx in ipairs(indexes) do
				logger.logDebug(SUBMODULE, "Adding damage reduction icon for %s with idx %d",
						spaceDamage.loc:GetString(), idx)
				more_plus.libs.weaponPreview.ExecuteWithState(previewState,
						function()
							more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
									more_plus.commonIcons.armor.key.."_"..idx)
						end)
			end

			logger.logDebug(SUBMODULE, "Alert reduced damage for pawn %d at %s (adjacent to vek)",
					spacePawn:GetId(), targetLoc:GetString())
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
