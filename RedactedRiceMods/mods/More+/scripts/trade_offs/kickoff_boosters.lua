local customSkill = more_plus.SkillActive:new{
	id = "RrKickoffBoosters",
	name = "Kickoff Boosters",
	description = "When moving, cracks tile moved from",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	notPreCracked = {},
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
	table.insert(customSkill.events, modapiext.events.onPawnUndoMove:subscribe(customSkill.undoCracked))
end

function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if not Board:IsCracked(p1) and pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			LOG("CRACKING SPACE "..p1:GetString())
			customSkill.notPreCracked[pawn:GetId()] = true
			local damageC = SpaceDamage(p1, 0)
			damageC.iCrack = EFFECT_CREATE
			skillEffect:AddDamage(damageC)
		else
			customSkill.notPreCracked[pawn:GetId()] = nil
		end
	end
end

function customSkill.undoCracked(mission, pawn, undonePosition)
	if customSkill.notPreCracked[pawn:GetId()] then
		Board:SetCracked(pawn:GetSpace(), false)
	end
end

return customSkill