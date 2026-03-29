local customSkill = more_plus.SkillActive:new{
	id = "RrShatterstep",
	name = "Shatterstep",
	description = "When moving, cracks tile moved from",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	moveStartPositions = {},
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
	table.insert(customSkill.events, modapiext.events.onPawnUndoMove:subscribe(customSkill.undoCracked))
end

function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			if not Board:IsCracked(p1) then
				local damageC = SpaceDamage(p1, 0)
				damageC.iCrack = EFFECT_CREATE
				damageC.sScript = [[
					more_plus.SkillActive.skills.RrShatterstep.moveStartPositions[]]..pawn:GetId()..[[] = ]] .. p1:GetString()
				skillEffect:AddDamage(damageC)
				--LOGF("Shatterstep: Will crack %s when pawn %d moves", p1:GetString(), pawn:GetId())
			end
		end
	end
end

function customSkill.undoCracked(mission, pawn, undonePosition)
	local startPos = customSkill.moveStartPositions[pawn:GetId()]
	if startPos then
		Board:SetCracked(startPos, false)
		customSkill.moveStartPositions[pawn:GetId()] = nil
		--LOGF("Shatterstep: Uncracked %s for pawn %d (move undone)", startPos:GetString(), pawn:GetId())
	end
end

return customSkill