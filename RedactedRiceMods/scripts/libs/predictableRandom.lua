--[[
PredictableRandom - Allows for choosing random values in a predictable with resets and undoing

Author: Das Keifer of Redacted Rice
Version: 1.2.0
Discord Server: https://discord.gg/CNjTVrpN4v

My own usage of this was mostly removed because I decided to go a different way for the non-passive weapons
but the passive "Wake the Forest" still uses this somewhat. See the Treeherder's
forestUtils:floraformNumOfRandomSpaces function for a simple example of usage

How to Use:
In the function mod:load(options, version) in init.lua add this lines:
	predictableRandom:load()
Make sure you have initialized and called passiveEffect:addPassiveEffect for each weapon as part of init to
ensure all weapons are loaded before the passive effects are loaded or else they will not work properly.
This must also be done once per instance and in the load function as the hooks are cleared and reloaded
when starting or reloading a game

When creating a weapon:
1. (optional) set the global seed for cross game consistency
	predictableRandom:seedGlobally(<some number>)
2. Create an ID for each random generator desired
	local randId = "Treeherders_Passive_WakeTheForest"..tostring(Pawn:GetId())
3. (optional) seed the random generator instance
	predictableRandom:seed(randId, <some number>)
4. Use the randomizer functions passing the randId

API
predictableRandom:getNextValue(id, minVal, maxVal, randSalt)
	Gets a bounded random value from the passed randomizer id
		id - the randomizer id
		minVal - Minimum value (inclusive)
		maxVal - Maximum value (inclusive)
		randSalt - If resetting and reusing the id, this allows variation while keeping randomness
					A good example might be passing in a hash of a target space to vary the result
					predictably based on what tile is targeted
predictableRandom:roll(id)
	Rolls the seed to a new value in a predictable/repeatable way. Used to refresh the random values
		id - the randomizer id

predictableRandom:resetToLastRoll(id)
	Resets the randomizer to the last rolled/inital values to repeat the predictable random values
		id - the randomizer id
 ]]--

local VERSION = "1.2.0"

-- Version check
local isNewestVersion = false
	or PredictableRandom == nil
	or modApi:isVersionAbove(VERSION, PredictableRandom.version)

if isNewestVersion then
	LOG("PredictableRandom: Loading version " .. VERSION .. " (previous: " .. tostring(PredictableRandom and PredictableRandom.version or "none") .. ")")

	-- Initialize global singleton
	PredictableRandom = PredictableRandom or {}
	PredictableRandom.version = VERSION

	-- Set to true to debug the lib or to help see how its behaving
	PredictableRandom.DebugLog = PredictableRandom.DebugLog or false

	--use a large value internally to preserve entropy
	PredictableRandom.min_internal = PredictableRandom.min_internal or 0
	PredictableRandom.max_internal = PredictableRandom.max_internal or 2147483647

	function PredictableRandom:seedGlobally(seed)
		if seed then
			PredictableRandom.seed_internal = seed
		else
			PredictableRandom.seed_internal = os.time()
		end
	end

	--set the global seed
	PredictableRandom:seedGlobally()

	-- Helper functions (part of the object, version-guarded)
	function PredictableRandom.rollRandomizer(rand)
		--add count just to prevent a case where it would be stuck on a seed
		local seed = (rand.currSeed + rand.currCount) % PredictableRandom.max_internal
		rand.currCount = rand.currCount + 1
		rand.savedCount = rand.currCount

		--use the seed to get a new seed so the seed space use isnt
		--continuous so its less likely to have two seeds align
		math.randomseed(seed)
		rand.currSeed = math.random(PredictableRandom.min_internal, PredictableRandom.max_internal)
		rand.savedSeed = rand.currSeed
	end

	function PredictableRandom.getRandomizer(id)
		--if its a tool tip in the squad selection GAME will not exist
		--create/seed it if the GAME or the randomizer for the id does not exist and return it
		if not(GAME and GAME.Randomizers and GAME.Randomizers[id]) then
			return PredictableRandom:seed(id)
		end

		--otherwise return the randomizer at the passed id
		return GAME.Randomizers[id]
	end

	function PredictableRandom:seed(id, seed)
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
			rand.currSeed = PredictableRandom.seed_internal
			PredictableRandom.seed_internal = PredictableRandom.seed_internal + 1
		end
		rand.savedSeed = rand.currSeed

		return rand
	end

	function PredictableRandom:roll(id)
		if PredictableRandom.DebugLog then LOG("Rolling "..id) end
		PredictableRandom.rollRandomizer(PredictableRandom.getRandomizer(id))
	end

	function PredictableRandom:resetToLastRoll(id)
		local rand = PredictableRandom.getRandomizer(id)
		rand.currSeed = rand.savedSeed
		rand.currCount = rand.savedCount
		if PredictableRandom.DebugLog then LOG("Reset "..id.." to count "..rand.currCount.." and seed "..rand.currSeed) end
	end

	function PredictableRandom:getNextValue(id, minVal, maxVal, randSalt)
		local rand = PredictableRandom.getRandomizer(id)
		if PredictableRandom.DebugLog then LOG("Getting value for "..id.." with seed "..rand.currSeed.." and count "..rand.currCount) end

		local seed = rand.currSeed + rand.currCount
		rand.currCount = rand.currCount + 1

		if randSalt then
			seed = seed + randSalt
		end
		seed = seed % PredictableRandom.max_internal

		--set the seed to the stored seed so the returned value is always the same
		math.randomseed(seed)
		rand.currSeed = math.random(PredictableRandom.min_internal, PredictableRandom.max_internal)

		math.randomseed(rand.currSeed)
		return math.random(minVal, maxVal)
	end

	--roll the randomizer each turn to keep things varying
	function PredictableRandom:registerAutoRollHook()
		modApi:addNextTurnHook(function()
				if GAME.Randomizers then
					for _, rand in pairs(GAME.Randomizers) do
						PredictableRandom.rollRandomizer(rand)
					end
				end
			end
		)
	end

	function PredictableRandom:load()
		PredictableRandom:registerAutoRollHook()
	end
else
	LOG("PredictableRandom: Skipping version " .. VERSION .. " (already have " .. PredictableRandom.version .. ")")
end

return PredictableRandom
