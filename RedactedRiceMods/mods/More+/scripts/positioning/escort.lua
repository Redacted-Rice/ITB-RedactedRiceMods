local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrEscort",
	name = "Escort",
	description = "Shield adjacent allies when you move next to them or they move next to you.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Escort", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

-- Initialize GAME save data structure
local function initGameSaveData()
	if GAME == nil then
		GAME = {}
	end

	if GAME.more_plus == nil then
		GAME.more_plus = {}
	end

	if GAME.more_plus.escort == nil then
		GAME.more_plus.escort = {}
	end

	if GAME.more_plus.escort.shielded_by_effect == nil then
		GAME.more_plus.escort.shielded_by_effect = {}
	end
end

local function resetShieldTracking()
	logger.logDebug(SUBMODULE, "Setting shield tracking")
	initGameSaveData()
	GAME.more_plus.escort.shielded_by_effect = {}
end

function customSkill.setShieldings(pawnId, setSelf, adjId)
	logger.logDebug(SUBMODULE, "Resetting shield tracking")

	initGameSaveData()
	if not GAME.more_plus.escort.shielded_by_effect[pawnId] then
		GAME.more_plus.escort.shielded_by_effect[pawnId] = {adjPawns = {}, self = setSelf or false}
	end
	if adjId then
		GAME.more_plus.escort.shielded_by_effect[pawnId].adjPawns[adjId] = true
	end
end

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
	table.insert(customSkill.events, modapiext.events.onPawnUndoMove:subscribe(customSkill.undoShield))

	-- Reset tracking on mission start and each turn
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(resetShieldTracking))
	table.insert(customSkill.events, modApi.events.onNextTurn:subscribe(resetShieldTracking))
end

function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		initGameSaveData()

		-- Check if the moving pawn has Escort skill
		local movingPilot = pawn:GetPilot()
		if movingPilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, movingPilot) then
			-- Moving pawn with Escort - check for adjacent allies at destination
			local adjacentMechs = more_plus.libs.boardUtils.getAdjacent(p2, function(adjacentLoc)
					local adjacentPawn = Board:GetPawn(adjacentLoc)
					-- Don't include self...
					return adjacentPawn and adjacentPawn:GetId() ~= pawn:GetId() and
							adjacentPawn:GetTeam() == TEAM_PLAYER and not adjacentPawn:IsShield()
			end)

			for _, adjacentLoc in ipairs(adjacentMechs) do
				local adjacentPawn = Board:GetPawn(adjacentLoc)
				local adjacentId = adjacentPawn:GetId()
				local movingPawnId = pawn:GetId()
				logger.logDebug(SUBMODULE, "Escort pawn %d moving to %s, shielding adjacent ally %d at %s",
						movingPawnId, p2:GetString(), adjacentId, adjacentLoc:GetString())

				more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
					function()
						more_plus.libs.weaponPreview:AddAnimation(adjacentLoc, more_plus.commonIcons.shield.key, nil,  -- delay
								more_plus.WEAPON_PREVIEW_GROUP_ID, GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
					end, movingPawnId
				)

				local shieldDamage = SpaceDamage(adjacentLoc, 0)
				shieldDamage.sScript = [[
						cplus_plus_ex.baseClasses.SkillActive.skills.RrEscort.setShieldings(]] .. movingPawnId .. [[, false, ]] .. adjacentId .. [[)
						Board:GetPawn(]] .. adjacentId .. [[):SetShield(true)]]
				skillEffect:AddDamage(shieldDamage)
			end
		end

		-- Check if moving pawn is moving adjacent to a pawn with Escort
		local hasAdjacentEscort = more_plus.libs.boardUtils.isAdjacent(p2, function(adjacentLoc)
			local adjacentPawn = Board:GetPawn(adjacentLoc)
			-- Don't include self again
			if adjacentPawn and adjacentPawn:GetId() ~= pawn:GetId() and adjacentPawn:GetTeam() == TEAM_PLAYER then
				local adjacentPilot = adjacentPawn:GetPilot()
				return adjacentPilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, adjacentPilot)
			end
			return false
		end)

		-- Shield the moving pawn if not already shielded and found an Escort pilot
		if hasAdjacentEscort and not pawn:IsShield() then
			local pawnId = pawn:GetId()
			logger.logDebug(SUBMODULE, "Pawn %d moving adjacent to Escort pawn, shielding",
					pawnId)

			more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
				function()
					more_plus.libs.weaponPreview:AddAnimation(p2, more_plus.commonIcons.shield.key, nil,  -- delay
						more_plus.WEAPON_PREVIEW_GROUP_ID, GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
				end, pawnId
			)

			local shieldDamage = SpaceDamage(p2, 0)
			shieldDamage.sScript = [[
					cplus_plus_ex.baseClasses.SkillActive.skills.RrEscort.setShieldings(]]..pawnId..[[, true)
					Board:GetPawn(]]..pawnId..[[):SetShield(true)]]
			skillEffect:AddDamage(shieldDamage)
		end
	end
end

function customSkill.undoShield(mission, pawn, undonePosition)
	initGameSaveData()
	local pawnId = pawn:GetId()

	-- If we added shield, then remove it
	if GAME.more_plus.escort.shielded_by_effect[pawnId] then
		if GAME.more_plus.escort.shielded_by_effect[pawnId].self then
			logger.logDebug(SUBMODULE, "Pawn %d (self) was not shielded before Escort, removing shield on undo", pawnId)
			pawn:SetShield(false)
		end
		for adjPawnId, _ in pairs(GAME.more_plus.escort.shielded_by_effect[pawnId].adjPawns) do
			logger.logDebug(SUBMODULE, "Pawn %d (adj) was not shielded before Escort, removing shield on undo", pawnId)
			Board:GetPawn(adjPawnId):SetShield(false)
		end
	end
	GAME.more_plus.escort.shielded_by_effect[pawnId] = nil
end

return customSkill
