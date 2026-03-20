local MIN_DISTANCE = 4

local customSkill = more_plus.SkillActive:new{
	id = "RrFocused",
	name = "Focused",
	description = "Deal +1 Damage if you have not moved yet",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(
		function(mission, pawn, weaponId, p1, p2, skillEffect)
			customSkill.modifySkillEffect(pawn, skillEffect.effect)
			customSkill.modifySkillEffect(pawn, skillEffect.q_effect)
		end))
	table.insert(customSkill.events, modapiext.events.onFinalEffectBuild:subscribe(
		function(mission, pawn, weaponId, p1, p2, p3, skillEffect)
			customSkill.modifySkillEffect(pawn, skillEffect.effect)
			customSkill.modifySkillEffect(pawn, skillEffect.q_effect)
		end))
end

function customSkill.modifySkillEffect(pawn, effects)
	if not pawn then
		return
	end
	local pilot = pawn:GetPilot()
	if pilot and not effects:empty() and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
		if pawn:IsMovementSpent() then
			LOG("Pawn ".. pawn:GetId().." already moved")
			return
		end
		local indexes = cplus_plus_ex:getPilotSkillIndices(customSkill.id, pilot)
		for _, idx in ipairs(indexes) do
			for _, spaceDamage in pairs(extract_table(effects)) do
				if spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and 
						spaceDamage.iDamage ~= DAMAGE_ZERO then

					more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
							function()
								more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
										more_plus.commonIcons.extraDamage.key.."_"..idx)
							end)

					spaceDamage.iDamage = spaceDamage.iDamage + 1
					LOG("Focused: Added +1 damage enemy at ".. spaceDamage.loc:GetString())
				end
			end
		end
	end
end

return customSkill

