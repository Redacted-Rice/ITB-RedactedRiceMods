local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrMilitia",
	name = "Militia",
	description = "+1 damage to enemies adjacent to buildings.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	constraints = {
		groups = {more_plus.GROUPS.ADD_DAMAGE},
	},
	priority = 80, -- go after doubling
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Militia", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	-- Check if this is damage to an enemy
	if source == self.SOURCE_ATTACKER and targetPawn and
			targetPawn:IsEnemy() and spaceDamage.iDamage > 0 and
	   		spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then

		-- Check if target is adjacent to any building
		local targetLoc = spaceDamage.loc
		local isAdjacentToBuilding = more_plus.libs.boardUtils.isAdjacent(targetLoc, function(adjacentLoc)
				return Board:IsBuilding(adjacentLoc)
		end)

		if isAdjacentToBuilding then
			for _, idx in ipairs(indexes) do
				logger.logDebug(SUBMODULE, "Adding militia damage icon for %s with idx %d",
					spaceDamage.loc:GetString(), idx)
				more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
						function()
							more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
									more_plus.commonIcons.extraDamage.key.."_"..idx)
						end, attackingPawn:GetId())
			end

			spaceDamage.iDamage = spaceDamage.iDamage + 1
			logger.logDebug(SUBMODULE, "Added +1 militia damage to enemy at %s (adjacent to building)",
				spaceDamage.loc:GetString())
		else
			logger.logDebug(SUBMODULE, "No militia bonus - target not adjacent to building")
		end
	end
end

return customSkill
