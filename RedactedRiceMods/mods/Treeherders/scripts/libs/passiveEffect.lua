passiveEffect = {}

local addPassiveEffectDebug = false --set this to true if you are having issues with running passive weapons to help determine what is going wrong
local PASSIVE_EFFECT_BASE_FN_NAME = "GetPassiveSkillEffect" --shouldn't change this. Treat it as a constant. Changing in later version would cause incompatibility


local passiveEffectData = {}
passiveEffectData.autoPassivedWeapons = {}
passiveEffectData.possibleEffects = {}
passiveEffectData.activeEffects = {}

--creates a string for the add function corresponding to the passed hook.
--For now all the hook appear to follow the same format but any special cases
--can be addressed in this function as needed
local function getAddFunctionForHook(hook)
	return "add"..hook:gsub("^%l", string.upper)
end

local function getFunctionNameForHook(hook)
	return PASSIVE_EFFECT_BASE_FN_NAME.."_"..hook:gsub("^%l", string.upper)
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
function passiveEffect:addPassiveEffect(weapon, hook, weaponIsNotPassiveOnly)
	--ensure they are valid weapon/effect combo upfront to reduce user error	
	assert(type(weapon) == "string")
	assert(_G[weapon])
	
	--if its a passive weapon, we will auto set the Passive field
	if not weaponIsNotPassiveOnly then
		--key based on the weapon as an easy way to avoid duplicates
		passiveEffectData.autoPassivedWeapons[weapon] = true 
	end
		
	--if they pass a table, add it for each hook
	if type(hook) == "table" then
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
		local weaponFunctionName = getFunctionNameForHook(hook)
		assert(_G[weapon][weaponFunctionName])
		assert(type(_G[weapon][weaponFunctionName]) == "function")
		
		--ensure the add function exists
		local addHook = getAddFunctionForHook(hook)
		assert(modapiext[addHook] or modApi[addHook])
		assert(type(modapiext[addHook]) == "function" or type(modApi[addHook]) == "function")
		
		
		--get the list of potential effects associated with the hook or create it
		local hookTable = passiveEffectData.possibleEffects[hook]
		if not hookTable then
			hookTable = {}
			passiveEffectData.possibleEffects[hook] = hookTable
		end
		
		--add the weapon to the list of possible passive effects
		table.insert(hookTable, weapon)
	end
end

--checks if the passed weapon data is in the list of potential passive weapons
--and if it is construct the data needed and add it to the active passive 
--weapons list
function passiveEffect:checkAndAddIfPassive(weaponTable, owningPawnId)
	--for each hook that has possible passive effects
	for hook, weaponsWithPassives in pairs(passiveEffectData.possibleEffects) do
		if addPassiveEffectDebug then LOG("Checking passive weapons for hook: "..hook) end
		
		--for each passive weapon of this hook
		for i, weapon in pairs(weaponsWithPassives) do
			if addPassiveEffectDebug then LOG("Checking known passive weapon id: "..weapon) end
			
			--check the id and if it matches then add the effect to the list of effects to execute for this hook
			if weaponTable.id == weapon then
			
				--get the name with extensions so we can find the right object to call the effect function on
				local wName = passiveEffect:getWeaponNameWithUpgrade(weaponTable)
				if addPassiveEffectDebug then LOG("FOUND PASSIVE WEAPON!: "..wName) end
				
				--if the weapon is powerd
				if self:isWeaponPowered(weaponTable) then
					if addPassiveEffectDebug then LOG("And it is active/powered") end
					
					--get the weapon object and the effect function to use when the hook is fired
					local wObj = _G[wName]
					local wEffect = wObj[getFunctionNameForHook(hook)]
					
					--get the list of active effects associated with the hook or create it
					local hookTable = passiveEffectData.activeEffects[hook]
					if not hookTable then
						hookTable = {}
						passiveEffectData.activeEffects[hook] = hookTable
					end
					
					--add the weapon and effect to the list of active passive effects for this hook
					local data = {}
					data.weapon = wObj
					data.effect = wEffect
					data.pawnId = owningPawnId --don't use Board:getPawn() bcause Board may not exist yet
					table.insert(hookTable, data)
				elseif addPassiveEffectDebug then 
					LOG("but it is not active(powered)...")
				end
			end
		end
	end
