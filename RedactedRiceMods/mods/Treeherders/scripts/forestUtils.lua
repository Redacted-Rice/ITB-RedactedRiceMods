forestUtils = {}

forestUtils.floraformBounce = -3

function forestUtils.arrayLength(array)
	local count = 0
	for _, _ in pairs(array) do 
		count = count + 1 
	end
	return count
end

local botNames = {"Snowtank", "Snowart", "Snowlaser", "Snowmine", "BotBoss"}
function forestUtils.isAVek(pawn)
	-- The bots don't use TEAM_BOT so we have to manually sort them out but
	-- still exclude it anyways
	local isVek = false
	if pawn:GetTeam() == TEAM_ENEMY or pawn:GetTeam() == TEAM_ENEMY_MAJOR then
		isVek = true
		for _, botName in pairs(botNames) do
			if string.sub(pawn:GetType(), 1 , string.len(botName)) == botName then
				isVek = false
				break
			end
		end	
	end
	return isVek
end


-------------------  FOREST CHECKER FUNCTIONS  ----------------------------

function forestUtils.isAForestFire(p)
	--do special logic for the tip since we cannot use getTileFireType
	if modapiext.weapon:isTipImage() then
		return Board:IsFire(p)
		
	--normal logic
	else
		return Board:IsForestFire(p) or 
				(Board:GetTerrain(p) == TERRAIN_FOREST and Board:IsFire(p))
	end
end

function forestUtils.isAForest(p)
	return Board:GetTerrain(p) == TERRAIN_FOREST or forestUtils.isAForestFire(p)
end

-------------------  SPACE DAMAGE FUNCTIONS  ----------------------------

function forestUtils.terrainFloraformableMatcher(p)
	local terrain = Board:GetTerrain(p)
	return (terrain == TERRAIN_FOREST or terrain == TERRAIN_ROAD or terrain == TERRAIN_RUBBLE or terrain == TERRAIN_SAND) and
			not(Board:IsAcid(p)) and not(Board:IsFire(p))
end

function forestUtils.isSpaceFloraformable(space)
	return forestUtils.terrainFloraformableMatcher(space)
end

function forestUtils:getSpaceDamageWithoutSettingFire(p, damage, pushDir, allyImmune, buildingImmune)
	local spaceDamage = nil
	local pawn = Board:GetPawn(p)
	
	local sDamage = damage
	if sDamage == 0 or (allyImmune and ((pawn and pawn:IsPlayer()) or Board:IsPod(p))) or (buildingImmune and Board:IsBuilding(p)) then
		sDamage = DAMAGE_ZERO
	end
	
	if pushDir then
		spaceDamage = SpaceDamage(p, sDamage, pushDir)
	else
		spaceDamage = SpaceDamage(p, sDamage)
	end
	
	--prevent it from setting a fire but don't put out an on fire pawn
	if not (Board:IsFire(p) or (pawn and pawn:IsFire())) then
		spaceDamage.iFire = EFFECT_REMOVE
	end
	
	-- For some reason we AE, we have to reset if its a forest or else
	-- the forest will disappear (but not forest fires)
	if Board:GetTerrain(p) == TERRAIN_FOREST then
		spaceDamage.iTerrain = TERRAIN_FOREST
	end
	
	--cover up the forest fire icon
	if sDamage > 0 and sDamage ~= DAMAGE_ZERO and Board:GetTerrain(p) == TERRAIN_FOREST and not Board:IsFire(p) then
		spaceDamage.sImageMark = "combat/icons/icon_th_forest_burn_cover.png"
	end
	
	return spaceDamage
end

function forestUtils:getFloraformSpaceDamage(p, damage, pushDir, allyImmune, buildingImmune)
	local spaceDamage = self:getSpaceDamageWithoutSettingFire(p, damage, pushDir, allyImmune, buildingImmune)
	
	if self.isSpaceFloraformable(p) and not self.isAForest(p) then
		spaceDamage.iTerrain = TERRAIN_FOREST
		spaceDamage.sImageMark = "combat/icons/damage_floraform.png"
		
		--This should prevent tile that are on fire from becoming fire tiles with forests instead of forest fire tiles
		if Board:IsFire(p) then
			spaceDamage.iFire = EFFECT_CREATE
		end
	end
	
	return spaceDamage
end

