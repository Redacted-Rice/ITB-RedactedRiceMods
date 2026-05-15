local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrCoveringFire",
	name = "Covering Fire",
	description = "Targeted enemies lose half their movement for a turn (rounded down).",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "CoveringFire", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	if source == self.SOURCE_ATTACKER and targetPawn and
			targetPawn:IsEnemy() then
		logger.logDebug(SUBMODULE, "Adding icon for %s", spaceDamage.loc:GetString())
		more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
			function()
				more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,more_plus.commonIcons.shackle.key, nil,  -- delay
						more_plus.WEAPON_PREVIEW_GROUP_ID, GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
			end, attackingPawn:GetId()
		)

		local baseMoveSpeed = _G[targetPawn:GetType()].MoveSpeed
		local targetMoveSpeed = math.floor(baseMoveSpeed / 2)
		local moveReduction = targetPawn:GetMoveSpeed() - targetMoveSpeed

		spaceDamage.sScript = spaceDamage.sScript .. "Board:GetPawn("..targetPawn:GetId().."):AddMoveBonus(-"..moveReduction..")"
		logger.logDebug(SUBMODULE, "Will reduce movement of enemy at %s to %d (base: %d, reduction: %d)",
				spaceDamage.loc:GetString(), targetMoveSpeed, baseMoveSpeed, moveReduction)
	end
end

return customSkill