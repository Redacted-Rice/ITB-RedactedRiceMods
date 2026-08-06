local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrPhoenix",
	name = "Phoenix",
	description = "Once per mission, the first time this mech dies it is revived with 1 HP at the start of the next turn (or mission end), clears statuses, and gains Boosted and Shield.",
	constraints = {
		pilotExclusions = {cplus_plus_ex.isCyborg},
		skillExclusions = {"InvulnerablePlus"},
	},
	reusabilityLimit = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = true
local logger = memhack.logger
local SUBMODULE = logger.register("Legendary+", "Phoenix", customSkill.DEBUG)

customSkill.icon = "img/combat/icons/icon_lp_RrPhoenix.png"

local function initGameSaveData()
	GAME = GAME or {}
	GAME.legendary_plus = GAME.legendary_plus or {}
	GAME.legendary_plus.phoenix = GAME.legendary_plus.phoenix or {}
	GAME.legendary_plus.phoenix.used_by_pawn = GAME.legendary_plus.phoenix.used_by_pawn or {}
	GAME.legendary_plus.phoenix.pending_revive = GAME.legendary_plus.phoenix.pending_revive or {}
	-- Pawns that revived this turn. needed because the game doesn't seem to save
	-- boosted and shielded in the reset save but the HP it does save for some reason
	GAME.legendary_plus.phoenix.buffed_by_pawn = GAME.legendary_plus.phoenix.buffed_by_pawn or {}
end

legendary_plus.libs.traitReplace:addStateful{
	targetTrait = "massive",
	func = function(trait, pawn)
		if not cplus_plus_ex:isSkillOnPawn(customSkill.id, pawn) then
			return 0
		end

		initGameSaveData()
		local pawnId = pawn:GetId()
		if GAME.legendary_plus.phoenix.used_by_pawn[pawnId] then
			return 2
		else
			return 1
		end
	end,
	states = {
		{
			icon = customSkill.icon,
			desc_title = customSkill.name .. " (Active)",
			desc_text = customSkill.description,
		},
		{
			icon = "img/combat/icons/icon_lp_RrPhoenix_used.png",
			desc_title = customSkill.name .. " (Used)",
			desc_text = "Phoenix revive has been used this mission.",
		},
	},
}

function customSkill:setupEffect()
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(customSkill.resetTrackedData))
	table.insert(customSkill.events, modApi.events.onMissionNextPhaseCreated:subscribe(customSkill.resetTrackedData))
	table.insert(customSkill.events, modapiext.events.onPawnKilled:subscribe(customSkill.pawnKilled))
	table.insert(customSkill.events, modApi.events.onNextTurn:subscribe(customSkill.nextTurnRevive))
	table.insert(customSkill.events, modApi.events.onMissionEnd:subscribe(customSkill.revivePending))
	-- Any time the game is loaded, we may need to reapply
	table.insert(customSkill.events, modApi.events.onPostLoadGame:subscribe(customSkill.reapplyReviveBuffs))
end

function customSkill.resetTrackedData()
	initGameSaveData()
	GAME.legendary_plus.phoenix.used_by_pawn = {}
	GAME.legendary_plus.phoenix.pending_revive = {}
	GAME.legendary_plus.phoenix.buffed_by_pawn = {}
end

local function applyReviveBuffs(pawn)
	if not pawn or pawn:IsDead() then
		return
	end
	pawn:SetBoosted(true)
	pawn:SetShield(true)
end

-- Mark for revive on next player turn
function customSkill.pawnKilled(mission, pawn)
	initGameSaveData()
	if not pawn or not pawn:IsMech() then
		return
	end

	local pilot = pawn:GetPilot()
	if not pilot or not cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
		return
	end

	local pawnId = pawn:GetId()
	if GAME.legendary_plus.phoenix.used_by_pawn[pawnId] then
		return
	end

	-- Delay so other death effects can resolve first (e.g. Rebel Hope)
	modApi:runLater(function()
		local effects = SpaceDamage()
		effects.sScript = string.format([[
			local pawnId = %d
			local pawn = Board:GetPawn(pawnId)
			if pawn and pawn:IsDead() then
				Board:AddAlert(pawn:GetSpace(), "PHOENIX")
				Board:Ping(pawn:GetSpace(), GL_Color(255, 140, 40))
				GAME.legendary_plus.phoenix.pending_revive[pawnId] = true
			end
		]], pawnId)
		Board:AddEffect(effects)
	end)
end

function customSkill.revivePending()
	initGameSaveData()
	for pawnId, _ in pairs(GAME.legendary_plus.phoenix.pending_revive) do
		local pawn = Board:GetPawn(pawnId)
		if pawn then
			if not pawn:IsDead() then
				logger.logDebug(SUBMODULE, "Phoenix pawn %d is already alive, skipping revive", pawnId)
			else
				local pawnSpace = pawn:GetSpace()

				-- Revive to 1 HP, clear fire/acid
				local repairDamage = SpaceDamage(pawnSpace, -1)
				repairDamage.iFire = EFFECT_REMOVE
				repairDamage.iAcid = EFFECT_REMOVE
				repairDamage.iFrozen = EFFECT_REMOVE
				-- iShield doesn't seem to work here
				--repairDamage.iShield = EFFECT_CREATE
				repairDamage.sScript = string.format([[
					local pawn = Board:GetPawn(%d)
					if pawn then
						pawn:SetBoosted(true)
						modApi:runLater(function()
							pawn:SetShield(true)
						end)
					end
					Board:AddAlert(%s, "PHOENIX")
					Board:Ping(%s, GL_Color(255, 180, 60))
				]], pawnId, pawnSpace:GetString(), pawnSpace:GetString())
				Board:AddEffect(repairDamage)

				GAME.legendary_plus.phoenix.used_by_pawn[pawnId] = true
				GAME.legendary_plus.phoenix.buffed_by_pawn[pawnId] = true
				logger.logDebug(SUBMODULE, "Phoenix revived pawn %d to 1 HP at %s",
						pawnId, pawnSpace:GetString())
			end
		end
		GAME.legendary_plus.phoenix.pending_revive[pawnId] = nil
	end
end

function customSkill.nextTurnRevive()
	if Game:GetTeamTurn() ~= TEAM_PLAYER then
		return
	end
	customSkill.revivePending()
end

-- Reset Turn restores undo tracked heal, but script buffs can be dropped.
-- Re apply after the board finishes restoring (runLater), and shield via AddEffect.
function customSkill.reapplyReviveBuffs(mission)
	initGameSaveData()
	local pawnIds = {}
	for pawnId, _ in pairs(GAME.legendary_plus.phoenix.buffed_by_pawn) do
		table.insert(pawnIds, pawnId)
	end
	if #pawnIds == 0 then
		return
	end

	modApi:runLater(function()
		for _, pawnId in ipairs(pawnIds) do
			local pawn = Board and Board:GetPawn(pawnId)
			if pawn and not pawn:IsDead() then
				applyReviveBuffs(pawn)
				logger.logDebug(SUBMODULE, "Phoenix re-applied shield/boost to pawn %d after turn reset", pawnId)
			end
		end
	end)
	-- Clear it so reloads don't reapply
	GAME.legendary_plus.phoenix.buffed_by_pawn = {}
end

return customSkill
