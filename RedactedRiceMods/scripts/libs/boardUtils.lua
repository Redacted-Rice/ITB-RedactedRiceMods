--[[
BoardUtils - Utilities related to board, pathing, and movement

Libs Wiki: https://github.com/Redacted-Rice/ITB-RedactedRiceMods/wiki

Author: Das Keifer of Redacted Rice
Discord Server: https://discord.gg/CNjTVrpN4v
]]

local VERSION = "1.8.0"

-- Version check
local isNewestVersion = false
	or BoardUtils == nil
	or modApi:isVersionAbove(VERSION, BoardUtils.version)

if isNewestVersion then
	LOG("BoardUtils: Loading version " .. VERSION .. " (previous: " .. tostring(BoardUtils and BoardUtils.version or "none") .. ")")

	-- Initialize global singleton
	BoardUtils = BoardUtils or {}
	BoardUtils.version = VERSION

	-- Initialize data tables
	BoardUtils.hijackedFlying = BoardUtils.hijackedFlying or {}
	BoardUtils.hijackedPath = BoardUtils.hijackedPath
	-- Caches pathing for performance reasons
	BoardUtils.movePathCache = {}
	BoardUtils.reachableCache = {}
	BoardUtils.NO_PATH = BoardUtils.NO_PATH or {}

	-- Constants
	BoardUtils.SPACE_DAMAGE_KEYS = {
		"bEvacuate",
		"iInjure",
		"iCrack",
		"bSimpleMark",
		"iPush",
		"sPawn",
		"iDamage",
		"bKO_Effect",
		"sItem",
		"iPawnTeam",
		"iFrozen",
		"sScript",
		"bHideIcon",
		"sSound",
		"iFire",
		"sImageMark",
		"iShield",
		"iSmoke",
		"iAcid",
		"sAnimation",
		"iTerrain",
		--"loc",
		"bHide",
		"fDelay",
		"bHidePath",
	}

	function BoardUtils.isPawnHijackedFlying(pawn)
		return BoardUtils.hijackedFlying[pawn:GetId()]
	end

	function BoardUtils.isPawnFlying(pawn)
		return pawn:IsFlying() and not BoardUtils.hijackedFlying[pawn:GetId()]
	end

	-- Helper for building the common "allow this if a condition is met, otherwise
	-- defer to whatever was already there" override chain used by CanMoveOn*/
	-- CanMoveThrough*
	-- Example: BoardUtils.CanMoveOnWater = BoardUtils.makeAllowIf(BoardUtils.CanMoveOnWater, myPredicate)
	function BoardUtils.makeAllowIf(original, allowIfFn)
		return function(pawn)
			if allowIfFn(pawn) then
				return true
			end
			if original ~= nil then
				return original(pawn)
			end
			return false
		end
	end

	-- Convenience wrapper: allowIfFn checks cplus_plus_ex:isSkillOnPawn for skillId.
	-- Example: BoardUtils.CanMoveOnWater = BoardUtils.makeAllowIfHasSkill(BoardUtils.CanMoveOnWater, customSkill.id)
	function BoardUtils.makeAllowIfHasSkill(original, skillId)
		return BoardUtils.makeAllowIf(original, function(pawn)
			return cplus_plus_ex:isSkillOnPawn(skillId, pawn)
		end)
	end

	function BoardUtils.setHijackedFlying(pawn, enabled)
		if enabled then
			BoardUtils.hijackedFlying[pawn:GetId()] = true
			pawn:SetFlying(true)
		elseif BoardUtils.hijackedFlying[pawn:GetId()] then
			BoardUtils.hijackedFlying[pawn:GetId()] = nil
			pawn:SetFlying(false)
		end
	end

	-- Road Runner (Kwan): pilot can pass through enemy units while moving
	-- So can flying and jumping but those currently are handled by the 
	-- pawnCheckType setting. In the future maybe migrate to using this
	-- instead?
	function BoardUtils.canPassThroughEnemyPawns(pawn)
		local pilot = pawn:GetPilot()
		return pilot ~= nil and pilot:getSkillStr() == "Road_Runner"
	end

	-- Override as needed per skills that allow this.
	-- Make sure to call original
	if not BoardUtils.CanMoveOnMountains then
		function BoardUtils.CanMoveOnMountains(pawn)
			return false
		end
	end

	-- Override as needed per skills that allow this.
	-- Make sure to call original
	if not BoardUtils.CanMoveOnBuildings then
		function BoardUtils.CanMoveOnBuildings(pawn)
			return false
		end
	end

	-- Vanilla: only flying pawns can be over holes
	-- Override for skills that grant hole immunity without granting full flight.
	if not BoardUtils.CanMoveOnHoles then
		function BoardUtils.CanMoveOnHoles(pawn)
			return BoardUtils.isPawnFlying(pawn)
		end
	end

	-- Vanilla: flying pawns hover above water/lava/acid, and massive pawns can
	-- move into them but not fire
	if not BoardUtils.CanMoveOnWater then
		function BoardUtils.CanMoveOnWater(pawn)
			return BoardUtils.isPawnFlying(pawn) or pawn:IsMassive()
		end
	end

	-- CanMoveThrough* below governs passing over terrain without landing on it,
	-- distinct from CanMoveOn* above (ending movement). Jumpers and teleporters 
	-- can pass over much unlandable terrain. Fliers can do so as well but are
	-- already covered via the matching CanMoveOn* fallback (if you can land on 
	-- it, you can pass  through it). Skills only need to override CanMoveOn* (eg. 
	-- Nimble, Pontoons/Admiral) and get the matching CanMoveThrough* for "free".
	if not BoardUtils.CanMoveThroughHoles then
		function BoardUtils.CanMoveThroughHoles(pawn)
			return pawn:IsJumper() or pawn:IsTeleporter()
					or BoardUtils.CanMoveOnHoles(pawn)
		end
	end

	if not BoardUtils.CanMoveThroughWater then
		function BoardUtils.CanMoveThroughWater(pawn)
			return pawn:IsJumper() or pawn:IsTeleporter()
					or BoardUtils.CanMoveOnWater(pawn)
		end
	end

	if not BoardUtils.CanMoveThroughBuildings then
		function BoardUtils.CanMoveThroughBuildings(pawn)
			return pawn:IsJumper() or pawn:IsTeleporter()
					or BoardUtils.CanMoveOnBuildings(pawn)
		end
	end

	if not BoardUtils.CanMoveThroughMountains then
		function BoardUtils.CanMoveThroughMountains(pawn)
			return pawn:IsJumper() or pawn:IsTeleporter()
					or BoardUtils.CanMoveOnMountains(pawn)
		end
	end

	function BoardUtils.setHijackedPath(path)
		BoardUtils.hijackedPath = path
	end

	function BoardUtils.getHijackedPath()
		return BoardUtils.hijackedPath
	end

	function BoardUtils.clearHijackedPath()
		BoardUtils.hijackedPath = nil
	end

	-- Move types from memedit constants.lua (SPACE_DAMAGE_PLIST_TYPE_*)
	function BoardUtils.skillEffectUsesPathMovement(skillEffect)
		if not skillEffect or not skillEffect.effect then
			return true
		end

		for idx = 1, skillEffect.effect:size() do
			local spaceDamage = skillEffect.effect:index(idx)
			if spaceDamage:IsMovement() then
				if not spaceDamage.GetMoveType then
					return true
				end
				local moveType = spaceDamage:GetMoveType()
				if moveType == SPACE_DAMAGE_PLIST_TYPE_MOVE
						or moveType == SPACE_DAMAGE_PLIST_TYPE_BURROW then
					return true
				end
				return false
			end
		end

		return true
	end

	function BoardUtils.skillEffectUsesPointToPointMovement(skillEffect)
		return not BoardUtils.skillEffectUsesPathMovement(skillEffect)
	end

	function BoardUtils.addForcedSigleMove(skillEffect, pawnId, dest)
		local moveDamage = SpaceDamage(dest, 0)
		moveDamage.sScript = [[Board:GetPawn(]] .. pawnId .. [[):SetSpace(]] .. dest:GetString() .. [[)]]
		skillEffect:AddDamage(moveDamage)
	end

	function BoardUtils.addForcedMove(skillEffect, path, delay)
		delay = delay or FULL_DELAY

		-- Preserve any existing damage effects. This ended up not being the issue
		-- with boosted not working with momentum and maneuverable but it seems a
		-- useful and good change so I'm leaving it though its largely untested
		local preservedDamages = {}
		-- skip the first one
		for i = 2, skillEffect.effect:size() do
			-- This seems to get a reference that can be changed so
			-- instead copy the data to a table
			local spaceDamage = skillEffect.effect:index(i)
			local copy = {}
			for _, key in ipairs(BoardUtils.SPACE_DAMAGE_KEYS) do
				copy[key] = spaceDamage[key]
			end
			-- Point is userdata and needs to be copied too
			copy.loc = Point(spaceDamage.loc)
			table.insert(preservedDamages, copy)
		end

		-- Clear the existing move from the skilleffect
		skillEffect.effect = SkillEffect().effect

		-- Add move for display purposes. This won't let us move onto unmovable spaces reliably
		skillEffect:AddMove(path, delay)

		-- Store the hijacked path so other systems can use it
		BoardUtils.setHijackedPath(path)

		--maybe needs to be p1?
		local pawnId = Board:GetPawn(path:index(1)):GetId()
		local secondToLastSpace = path:index(path:size() - 1)
		local lastSpace = path:index(path:size())
		BoardUtils.addForcedSigleMove(skillEffect, pawnId, lastSpace)

		-- Re-add any preserved damage effects
		for _, damage in ipairs(preservedDamages) do
			local recreated = SpaceDamage()
			for _, key in ipairs(BoardUtils.SPACE_DAMAGE_KEYS) do
				recreated[key] = damage[key]
			end
			-- Already copied the point so don't need to again
			recreated.loc = damage.loc
			skillEffect:AddDamage(recreated)
		end
	end

	function BoardUtils.makeInSubsetMatcher(tiles)
		return function(point, hash)
			return tiles[hash] ~= nil
		end
	end

	function BoardUtils.isAPlayerTeam(team)
		return team == TEAM_PLAYER or team == TEAM_MECH
	end
	function BoardUtils.isAnEnemyTeam(team)
		return team == TEAM_BOTS or team == TEAM_ENEMY or team == TEAM_ENEMY_MAJOR
	end

	function BoardUtils.makeTerrainBasedMatcher(pawn, pawnCheckType, exclTerrainCheckFn)
		return function(point, hash)
			if exclTerrainCheckFn(point) then
				return false
			end
			if pawnCheckType == "none" then
				return true
			end

			local otherPawn = Board:GetPawn(point)
			if otherPawn then
				if pawnCheckType == "any" then
					return false
				end
				-- Flying, jumping, and teleporting pawns can pass through any other pawn
				if BoardUtils.isPawnFlying(pawn) or pawn:IsJumper() or pawn:IsTeleporter() then
					return true
				end
				-- Block opposing team pawns as default (Road Runner exempt)
				if pawnCheckType == "default" then
					local moverTeam = pawn:GetTeam()
					local otherTeam = otherPawn:GetTeam()
					if BoardUtils.isAPlayerTeam(moverTeam) and BoardUtils.isAnEnemyTeam(otherTeam) or
							BoardUtils.isAnEnemyTeam(moverTeam) and BoardUtils.isAPlayerTeam(otherTeam) then
						return BoardUtils.canPassThroughEnemyPawns(pawn)
					end
				end
			end
			return true
		end
	end

	function BoardUtils.isLiquid(terrain)
		return terrain == TERRAIN_WATER or terrain == TERRAIN_LAVA or terrain == TERRAIN_ACID
	end

	-- pawnCheckType "none", "default", "any"
	-- Normal move end space: respects CanMoveOnHoles/CanMoveOnWater/CanMoveOnBuildings/
	-- CanMoveOnMountains
	function BoardUtils.makeMoveLandableMatcher(pawn, pawnCheckType)
		return BoardUtils.makeTerrainBasedMatcher(pawn, pawnCheckType, function(point)
			local terrain = Board:GetTerrain(point)
			return (terrain == TERRAIN_HOLE and not BoardUtils.CanMoveOnHoles(pawn)) or
					(BoardUtils.isLiquid(terrain) and not BoardUtils.CanMoveOnWater(pawn)) or
					(terrain == TERRAIN_BUILDING and not BoardUtils.CanMoveOnBuildings(pawn)) or
					(terrain == TERRAIN_MOUNTAIN and not BoardUtils.CanMoveOnMountains(pawn))
		end)
	end

	-- pawnCheckType "none", "default", "any"
	-- Normal move path through spaces: respects CanMoveThroughHoles/CanMoveThroughWater/
	-- CanMoveThroughBuildings/CanMoveThroughMountains (which each respect the *CanMoveOn* 
	-- versions)
	function BoardUtils.makeMovePassableMatcher(pawn, pawnCheckType)
		return BoardUtils.makeTerrainBasedMatcher(pawn, pawnCheckType, function(point)
			local terrain = Board:GetTerrain(point)
			return (terrain == TERRAIN_HOLE and not BoardUtils.CanMoveThroughHoles(pawn)) or
					(BoardUtils.isLiquid(terrain) and not BoardUtils.CanMoveThroughWater(pawn)) or
					(terrain == TERRAIN_BUILDING and not BoardUtils.CanMoveThroughBuildings(pawn)) or
					(terrain == TERRAIN_MOUNTAIN and not BoardUtils.CanMoveThroughMountains(pawn))
		end)
	end

	function BoardUtils.clearMoveCaches()
		BoardUtils.movePathCache = {}
		BoardUtils.reachableCache = {}
	end

	-- Cache key has many parts in case it modifies and is called multiple times in a build
	function BoardUtils.makeMoveCacheKey(pawnId, startHash, extraHash, passThroughMode)
		return pawnId .. ":" .. startHash .. ":" .. extraHash .. ":" .. (passThroughMode or "default")
	end

	function BoardUtils.hashesToPointList(hashes, asPointList)
		if asPointList == false then
			local path = {}
			for _, hash in ipairs(hashes) do
				local x, y = BoardUtils.unhashSpace(hash)
				table.insert(path, Point(x, y))
			end
			return path
		end
		local points = PointList()
		for _, hash in ipairs(hashes) do
			local x, y = BoardUtils.unhashSpace(hash)
			points:push_back(Point(x, y))
		end
		return points
	end

	function BoardUtils.pointListToHashes(pointList)
		local hashes = {}
		for idx = 1, pointList:size() do
			table.insert(hashes, BoardUtils.getSpaceHash(pointList:index(idx)))
		end
		return hashes
	end

	function BoardUtils.getReachableInRange(reachable, range, start, predicatePassable, predicateStoppable)
		-- dont include start in reachable
		local visited = {}
		visited[BoardUtils.getSpaceHash(start)] = true

		local queue = { start }
		local dist = { [BoardUtils.getSpaceHash(start)] = 0 }

		local size = 8
		while #queue > 0 do
			local cur = table.remove(queue, 1)
			local curDist = dist[BoardUtils.getSpaceHash(cur)]

			if curDist < range then
				for idx = 0, 3 do
					local adj = cur + DIR_VECTORS[idx]

					if adj.x >= 0 and adj.x < size and adj.y >= 0 and adj.y < size then
						local adjHash = BoardUtils.getSpaceHash(adj)

						if not visited[adjHash] then
							if not predicatePassable or predicatePassable(adj, adjHash) then
								visited[adjHash] = true
								dist[adjHash] = curDist + 1
								if not predicateStoppable or predicateStoppable(adj, adjHash) then
									reachable:push_back(adj)
								end
								table.insert(queue, adj)
							end
						end
					end
				end
			end
		end
	end

	-- Cached wrapper around getReachableInRange using standard move matchers.
	function BoardUtils.getMoveReachableInRange(pawn, range, start, passThroughMode)
		passThroughMode = passThroughMode or "default"
		local cacheKey = BoardUtils.makeMoveCacheKey(
				pawn:GetId(),
				BoardUtils.getSpaceHash(start),
				range,
				passThroughMode)
		local cached = BoardUtils.reachableCache[cacheKey]
		if cached then
			return BoardUtils.hashesToPointList(cached, true)
		end

		local reachable = PointList()
		BoardUtils.getReachableInRange(reachable, range, start,
				BoardUtils.makeMovePassableMatcher(pawn, passThroughMode),
				BoardUtils.makeMoveLandableMatcher(pawn, "any"))
		BoardUtils.reachableCache[cacheKey] = BoardUtils.pointListToHashes(reachable)
		return BoardUtils.hashesToPointList(BoardUtils.reachableCache[cacheKey], true)
	end

	function BoardUtils.findBfsPath(p1, p2, predicatePassable, predicateStoppable, asPointList)
		local size = 8
		local queue = {p1}
		local head = 1

		local cameFrom = {}
		cameFrom[BoardUtils.getSpaceHash(p1)] = false

		while queue[head] do
			local cur = queue[head]
			head = head + 1

			if cur == p2 then
				-- Convert to points list
				local path = {}
				local k = BoardUtils.getSpaceHash(cur)

				while k do
					local x, y = BoardUtils.unhashSpace(k)
					table.insert(path, 1, Point(x, y))
					k = cameFrom[k]
				end
				if asPointList then
					local pointsPath = PointList()
					for _, point in ipairs(path) do
						pointsPath:push_back(point)
					end
					return pointsPath
				end
				return path
			end

			for idx = 0, 3 do
				local adj = cur + DIR_VECTORS[idx]

				if adj.x >= 0 and adj.x < size and adj.y >= 0 and adj.y < size then
					local h = BoardUtils.getSpaceHash(adj)
					if cameFrom[h] == nil then
						-- Same rules as getReachableInRange: passable for traversal,
						-- and destination must also be landable.
						local canTraverse = not predicatePassable or predicatePassable(adj, h)
						if adj == p2 then
							canTraverse = canTraverse
									and (not predicateStoppable or predicateStoppable(adj, h))
						end
						if canTraverse then
							cameFrom[h] = BoardUtils.getSpaceHash(cur)
							table.insert(queue, adj)
						end
					end
				end
			end
		end
		return nil
	end

	-- BFS move path using the same passable/landable matchers as getReachableInRange.
	function BoardUtils.findMovePath(pawn, p1, p2, passThroughMode, asPointList)
		passThroughMode = passThroughMode or "default"
		local cacheKey = BoardUtils.makeMoveCacheKey(
				pawn:GetId(),
				BoardUtils.getSpaceHash(p1),
				BoardUtils.getSpaceHash(p2),
				passThroughMode)
		local cached = BoardUtils.movePathCache[cacheKey]
		if cached ~= nil then
			if cached == BoardUtils.NO_PATH then
				return nil
			end
			return BoardUtils.hashesToPointList(cached, asPointList)
		end

		local path = BoardUtils.findBfsPath(p1, p2,
				BoardUtils.makeMovePassableMatcher(pawn, passThroughMode),
				BoardUtils.makeMoveLandableMatcher(pawn, "any"),
				true)
		if path then
			BoardUtils.movePathCache[cacheKey] = BoardUtils.pointListToHashes(path)
		else
			BoardUtils.movePathCache[cacheKey] = BoardUtils.NO_PATH
		end
		if BoardUtils.movePathCache[cacheKey] == BoardUtils.NO_PATH then
			return nil
		end
		return BoardUtils.hashesToPointList(BoardUtils.movePathCache[cacheKey], asPointList)
	end

	function BoardUtils.getSpaceHash(spaceOrX, y)
		local pX = spaceOrX
		local pY = y
		if not y then
			pX = spaceOrX.x
			pY = spaceOrX.y
		end
		return pY * 10 + pX
	end

	function BoardUtils.unhashSpace(hash)
		return hash % 10, math.floor(hash / 10)
	end

	-- Check if any adjacent point matches the given matcher function
	-- matcher(point) should return true if the point matches the desired condition
	function BoardUtils.isAdjacent(loc, matcher)
		for dir = DIR_START, DIR_END do
			local adjacentLoc = loc + DIR_VECTORS[dir]
			if Board:IsValid(adjacentLoc) and matcher(adjacentLoc) then
				return true
			end
		end
		return false
	end

	-- Get all adjacent points that match the given matcher function
	-- matcher(point) should return true if the point matches the desired condition
	-- Returns a table of Points
	function BoardUtils.getAdjacent(loc, matcher)
		local adjacent = {}
		for dir = DIR_START, DIR_END do
			local adjacentLoc = loc + DIR_VECTORS[dir]
			if Board:IsValid(adjacentLoc) and matcher(adjacentLoc) then
				table.insert(adjacent, adjacentLoc)
			end
		end
		return adjacent
	end

	-- Last Acted Pawn Tracking
	-- Tracks the last pawn that performed an action for use by skills that need to reference it
	BoardUtils.lastActed = nil

	function BoardUtils.setLastActed(pawn)
		BoardUtils.lastActed = pawn
	end

	function BoardUtils.unsetLastActed()
		BoardUtils.lastActed = nil
	end

	local function startsWith(str, prefix)
		return string.sub(str, 1, #prefix) == prefix
	end

	-- Custom tiles that are not cosmetic ground overlays. Spawn logic treats
	-- these as unsafe. Mirrors WorldBuilders Shift's unallowed terrain swaps,
	-- plus mission tiles such as train rails.
	BoardUtils.UNSAFE_CUSTOM_TILE_PREFIXES = {
		-- Vanilla missions
		"ground_rail",          -- train / armored train tracks
		"square_missilesilo",   -- satellite silos
		"supervolcano",         -- final island volcano
		"tele_",                -- teleporter pads
		"conveyor",             -- conveyor belts
		-- Into the Wild
		"lmn_ground_geyser",
		"lmn_ground_volcanic_vent",
		-- Nautilus
		"ground_buried_s",
		"ground_buried_f",
		"ground_mineral",
		-- Far Line
		"tosx_whirlpool",
		"tosx_vent_",
		-- Vertex
		"tosx_evacsite",
	}

	function BoardUtils.isUnallowedCustomTerrain(customTile)
		if customTile == nil or customTile == "" then
			return false
		end
		for _, prefix in ipairs(BoardUtils.UNSAFE_CUSTOM_TILE_PREFIXES) do
			if startsWith(customTile, prefix) then
				return true
			end
		end
		return false
	end

	function BoardUtils.isSafeCustomTile(point)
		if not Board:IsValid(point) then
			return false
		end
		return not BoardUtils.isUnallowedCustomTerrain(Board:GetCustomTile(point))
	end

	function BoardUtils.addCancelEffect(p, effect)
		local smoked = Board:IsSmoke(p)
		if not smoked then
			local fireType = Board:GetFireType(p)
			effect:AddScript([[Board:SetSmoke(]]..p:GetString()..[[, true, false)]])

			local damage = SpaceDamage(p, DAMAGE_ZERO)
			damage.bHide = true
			-- Needs a frame to cancel attack but not to cancel web interestingly
			damage.fDelay = 0.00017 --force a one frame delay on the board
			effect:AddDamage(damage)

			if fireType ~= FIRE_TYPE_NONE then
				if fireType == FIRE_TYPE_FOREST_FIRE then
					effect:AddScript([[Board:SetTerrain(]]..p:GetString()..[[, TERRAIN_FOREST)]])
				end
				effect:AddScript([[Board:SetFire(]]..p:GetString()..[[, true)]])
			else
				effect:AddScript([[Board:SetSmoke(]]..p:GetString()..[[, false, false)]])
			end
		end
	end

	function BoardUtils.isSafeSpawnTile(point, pathing)
		if not Board:IsValid(point) then
			return false
		end
		if Board:IsPawnSpace(point) then
			return false
		end
		if Board:IsItem(point) then
			return false
		end
		if not BoardUtils.isSafeCustomTile(point) then
			return false
		end
		if pathing and Board:IsBlocked(point, pathing) then
			return false
		end
		-- Some of these may be redundant
		if not Board:IsSafe(point) then
			return false
		end
		if Board:IsDangerous(point) then
			return false
		end
		if Board:IsDangerousItem(point) then
			return false
		end
		if Board:IsSpawning(point) then
			return false
		end
		if Board:IsEnvironmentDanger(point) then
			return false
		end
		if Board:IsAcid(point) then
			return false
		end
		return true
	end

	function BoardUtils.getSafeSpawnTiles(pathing)
		local candidates = {}
		local boardSize = Board:GetSize()

		for x = 0, boardSize.x - 1 do
			for y = 0, boardSize.y - 1 do
				local point = Point(x, y)
				if BoardUtils.isSafeSpawnTile(point, pathing) then
					table.insert(candidates, point)
				end
			end
		end

		return candidates
	end

	function BoardUtils:finalizeInit()
		modapiext.events.onPawnUndoMove:subscribe(function(mission, pawn, undonePosition)
			BoardUtils.clearHijackedPath()
			BoardUtils.clearMoveCaches()
		end)

		modapiext.events.onPawnPositionChanged:subscribe(function()
			BoardUtils.clearMoveCaches()
		end)

		modApi.events.onMissionStart:subscribe(function()
			BoardUtils.clearMoveCaches()
		end)

		modApi.events.onMissionEnd:subscribe(function()
			BoardUtils.clearMoveCaches()
		end)

		-- Setup last acted pawn tracking
		modapiext.events.onSkillStart:subscribe(function(mission, pawn) BoardUtils.setLastActed(pawn) end)
		modapiext.events.onFinalEffectStart:subscribe(function(mission, pawn) BoardUtils.setLastActed(pawn) end)
		modapiext.events.onQueuedSkillStart:subscribe(function(mission, pawn) BoardUtils.setLastActed(pawn) end)
		modapiext.events.onQueuedFinalEffectStart:subscribe(function(mission, pawn) BoardUtils.setLastActed(pawn) end)
		modApi.events.onSaveGame:subscribe(function() BoardUtils.unsetLastActed() end)
	end
else
	LOG("BoardUtils: Skipping version " .. VERSION .. " (already have " .. BoardUtils.version .. ")")
end

local function onModsInitialized()
	if VERSION < BoardUtils.version then
		return
	end

	if BoardUtils.initialized then
		return
	end

	BoardUtils:finalizeInit()
	BoardUtils.initialized = true
end

modApi:addModsInitializedHook(onModsInitialized)

return BoardUtils
