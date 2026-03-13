local customSkill = more_plus.SkillActive:new{
	id = "RrKillShot",
	name = "Kill Shot",
	description = "+1 damage if the vek would be killed",
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
	if not pawn then
		return
	end
	local pilot = pawn:GetPilot()
	if pilot and not effects:empty() and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
		local indexes = cplus_plus_ex:getPilotSkillIndices(customSkill.id, pilot)
		local numInstances = #indexes

		for _, spaceDamage in pairs(extract_table(effects)) do
			local spacePawn = Board:GetPawn(spaceDamage.loc)
			if spacePawn and spacePawn:IsEnemy() and
					spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and
					spaceDamage.iDamage ~= DAMAGE_ZERO then

				-- Handle multiple instances by checking if +n damage would kill
				local currentHealth = spacePawn:GetHealth()
				local totalBonusDamage = numInstances
				local wouldKillWithExtra = (currentHealth - (spaceDamage.iDamage + totalBonusDamage)) <= 0

				if wouldKillWithExtra then
					-- Add image for each instance
					for _, idx in ipairs(indexes) do
						more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
								function()
									more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
											more_plus.commonIcons.extraDamage.key.."_"..idx)
								end)
					end

					spaceDamage.iDamage = spaceDamage.iDamage + totalBonusDamage
					LOG("Kill Shot: Added +" .. totalBonusDamage .. " damage to finish off vek at ".. spaceDamage.loc:GetString() .. " (" .. numInstances .. " instances)")
				end
			end
		end
	end
end

return customSkill
