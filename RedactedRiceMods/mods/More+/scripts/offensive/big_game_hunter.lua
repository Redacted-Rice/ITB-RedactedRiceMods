local customSkill = more_plus.SkillActive:new{
	id = "RrBigGameHunter",
	shortName = "Big Game",
	fullName = "Big Game Hunter",
	description = "Doubles damage to boss vek",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(
			function(mission, pawn, weaponId, p1, p2, skillEffect) 
				customSkill.doubleBossDamage(pawn, skillEffect.effect)
				customSkill.doubleBossDamage(pawn, skillEffect.q_effect)
			end))
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(
			function(mission, pawn, weaponId, p1, p2, p3, skillEffect) 
				customSkill.doubleBossDamage(pawn, skillEffect.effect)
				customSkill.doubleBossDamage(pawn, skillEffect.q_effect)
			end))
end

function customSkill.doubleBossDamage(pawn, effects)
	local pilot = pawn:GetPilot()
	if pilot and not effects:empty() and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
		-- Go through each space being attacked
		for _, spaceDamage in pairs(extract_table(effects)) do
			local spacePawn = Board:GetPawn(spaceDamage.loc)
			if spacePawn and spacePawn.Tier == TIER_BOSS and spaceDamage.iDamage > 0 and 
					spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then
				-- TODO: Add an icon?
				LOG("DOUBLING DAMAGE FOR SPACE "..spaceDamage.loc:GetString())
				spaceDamage.iDamage = spaceDamage.iDamage * 2
			end
		end
	end
end

return customSkill