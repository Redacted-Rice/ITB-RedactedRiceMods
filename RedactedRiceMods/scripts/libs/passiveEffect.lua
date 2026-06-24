--[[
PassiveEffect - Allows for easily creating passive effect for weapons

Libs Wiki: https://github.com/Redacted-Rice/ITB-RedactedRiceMods/wiki

Author: Das Keifer of Redacted Rice
Discord Server: https://discord.gg/CNjTVrpN4v

How to Use:
In the function mod:load(options, version) in init.lua after loading your weapons, load the passive effects:
	passiveEffect:load()
Make sure you have initialized and called passiveEffect:addPassiveEffect for each weapon as part of init to
ensure all weapons are loaded before the passive effects are loaded or else they will not work properly.
This must also be done once per instance and in the load function as the hooks are cleared and reloaded
when starting or reloading a game

When creating a weapon:
1. Inherit with PassiveSkill:new instead of Skill:new
2. Define GetSkillEffect - these are used for the weapon preview only so they can be hardcoded
3. For any hook, define a function in the weapon for it prefixing the hook name with "GetPassiveSkillEffect".
   All the same arguments will be passed and the signiture must match exactly.
   For example, one of the hooks used by "Wake the Forest" is the SkillBuildHook to reduce damage when the
   Mech in in a forest. To do this the weapon defines this function:
	  Treeherders_Passive_WakeTheForest:GetPassiveSkillEffect_SkillBuildHook(mission, pawn, weaponId, p1, p2, skillFx)
   Inside it, it will check for damage to a mech and reduce it
4. Implement as many hooks as you like! All modloader and modutil hooks should be supported
5. Add the passive effect using the following command:
	passiveEffect:addPassiveEffect(<weapon_name>, {<overriden hook1>, <hook2>, ...})
	e.g from "Wake the Forest"
		"Treeherders_Passive_WakeTheForest",
			{"skillBuildHook", "finalEffectBuildHook",
			"skillEndHook", "finalEffectEndHook",
			"queuedSkillEndHook", "queuedFinalEffectEndHook",
			"preEnvironmentHook"})
 ]]--

local VERSION = "1.5.0"

-- Version check
local isNewestVersion = false
	or PassiveEffect == nil
	or modApi:isVersionAbove(VERSION, PassiveEffect.version)

