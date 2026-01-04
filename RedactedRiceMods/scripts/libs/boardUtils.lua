local boardUtils = {
	Version="1.0.0",
}
	
function boardUtils.addForcedMove(skillEffect, path)
	-- Clear the existing move from the skilleffect
	skillEffect.effect = SkillEffect().effect
	
	-- Add move for display purposes. This won't let us move onto unmovable spaces reliably
	skillEffect:AddMove(path, FULL_DELAY)

	--maybe needs to be p1?
	local pawnId = Board:GetPawn(path:index(1)):GetId()
	local secondToLastSpace = path:index(path:size() - 1)
	local lastSpace = path:index(path:size())
	local moveDamage = SpaceDamage(secondToLastSpace, 0)
	moveDamage.sScript = [[Board:GetPawn(]] .. pawnId .. [[):SetSpace(]] .. lastSpace:GetString() .. [[)]]
	skillEffect:AddDamage(moveDamage)
end

function boardUtils.makeInSubsetMatcher(tiles)
	 return function(point, hash)
	 	   return tiles[hash] ~= nil
	 end
end

function boardUtils.makeAllTerrainMatcher(pawn, skipPawnCheck)
	 return function(point, hash) 
	 	 return (skipPawnCheck or not Board:IsPawnSpace(point)) and 
			(pawn:IsFlying() or Board:GetTerrain(point) ~= TERRAIN_HOLE)
	 end
end


function boardUtils.getReachableInRange(reachable, range, start, predicatePassable, predicateStoppable)
	-- dont include start in reachable
    local visited = {}
    visited[boardUtils.getSpaceHash(start)] = true

    local queue = { start }
    local dist = { [boardUtils.getSpaceHash(start)] = 0 }

    local size = 8
    while #queue > 0 do
        local cur = table.remove(queue, 1)
        local curDist = dist[boardUtils.getSpaceHash(cur)]

        if curDist < range then
            for idx = 0, 3 do
                local adj = cur + DIR_VECTORS[idx]

                if adj.x >= 0 and adj.x < size and adj.y >= 0 and adj.y < size then
                    local adjHash = boardUtils.getSpaceHash(adj)

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

function boardUtils.findBfsPath(p1, p2, predicate, asPointList)
    local queue = {p1}
    local head = 1

    local cameFrom = {}
    cameFrom[boardUtils.getSpaceHash(p1)] = false

    while queue[head] do
        local cur = queue[head]
        head = head + 1

        if cur == p2 then
            -- Convert to points list
            local path = {}
			local k = boardUtils.getSpaceHash(cur)

            while k do
                local x, y = boardUtils.unhashSpace(k)
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
            local h = boardUtils.getSpaceHash(adj)
            -- only walk tiles if there is no subset or that exist in the subset
            if (not predicate or predicate(adj, h)) and cameFrom[h] == nil then
                cameFrom[h] = boardUtils.getSpaceHash(cur)
                table.insert(queue, adj)
            end
        end
    end
    return nil
end

function boardUtils.getSpaceHash(spaceOrX, y)
    local pX = spaceOrX
    local pY = y
    if not y then
        pX = spaceOrX.x
        pY = spaceOrX.y
    end
    return pY * 10 + pX
end

function boardUtils.unhashSpace(hash)
	return hash % 10, math.floor(hash / 10)
end

return boardUtils