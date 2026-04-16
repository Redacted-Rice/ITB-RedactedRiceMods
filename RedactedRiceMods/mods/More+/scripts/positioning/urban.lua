local customSkill = more_plus.SkillActive:new{
	id = "RrUrban",
	name = "Urban",
	description = "Gain a shield when moving adjacent to a building.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	shieldedPawns = {},
	groups = {more_plus.GROUPS.SHIELD},
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Urban", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
	table.insert(customSkill.events, modapiext.events.onPawnUndoMove:subscribe(customSkill.undoShield))
end

function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			-- Check if p2 (destination) is adjacent to any building
			local isAdjacentToBuilding = more_plus.libs.boardUtils.isAdjacent(p2, function(adjacentLoc)
					return Board:IsBuilding(adjacentLoc)
			end)

			if isAdjacentToBuilding and not pawn:IsShield() then
				logger.logDebug(SUBMODULE, "Pawn %d moving to %s adjacent to building, will add shield",
						pawn:GetId(), p2:GetString())

				local shieldDamage = SpaceDamage(p2, 0)
				shieldDamage.iShield = EFFECT_CREATE
				shieldDamage.sScript = [[
						more_plus.SkillActive.skills.RrUrban.shieldedPawns[]]..pawn:GetId()..[[] = true]]
				skillEffect:AddDamage(shieldDamage)
			else
				logger.logDebug(SUBMODULE, "No shield - not adjacent to building or already shielded")
			end
		end
	end
end

function customSkill.undoShield(mission, pawn, undonePosition)
	if customSkill.shieldedPawns[pawn:GetId()] then
		pawn:SetShield(false)
		customSkill.shieldedPawns[pawn:GetId()] = nil
		logger.logDebug(SUBMODULE, "Removed shield from pawn %d (move undone)", pawn:GetId())
	end
end

return customSkill
