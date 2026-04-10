local customSkill = more_plus.SkillActive:new{
	id = "RrEscort",
	name = "Escort",
	description = "Shield adjacent allies when you move next to them or they move next to you.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	shieldedPawns = {},
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Escort", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
	table.insert(customSkill.events, modapiext.events.onPawnUndoMove:subscribe(customSkill.undoShield))
end

function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		-- Check if the moving pawn has Escort skill
		local movingPilot = pawn:GetPilot()
		if movingPilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, movingPilot) then
			-- Moving pawn with Escort - check for adjacent allies at destination
			local adjacentMechs = more_plus.libs.boardUtils.getAdjacent(p2, function(adjacentLoc)
					local adjacentPawn = Board:GetPawn(adjacentLoc)
					-- Don't include self...
					return adjacentPawn and adjacentPawn:GetId() ~= pawn:GetId() and
							adjacentPawn:IsMech() and not adjacentPawn:IsShield()
			end)

			for _, adjacentLoc in ipairs(adjacentMechs) do
				local adjacentPawn = Board:GetPawn(adjacentLoc)
				logger.logDebug(SUBMODULE, "Escort pawn %d moving to %s, shielding adjacent ally %d at %s",
						pawn:GetId(), p2:GetString(), adjacentPawn:GetId(), adjacentLoc:GetString())

				local shieldDamage = SpaceDamage(adjacentLoc, 0)
				shieldDamage.iShield = EFFECT_CREATE
				shieldDamage.sScript = string.format([[
						more_plus.SkillActive.skills.RrEscort.shieldedPawns[%d] = true]],
						adjacentPawn:GetId())
				skillEffect:AddDamage(shieldDamage)
			end
		end

		-- Check if moving pawn is moving adjacent to a pawn with Escort
		local hasAdjacentEscort = more_plus.libs.boardUtils.isAdjacent(p2, function(adjacentLoc)
			local adjacentPawn = Board:GetPawn(adjacentLoc)
			-- Don't include self again
			if adjacentPawn and adjacentPawn:GetId() ~= pawn:GetId() and adjacentPawn:IsMech() then
				local adjacentPilot = adjacentPawn:GetPilot()
				return adjacentPilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, adjacentPilot)
			end
			return false
		end)

		-- Shield the moving pawn if not already shielded and found an Escort pilot
		if hasAdjacentEscort and not pawn:IsShield() then
			logger.logDebug(SUBMODULE, "Pawn %d moving adjacent to Escort pawn, shielding",
					pawn:GetId())

			local shieldDamage = SpaceDamage(p2, 0)
			shieldDamage.iShield = EFFECT_CREATE
			shieldDamage.sScript = string.format([[
					more_plus.SkillActive.skills.RrEscort.shieldedPawns[%d] = true]],
					pawn:GetId())
			skillEffect:AddDamage(shieldDamage)
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
