local customSkill = more_plus.SkillActive:new{
	id = "RrFirstBlood",
	name = "First Blood",
	description = "+1 damage to undamaged vek",
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
		local indexes = cplus_plus_ex:getPilotEarnedSkillIndexes(pilot)
		for _, idx in ipairs(indexes) do
			if pilot:getLvlUpSkill(idx):getIdStr() == customSkill.id then
				for _, spaceDamage in pairs(extract_table(effects)) do
					local spacePawn = Board:GetPawn(spaceDamage.loc)
					if spacePawn and spacePawn:IsEnemy() and
							spacePawn:GetHealth() == _G[spacePawn:GetType()].Health and
							spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and
							spaceDamage.iDamage ~= DAMAGE_ZERO then

						more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
							function()
								more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, "rr_hunter_"..idx)
							end)

						spaceDamage.iDamage = spaceDamage.iDamage + 1
						LOG("First Blood: Added +1 damage to undamaged vek at ".. spaceDamage.loc:GetString())
					end
				end
			end
		end
	end
end

return customSkill
