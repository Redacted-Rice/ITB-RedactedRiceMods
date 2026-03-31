--[[
BoardUtils - Utilities related to board, pathing, and movement

Author: Das Keifer of Redacted Rice
Version: 1.3.0
Discord Server: https://discord.gg/CNjTVrpN4v
]]

local VERSION = "1.3.0"

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

	function BoardUtils.setHijackedFlying(pawn, enabled)
		if enabled then
			BoardUtils.hijackedFlying[pawn:GetId()] = true
			pawn:SetFlying(true)
		elseif BoardUtils.hijackedFlying[pawn:GetId()] then
			BoardUtils.hijackedFlying[pawn:GetId()] = nil
			pawn:SetFlying(false)
		end
	end

	function BoardUtils.isPawnHijackedFlying(pawn)
		return BoardUtils.hijackedFlying[pawn:GetId()]
	end

	function BoardUtils.isPawnFlying(pawn)
		return pawn:IsFlying() and not BoardUtils.hijackedFlying[pawn:GetId()]
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

	function BoardUtils.addForcedMove(skillEffect, path)
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
		skillEffect:AddMove(path, FULL_DELAY)

		-- Store the hijacked path so other systems can use it
		BoardUtils.setHijackedPath(path)

		--maybe needs to be p1?
		local pawnId = Board:GetPawn(path:index(1)):GetId()
		local secondToLastSpace = path:index(path:size() - 1)
		local lastSpace = path:index(path:size())
		local moveDamage = SpaceDamage(secondToLastSpace, 0)
		moveDamage.sScript = [[Board:GetPawn(]] .. pawnId .. [[):SetSpace(]] .. lastSpace:GetString() .. [[)]]
		skillEffect:AddDamage(moveDamage)

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

	function BoardUtils.makeTerrainBasedMatcher(pawn, pawnCheckType, exclTerrainCheckFn)
		return function(point, hash)
			if exclTerrainCheckFn(point) then
				return false
			end
			local pawn = Board:GetPawn(point)
			if pawn then
				if pawnCheckType == "any" then
					return false
				end
				local pawnTeam = pawn:GetTeam()
				if pawnCheckType == "friendly" and (pawnTeam == TEAM_BOTS or
						pawnTeam == TEAM_ENEMY or pawnTeam == TEAM_ENEMY_MAJOR) then
					return false
				end
			end
			return true
		end
	end

	--pawnCheckType "none", "friendly", "any"
	function BoardUtils.makeAllTerrainMatcher(pawn, pawnCheckType, flying)
		return BoardUtils.makeTerrainBasedMatcher(pawn, pawnCheckType, function(point)
			return not BoardUtils.isPawnFlying(pawn) and Board:GetTerrain(point) == TERRAIN_HOLE
		end)
	end

	--pawnCheckType "none", "friendly", "any"
	function BoardUtils.makeGenericMatcher(pawn, flying, pawnCheckType)
		return BoardUtils.makeTerrainBasedMatcher(pawn, pawnCheckType, function(point)
			local terrain = Board:GetTerrain(point)
			return (not BoardUtils.isPawnFlying(pawn) and Board:GetTerrain(point) == TERRAIN_HOLE) or
					terrain == TERRAIN_BUILDING or terrain == TERRAIN_MOUNTAIN
		end)
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

	function BoardUtils.findBfsPath(p1, p2, predicate, asPointList)
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
					pointsPath = PointList()
					for _, point in ipairs(path) do
						pointsPath:push_back(point)
					end
					return pointsPath
				end
				return path
			end

			for idx = 0, 3 do
				local adj = cur + DIR_VECTORS[idx]
				local h = BoardUtils.getSpaceHash(adj)
				-- only walk tiles if there is no subset or that exist in the subset
				if (not predicate or predicate(adj, h)) and cameFrom[h] == nil then
					cameFrom[h] = BoardUtils.getSpaceHash(cur)
					table.insert(queue, adj)
				end
			end
		end
		return nil
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

	function BoardUtils:init()
		-- Initialize event subscriptions
		modapiext.events.onPawnUndoMove:subscribe(function(mission, pawn, undonePosition)
			BoardUtils.clearHijackedPath()
		end)
	end
else
	LOG("BoardUtils: Skipping version " .. VERSION .. " (already have " .. BoardUtils.version .. ")")
end

return BoardUtils