end

function passiveEffect:checkAndAddIfPassiveByPoweredWeaponName(weaponNameWithSuffix, owningPawnId)
	--for each hook that has possible passive effects
	for hook, weaponsWithPassives in pairs(passiveEffectData.possibleEffects) do
		if addPassiveEffectDebug then LOG("Checking passive weapons for hook: "..hook) end
		
		--for each passive weapon of this hook
		for i, weapon in pairs(weaponsWithPassives) do
			if addPassiveEffectDebug then LOG("Checking known passive weapon id: "..weapon) end
			
			--check the id and if it matches then add the effect to the list of effects to execute for this hook
			if string.sub(weaponNameWithSuffix,1,string.len(weapon)) == weapon then
				if addPassiveEffectDebug then LOG("FOUND POWERED PASSIVE WEAPON!: "..weaponNameWithSuffix) end
				
				--get the weapon object and the effect function to use when the hook is fired
				local wObj = _G[weaponNameWithSuffix]
				local wEffect = wObj[getFunctionNameForHook(hook)]
				
				--get the list of active effects associated with the hook or create it
				local hookTable = passiveEffectData.activeEffects[hook]
				if not hookTable then
					hookTable = {}
					passiveEffectData.activeEffects[hook] = hookTable
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
function passiveEffect.determineIfPassivesAreActiveFromSaveData(mission)
	if addPassiveEffectDebug then LOG("Determining what Passive Effects are active(powered)...") end

	--clear the previous list of active effects
	passiveEffect.clearActivePassives(mission)
	
	--loop through the player mechs to see if they have one of the passive weapons equiped and powered
	local pawns = passiveEffect:getAllSavedPawnData()
	for _, pawnData in pairs(pawns) do
		if addPassiveEffectDebug then LOG("Checking pawn: "..pawnData.type) end
		
        --get theweapon data
        local primary = modapiext.pawn:getWeaponData(pawnData, "primary")
        local secondary = modapiext.pawn:getWeaponData(pawnData, "secondary")
    
        --if it has a primary then check if it is in the passive effects list
        if primary.id then
            if addPassiveEffectDebug then LOG("Checking primary weapon: "..primary.id) end
            passiveEffect:checkAndAddIfPassive(primary, pawnData.id)
		end
		       
	   --if it has a secondary then check if it is in the passive effects list
        if secondary.id then
            if addPassiveEffectDebug then LOG("Checking secondary weapon: "..secondary.id) end
            passiveEffect:checkAndAddIfPassive(secondary, pawnData.id)
		end
	end
end

function passiveEffect.determineIfPassivesAreActive(mission)
	if addPassiveEffectDebug then LOG("Determining what Passive Effects are active(powered)...") end

	--clear the previous list of active effects
	passiveEffect.clearActivePassives(mission)
	
	--loop through the player mechs to see if they have one of the passive weapons equiped and powered
	local pawns = Board:GetPawns(TEAM_ANY)
	for _, pawnId in pairs(extract_table(pawns)) do
		if addPassiveEffectDebug then LOG("Checking pawn: "..pawnId) end
		
		--get the weapon data
		local pawn = Board:GetPawn(pawnId) 
		local weapons = pawn:GetPoweredWeaponTypes() 
		for _, result in pairs(weapons) do
			LOG("Weapon " .. tostring(result))
			passiveEffect:checkAndAddIfPassiveByPoweredWeaponName(result, pawnId)
		end
	end
end

function passiveEffect.clearActivePassives(mission)
	passiveEffectData.activeEffects = {}
end