if isNewestVersion then
	LOG("PassiveEffect: Loading version " .. VERSION .. " (previous: " .. tostring(PassiveEffect and PassiveEffect.version or "none") .. ")")

	-- Initialize global singleton
	PassiveEffect = PassiveEffect or {}
	PassiveEffect.version = VERSION

	-- Set to true to debug the lib
	PassiveEffect.DebugLog = PassiveEffect.DebugLog or false

	--shouldn't change this. Treat it as a constant. Changing in later version would cause incompatibility
	PassiveEffect.PASSIVE_EFFECT_BASE_FN_NAME = PassiveEffect.PASSIVE_EFFECT_BASE_FN_NAME or "GetPassiveSkillEffect"

	-- Initialize data tables
	PassiveEffect.data = PassiveEffect.data or {}
	PassiveEffect.data.autoPassivedWeapons = PassiveEffect.data.autoPassivedWeapons or {}
	PassiveEffect.data.possibleEffects = PassiveEffect.data.possibleEffects or {}
	PassiveEffect.data.activeEffects = PassiveEffect.data.activeEffects or {}
	PassiveEffect.data.activePassives = PassiveEffect.data.activePassives or {}
	PassiveEffect.data.eventSubscriptions = PassiveEffect.data.eventSubscriptions or {}  -- Track event subscriptions

	if PassiveEffect.IsMechTest == nil then
		PassiveEffect.IsMechTest = false
		PassiveEffect.hasEvaluatedForMechTest = false
	end

	--creates a string for the add function corresponding to the passed hook.
	--For now all the hook appear to follow the same format but any special cases
	--can be addressed in this function as needed
	function PassiveEffect.getAddFunctionForHook(hook)
		return "add"..hook:gsub("^%l", string.upper)
	end

	-- Check if this is an event (starts with "on") vs a hook (ends with "Hook")
	function PassiveEffect.isEvent(name)
		return name:match("^on")
	end

	function PassiveEffect.isHook(name)
		return name:match("Hook$")
	end

	-- Find an event in modApi.events, modapiext.events, or BoardEvents
	function PassiveEffect.findEvent(eventName)
		if modApi and modApi.events and modApi.events[eventName] then
			return modApi.events[eventName], "modApi.events"
		end
		if modapiext and modapiext.events and modapiext.events[eventName] then
			return modapiext.events[eventName], "modapiext.events"
		end
		if BoardEvents and BoardEvents[eventName] then
			return BoardEvents[eventName], "BoardEvents"
		end
		return nil, nil
	end

	function PassiveEffect.getFunctionNameForHook(hook)
		return PassiveEffect.PASSIVE_EFFECT_BASE_FN_NAME.."_"..hook:gsub("^%l", string.upper)
	end

	--A function that adds the passive effect to the game. Generally these will
	--be for passive weapons only but could in theory be non passive weapons
	--as well. Passive weapons should be declared the same as other weapons. The
	--GetSkillEffect method that is generally used for weapons is only used to
	--construct the tool tip for passive only weapons. The GetPassiveSkillEffect(...)
	--function of the passed in weapon will be called each time the specified hook(s)
	--are fired if a mech has the weapon equiped and it is powered on. The
	--GetPassiveSkillEffect function can use all the fields of the weapon via
	--"self" and will be passed the arguements of whatever hook is specified.
	--Additionally, "Pawn" will be set to be the pawn who owns the weapon with
	--the passive effect similar to how it is done in GetSkillEffect(). The
	--name of the hook that was fired is stored in "self.HookName" if different
	--logic is required for different hooks. If the hook is omitted it
	--defaults to postEnvironmentHook. This should support all hooks in the
	--ModLoader and the ModUtil.
	function PassiveEffect:addPassiveEffect(weapon, hook, weaponIsNotPassiveOnly)
		--ensure they are valid weapon/effect combo upfront to reduce user error
		assert(type(weapon) == "string")
		assert(_G[weapon])

		--if its a passive weapon, we will auto set the Passive field
		if not weaponIsNotPassiveOnly then
			--key based on the weapon as an easy way to avoid duplicates
			PassiveEffect.data.autoPassivedWeapons[weapon] = true
		end

		--if they pass a table, add it for each hook
		if type(hook) == "table" then
			if PassiveEffect.DebugLog then LOG("For "..weapon.. " adding several hooks") end
			for _,singleHook in pairs(hook) do
				self:addPassiveEffect(weapon, singleHook, weaponIsNotPassiveOnly)
			end
		else
			hook = hook or "postEnvironmentHook" --default to Post environemnt since thats when most effects occur

			--ensure there is an add function for it and ensure the first character is lower case.
			--This just makes things easier to have consistent format
			assert(type(hook) == "string")
			assert(hook:sub(1,1):lower() == hook:sub(1,1))

			--ensure the hook is defined for the function
			local weaponFunctionName = PassiveEffect.getFunctionNameForHook(hook)
			assert(_G[weapon][weaponFunctionName])
			assert(type(_G[weapon][weaponFunctionName]) == "function")

			-- Check if this is an event or a hook
			local isEvent = PassiveEffect.isEvent(hook)
			local isHook = PassiveEffect.isHook(hook)

			if isEvent then
				-- For events, verify the event exists
				local event, source = PassiveEffect.findEvent(hook)
				if not event then
					error("Event '" .. hook .. "' not found in modApi.events, modapiext.events, or BoardEvents")
				end
				if PassiveEffect.DebugLog then LOG("Found event " .. hook .. " in " .. source) end
			elseif isHook then
				-- For hooks, ensure the add function exists
				local addHook = PassiveEffect.getAddFunctionForHook(hook)
				assert(modapiext[addHook] or modApi[addHook], "Hook function not found: " .. addHook)
				assert(type(modapiext[addHook]) == "function" or type(modApi[addHook]) == "function")
			else
				error("'" .. hook .. "' must be either a hook (ending with 'Hook') or an event (starting with 'on')")
			end

			--get the list of potential effects associated with the hook or create it
			local hookTable = PassiveEffect.data.possibleEffects[hook]
			if not hookTable then
				hookTable = {}
				PassiveEffect.data.possibleEffects[hook] = hookTable
			end

			if PassiveEffect.DebugLog then LOG("For "..weapon.. " added passive hook "..hook) end
			--add the weapon to the list of possible passive effects
			table.insert(hookTable, weapon)
		end
	end

	--Checks if the any weapon with the passed base name is active
	function PassiveEffect:countAnyVersionOfPassiveActive(weaponBaseName)
		local count = 0
		for pawn, activeWeapons in pairs(self.data.activePassives) do
			for	_, activeWeapon in pairs(activeWeapons) do
				if string.sub(activeWeapon, 1, string.len(weaponBaseName)) == weaponBaseName then
					count = count + 1
				end
			end
		end
		return count
	end

	--Checks if the any weapon with the passed base name is active
	function PassiveEffect:isPassiveActive(weaponName)
		for pawn, activeWeapons in pairs(self.data.activePassives) do
			for	_, activeWeapon in pairs(activeWeapons) do
				if activeWeapon == weaponName then
					return true
				end
			end
		end
		return false
	end

	--checks if the passed weapon data is in the list of potential passive weapons
	--and if it is construct the data needed and add it to the active passive
	--weapons list
	function PassiveEffect:checkAndAddIfPassive(weaponTable, owningPawnId)
		--for each hook that has possible passive effects
		for hook, weaponsWithPassives in pairs(PassiveEffect.data.possibleEffects) do
			if PassiveEffect.DebugLog then LOG("Checking passive weapons for hook: "..hook) end

			--for each passive weapon of this hook
			for i, weapon in pairs(weaponsWithPassives) do
				if PassiveEffect.DebugLog then LOG("Checking known passive weapon id: "..weapon) end

				--check the id and if it matches then add the effect to the list of effects to execute for this hook
				if weaponTable.id == weapon then

					--get the name with extensions so we can find the right object to call the effect function on
					local wName = PassiveEffect:getWeaponNameWithUpgrade(weaponTable)
					if PassiveEffect.DebugLog then LOG("FOUND PASSIVE WEAPON!: "..wName) end

					--if the weapon is powerd
					if self:isWeaponPowered(weaponTable) then
						if PassiveEffect.DebugLog then LOG("And it is active/powered") end

						-- add weapon to active passives
						if not PassiveEffect.data.activePassives[owningPawnId] then
							PassiveEffect.data.activePassives[owningPawnId] = {}
						end
						table.insert(PassiveEffect.data.activePassives[owningPawnId], wName)

						--get the weapon object and the effect function to use when the hook is fired
						local wObj = _G[wName]
						local wEffect = wObj[PassiveEffect.getFunctionNameForHook(hook)]

						--get the list of active effects associated with the hook or create it
						local hookTable = PassiveEffect.data.activeEffects[hook]
						if not hookTable then
							hookTable = {}
							PassiveEffect.data.activeEffects[hook] = hookTable
						end

						--add the weapon and effect to the list of active passive effects for this hook
						local data = {}
						data.weapon = wObj
						data.effect = wEffect
						data.pawnId = owningPawnId --don't use Board:getPawn() bcause Board may not exist yet
						table.insert(hookTable, data)
					elseif PassiveEffect.DebugLog then
						LOG("but it is not active(powered)...")
					end
				end
			end
		end
	end

	function PassiveEffect:checkAndAddIfPassiveByPoweredWeaponName(weaponNameWithSuffix, owningPawnId)
		--for each hook that has possible passive effects
		for hook, weaponsWithPassives in pairs(PassiveEffect.data.possibleEffects) do
			if PassiveEffect.DebugLog then LOG("Checking passive weapons for hook: "..hook) end

			--for each passive weapon of this hook
			for i, weapon in pairs(weaponsWithPassives) do
				if PassiveEffect.DebugLog then LOG("Checking known passive weapon id: "..weapon) end

				--check the id and if it matches then add the effect to the list of effects to execute for this hook
				if string.sub(weaponNameWithSuffix,1,string.len(weapon)) == weapon then
					if PassiveEffect.DebugLog then LOG("FOUND POWERED PASSIVE WEAPON!: "..weaponNameWithSuffix) end

					-- add weapon to active passives
					if not PassiveEffect.data.activePassives[owningPawnId] then
						PassiveEffect.data.activePassives[owningPawnId] = {}
					end
					table.insert(PassiveEffect.data.activePassives[owningPawnId], weaponNameWithSuffix)

					--get the weapon object and the effect function to use when the hook is fired
					local wObj = _G[weaponNameWithSuffix]
					local wEffect = wObj[PassiveEffect.getFunctionNameForHook(hook)]

					--get the list of active effects associated with the hook or create it
					local hookTable = PassiveEffect.data.activeEffects[hook]
					if not hookTable then
						hookTable = {}
						PassiveEffect.data.activeEffects[hook] = hookTable
					end

					--add the weapon and effect to the list of active passive effects for this hook
					local data = {}
					data.weapon = wObj
					data.effect = wEffect
					data.pawnId = owningPawnId --don't use Board:getPawn() bcause Board may not exist yet
					table.insert(hookTable, data)
				end
			end
		end
	end

	--function that is called on mission start or when continuing a mission to determine
	--which passive effects are required
	function PassiveEffect.determineIfPassivesAreActiveFromSaveData()
		if PassiveEffect.DebugLog then LOG("Determining what Passive Effects are active(powered)...") end

		--clear the previous list of active effects
		PassiveEffect.clearActivePassives()

		local pawns = PassiveEffect:getAllSavedPawnData()

		--Loaded not in the middle of a mission, nothing needs to be done
		if pawns == nil then
			return
		end

		--loop through the player mechs to see if they have one of the passive weapons equiped and powered
		for _, pawnData in pairs(pawns) do
			if PassiveEffect.DebugLog then LOG("Checking pawn: "..pawnData.type) end

			--get theweapon data
			local primary = modapiext.pawn:getWeaponData(pawnData, "primary")
			local secondary = modapiext.pawn:getWeaponData(pawnData, "secondary")

			--if it has a primary then check if it is in the passive effects list
			if primary.id then
				if PassiveEffect.DebugLog then LOG("Checking primary weapon: "..primary.id) end
				PassiveEffect:checkAndAddIfPassive(primary, pawnData.id)
			end

		   --if it has a secondary then check if it is in the passive effects list
			if secondary.id then
				if PassiveEffect.DebugLog then LOG("Checking secondary weapon: "..secondary.id) end
				PassiveEffect:checkAndAddIfPassive(secondary, pawnData.id)
			end
		end
	end

	function PassiveEffect.determineIfPassivesAreActive()
		if PassiveEffect.DebugLog then LOG("Determining what Passive Effects are active (powered)...") end
		if PassiveEffect.IsMechTest then
			if PassiveEffect.DebugLog then LOG("Test scenario! Aborting update") end
			return
		end

		--clear the previous list of active effects
		PassiveEffect.clearActivePassives()

		--loop through the player mechs to see if they have one of the passive weapons equiped and powered
		-- If we have a board use that
		if GetCurrentMission() then
			if PassiveEffect.DebugLog then LOG("Mission available. Checking it") end
			local pawns = Board:GetPawns(TEAM_ANY)
			for _, pawnId in pairs(extract_table(pawns)) do
				if PassiveEffect.DebugLog then LOG("Checking pawn: "..pawnId) end

				--get the weapon data
				local pawn = Board:GetPawn(pawnId)
				local weapons = pawn:GetPoweredWeaponTypes()
				for _, result in pairs(weapons) do
					PassiveEffect:checkAndAddIfPassiveByPoweredWeaponName(result, pawnId)
				end
			end
		else
			-- Otherwise do our best with Game
			if PassiveEffect.DebugLog then LOG("Mission not available. Updating player mechs only") end
			for pawnId = 0, 2 do
				PassiveEffect.addPassivesGamePawn(pawnId)
			end
		end
	end

	function PassiveEffect.addPassivesGamePawn(pawnId)
		if PassiveEffect.DebugLog then LOG("Checking Game pawn: "..pawnId) end
		--get the weapon data
		local pawn = Game:GetPawn(pawnId)
		if pawn then
			if PassiveEffect.DebugLog then LOG("found pawn. Checking weapons...") end
			local weapons = pawn:GetPoweredWeaponTypes()
			for _, result in pairs(weapons) do
				PassiveEffect:checkAndAddIfPassiveByPoweredWeaponName(result, pawnId)
			end
		end
	end

	function PassiveEffect.saveGameRefreshPassives()
		if PassiveEffect.IsMechTest then
			if not PassiveEffect.hasEvaluatedForMechTest then
				if PassiveEffect.DebugLog then LOG("Refreshing test mechs passives") end
				-- if its a test, just refresh this mechs stuff
				PassiveEffect.hasEvaluatedForMechTest = true
				-- only one should be non-nil but this will handle regardless
				for pawnId = 0, 2 do
					if Game:GetPawn(pawnId) then
						PassiveEffect.data.activePassives[pawnId] = nil
						PassiveEffect.addPassivesGamePawn(pawnId)
					end
				end
			end
		else
			-- Otherwise refresh for all our mechs
			if PassiveEffect.DebugLog then LOG("Updating all passives") end
			PassiveEffect.determineIfPassivesAreActive()
		end
	end

	function PassiveEffect.clearActivePassives()
		PassiveEffect.data.activeEffects = {}
		PassiveEffect.data.activePassives = {}
	end

	--Function that is called after the mods are loaded that will set the passive
	--field of any passive weapons automagically so the modder doesn't have to worry
	--about remembering to do this
	function PassiveEffect:autoSetWeaponsPassiveFields()
		for weapon,_ in pairs(PassiveEffect.data.autoPassivedWeapons) do
			if PassiveEffect.DebugLog then LOG("Making weapon "..weapon.." passive...") end
			for _, variety in pairs(self:getAllExistingNamesForWeapon(weapon)) do
				_G[variety].Passive = variety
				if PassiveEffect.DebugLog then LOG("   Made variety "..variety.." passive!") end
			end
		end
	end

	--Generates the function that calls all passive effects registered for a specific
	--hook when the hook is fired. This should be called once per hook with possible
	--passive effects
	function PassiveEffect.buildPassiveEffectHookFn(hook)
		return function(...)
			if not (Pawn and Board and Board:IsTipImage()) then
				local previousPawn = Pawn
				if PassiveEffect.data.activeEffects[hook] then
					if PassiveEffect.DebugLog then LOG("Evaluating #"..#PassiveEffect.data.activeEffects[hook].." active(powered) passive effects for hook: "..hook) end
					for _,effectWeaponTable in pairs(PassiveEffect.data.activeEffects[hook]) do
						if Board then
							Pawn = Board:GetPawn(effectWeaponTable.pawnId)
						end
						effectWeaponTable.effect(effectWeaponTable.weapon, ...)
					end
				elseif PassiveEffect.DebugLog then
					LOG("No active(powered) passive effects for hook: "..hook)
				end
				Pawn = previousPawn
			else
				if PassiveEffect.DebugLog then LOG("Detected this is for a tool tip. Skipping active(powered) passive effects for hook: "..hook) end
			end
		end
	end

	function PassiveEffect.setIsTestMech(mission)
		PassiveEffect.IsMechTest = true
		PassiveEffect.hasEvaluatedForMechTest = false
	end

	function PassiveEffect.unsetIsTestMech()
		PassiveEffect.IsMechTest = false
		PassiveEffect.hasEvaluatedForMechTest = false
		PassiveEffect.saveGameRefreshPassives()
	end

	function PassiveEffect:subscribeLibEvents()
		if self.libEventsSubscribed then
			return
		end
		self.libEventsSubscribed = true

		modApi.events.onModsLoaded:subscribe(function()
			PassiveEffect:reloadWeaponHooks()
		end)

		modApi.events.onMissionStart:subscribe(function(mission)
			PassiveEffect.determineIfPassivesAreActive()
		end)

		modApi.events.onPostLoadGame:subscribe(function()
			PassiveEffect.determineIfPassivesAreActiveFromSaveData()
		end)

		modApi.events.onSaveGame:subscribe(function()
			PassiveEffect.saveGameRefreshPassives()
		end)

		modApi.events.onTestMechEntered:subscribe(function(mission)
			PassiveEffect.setIsTestMech(mission)
		end)

		modApi.events.onTestMechExited:subscribe(function()
			PassiveEffect.unsetIsTestMech()
		end)
	end

	function PassiveEffect:subscribeWeaponEvents()
		for hookOrEvent, _ in pairs(PassiveEffect.data.possibleEffects) do
			if PassiveEffect.isEvent(hookOrEvent) and not PassiveEffect.data.eventSubscriptions[hookOrEvent] then
				local event, source = PassiveEffect.findEvent(hookOrEvent)
				if event and event.subscribe then
					local handlerFn = PassiveEffect.buildPassiveEffectHookFn(hookOrEvent)
					if PassiveEffect.DebugLog then LOG("Subscribing to event " .. hookOrEvent .. " from " .. source) end
					PassiveEffect.data.eventSubscriptions[hookOrEvent] = event:subscribe(handlerFn)
				else
					LOG("WARNING: Event " .. hookOrEvent .. " not found or doesn't support subscribe!")
				end
			elseif PassiveEffect.DebugLog and PassiveEffect.isEvent(hookOrEvent) then
				LOG("Already subscribed to event: " .. hookOrEvent)
			end
		end
	end

	function PassiveEffect:reloadWeaponHooks()
		for hookOrEvent, _ in pairs(PassiveEffect.data.possibleEffects) do
			if PassiveEffect.isHook(hookOrEvent) then
				if PassiveEffect.DebugLog then LOG("Processing passive effect hook for: " .. hookOrEvent) end

				local handlerFn = PassiveEffect.buildPassiveEffectHookFn(hookOrEvent)
				local addHook = PassiveEffect.getAddFunctionForHook(hookOrEvent)
				if PassiveEffect.DebugLog then LOG("Adding hook " .. hookOrEvent .. " via " .. addHook) end

				if modapiext[addHook] then
					modapiext[addHook](modapiext, handlerFn)
				else
					modApi[addHook](modApi, handlerFn)
				end
			end
		end
	end

	-- One-time setup: lib lifecycle events and weapon event subscriptions
	function PassiveEffect:finalizeInit()
		PassiveEffect:subscribeLibEvents()
		PassiveEffect:subscribeWeaponEvents()
		PassiveEffect:autoSetWeaponsPassiveFields()
	end


	--returns all the player mechs in the passed source table. If the table
	--is omitted it will determine the table to use.
	--This is a modified version of the pawn:getSavedataTable() function
	function PassiveEffect:getAllSavedPawnData(sourceTable)
		pawnsIds = {}
		if sourceTable then
			--look through each item in the table for mechs
			for k, v in pairs(sourceTable) do
				--player mechs keys start with pawn and have the mech flag set to true
				if type(v) == "table" and modApi:stringStartsWith(k, "pawn") then
					pawnsIds[#pawnsIds+1] = v
				end
			end

			--if we found some mechs then return their data
			if #pawnsIds > 0 then
				return pawnsIds
			end
		else
			--determine what table to use and call ourselves with that one
			local region = modapiext.board:getCurrentRegion()
			if region then
				return self:getAllSavedPawnData(region.player.map_data)
			end
		end

		--if we didn't find any pawns return nil
		return nil
	end



	--Returns the upgrade suffix of the weapon i.e. _A,_B,_AB, or empty
	function PassiveEffect:getUpgradeSuffix(wtable)
		if
			wtable.upgrade1 and wtable.upgrade1[1] > 0 and
			wtable.upgrade2 and wtable.upgrade2[1] > 0
		then
			return "_AB"
		elseif wtable.upgrade1 and wtable.upgrade1[1] > 0 then
			return "_A"
		elseif wtable.upgrade2 and wtable.upgrade2[1] > 0 then
			return "_B"
		end

		return ""
	end

	--Returns the full name of the weapon including the suffix (_A,_B,_AB, or none)
	function PassiveEffect:getWeaponNameWithUpgrade(weaponTable)
		return weaponTable.id..self:getUpgradeSuffix(weaponTable)
	end

	--Determines if the weapon is powered on. This will return true if the
	--weapon is on by default (i.e. requires no power) or it is fully
	--powered and false otherwise
	function PassiveEffect:isWeaponPowered(weaponTable)
		--Check that all numbers are greater than 0
		--I think you really only need to check the first but just to be safe I check them all
		for _,power in pairs(weaponTable.power) do
			if power <= 0 then
				return false
			end
		end

		--empty means it needs no power so its always on!
		return true
	end

	--Returns all the varieties of the past weapon name that are defined
	function PassiveEffect:getAllExistingNamesForWeapon(weaponBaseName)
		local allExisting = {}
		for _, possiblility in pairs({weaponBaseName, weaponBaseName.."_A", weaponBaseName.."_B", weaponBaseName.."_AB"}) do
			if _G[possiblility] then
				table.insert(allExisting, possiblility)
			end
		end

		return allExisting
	end
else
	LOG("PassiveEffect: Skipping version " .. VERSION .. " (already have " .. PassiveEffect.version .. ")")
end

local function onModsInitializedHook()
	if VERSION < PassiveEffect.version then
		return
	end

	if BoardUtils.initialized then
		return
	end
	PassiveEffect:finalizeInit()
	PassiveEffect.initialized = true
end

modApi:addModsInitializedHook(onModsInitializedHook)

return PassiveEffect
