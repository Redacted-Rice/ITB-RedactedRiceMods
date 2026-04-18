local customSkill = more_plus.SkillActive:new{
	id = "RrSupporter",
	name = "Supporter",
	description = "Piloted mech can teleport to tiles adjacent to allies.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	skipSupporter = false
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Supporter", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onTargetAreaBuild:subscribe(customSkill.moveTargetArea))
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
end

function customSkill.moveTargetArea(mission, pawn, weaponId, p1, targetArea)
	if weaponId == "Move" then
		if pawn and cplus_plus_ex:isSkillOnPawn(customSkill.id, pawn) then
			-- Skip if analyzing for the build effect
			if customSkill.skipSupporter then
				logger.logDebug(SUBMODULE, "Skipping supporter target area for pawn %d from %s",
						pawn:GetId(), p1:GetString())
				return
			end

			logger.logDebug(SUBMODULE, "Supporter pawn %d at %s, finding allies for teleport",
					pawn:GetId(), p1:GetString())

			-- Find all ally mechs
			local addedCount = 0
			local addedPoints = {}

			-- Build set of existing target area points to avoid duplicates
			local existingPoints = {}
			for i = 1, targetArea:size() do
				local point = targetArea:index(i)
				existingPoints[point:GetString()] = true
			end

			for _, pawnId in ipairs(extract_table(Board:GetPawns(TEAM_PLAYER))) do
				local allyPawn = Board:GetPawn(pawnId)

				-- Skip self
				if allyPawn:GetId() ~= pawn:GetId() then
					local allyLoc = allyPawn:GetSpace()
					logger.logDebug(SUBMODULE, "Found ally %d at %s", allyPawn:GetId(), allyLoc:GetString())

					-- Get all potential adjacent tiles to the ally
					local adjacentTiles = more_plus.libs.boardUtils.getAdjacent(allyLoc, function(adjacentLoc)
						-- Check if valid board space
						if not Board:IsValid(adjacentLoc) then
							return false
						end
						-- Check if occupied by a pawn
						if Board:GetPawn(adjacentLoc) then
							return false
						end
						-- check if its passable
						local terrain = Board:GetTerrain(adjacentLoc)
						if (not more_plus.libs.boardUtils.isPawnFlying(pawn)) and
								terrain == TERRAIN_HOLE then
							return false
						end
						if (not cplus_plus_ex:isSkillOnPawn("RrNimble", pawn)) and
								(terrain == TERRAIN_BUILDING or terrain == TERRAIN_MOUNTAIN) then
							return false
						end
						return true
					end)

					-- Add each new valid adjacent tile to move area
					for _, adjLoc in ipairs(adjacentTiles) do
						local locStr = adjLoc:GetString()
						if not existingPoints[locStr] then
							targetArea:push_back(adjLoc)
							existingPoints[locStr] = true
							table.insert(addedPoints, locStr)
							addedCount = addedCount + 1
						end
					end
				end
			end

			if addedCount > 0 then
				logger.logDebug(SUBMODULE, "Added %d supporter move targets for pawn %d: [%s]",
						addedCount, pawn:GetId(), table.concat(addedPoints, ", "))
			else
				logger.logDebug(SUBMODULE, "No additional supporter targets added for pawn %d", pawn:GetId())
			end
		end
	end
end

function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			-- Recalculate target area without supporter skill to check if destination is normally reachable
			customSkill.skipSupporter = true
			local nonSupporterPoints = Move:GetTargetArea(p1)
			customSkill.skipSupporter = false

			-- Check if we can reach with normal movement, in which case, do so and return
			for idx = 1, nonSupporterPoints:size() do
				if nonSupporterPoints:index(idx) == p2 then
					logger.logDebug(SUBMODULE, "Destination %s reachable via normal move for pawn %d, using normal movement",
							p2:GetString(), pawn:GetId())
					return
				end
			end

			-- Otherwise we need to teleport there!
			logger.logDebug(SUBMODULE, "Destination %s requires teleport for pawn %d - teleporting!",
					p2:GetString(), pawn:GetId())

			-- Clear the existing move and add a teleport
			skillEffect.effect = SkillEffect().effect
			skillEffect:AddTeleport(p1, p2, NO_DELAY)
		end
	end
end

return customSkill
