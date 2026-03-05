local customSkill = more_plus.SkillActive:new{
	id = "RrKickoffBoosters",
	shortName = "Kickoff",
	fullName = "Kickoff Boosters",
	description = "When moving, cracks tile moved from",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

-- TODO:
--customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
end

function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			LOG("CRACKING SPACE "..p1:GetString())
			local damageC = SpaceDamage(p1, 0)
			damageC.iCrack = EFFECT_CREATE
			skillEffect:AddDamage(damageC)
		end
	end
end

return customSkill