local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrSupporter",
	name = "Supporter",
	description = "Piloted mech can teleport to tiles adjacent to allies.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Supporter", customSkill.DEBUG)

customSkill.addedPointsByPawn = {}

local function resetAddedPointsCache()
	customSkill.addedPointsByPawn = {}
end

more_plus:addCustomTraitIcon(customSkill)

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onTargetAreaBuild:subscribe(customSkill.moveTargetArea))
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(resetAddedPointsCache))
end

function customSkill.moveTargetArea(mission, pawn, weaponId, p1, targetArea)
	if weaponId == "Move" then
		if pawn and cplus_plus_ex:isSkillOnPawn(customSkill.id, pawn) then
			logger.logDebug(SUBMODULE, "Supporter pawn %d at %s, finding allies for teleport",
					pawn:GetId(), p1:GetString())

			-- Find all ally mechs
			local addedCount = 0
			local addedPoints = {}

			-- Build set of existing target area points to avoid duplicates
			local existingPoints = {}
			for i = 1, targetArea:size() do
				local point = targetArea:index(i)
				existingPoints[BoardUtils.getSpaceHash(point)] = true
			end

			-- Track exactly which points this added so moveSkillBuild can check
			-- reachability later without re calling GetTargetArea as that causes issues
			local supporterAddedPoints = {}
			customSkill.addedPointsByPawn[pawn:GetId()] = supporterAddedPoints

			for _, pawnId in ipairs(extract_table(Board:GetPawns(TEAM_PLAYER))) do
				local allyPawn = Board:GetPawn(pawnId)

				-- Skip self
				if allyPawn:GetId() ~= pawn:GetId() then
					local allyLoc = allyPawn:GetSpace()
					logger.logDebug(SUBMODULE, "Found ally %d at %s", allyPawn:GetId(), allyLoc:GetString())

					-- Get all potential adjacent tiles to the ally
					local adjacentTiles = BoardUtils.getAdjacent(allyLoc, function(adjacentLoc)
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
						if (not BoardUtils.isPawnFlying(pawn)) and
								terrain == TERRAIN_HOLE then
							return false
						end
						if terrain == TERRAIN_BUILDING and not BoardUtils.CanMoveOnBuildings(pawn) then
							return false
						end
						if terrain == TERRAIN_MOUNTAIN and not BoardUtils.CanMoveOnMountains(pawn) then
							return false
						end
						return true
					end)

					-- Add each new valid adjacent tile to move area
					for _, adjLoc in ipairs(adjacentTiles) do
						local locHash = BoardUtils.getSpaceHash(adjLoc)
						if not existingPoints[locHash] then
							targetArea:push_back(adjLoc)
							existingPoints[locHash] = true
							supporterAddedPoints[locHash] = true
							table.insert(addedPoints, adjLoc:GetString())
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
			-- Use the added points to determine if the destination is reachable without a teleport
			local supporterAddedPoints = customSkill.addedPointsByPawn[pawn:GetId()]

			-- This should always be populated by moveTargetArea before a skill effect
			-- is ever built for this pawn's Move but just to be safe...
			if not supporterAddedPoints then
				logger.logWarn(SUBMODULE, "No cached supporter target area for pawn %d at %s, skipping teleport check",
						pawn:GetId(), p1:GetString())
				return
			end

			-- If this destination isn't one we added its reachable some other way
			-- so don't change the move type
			if not supporterAddedPoints[BoardUtils.getSpaceHash(p2)] then
				logger.logDebug(SUBMODULE, "Destination %s reachable without supporter for pawn %d, using normal movement",
						p2:GetString(), pawn:GetId())
				return
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
