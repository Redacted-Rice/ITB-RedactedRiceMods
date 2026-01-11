local mod = mod_loader.mods[modApi.currentMod]
local path = mod.scriptPath

WorldBuildersAchievements = {
	zapPreDamage = 0,
	zapBuildingHealth = 0,
	spleefSkillBuilt = false,
	queuedAttacks = {},
}

local squad = "worldbuilders"
local achievements = {
	utilitarian = modApi.achievements:add{
		id = "utilitarian",
		name = "Utilitarian",
		tooltip = "Consume a building to prevent even more grid damage from happening (consumed building doesn't count)",
		image = mod.resourcePath .. "img/achievements/utilitarian.png",
		squad = squad,
	},

	greatwall = modApi.achievements:add{
		id = "greatwall",
		name = "The Great Wall",
		tooltip = "Complete a mission with mountains connecting one side of the board to the other",
		image = mod.resourcePath .. "img/achievements/greatwall.png",
		squad = squad,
	},

	spleef = modApi.achievements:add{
		id = "spleef",
		name = "Spleef!",
		tooltip = "Drop an enemy into the void by swapping out the terrain under them",
		image = mod.resourcePath .. "img/achievements/spleef.png",
		squad = squad,
	},
}

local function isGame()
	return Game ~= nil and GAME ~= nil
end

local function isRightSquad()
	return isGame() and GAME.additionalSquadData.squad == squad
end

local function isInMission()
	local mission = GetCurrentMission()
	return isGame() and mission ~= nil and mission ~= Mission_Test
end

local function hashPoint(point) 
	return point.x + point.y * Board:GetSize().x
end

local function unhashPoint(hash) 
	local size = Board:GetSize()
	return Point(hash % size.x, math.floor(hash / size.x))
end


