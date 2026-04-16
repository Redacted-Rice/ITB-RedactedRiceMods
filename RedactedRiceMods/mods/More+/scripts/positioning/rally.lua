local customSkill = more_plus.SkillActive:new{
	id = "RrRally",
	name = "Rally",
	description = "Boost adjacent allies when you move next to them or they move next to you.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	boostedPawns = {},
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Rally", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
	table.insert(customSkill.events, modapiext.events.onPawnUndoMove:subscribe(customSkill.undoBoosted))
end

function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		-- Check if the moving pawn has Rally skill
		local movingPilot = pawn:GetPilot()
		if movingPilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, movingPilot) then
			-- Moving pawn with Rally - check for adjacent allies at destination
			local adjacentMechs = more_plus.libs.boardUtils.getAdjacent(p2, function(adjacentLoc)
					local adjacentPawn = Board:GetPawn(adjacentLoc)
					return adjacentPawn and adjacentPawn:GetId() ~= pawn:GetId() and
							adjacentPawn:GetTeam() == TEAM_PLAYER and not adjacentPawn:IsBoosted()
			end)

			for _, adjacentLoc in ipairs(adjacentMechs) do
				local adjacentPawn = Board:GetPawn(adjacentLoc)
				logger.logDebug(SUBMODULE, "Rally pawn %d moving to %s, boosting adjacent ally %d at %s",
						pawn:GetId(), p2:GetString(), adjacentPawn:GetId(), adjacentLoc:GetString())

				more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
						function()
							more_plus.libs.weaponPreview:AddAnimation(adjacentLoc,
									more_plus.commonIcons.boost.key.."_1")
						end)

				local boostDamage = SpaceDamage(adjacentLoc, 0)
				boostDamage.sScript = string.format([[
						more_plus.SkillActive.skills.RrRally.boostedPawns[%d] = true
						Board:GetPawn(%d):SetBoosted(true)]],
						adjacentPawn:GetId(), adjacentPawn:GetId())
				skillEffect:AddDamage(boostDamage)
			end
		end

		-- Check if moving pawn is moving adjacent to a pawn with Rally
		local hasAdjacentRally = more_plus.libs.boardUtils.isAdjacent(p2, function(adjacentLoc)
			local adjacentPawn = Board:GetPawn(adjacentLoc)
			if adjacentPawn and adjacentPawn:GetId() ~= pawn:GetId() and
					adjacentPawn:GetTeam() == TEAM_PLAYER then
				local adjacentPilot = adjacentPawn:GetPilot()
				return adjacentPilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, adjacentPilot)
			end
			return false
		end)

		-- Boost the moving pawn if not already boosted and found a Rally pilot
		if hasAdjacentRally and not pawn:IsBoosted() then
			logger.logDebug(SUBMODULE, "Pawn %d moving adjacent to Rally pawn, boosting",
				pawn:GetId())

			more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
					function()
						more_plus.libs.weaponPreview:AddAnimation(p2,
								more_plus.commonIcons.boost.key.."_1")
					end)

			local boostDamage = SpaceDamage(p2, 0)
			boostDamage.sScript = string.format([[
					more_plus.SkillActive.skills.RrRally.boostedPawns[%d] = true
					Board:GetPawn(%d):SetBoosted(true)]],
					pawn:GetId(), pawn:GetId())
			skillEffect:AddDamage(boostDamage)
		end
	end
end

function customSkill.undoBoosted(mission, pawn, undonePosition)
	if customSkill.boostedPawns[pawn:GetId()] then
		pawn:SetBoosted(false)
		customSkill.boostedPawns[pawn:GetId()] = nil
		logger.logDebug(SUBMODULE, "Removed boosted from pawn %d (move undone)", pawn:GetId())
	end
end

return customSkill
