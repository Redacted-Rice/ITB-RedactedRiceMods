predictableRandom = {
	DebugLog = false
}

--use a large value internally to preserve entropy
predictableRandom.min_internal = 0
predictableRandom.max_internal = 2147483647

function predictableRandom:seedGlobally(seed)
	if seed then
		predictableRandom.seed_internal = seed
	else
		predictableRandom.seed_internal = os.time()
	end
end

--set the global seed
predictableRandom:seedGlobally()

local function rollRandomizer(rand)
	--add count just to prevent a case where it would be stuck on a seed
	local seed = (rand.currSeed + rand.currCount) % predictableRandom.max_internal
	rand.currCount = rand.currCount + 1
	rand.savedCount = rand.currCount
	
	--use the seed to get a new seed so the seed space use isnt 
	--continuous so its less likely to have two seeds align
	math.randomseed(seed)
	rand.currSeed = math.random(predictableRandom.min_internal, predictableRandom.max_internal)
	rand.savedSeed = rand.currSeed
end

local function getRandomizer(id)
	--if its a tool tip in the squad selection GAME will not exist
	--create/seed it if the GAME or the randomizer for the id does not exist and return it
	if not(GAME and GAME.Randomizers and GAME.Randomizers[id]) then
		return predictableRandom:seed(id)
	end
	
	--otherwise return the randomizer at the passed id
	return GAME.Randomizers[id] 
end

function predictableRandom:seed(id, seed)
	local rand = {}
	
	--If used in a tooltip in squad selection then GAME wont exist
	if GAME then
		if not GAME.Randomizers then
			GAME.Randomizers = {}
		end
		
		rand = GAME.Randomizers[id]
		if not rand then
			rand = {}
			GAME.Randomizers[id] = rand
		end
	end
	
	rand.currCount = 0
	rand.savedCount = 0
	
	if seed then
		rand.currSeed = seed
	else
		rand.currSeed = predictableRandom.seed_internal
		predictableRandom.seed_internal = predictableRandom.seed_internal + 1
	end
	rand.savedSeed = rand.currSeed
	
	return rand
end

function predictableRandom:roll(id)
	if predictableRandom.DebugLog then LOG("Rolling "..id) end
	rollRandomizer(getRandomizer(id))
end

function predictableRandom:resetToLastRoll(id)
	local rand = getRandomizer(id)
	rand.currSeed = rand.savedSeed
	rand.currCount = rand.savedCount
	if predictableRandom.DebugLog then LOG("Reset "..id.." to count "..rand.currCount.." and seed "..rand.currSeed) end
end

function predictableRandom:getNextValue(id, minVal, maxVal, randSalt)
	local rand = getRandomizer(id)
	if predictableRandom.DebugLog then LOG("Getting value for "..id.." with seed "..rand.currSeed.." and count "..rand.currCount) end
	
	local seed = rand.currSeed + rand.currCount
	rand.currCount = rand.currCount + 1
	
	if randSalt then
		seed = seed + randSalt
	end
	seed = seed % predictableRandom.max_internal
	
	--set the seed to the stored seed so the returned value is always the same
	math.randomseed(seed)
	rand.currSeed = math.random(predictableRandom.min_internal, predictableRandom.max_internal)
	
	math.randomseed(rand.currSeed)
	return math.random(minVal, maxVal)
end

--roll the randomizer each turn to keep things varying
function predictableRandom:registerAutoRollHook()
	modApi:addNextTurnHook(function()
			if GAME.Randomizers then
				for _, rand in pairs(GAME.Randomizers) do
					rollRandomizer(rand)
				end
			end
		end
	)
end

return predictableRandom
    