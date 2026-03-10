local customSkill = more_plus.SkillActive:new{
	id = "RrTrophyHunter",
	name = "Trophy Hunter",
	description = "+1 damage to unique vek",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
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
	local pilot = pawn:GetPilot()
	if pilot and not effects:empty() and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
		local indexes = cplus_plus_ex:getPilotSkillIndices(customSkill.id, pilot)
		for _, idx in ipairs(indexes) do
			for _, spaceDamage in pairs(extract_table(effects)) do
				local spacePawn = Board:GetPawn(spaceDamage.loc)
				if spacePawn and more_plus.libs.pawnTypeUtils.isSpawnCategory(spacePawn, "Unique") and
						spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and
						spaceDamage.iDamage ~= DAMAGE_ZERO then
					LOG("ADD")
					more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
							function() 
								more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, "rr_hunter_"..idx)
							end)
					lastLoc = spaceDamage.loc
					spaceDamage.iDamage = spaceDamage.iDamage + 1
				end
			end
		end
	end
end

return customSkill