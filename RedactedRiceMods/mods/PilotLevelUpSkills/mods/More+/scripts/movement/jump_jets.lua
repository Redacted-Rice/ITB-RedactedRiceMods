local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrJumpJets",
	name = "Jump Jets",
	description = "Piloted Mech can jump with -1 move as its movement.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	-- Don't allow on kwan - its mostly duplicative with his skill
	-- Propsero already has flying so it doesn't help at all either
	-- Flying/jumper/teleporter cyborgs already have equal or better movement
	constraints = {
		groups = {PlusHelper.GROUPS.MOVE_TYPE},
		pilotExclusions = {
			"Pilot_Hotshot",
			"Pilot_Recycler",
			cplus_plus_ex.isFlyingCyborg,
			cplus_plus_ex.isJumperCyborg,
			cplus_plus_ex.isTeleporterCyborg,
			cplus_plus_ex.isBurrowerCyborg,
		},
	}
}


-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "JumpJets", customSkill.DEBUG)

-- Cache of the points this adds to the move target area per pawn for performance
-- and so we can readd them without calling getTargetArea to avoid weapon preview
-- issues
customSkill.addedPointsByPawn = {}

local function resetAddedPointsCache()
	customSkill.addedPointsByPawn = {}
end

-- Leap can go through all tiles (but not on them)
BoardUtils.CanMoveThroughHoles = BoardUtils.makeAllowIfHasSkill(BoardUtils.CanMoveThroughHoles, customSkill.id)
BoardUtils.CanMoveThroughBuildings = BoardUtils.makeAllowIfHasSkill(BoardUtils.CanMoveThroughBuildings, customSkill.id)
BoardUtils.CanMoveThroughMountains = BoardUtils.makeAllowIfHasSkill(BoardUtils.CanMoveThroughMountains, customSkill.id)
BoardUtils.CanMoveThroughWater = BoardUtils.makeAllowIfHasSkill(BoardUtils.CanMoveThroughWater, customSkill.id)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onTargetAreaBuild:subscribe(customSkill.moveTargetArea))
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(resetAddedPointsCache))
end

function customSkill.moveTargetArea(mission, pawn, weaponId, p1, targetArea)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			local hashedNormalPoints = {}
			for idx = 1, targetArea:size() do
				local point = targetArea:index(idx)
				hashedNormalPoints[more_plus.libs.boardUtils.getSpaceHash(point)] = true
			end

			-- Get our jump speed and determine the reachable points. Board utils handles passable/
			-- stoppable checks already
			local jumpMoveSpeed = math.max(0, pawn:GetMoveSpeed() - 1)
			local jumpPoints = more_plus.libs.boardUtils.getMoveReachableInRange(
					pawn, jumpMoveSpeed, p1, "none")

			logger.logDebug(SUBMODULE, "Jump jets target area from %s with speed %d found %d reachable spaces",
					p1:GetString(), jumpMoveSpeed, jumpPoints:size())

			-- Track exactly which points this added so moveSkillBuild can check
			-- reachability later without re calling GetTargetArea as that causes issues
			local jumpAddedPoints = {}
			customSkill.addedPointsByPawn[pawn:GetId()] = jumpAddedPoints

			-- Go through and add any that are not already there
			local addedCount = 0
			local addedPoints = {}
			for idx = 1, jumpPoints:size() do
				local point = jumpPoints:index(idx)
				local pointHash = more_plus.libs.boardUtils.getSpaceHash(point)
				if not hashedNormalPoints[pointHash] then
					targetArea:push_back(point)
					jumpAddedPoints[pointHash] = true
					table.insert(addedPoints, point:GetString())
					addedCount = addedCount + 1
				end
			end

			-- Log a summary
			if addedCount > 0 then
				logger.logDebug(SUBMODULE, "Added %d jump move targets for pawn %d: [%s]",
					addedCount, pawn:GetId(), table.concat(addedPoints, ", "))
			else
				logger.logDebug(SUBMODULE, "No additional jump targets added for pawn %d", pawn:GetId())
			end
		end
	end
end

function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			-- Use the added points to determine if the destination is reachable without a jump
			local jumpAddedPoints = customSkill.addedPointsByPawn[pawn:GetId()]

			-- This should always be populated by moveTargetArea before a skill effect
			-- is ever built for this pawn's Move but just to be safe...
			if not jumpAddedPoints then
				logger.logWarn(SUBMODULE, "No cached jump target area for pawn %d at %s, skipping jump check",
						pawn:GetId(), p1:GetString())
				return
			end

			-- If this destination isn't one we added its reachable some other way
			-- so don't change the move type
			if not jumpAddedPoints[more_plus.libs.boardUtils.getSpaceHash(p2)] then
				logger.logDebug(SUBMODULE, "Destination %s reachable without jump for pawn %d, using normal movement",
						p2:GetString(), pawn:GetId())
				return
			end

			-- Otherwise we get to leap there!
			logger.logDebug(SUBMODULE, "Destination %s requires jump for pawn %d - blasting off!",
					p2:GetString(), pawn:GetId())

			-- Clear the existing move and add a leap, preserving any other
			-- skill effect entries already added
			local preservedDamages = BoardUtils.extractNonMoveSkillEffectEntries(skillEffect)
			skillEffect.effect = SkillEffect().effect
			local leapPath = PointList()
			leapPath:push_back(p1)
			leapPath:push_back(p2)
			skillEffect:AddLeap(leapPath, FULL_DELAY)
			BoardUtils.addSkillEffectEntries(skillEffect, preservedDamages)
		end
	end
end

return customSkill