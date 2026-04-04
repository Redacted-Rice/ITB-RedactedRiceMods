local customSkill = more_plus.SkillActive:new{
	id = "RrJumpJets",
	name = "Jump Jets",
	description = "Piloted Mech can jump with -1 move as its movement.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	skipJump = false
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "JumpJets", customSkill.DEBUG)

-- Exclude prospero as he has flying and Henry as he already moves through enemies
cplus_plus_ex:registerPilotSkillExclusions("Pilot_Recycler", customSkill.id)
cplus_plus_ex:registerPilotSkillExclusions("Pilot_Hotshot", customSkill.id)

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onTargetAreaBuild:subscribe(customSkill.moveTargetArea))
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
end

function customSkill.moveTargetArea(mission, pawn, weaponId, p1, targetArea)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			if customSkill.skipJump then
				logger.logDebug(SUBMODULE, "Skipping jump jets target area for pawn %d from %s",
					pawn:GetId(), p1:GetString())
				return
			end

			local hashedNormalPoints = {}
			for idx = 1, targetArea:size() do
				local point = targetArea:index(idx)
				hashedNormalPoints[more_plus.libs.boardUtils.getSpaceHash(point)] = true
			end

			-- Get our jump params and determine the reachable points
			local jumpMoveSpeed = math.max(0, pawn:GetMoveSpeed() - 1)
			local jumpPoints = PointList()
			more_plus.libs.boardUtils.getReachableInRange(jumpPoints, jumpMoveSpeed, p1,
					more_plus.libs.boardUtils.makeAllTerrainMatcher(pawn, "any"),
					more_plus.libs.boardUtils.makeGenericMatcher(pawn, "any"))

			logger.logDebug(SUBMODULE, "Jump jets target area from %s with speed %d found %d reachable spaces",
					p1:GetString(), jumpMoveSpeed, jumpPoints:size())

			-- Go through and add any that are not already there
			local addedCount = 0
			local addedPoints = {}
			for idx = 1, jumpPoints:size() do
				local point = jumpPoints:index(idx)
				local pointHash = more_plus.libs.boardUtils.getSpaceHash(point)
				if not hashedNormalPoints[pointHash] then
					targetArea:push_back(point)
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
			-- Instead of storing, we recalulcate skipping jump for better order-independent
			-- calculation for other skills like nimble and water proof that change things up
			customSkill.skipJump = true
			local nonJumpPoints = Move:GetTargetArea(p1)
			customSkill.skipJump = false

			-- Now determine if we can reach with normal movement, in which case, do so and return
			for idx = 1, nonJumpPoints:size() do
				if nonJumpPoints:index(idx) == p2 then
					logger.logDebug(SUBMODULE, "Destination %s reachable via normal move for pawn %d, using normal movement",
							p2:GetString(), pawn:GetId())
					return
				end
			end

			-- Otherwise we get to leap there!
			logger.logDebug(SUBMODULE, "Destination %s requires jump for pawn %d - blasting off!",
					p2:GetString(), pawn:GetId())
			for idx = 1, skillEffect.effect:size() do
				local spaceDamage = skillEffect.effect:index(idx)
				if spaceDamage:IsMovement() then
					spaceDamage:SetMoveType(1) -- 1 == leap
					logger.logDebug(SUBMODULE, "Set move type to Leap for space damage at %s", spaceDamage.loc:GetString())
				end
			end
		end
	end
end

return customSkill