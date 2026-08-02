local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrMilitia",
	name = "Militia",
	description = "+1 damage to enemies adjacent to buildings.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	constraints = {
		groups = {more_plus.GROUPS.ADD_DAMAGE},
	},
	priority = 80, -- go after doubling
	modifiesKillDamage = true,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Militia", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, currentDamage)
	-- Check if this is damage to an enemy
	if source ~= customSkill.SOURCE_ATTACKER or not targetPawn or not targetPawn:IsEnemy() or
			not (currentDamage > 0 and currentDamage ~= DAMAGE_DEATH and currentDamage ~= DAMAGE_ZERO) then
		return currentDamage
	end

	-- Check if target is adjacent to any building
	local isAdjacentToBuilding = more_plus.libs.boardUtils.isAdjacent(spaceDamage.loc, function(adjacentLoc)
		return Board:IsBuilding(adjacentLoc)
	end)
	if isAdjacentToBuilding then
		return currentDamage + 1
	end
	return currentDamage
end

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	local newDamage = self:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, spaceDamage.iDamage)
	if newDamage == spaceDamage.iDamage then
		return
	end

	logger.logDebug(SUBMODULE, "Adding militia damage icon for %s", spaceDamage.loc:GetString())
	more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
		function()
			more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, more_plus.commonIcons.extraDamage.key, nil,  -- delay
					more_plus.WEAPON_PREVIEW_GROUP_ID, GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
		end, attackingPawn:GetId()
	)
	spaceDamage.iDamage = newDamage
	logger.logDebug(SUBMODULE, "Added +1 militia damage to enemy at %s (adjacent to building)",
		spaceDamage.loc:GetString())
end

return customSkill
