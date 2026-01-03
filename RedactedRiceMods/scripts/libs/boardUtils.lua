local boardUtils = {
	Version="1.0.0",
	DebugLog = false,
}

function boardUtils.addForcedMove(skillEffect, path)
	-- Clear the existing move from the skilleffect
	skillEffect.effect = SkillEffect().effect
	
	-- Add move for display purposes. This won't let us move onto unmovable spaces
	-- reliably
	skillEffect:AddMove(path, FULL_DELAY)

		--maybe needs to be p1?
	local pawnId = Board:GetPawn(path[1]):GetId()
	local secondToLastSpace = path:index(path:size() - 1)
	local lastSpace = path:index(path:size())
	local moveDamage = SpaceDamage(secondToLastSpace, 0)
	moveDamage.sScript = [[Board:GetPawn(]] .. pawnId .. [[):SetSpace(]] .. lastSpace:GetString() .. [[)]]
	skillEffect:AddDamage(moveDamage)
end

-- Generic pathfinder that can go over holes
function boardUtils.addReachableTiles(start, targetArea)
	-- "borrowed" from general_DiamondTarget and modified to not
	-- include point
	local pawn = Board:GetPawn(start)
	local isFlying = pawn:IsFlying()
	local size = pawn:GetBaseMove()
	local corner = start - Point(size, size)

	local p = Point(corner)

	for i = 0, ((size*2+1)*(size*2+1)) do
		local diff = start - p
		local dist = math.abs(diff.x) + math.abs(diff.y)
		-- If its a valid, unoccupied space, allow it
		if Board:IsValid(p) and dist <= size and not Board:IsPawnSpace(p) and (isFlying or Board:GetTerrain(p) ~= TERRAIN_HOLE) then
			targetArea:push_back(p)
		end
		p = p + VEC_RIGHT
		if math.abs(p.x - corner.x) == (size*2+1) then
			p.x = p.x - (size*2+1)
			p = p + VEC_DOWN
		end
	end
end

function boardUtils.getDirect Path(start, target)
    local path = PointList()
	path:push_back(start)
    local current = Point(start.x, start.y)

    local dx = target.x - start.x
    local dy = target.y - start.y

    local stepX = dx > 0 and 1 or -1
    for i = 1, math.abs(dx) do
        current = Point(current.x + stepX, current.y)
        path:push_back(current)
    end

    local stepY = dy > 0 and 1 or -1
    for i = 1, math.abs(dy) do
        current = Point(current.x, current.y + stepY)
        path:push_back(current)
    end

    return path
end

return boardUtils