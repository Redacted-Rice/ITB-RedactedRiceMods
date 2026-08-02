local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "InvulnerablePlus",
	shortName = "Invulnerable+",
	fullName = "Invulnerable+",
	description = "Once per mission, the first time this mech dies, it is revived with 1 HP at the start of the next turn (or mission end).",
	icon = "img/combat/icons/icon_Pilot_Invulnerable_Plus.png",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	constraints = {
		pilotExclusions = {cplus_plus_ex.isCyborg},
		groups = {"Revive"},
	}
}

customSkill.DEBUG = true
local logger = memhack.logger
local SUBMODULE = logger.register("RebalCore+", "InvulnerablePlus", customSkill.DEBUG)

local mod = mod_loader.mods[modApi.currentMod]

-- Initialize GAME save data structure
local function initGameSaveData()
	if GAME == nil then
		GAME = {}
	end

	if GAME.rebalcoreplus == nil then
		GAME.rebalcoreplus = {}
	end

	if GAME.rebalcoreplus.invulnerable_plus == nil then
		GAME.rebalcoreplus.invulnerable_plus = {}
	end

	-- Track which mechs have used their revive this mission (per pawn ID)
	if GAME.rebalcoreplus.invulnerable_plus.used_by_pawn == nil then
		GAME.rebalcoreplus.invulnerable_plus.used_by_pawn = {}
	end

	-- Track which mechs died this turn and need to be revived (per pawn ID)
	if GAME.rebalcoreplus.invulnerable_plus.pending_revive == nil then
		GAME.rebalcoreplus.invulnerable_plus.pending_revive = {}
	end
end

-- Change icon based on if its been used or not
more_plus.libs.traitReplace:addStateful{
	targetTrait = "massive",
	func = function(trait, pawn)
		if not cplus_plus_ex:isSkillOnPawn(customSkill.id, pawn) then
			return 0  -- Don't display
		end

		initGameSaveData()
		local pawnId = pawn:GetId()
		if GAME.rebalcoreplus.invulnerable_plus.used_by_pawn[pawnId] then
			return 2  -- Used state
		else
			return 1  -- Active state
		end
	end,
	states = {
		{
			icon = customSkill.icon,
			desc_title = customSkill.shortName .." (Active)",
			desc_text = customSkill.description,
		},
		{
			icon = "img/combat/icons/icon_Pilot_Invulnerable_Plus_Used.png",
			desc_title = customSkill.shortName .." (Used)",
			desc_text = "Invulnerable+ revive has been used this mission.",
		},
	}
}

function customSkill:setupEffect()
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(customSkill.resetTrackedData))
	table.insert(customSkill.events, modApi.events.onMissionNextPhaseCreated:subscribe(customSkill.resetTrackedData))
	table.insert(customSkill.events, modapiext.events.onPawnKilled:subscribe(customSkill.pawnKilled))
	table.insert(customSkill.events, modApi.events.onNextTurn:subscribe(customSkill.nextTurnRevive))
	table.insert(customSkill.events, modApi.events.onMissionEnd:subscribe(customSkill.revivePending))
end

-- Mission start hook - reset all tracking
function customSkill.resetTrackedData()
	initGameSaveData()
	GAME.rebalcoreplus.invulnerable_plus.used_by_pawn = {}
	GAME.rebalcoreplus.invulnerable_plus.pending_revive = {}
end

-- Pawn killed hook - mark pawn for revive if eligible
function customSkill.pawnKilled(mission, pawn)
	initGameSaveData()
	-- Only trigger on mechs with the effect
	if not pawn or not pawn:IsMech() then
		return
	end
	local pilot = pawn:GetPilot()
	if not pilot or not cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
		return
	end
	
	local pawnId = pawn:GetId()
	if not GAME.rebalcoreplus.invulnerable_plus.used_by_pawn[pawnId] then
		-- Mark this pawn as pending revive in a run later to allow other 
		-- effects to trigger first (e.g. rebel hope)
		modApi:runLater(function()
			local effects = SpaceDamage()
			effects.sScript = [[
				local pawnId = ]]..pawn:GetId()..[[
				local pawn = Board:GetPawn(pawnId)
				if pawn and pawn:IsDead() then
					Board:AddAlert(pawn:GetSpace(), "INVULNERABLE+")
					Board:Ping(pawn:GetSpace(), GL_Color(255, 0, 0))
					GAME.rebalcoreplus.invulnerable_plus.pending_revive[pawnId] = true
				end
			]]
			Board:AddEffect(effects)
		end)
	end
end
	
function customSkill.revivePending()
	initGameSaveData()
	for pawnId, _ in pairs(GAME.rebalcoreplus.invulnerable_plus.pending_revive) do
		local pawn = Board:GetPawn(pawnId)
		if pawn and pawn:IsDead() then
			-- Revive the pawn to 1 HP using the repair skill effect
			local pawnSpace = pawn:GetSpace()
			local repairDamage = SpaceDamage(pawnSpace, -1)
			repairDamage.iFire = EFFECT_REMOVE
			repairDamage.iAcid = EFFECT_REMOVE
			Board:AddEffect(repairDamage)
			logger.logDebug(SUBMODULE, "Added heal for pawn %d at %s", 
					pawnId, pawnSpace:GetString())

			-- Add visual feedback
			Board:AddEffect(SpaceDamage(Point(0,0), 0, 0.5))
			local effects = SpaceDamage()
			effects.sScript = [[
				Board:AddAlert(]]..pawnSpace:GetString()..[[, "INVULNERABLE+")
				Board:Ping(]]..pawnSpace:GetString()..[[, GL_Color(100, 200, 255))
			]]
			Board:AddEffect(effects)

			-- Mark this pawn as having used their revive
			GAME.rebalcoreplus.invulnerable_plus.used_by_pawn[pawnId] = true
		end
		-- Clear the pending revive flag
		GAME.rebalcoreplus.invulnerable_plus.pending_revive[pawnId] = nil
	end
end

-- Next turn hook - revive any pending mechs at the start of player's turn
function customSkill.nextTurnRevive()
	-- data initialized in revivePending
	if Game:GetTeamTurn() ~= TEAM_PLAYER then
		return
	end
	customSkill.revivePending()
end

return customSkill