-- Great Wall
local function searchForMountains(doReverse)
	local possibleLoc = {}
	local size = Board:GetSize()
	local yPoint = 0
	local yGoal = size.y - 1
	local baseDir = DIR_DOWN
	local closest = 0
	if doReverse then
		yPoint = size.y - 1
		yGoal = 0
		baseDir = DIR_UP
	end
	
	-- Create starting points
	for x = 0, size.x - 1 do
		local point = Point(x, yPoint)
		if Board:GetTerrain(point) == TERRAIN_MOUNTAIN then
			possibleLoc[#possibleLoc + 1] = point
		end
	end	
	
	local explored = {}
	while #possibleLoc ~= 0 do
		local current = pop_back(possibleLoc)
		
		if not explored[hashPoint(current)] then
			explored[hashPoint(current)] = true
			
			if Board:GetTerrain(current) == TERRAIN_MOUNTAIN then
				local value = current.y + 1
				if doReverse then
					value = size.y - current.y
				end
				
				if value > closest then
					closest = value
					if closest >= size.y then
						break
					end
				end
			
				-- in reverse search priority
				local back = (baseDir + 2) % 4
				local front = baseDir
				local side1 = (baseDir + 1) % 4
				local side2 = (baseDir + 3) % 4
				local points = {current + DIR_VECTORS[back], current + DIR_VECTORS[back] + DIR_VECTORS[side1], current + DIR_VECTORS[back] + DIR_VECTORS[side2],
								current + DIR_VECTORS[side1], current + DIR_VECTORS[side2],
								current + DIR_VECTORS[front] + DIR_VECTORS[side1], current + DIR_VECTORS[front] + DIR_VECTORS[side2], current + DIR_VECTORS[front]}
				for _, neighbor in pairs(points) do
					if Board:IsValid(neighbor) and not explored[hashPoint(neighbor)] then
						possibleLoc[#possibleLoc + 1] = neighbor
					end
				end
			end	
		end
	end
	
	return closest
end

local function sideToSideMountainChainLength()
	-- left bottom to top right check, then reverse check
	--LOG("PASS 1")
	local length = searchForMountains(false)
	if length < Board:GetSize().x then
		--LOG("PASS 2")
		local length2 = searchForMountains(true)
		if length2 > length then
			return length2
		end
	end
	return length
end

local baseTooltip = achievements.greatwall.getTooltip
achievements.greatwall.getTooltip = function(self)
	local result = baseTooltip(self)
	
	if (not achievements.greatwall:isComplete()) and isInMission() then
		result = result .. "\n\nCurrent Mountain Chain Length: " .. tostring(sideToSideMountainChainLength() .. " / " .. Board:GetSize().x)
		--result = result .. "\n\nCurrent Mountain Chain Length: " .. " / " .. Board:GetSize().x
	end

	return result
end

-- utilitarian
local function determineTotalGridThread(consumedSpace)
	local threat = {}
	
	--LOG("PARSING QUEUED ATTACKS")
	for pawnLoc, queuedAttacks in pairs(WorldBuildersAchievements.queuedAttacks) do
		--LOG("PARSING QUEUED ATTACKS for pawn "..unhashPoint(pawnLoc):GetString())
		if Board:GetPawn(unhashPoint(pawnLoc)) ~= nil then
			--LOG("PAWN FOUND")
			for _, qAttack in pairs(queuedAttacks) do
				--LOG("PARSING QUEUED ATTACK at "..qAttack.loc:GetString())
				if Board:GetTerrain(qAttack.loc) == TERRAIN_BUILDING then
					--LOG("ATTACKING BUILDING")
					if threat[qAttack.loc] == nil then
						--LOG("NEW ENTRY ".. qAttack.loc:GetString() .. " - " .. qAttack.damage)
						threat[qAttack.loc] = qAttack.damage
					else 
						--LOG("OLD ENTRY ".. qAttack.loc:GetString() .. " - " .. threat[qAttack.loc] .. " to " .. (threat[qAttack.loc] + qAttack.damage))
						threat[qAttack.loc] = threat[qAttack.loc] + qAttack.damage
					end
				end
			end
		end
	end
	
	--LOG("PARSING GRID THREAT")
	local gridThreat = 0
	for loc, damage in pairs(threat) do
		if loc ~= consumedSpace then
			--LOG("PARSING GRID THREAT at " .. loc:GetString() .. " - " .. Board:GetHealth(loc) .. " - " .. damage)
			if Board:GetHealth(loc) > damage then
				--LOG("DAMAGE")
				gridThreat = gridThreat + damage
			else
				--LOG("HEALTH")
				gridThreat = gridThreat + Board:GetHealth(loc)
			end
		--else
			--LOG("PARSING GRID THREAT at " .. loc:GetString() .. " FOUND CONSUMED - " .. Board:GetHealth(loc) .. " - " .. damage)
		end
	end
	return gridThreat
end

-- Great Wall
function WorldBuildersAchievements.onMissionEndHook(mission)
	if (not achievements.greatwall:isComplete() and sideToSideMountainChainLength() >= Board:GetSize().x) then
		achievements.greatwall:trigger()
	end
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

-- Utilitarian
function WorldBuildersAchievements.onSkillBuildHook(mission, pawn, weaponId, p1, p2, skillEffect)
	if isRightSquad() and not achievements.utilitarian:isComplete() then	


		-- make sure we have the actual weaponid
		if type(weaponId) == 'table' then
			weaponId = weaponId.__Id
		end 
		
		-- check the conditions to see if this built skill satisfies the requirement

		if string.sub(weaponId, 1 , string.len("WorldBuilders_Consume")) == "WorldBuilders_Consume" then
			-- reset the flag. We do this inside the check because other
			-- weapons can be called between the final skill build hook and the
			-- skill end hook
			WorldBuildersAchievements.zapBuildingHealth = 0
		
			--LOG("BUILDING CONSUME")
			local dir = GetDirection(p2 - p1) % 4
			local consumeSpace = p1 + DIR_VECTORS[(dir + 2) % 4]
			if Board:GetTerrain(consumeSpace) == TERRAIN_BUILDING then
				WorldBuildersAchievements.zapBuildingHealth = Board:GetHealth(consumeSpace)
			end
		-- track all other attacks
		elseif string.sub(weaponId, 1 , string.len("Move")) ~= "Move" then
			--LOG("QUEUING ATTACK for " .. weaponId .. " at " .. p1:GetString())
			local queued = {}
			for _, spaceDamage in pairs(extract_table(skillEffect.q_effect)) do
				--LOG("QUEUING " .. spaceDamage.loc:GetString() .. " - " .. spaceDamage.iDamage)
				local entry = {}
				entry.loc = Point(spaceDamage.loc)
				entry.damage = spaceDamage.iDamage
				queued[#queued + 1] = entry
			end	
			WorldBuildersAchievements.queuedAttacks[hashPoint(p1)] = queued
			--LOG("QUEUed ATTACK CNT " .. tablelength(WorldBuildersAchievements.queuedAttacks))
		end
	end
end

-- Spleef
function WorldBuildersAchievements.onFinalEffectBuildHook(mission, pawn, weaponId, p1, p2, p3, skillEffect)
	if isRightSquad() and not achievements.spleef:isComplete() then		
		-- make sure we have the actual weaponid
		if type(weaponId) == 'table' then
			weaponId = weaponId.__Id
		end 
		
		-- check the conditions to see if this built skill satisfies the requirement

		if string.sub(weaponId, 1 , string.len("WorldBuilders_Shift")) == "WorldBuilders_Shift" then
			-- reset the flag. We do this inside the check because other
			-- weapons can be called between the final skill build hook and the
			-- skill end hook
			WorldBuildersAchievements.spleefSkillBuilt = false
		
			-- update here
			-- Skip if not a multitarget - but how?
			-- for p2 & p3 to see if they will fall into a void when swapped
			if (Board:GetTerrain(p3) == TERRAIN_HOLE and Board:GetPawn(p2) ~= nil and Board:GetPawn(p2):IsEnemy() and (Board:GetPawn(p2):IsFrozen() or not Board:GetPawn(p2):IsFlying())) or 
			   (Board:GetTerrain(p2) == TERRAIN_HOLE and Board:GetPawn(p3) ~= nil and Board:GetPawn(p3):IsEnemy() and (Board:GetPawn(p3):IsFrozen() or not Board:GetPawn(p3):IsFlying())) then
				WorldBuildersAchievements.spleefSkillBuilt = true
			end
		end
	end
end

-- Utilitarian
function WorldBuildersAchievements.onSkillStartHook(mission, pawn, weaponId, p1, p2)
	if isRightSquad() and not achievements.utilitarian:isComplete()then
		-- make sure we have the actual weaponid
		if type(weaponId) == 'table' then
			weaponId = weaponId.__Id
		end 
		
		if string.sub(weaponId, 1 , string.len("WorldBuilders_Consume")) == "WorldBuilders_Consume" and WorldBuildersAchievements.zapBuildingHealth > 0 then
			local dir = GetDirection(p2 - p1) % 4
			local consumeSpace = p1 + DIR_VECTORS[(dir + 2) % 4]
			WorldBuildersAchievements.zapPreDamage = determineTotalGridThread(consumeSpace)
			--LOG("PRE GRID " .. WorldBuildersAchievements.zapPreDamage)
		end
	end
end

-- Utilitarian
function WorldBuildersAchievements.onSkillEndHook(mission, pawn, weaponId, p1, p2)
	if isRightSquad() and not achievements.utilitarian:isComplete()then
		-- make sure we have the actual weaponid
		if type(weaponId) == 'table' then
			weaponId = weaponId.__Id
		end 
		
		if string.sub(weaponId, 1 , string.len("WorldBuilders_Consume")) == "WorldBuilders_Consume" and WorldBuildersAchievements.zapBuildingHealth > 0 then
			local dir = GetDirection(p2 - p1) % 4
			local consumeSpace = p1 + DIR_VECTORS[(dir + 2) % 4]
			local postDamage = determineTotalGridThread(consumeSpace)
			--LOG("PRE GRID " .. WorldBuildersAchievements.zapPreDamage .. " POST GRID " .. postDamage)
			if WorldBuildersAchievements.zapPreDamage - postDamage > WorldBuildersAchievements.zapBuildingHealth then
				achievements.utilitarian:trigger()
			end
		end
	end
end

-- Spleef
function WorldBuildersAchievements.onFinalEffectEndHook(mission, pawn, weaponId, p1, p2, p3)
	if isRightSquad() and not achievements.spleef:isComplete()then
		-- make sure we have the actual weaponid
		if type(weaponId) == 'table' then
			weaponId = weaponId.__Id
		end 
		
		if string.sub(weaponId, 1 , string.len("WorldBuilders_Shift")) == "WorldBuilders_Shift" and WorldBuildersAchievements.spleefSkillBuilt then
			achievements.spleef:trigger()
		end
	end
end


function WorldBuildersAchievements:addHooks()
	modApi.events.onMissionEnd:subscribe(self.onMissionEndHook)
	
	modapiext:addSkillBuildHook(self.onSkillBuildHook)
	modapiext:addSkillStartHook(self.onSkillStartHook)
	modapiext:addSkillEndHook(self.onSkillEndHook)
	modapiext:addFinalEffectBuildHook(self.onFinalEffectBuildHook)
	modapiext:addFinalEffectEndHook(self.onFinalEffectEndHook)
end