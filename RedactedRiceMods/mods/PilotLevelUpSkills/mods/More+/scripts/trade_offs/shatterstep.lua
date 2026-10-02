local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrShatterstep",
	name = "Shatterstep",
	description = "When moving, cracks the tile moved from. Skips already cracked or damaged mountain/ice tiles.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	moveStartPositions = {},
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Shatterstep", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
	table.insert(customSkill.events, modapiext.events.onPawnUndoMove:subscribe(customSkill.undoCracked))
end

function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			if BoardUtils.canCrack(p1) then
				logger.logDebug(SUBMODULE, "Pawn %d moving from %s to %s, will crack start tile", pawn:GetId(), p1:GetString(), p2:GetString())
				local damageC = SpaceDamage(p1, 0)
				damageC.iCrack = EFFECT_CREATE
				damageC.sScript = [[
					cplus_plus_ex.baseClasses.SkillActive.skills.RrShatterstep.moveStartPositions[]]..pawn:GetId()..[[] = ]] .. p1:GetString()
				skillEffect:AddDamage(damageC)
				logger.logDebug(SUBMODULE, "Will crack %s when pawn %d moves", p1:GetString(), pawn:GetId())
			else
				logger.logDebug(SUBMODULE, "Tile %s not crackable, no effect", p1:GetString())
			end
		end
	end
end

function customSkill.undoCracked(mission, pawn, undonePosition)
	local startPos = customSkill.moveStartPositions[pawn:GetId()]
	if not startPos then
		return
	end

	if BoardUtils.undoCrack(startPos) then
		logger.logDebug(SUBMODULE, "Undid crack on %s for pawn %d (move undone)", startPos:GetString(), pawn:GetId())
	end
	customSkill.moveStartPositions[pawn:GetId()] = nil
end

return customSkill
