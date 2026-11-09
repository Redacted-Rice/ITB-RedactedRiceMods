--[[
IgnoreLiquid - A small lib to add support for IgnoreLiquid flag for pawns and a set method
to dynamically override this flag

Wiki: https://github.com/Redacted-Rice/ITB-RedactedRiceMods/wiki/%5BLib%5D-IgnoreLiquid

Author: Das Keifer of Redacted Rice
Discord Server: https://discord.gg/CNjTVrpN4v
]]

local VERSION = "1.0.0"
local DEBUG = false

-- Massive trait cycle slot for ignore defined here so we can overwrite it if desired (e.g. Admiral legendary+ skill)
local REPLACE_NAME = "ignoreLiquid"
local ICON_FILE = "icon_rr_ignore_liquid.png"
local TRAIT_ICON = "img/combat/icons/" .. ICON_FILE

local function logDebug(...)
	if DEBUG then
		LOG("IgnoreLiquid: " .. string.format(...))
	end
end

local isNewestVersion = false
	or IgnoreLiquid == nil
	or modApi:isVersionAbove(VERSION, IgnoreLiquid.version)

if isNewestVersion then
	LOG("IgnoreLiquid: Loading version " .. VERSION .. " (previous: "
			.. tostring(IgnoreLiquid and IgnoreLiquid.version or "none") .. ")")

	IgnoreLiquid = IgnoreLiquid or {}
	IgnoreLiquid.version = VERSION
	IgnoreLiquid.REPLACE_NAME = REPLACE_NAME
	IgnoreLiquid.TRAIT_ICON = TRAIT_ICON

	-- Pawns that should ignore liquid dynamically (ones with the IgnoreLiquid unit flag
	-- are not inlcuded here unless we override them to false)
	-- true = force on, false = force off (overrides mech IgnoreLiquid), nil = use mech flag only
	IgnoreLiquid.modifiedIgnoreLiquidPawns = IgnoreLiquid.modifiedIgnoreLiquidPawns or {}
	-- Actual pawns actively hijacking flying to make them ignore liquid
	IgnoreLiquid.hijackedFlying = IgnoreLiquid.hijackedFlying or {}
	IgnoreLiquid.ignoreLiquidMoveRecalculating = false

	-- Will get combined with BoardUtils.isPawnFlying if present
	function IgnoreLiquid.isPawnFlying(pawn)
		return pawn:IsFlying() and not IgnoreLiquid._isPawnHijackedFlyingForIgnoreLiquid(pawn)
	end

	-- We use our own hijacked flying state and tracking
	function IgnoreLiquid._isPawnHijackedFlyingForIgnoreLiquid(pawn)
		return pawn and IgnoreLiquid.hijackedFlying[pawn:GetId()]
	end

	function IgnoreLiquid._setHijackedFlyingForIgnoreLiquid(pawn, enabled)
		if not pawn then
			return
		end
		local pawnId = pawn:GetId()
		if enabled then
			IgnoreLiquid.hijackedFlying[pawnId] = true
			pawn:SetFlying(true)
			logDebug("Hijacked flying enabled for pawn %d", pawnId)
		elseif IgnoreLiquid.hijackedFlying[pawnId] then
			IgnoreLiquid.hijackedFlying[pawnId] = nil
			pawn:SetFlying(false)
			logDebug("Hijacked flying disabled for pawn %d", pawnId)
		end
	end

	function IgnoreLiquid.pawnHasIgnoreLiquidUnitFlag(pawn)
		if not pawn then
			return false
		end
		local unit = _G[pawn:GetType()]
		return unit ~= nil and unit.IgnoreLiquid == true
	end

	function IgnoreLiquid.set(pawn, active, force)
		if not pawn then
			return
		end
		local pawnId = pawn:GetId()
		if active then
			IgnoreLiquid.modifiedIgnoreLiquidPawns[pawnId] = true
		-- If we put it in as false, it overrides the units flag
		elseif force then
			IgnoreLiquid.modifiedIgnoreLiquidPawns[pawnId] = false
		else
			IgnoreLiquid.modifiedIgnoreLiquidPawns[pawnId] = nil
		end
		logDebug("setIgnoreLiquid pawn %d active=%s force=%s override=%s",
				pawnId, tostring(active), tostring(force),
				tostring(IgnoreLiquid.modifiedIgnoreLiquidPawns[pawnId]))

		-- Refresh the pawn in case we need to apply flying
		IgnoreLiquid._refreshIgnoreLiquidFlying(pawn)
	end

	function IgnoreLiquid.pawnIgnoresLiquid(pawn)
		if not pawn then
			return false
		end
		local pawnId = pawn:GetId()
		local override = IgnoreLiquid.modifiedIgnoreLiquidPawns[pawnId]
		if override ~= nil then
			return override
		end
		return IgnoreLiquid.pawnHasIgnoreLiquidUnitFlag(pawn)
	end

	function IgnoreLiquid.pawnIsOnLiquid(pawn)
		return pawn and Board and BoardUtils.isLiquid(Board:GetTerrain(pawn:GetSpace()))
	end

	function IgnoreLiquid._forEachPawn(fn)
		if Board then
			local pawns = Board:GetPawns(TEAM_ANY)
			for i = 1, pawns:size() do
				local pawnId = pawns:index(i)
				local pawn = Board:GetPawn(pawnId)
				if pawn then
					fn(pawn, pawnId)
				end
			end
			return
		end
		-- If board is not ready but game is, its just the player pawns
		if Game then
			for pawnId = 0, 2 do
				local pawn = Game:GetPawn(pawnId)
				if pawn then
					fn(pawn, pawnId)
				end
			end
		end
	end

	function IgnoreLiquid._refreshIgnoreLiquidFlyingWrapper(mission, pawn)
		return IgnoreLiquid._refreshIgnoreLiquidFlying(pawn)
	end

	function IgnoreLiquid._refreshIgnoreLiquidFlying(pawn)
		if pawn and Board and not Board:IsTipImage() then
			logDebug("_refreshIgnoreLiquidFlying pawn %d", pawn:GetId())
			if IgnoreLiquid.pawnIgnoresLiquid(pawn) then
				local terrain = Board:GetTerrain(pawn:GetSpace())
				if BoardUtils.isLiquid(terrain) then
					logDebug("Setting flying for pawn %d on liquid terrain", pawn:GetId())
					IgnoreLiquid._setHijackedFlyingForIgnoreLiquid(pawn, true)
				else
					logDebug("Removing flying for pawn %d on solid terrain", pawn:GetId())
					IgnoreLiquid._setHijackedFlyingForIgnoreLiquid(pawn, false)
				end
			elseif IgnoreLiquid._isPawnHijackedFlyingForIgnoreLiquid(pawn) then
				logDebug("Removing hijacked flying for pawn %d (no longer ignores liquid)", pawn:GetId())
				IgnoreLiquid._setHijackedFlyingForIgnoreLiquid(pawn, false)
			end
		end
	end

	function IgnoreLiquid._applyOnMissionEnter()
		-- Board may not be ready yet - just always run later for consistency
		-- and simplicity
		modApi:runLater(function()
			logDebug("ApplyOnMissionEnter - Run Later")
			IgnoreLiquid._forEachPawn(function(pawn)
				IgnoreLiquid._refreshIgnoreLiquidFlying(pawn)
			end)
		end)
	end

	-- Restore any hijacked pawns to not flying
	function IgnoreLiquid._clearMissionState()
		IgnoreLiquid._forEachPawn(function(pawn, pawnId)
			if IgnoreLiquid.hijackedFlying[pawnId] then
				logDebug("Clearing hijacked flying for pawn %d", pawnId)
				IgnoreLiquid._setHijackedFlyingForIgnoreLiquid(pawn, false)
			end
		end)
	end

	-- Overrides target area calculation for pawns set to flying to ignore liquid
	function IgnoreLiquid._onMoveTargetArea(mission, pawn, weaponId, p1, targetArea)
		-- ignoreLiquidMoveRecalculating guards against re entering from fireTargetAreaBuildHooks below.
		if weaponId == "Move" and not IgnoreLiquid.ignoreLiquidMoveRecalculating then
			-- If the pawn should ignore liquid, is on liquid and is currently hijacking flying we need to
			-- recalculate without flying
			if IgnoreLiquid.pawnIgnoresLiquid(pawn) and IgnoreLiquid._isPawnHijackedFlyingForIgnoreLiquid(pawn)
					and IgnoreLiquid.pawnIsOnLiquid(pawn) then
				logDebug("Recalculating move target area for pawn %d at %s",
						pawn:GetId(), p1:GetString())
				while not targetArea:empty() do
					targetArea:erase(0)
				end
				local groundedPoints = BoardUtils.getMoveReachableInRange(
						pawn, pawn:GetMoveSpeed(), p1, "default")
				for idx = 1, groundedPoints:size() do
					targetArea:push_back(groundedPoints:index(idx))
				end

				IgnoreLiquid.ignoreLiquidMoveRecalculating = true
				modApiExt_internal.fireTargetAreaBuildHooks(mission, pawn, weaponId, p1, targetArea)
				IgnoreLiquid.ignoreLiquidMoveRecalculating = false
			end
		end
	end

	function IgnoreLiquid._registerTraitReplaceIcon()
		if not TraitReplace or not TraitReplace.add or not TraitReplace.registerTrait then
			logDebug("TraitReplace unavailable, skip ignoreLiquid cycle icon")
			return
		end

		local iconPath = mod_loader.mods.redactedrice_libs.scriptPath .. "libs/" .. ICON_FILE
		if not modApi:fileExists(iconPath) then
			logDebug("ignoreLiquid icon missing at %s", iconPath)
			return
		end

		modApi:appendAsset(TRAIT_ICON, iconPath)

		TraitReplace:add{
			id = REPLACE_NAME,
			targetTrait = "massive",
			replaces = false,
			func = function(_, pawn)
				return IgnoreLiquid.pawnIgnoresLiquid(pawn)
			end,
			icon = TRAIT_ICON,
			desc_title = "Ignore Liquid",
			desc_text = "Mech is unaffected by liquid tiles.",
		}
		logDebug("Registered ignoreLiquid trait replace icon")
	end

	function IgnoreLiquid._installBoardUtilsOverrides()
		if IgnoreLiquid._overrideBoardUtils or not BoardUtils then
			return
		end

		BoardUtils.CanMoveOnWater = BoardUtils.makeAllowIf(BoardUtils.CanMoveOnWater, function(pawn)
			return IgnoreLiquid.pawnIgnoresLiquid(pawn)
		end)

		-- Combine our isPawnHijackedFlying with BoardUtils but keep our version sepearte
		local originalIsPawnHijackedFlying = BoardUtils.isPawnHijackedFlying
		BoardUtils.isPawnHijackedFlying = function(pawn)
			return originalIsPawnHijackedFlying(pawn) or IgnoreLiquid._isPawnHijackedFlyingForIgnoreLiquid(pawn)
		end

		-- Defer our isFlying it BoardUtils - it already calls isPawnHijackedFlying so the above
		-- override will cause it to combine this behavior with that
		IgnoreLiquid.isPawnFlying = function(pawn)
			return BoardUtils.isPawnFlying(pawn)
		end

		IgnoreLiquid._overrideBoardUtils = true
		logDebug("Installed BoardUtils Overrides")
	end

	function IgnoreLiquid:finalizeInit()
		-- At this point the last BoardUtils will have already set its fns so its safe to override them here
		IgnoreLiquid._installBoardUtilsOverrides()
		IgnoreLiquid._registerTraitReplaceIcon()

		-- Override move targetting so it won't allow moving on holes
		modapiext.events.onTargetAreaBuild:subscribe(IgnoreLiquid._onMoveTargetArea)

		-- On move (or on selected as a backup), update the flying state of the pawn
		modapiext.events.onPawnPositionChanged:subscribe(IgnoreLiquid._refreshIgnoreLiquidFlyingWrapper)
		modapiext.events.onPawnSelected:subscribe(IgnoreLiquid._refreshIgnoreLiquidFlyingWrapper)

		-- Make sure state is updated on mission starts and loading into a mission
		modApi.events.onMissionStart:subscribe(IgnoreLiquid._applyOnMissionEnter)
		modApi.events.onMissionNextPhaseCreated:subscribe(IgnoreLiquid._applyOnMissionEnter)
		modApi.events.onPostLoadGame:subscribe(IgnoreLiquid._applyOnMissionEnter)

		modApi.events.onMissionEnd:subscribe(IgnoreLiquid._clearMissionState)
	end
else
	LOG("IgnoreLiquid: Skipping version " .. VERSION .. " (previous: "
			.. IgnoreLiquid.version .. ")")
end

local function onModsInitialized()
	if VERSION < IgnoreLiquid.version then
		return
	end

	if IgnoreLiquid.initialized then
		return
	end

	IgnoreLiquid:finalizeInit()
	IgnoreLiquid.initialized = true
	logDebug("Finalized version %s", VERSION)
end

modApi:addModsInitializedHook(onModsInitialized)

return IgnoreLiquid
