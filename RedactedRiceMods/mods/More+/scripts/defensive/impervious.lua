local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrImpervious",
	name = "Impervious",
	description = "Piloted mech is immune to self and friendly, non-instakill damage (direct damage from attack only).",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	priority = 30 -- execute before other skills such as cheap plating
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Impervious", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	-- Only process if attacker is an ally (but not self) and target is taking damage
	if source == self.SOURCE_TARGET and attackingPawn and
			attackingPawn:GetTeam() == TEAM_PLAYER and spaceDamage.iDamage > 0 and
			spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then
		-- Show icon
		more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
			function()
				more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, more_plus.commonIcons.noDamage.key, nil,  -- delay
						more_plus.WEAPON_PREVIEW_GROUP_ID, GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
			end, targetPawn:GetId()
		)
		local oldDamage = spaceDamage.iDamage
		spaceDamage.iDamage = DAMAGE_ZERO
		logger.logDebug(SUBMODULE, "Blocked ally damage from pawn %d to pawn %d (damage: %d -> DAMAGE_ZERO)",
				attackingPawn:GetId(), targetPawn:GetId(), oldDamage)
	end
end

return customSkill