--Function that is called after the mods are loaded that will set the passive
--field of any passive weapons automagically so the modder doesn't have to worry 
--about remembering to do this
function passiveEffect:autoSetWeaponsPassiveFields()
	for weapon,_ in pairs(passiveEffectData.autoPassivedWeapons) do
		if addPassiveEffectDebug then LOG("Making weapon "..weapon.." passive...") end
		for _, variety in pairs(self:getAllExistingNamesForWeapon(weapon)) do
			_G[variety].Passive = variety
			if addPassiveEffectDebug then LOG("   Made variety "..variety.." passive!") end
		end
	end
end

--Generates the function that calls all passive effects registered for a specific 
--hook when the hook is fired. This should be called once per hook with possible
--passive effects
function buildPassiveEffectHookFn(hook)
	return function(...)
		if not (Pawn and Board and modapiext.weapon:isTipImage()) then
			if addPassiveEffectDebug then LOG("Evaluating active(powered) passive effects for hook: "..hook) end
			local previousPawn = Pawn
			if passiveEffectData.activeEffects[hook] then
				for _,effectWeaponTable in pairs(passiveEffectData.activeEffects[hook]) do
					if Board then
						Pawn = Board:GetPawn(effectWeaponTable.pawnId)
					end
					effectWeaponTable.effect(effectWeaponTable.weapon, ...)
				end
			end
			Pawn = previousPawn
		else
			if addPassiveEffectDebug then LOG("Detected this is for a tool tip. Skipping active(powered) passive effects for hook: "..hook) end
		end
	end
end

--The function that adds the required hooks to the game for passive weapons
--This should only be called once for all instances of ModUtils!
function passiveEffect:addHooks()
	modApi:addMissionStartHook(self.determineIfPassivesAreActive) --covers starting a new 
	modApi:addPostLoadGameHook(self.determineIfPassivesAreActiveFromSaveData) --covers loading into (continuing) a mission
	modApi:addMissionNextPhaseCreatedHook(self.determineIfPassivesAreActive) --covers transition from first phase of final fight to second phase
	modApi:addMissionEndHook(self.clearActivePassives) --covers ending a mission (prevents adding multiple times)`
	
	--Create the needed hook objects and add the functions that handle executing
	--the active passive effects
	for hook,_ in pairs(passiveEffectData.possibleEffects) do 
		local hookObj = buildPassiveEffectHookFn(hook)
		local addHook = getAddFunctionForHook(hook)
		
		--supports hooks in both the ModLoader and the ModUtils
		if modapiext[addHook] then
			modapiext[addHook](modapiext, hookObj)
		else --already asserted that its in one of the two
			modApi[addHook](modApi, hookObj)
		end
	end
end
		
		
--TODO remove once incorperated into modUtils

--returns all the player mechs in the passed source table. If the table
--is omitted it will determine the table to use.
--This is a modified version of the pawn:getSavedataTable() function
function passiveEffect:getAllSavedPawnData(sourceTable)
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
        return self:getAllSavedPawnData(region.player.map_data)
    end

    --if we didn't find any pawns return nil
    return nil
end        
        

		
--Returns the upgrade suffix of the weapon i.e. _A,_B,_AB, or empty
function passiveEffect:getUpgradeSuffix(wtable)
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
function passiveEffect:getWeaponNameWithUpgrade(weaponTable)
    return weaponTable.id..self:getUpgradeSuffix(weaponTable)
end

--Determines if the weapon is powered on. This will return true if the 
--weapon is on by default (i.e. requires no power) or it is fully 
--powered and false otherwise
function passiveEffect:isWeaponPowered(weaponTable)
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
function passiveEffect:getAllExistingNamesForWeapon(weaponBaseName)
    local allExisting = {}
    for _, possiblility in pairs({weaponBaseName, weaponBaseName.."_A", weaponBaseName.."_B", weaponBaseName.."_AB"}) do
        if _G[possiblility] then
            table.insert(allExisting, possiblility)
        end
    end
    
    return allExisting
end

return passiveEffect