local customSkill = more_plus.SkillActive:new{
	id = "RrStreetwise",
	name = "Streetwise",
	description = "Prevents non-fatal damage to buildings from weapon attacks",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	processedDamages = {}
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(
		function(mission, pawn, weaponId, p1, p2, skillEffect)
			customSkill.modifySkillEffect(pawn, skillEffect.effect, p2)
			customSkill.modifySkillEffect(pawn, skillEffect.q_effect, p2)
		end))
	table.insert(customSkill.events, modapiext.events.onFinalEffectBuild:subscribe(
		function(mission, pawn, weaponId, p1, p2, p3, skillEffect)
			customSkill.modifySkillEffect(pawn, skillEffect.effect, p2)
			customSkill.modifySkillEffect(pawn, skillEffect.q_effect, p2)
		end))
end

function customSkill.hashSpaceDamage(pawnId, spaceDmg, p2)
	return "p_"..pawnId.."_"..more_plus.libs.boardUtils.getSpaceHash(spaceDmg.loc)..
			"_"..more_plus.libs.boardUtils.getSpaceHash(p2)
end

function customSkill.modifySkillEffect(pawn, effects, p2)
	if not pawn then
		return
	end
	local pilot = pawn:GetPilot()
	if pilot and not effects:empty() and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
		local indexes = cplus_plus_ex:getPilotSkillIndices(customSkill.id, pilot)

		for i, spaceDamage in pairs(extract_table(effects)) do
			local spaceDamageKey = customSkill.hashSpaceDamage(pawn:GetId(), spaceDamage, p2)
			if not customSkill.processedDamages[spaceDamageKey] then
				customSkill.processedDamages[spaceDamageKey] = true
				
				if Board:IsBuilding(spaceDamage.loc) and
				   spaceDamage.iDamage > 0 and
				   spaceDamage.iDamage ~= DAMAGE_DEATH then
				   
					modApi:runLater(function()
						more_plus.SkillActive.skills.RrStreetwise.processedDamages = {}
					end)
					
					for _, idx in ipairs(indexes) do
						more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
								function()
									more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
											more_plus.commonIcons.noDamage.key.."_"..idx)
								end)

						spaceDamage.iDamage = DAMAGE_ZERO
						--LOG("Streetwise: Prevented damage to building at ".. spaceDamage.loc:GetString())
					end
				end
			--[[else
				LOG("Streetwise: Already processed damage at ".. spaceDamage.loc:GetString())]]
			end
		end
	end
end

return customSkill
