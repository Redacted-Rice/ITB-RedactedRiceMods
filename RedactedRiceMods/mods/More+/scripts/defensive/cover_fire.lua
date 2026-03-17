local MOVE_REDUCTION = 1

local customSkill = more_plus.SkillActive:new{
	id = "RrCoveringFire",
	name = "Covering Fire",
	description = "Damaged targets lose "..MOVE_REDUCTION.." movement",
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
		for _, idx in ipairs(indexes) do
			for _, spaceDamage in pairs(extract_table(effects)) do
				local targetPawn = Board:GetPawn(spaceDamage.loc)
				if targetPawn and targetPawn:IsEnemy() and
						spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and
						spaceDamage.iDamage ~= DAMAGE_ZERO then

					more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
							function()
								more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
										more_plus.commonIcons.shackle.key.."_"..idx)
							end)

					-- TODO: Doesn't work with multiple
					spaceDamage.sScript = "Board:GetPawn("..targetPawn:GetId().."):AddMoveBonus(-"..MOVE_REDUCTION..")"
					LOG("Covering Fire: Will reduce movement of enemy at " .. spaceDamage.loc:GetString() .. " by " .. MOVE_REDUCTION)
				end
			end
		end
	end
end

return customSkill
