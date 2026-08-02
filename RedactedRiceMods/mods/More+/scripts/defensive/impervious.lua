local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrImpervious",
	name = "Impervious",
	description = "Piloted mech is immune to self and friendly, non-instakill damage (direct damage from attack only).",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	priority = 30, -- execute before other skills such as cheap plating
	modifiesKillDamage = true,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Impervious", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

-- Block friendly fire damage (non-instakill)
function customSkill:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, currentDamage)
	-- Only process if attacker is an ally (but not self) and target is taking damage
	if source == customSkill.SOURCE_TARGET and attackingPawn and
			attackingPawn:GetTeam() == TEAM_PLAYER and currentDamage > 0 and currentDamage ~= DAMAGE_DEATH and currentDamage ~= DAMAGE_ZERO then
		return DAMAGE_ZERO
	end
	return currentDamage
end

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	local newDamage = self:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, spaceDamage.iDamage)
	if newDamage == spaceDamage.iDamage then
		return
	end

	-- Show icon
	more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
		function()
			more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, more_plus.commonIcons.noDamage.key, nil,  -- delay
					more_plus.WEAPON_PREVIEW_GROUP_ID, GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
		end, targetPawn:GetId()
	)
	local oldDamage = spaceDamage.iDamage
	spaceDamage.iDamage = newDamage
	logger.logDebug(SUBMODULE, "Blocked ally damage from pawn %d to pawn %d (damage: %d -> DAMAGE_ZERO)",
			attackingPawn:GetId(), targetPawn:GetId(), oldDamage)
end

return customSkill
