local customSkill = more_plus.SkillActive:new{
	id = "RrFirstBlood",
	name = "First Blood",
	description = "+1 damage to undamaged vek with 4+ health",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

customSkill:addCustomTrait()

-- Track processed spaces to prevent double triggering on skill build and final effect build
customSkill.processedDamages = {}

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

function hashSpaceDamage(point, index)
	return "p_"..point.x.."_"..point.y
end

function customSkill.modifySkillEffect(pawn, effects)
	if not pawn then
		return
	end
	local pilot = pawn:GetPilot()
	if pilot and not effects:empty() and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
		local indexes = cplus_plus_ex:getPilotSkillIndices(customSkill.id, pilot)

		for i, spaceDamage in pairs(extract_table(effects)) do
			local spaceDamageKey = hashSpaceDamage(spaceDamage.loc, i)
			LOG(spaceDamageKey)
			if not customSkill.processedDamages[spaceDamageKey] then
				customSkill.processedDamages[spaceDamageKey] = true
				local spacePawn = Board:GetPawn(spaceDamage.loc)

				if spacePawn and spacePawn:IsEnemy() and
						spacePawn:GetHealth() == _G[spacePawn:GetType()].Health and
						spacePawn:GetHealth() >= 4 and spaceDamage.iDamage > 0 and
						spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then
					
					modApi:runLater(function()
						more_plus.SkillActive.skills.RrFirstBlood.processedDamages = {}
					end)
					
					for _, idx in ipairs(indexes) do
						more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
								function()
									more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
											more_plus.commonIcons.extraDamage.key.."_"..idx)
								end)

						spaceDamage.iDamage = spaceDamage.iDamage + 1
						LOG("First Blood: Added +1 damage to undamaged vek with 4+ health at ".. spaceDamage.loc:GetString())
					end
				end
			else
				LOG("First Blood: Already processed damage at ".. spaceDamage.loc:GetString())
			end
		end
	end
end

return customSkill
