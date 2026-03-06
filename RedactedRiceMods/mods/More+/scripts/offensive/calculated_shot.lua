local customSkill = more_plus.SkillActive:new{
	id = "RrCalculatedShot",
	name = "Calculated Shot",
	description = "Deals +1 damage to pawns with two or less move",
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
		-- Go through each space being attacked
		for _, spaceDamage in pairs(extract_table(effects)) do
			local spacePawn = Board:GetPawn(spaceDamage.loc)
			-- Unintuitively get base move is the current speed
			if spacePawn and spacePawn:GetBaseMove() <= 2 and spaceDamage.iDamage > 0 and 
					spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then
				spaceDamage.iDamage = spaceDamage.iDamage + 1
			end
		end
	end
end

return customSkill