-------------------  FLORAFORMING FUNCTIONS  ----------------------------

function forestUtils:getNumForestsInPlus(p)
	local count = 0
	
	if self.isAForest(p) then
		count = count + 1
	end
	
	for dir = 0, 3 do
		if forestUtils.isAForest(p + DIR_VECTORS[dir]) then
			count = count + 1
		end
	end
	
	return count
end

function forestUtils:floraformSpace(effect, point, damage, pushDir, allyImmune, buildingImmune)
	damage = damage or DAMAGE_ZERO
	
	effect:AddDamage(self:getFloraformSpaceDamage(point, damage, pushDir, allyImmune, buildingImmune))			
	effect:AddBounce(point, self.floraformBounce)
end

local function randFloraformDamage(effect, point, damage, pushDir, damageOnlyEnemy, allyImmune, buildingImmune)
	local pawn = Board:GetPawn(point)
	
	if damageOnlyEnemy and not (pawn and pawn:IsEnemy()) then
		damage = DAMAGE_ZERO
	end
	
	forestUtils:floraformSpace(effect, point, damage, pushDir, allyImmune, buildingImmune)
end

function forestUtils:floraformNumOfRandomSpaces(effect, randId, candidates, numToForm, damage, pushDir,
					damageOnlyEnemy, allyImmune, buildingImmune, seekMech, seekEnemy, randSalt, skipFloraformableCheck)
	damage = damage or DAMAGE_ZERO
	
	--remove any points that can't be floraformed
	if not skipFloraformableCheck then
		local toRemove = {}
		for k, v in pairs(candidates) do
			--shouldn't have returned any forests or forest fires
			if not forestUtils.isSpaceFloraformable(v) then
				table.insert(toRemove, k)
			end
		end
		
		--do it in two loops to ensure the iterator isn't messed up by removing items mid iteration
		for _, v in pairs(toRemove) do
			candidates[v] = nil
		end
	end
	
	--if there are not enough, floraform them all and return how many were floraformed
	local retList = {}
	if forestUtils.arrayLength(candidates) <= numToForm then
		for k, point in pairs(candidates) do	
			randFloraformDamage(effect, point, damage, pushDir, damageOnlyEnemy, allyImmune, buildingImmune)
			retList[k] = point
		end
		
	--if there are enough points choose some random ones
	else
		local leftToFloraForm = numToForm
		
		local preferred = {}
		if seekMech or seekEnemy then	
			for k, v in pairs(candidates) do
				local unit = Board:GetPawn(v)
				if unit and ((seekEnemy and unit:IsEnemy()) or (seekMech and unit:IsMech())) then
					preferred[k] = v
				end
			end		
			
			retList = self:floraformNumOfRandomSpaces(effect, randId, preferred, leftToFloraForm, 
					damage, pushDir, damageOnlyEnemy, allyImmune, buildingImmune, false, false, randSalt, skipFloraformableCheck)
			leftToFloraForm = leftToFloraForm - self.arrayLength(retList)
		end
	
	
		if leftToFloraForm > 0 then
			local keys = {}
			for k, _ in pairs(candidates) do
				--only add it if we have not already been floraformed
				if not retList[k] then
					table.insert(keys, k)
				end
			end
			
			for i = 1, leftToFloraForm do
				if #keys > 0 then		
					local index = predictableRandom:getNextValue(randId, 1, #keys, randSalt)
					local point = candidates[keys[index]]
					
					retList[keys[index]] = point
					candidates[keys[index]] = nil
					table.remove(keys, index)
					
					randFloraformDamage(effect, point, damage, pushDir, damageOnlyEnemy, allyImmune, buildingImmune)
				end
			end
		end
	end
	
	
	--Reset the roll at the end to keep the state clean in case this is rebuilt
	--why this no work???
	predictableRandom:resetToLastRoll(randId)
	
	return retList
end

--TODO remove once isolated to library or mod utils
-------------------  TEMP FUNCTIONS  ----------------------------

function forestUtils:addCancelEffect(p, effect)
	effect:AddScript([[
		local enemy = Board:GetPawn(Point(]]..p.x..","..p.y..[[))
		if enemy then
			enemy:ClearQueued()
			Board:AddAlert(]].. p:GetString() ..[[, Global_Texts["Alert_Cleared"])
		end
		Board:Ping(]].. p:GetString() ..[[, GL_Color(210, 210, 210, 0))
	]])
end

function forestUtils:getTileFireType(point)
    local tileTable = modapiext.board:getTileTable(point)
	if tileTable then
		return tileTable.fire or 0
	else
		return 0
	end
end

function forestUtils:getSpaces(predicate, ...)
	assert(type(predicate) == "function")
	
	local matches = {}
	
	if Board then
		--go through each space on the board and check if it matches
		local size = Board:GetSize()
		for y = 0, size.y - 1 do
			for x = 0, size.x - 1 do
				local p = Point(x, y)
				if predicate(p, ...) then
					matches[self:getSpaceHash(p)] = p
				end
			end
		end
	end
	
	return matches
end

function forestUtils:getSpacesThatBorder(predicate, ...)
	assert(type(predicate) == "function")

	bordering = {}

	--covers if board doesnt exist as well
	if Board then
		local size = Board:GetSize()
		for y = 0, size.y - 1 do
			for x = 0, size.x - 1 do
				local currPoint = Point(x, y)
				
				--only check + x and y spaces to optimize some
				local adjacents = {}
				if x < size.x - 1 then
					adjacents[self:getSpaceHash(x + 1, y)] = Point(x + 1, y)
				end
				if y < size.y - 1 then
					adjacents[self:getSpaceHash(x, y + 1)] = Point(x, y + 1)
				end
				
				--if it matches then see if we need to add the + x and y spaces
				if predicate(currPoint, ...) then
					for hash, point in pairs(adjacents) do
						--only add if it doesn't match
						if not predicate(point, ...) then
							bordering[hash] = point
						end
					end
				--otherwise check the + x and y spaces to see if we should add this point
				else
					for _, point in pairs(adjacents) do
						if predicate(point, ...) then
							bordering[self:getSpaceHash(currPoint)] = currPoint
						end
					end
				end
			end
		end
	end
	
	return bordering
end

local function getGrouping_internal(space, groupedSpaces, boarderingSpaces, predicate, ...)
	if not groupedSpaces[forestUtils:getSpaceHash(space)] then
		groupedSpaces[forestUtils:getSpaceHash(space)] = space
	
		local size = Board:GetSize()
		for _, dir in pairs(DIR_VECTORS) do
			local p = space + dir
			if p.x >= 0 and p.x < size.x and p.y >= 0 and p.y < size.y then
				if predicate(p, ...) then
					getGrouping_internal(p, groupedSpaces, boarderingSpaces, predicate, ...)
				else
					boarderingSpaces[forestUtils:getSpaceHash(p)] = p
				end
			end
		end
	end
end

function forestUtils:getGroupingOfSpaces(spaceInGroup, predicate, ...)
	assert(type(predicate) == "function")
	
	local spaces = {}
	spaces.group = {}
	spaces.boardering = {}
	
	getGrouping_internal(spaceInGroup, spaces.group, spaces.boardering, predicate, ...)
	
	return spaces
end

function forestUtils:isSpaceSurroundedBy(space, predicate, ...)
	assert(type(predicate) == "function")

	local surrondingTiles = {space + DIR_VECTORS[1],
			space + DIR_VECTORS[2],
			space + DIR_VECTORS[3],
			space + DIR_VECTORS[0],
	}
 
	for _, p in pairs(surrondingTiles) do 
		if not predicate(p, ...) then
			return false
		end
	end
	
	return true
end

function forestUtils:getClosestOfSpaces(space, otherSpaces)
	assert(type(otherSpaces) == "table")
	
	local closest = nil
	local closestDistance = 999 --much larger than should ever exist
	local dist = 0
	
	for _, s in pairs(otherSpaces) do
		--Board:GetDistance() doesn't seem to work consistently so do it ourselves
		dist = math.abs(space.x - s.x) +  math.abs(space.y - s.y)
		if dist < closestDistance then
			closestDistance = dist
			closest = s
		end
	end
	
	return closest
end

--TODO already in modutils or modloader (not sure which)
function forestUtils:getSpaceHash(spaceOrX, y)
    local pX = spaceOrX
    local pY = y
    if not y then
        pX = spaceOrX.x
        pY = spaceOrX.y
    end
    return pY * 10 + pX

end



return forestUtils
    
    
