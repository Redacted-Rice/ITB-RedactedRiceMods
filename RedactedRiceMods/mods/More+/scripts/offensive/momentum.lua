local MIN_DISTANCE = 4

local customSkill = more_plus.SkillActive:new{
	id = "RrMomentum",
	name = "Momentum",
	description = "Gain boosted after moving at least 4 tiles.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	notPreBoosted = {},
	reentrant = false,
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Momentum", customSkill.DEBUG)

-- Exclude Kai and Morgan as they give boosted already
cplus_plus_ex:registerPilotSkillExclusions("Pilot_Arrogant", customSkill.id)
cplus_plus_ex:registerPilotSkillExclusions("Pilot_Chemical", customSkill.id)

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.checkMove))
	table.insert(customSkill.events, modapiext.events.onPawnUndoMove:subscribe(customSkill.undoBoosted))
end

function customSkill:momentumTriggered(pawnId, p1, p2, effect)
	local pawn = Board:GetPawn(pawnId)
	local distance = 0
	local pathSource = "unknown"

	-- For jumpers and teleporters always use manhattan distance
	if pawn:IsJumper() or pawn:IsTeleporter() then
		distance = math.abs(p2.x - p1.x) + math.abs(p2.y - p1.y)
		pathSource = "manhattan"
	else
		local path = nil

		-- Check if there's a hijacked path and use it if so
		path = more_plus.libs.boardUtils.getHijackedPath()
		if path then
			pathSource = "hijacked"
		else
			-- Otherwise use vanilla pathfinding
			path = Board:GetPath(p1, p2, pawn:GetPathProf())
			pathSource = "calculated"
		end

		if path and path:size() > 0 then
			distance = path:size() - 1
		end
	end

	logger.logDebug(SUBMODULE, "Pawn %d moving %d tiles from %s to %s with source: %s",
		pawn:GetId(), distance, p1:GetString(), p2:GetString(), pathSource)

	if distance >= MIN_DISTANCE and not pawn:IsBoosted() then
		more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
			function()
				more_plus.libs.weaponPreview:AddAnimation(p2,
						more_plus.commonIcons.boost.key.."_1")
			end)
		effect:AddScript([[more_plus.SkillActive.skills.RrMomentum.notPreBoosted[]]..pawnId..[[] = true
						Board:GetPawn(]]..pawnId..[[):SetBoosted(true)]])
		logger.logDebug(SUBMODULE, "Will apply boosted to pawn %d moving %d tiles", pawnId, distance)
	end
end

function customSkill.checkMove(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			if not customSkill.reentrant then
				logger.logDebug(SUBMODULE, "First calculation pass, will recalculate pathing", pawn:GetId())
				customSkill.reentrant = true
				-- Ensure the skill is calculated. We actually don't care about the
				-- return value as we use global type variables to check
				Move:GetSkillEffect(p1, p2)
				customSkill:momentumTriggered(pawn:GetId(), p1, p2, skillEffect)
				customSkill.reentrant = false
			else
				logger.logDebug(SUBMODULE, "Second calculation pass - skipping logic", pawn:GetId())
			end
		end
	end
end

function customSkill.undoBoosted(mission, pawn, undonePosition)
	if customSkill.notPreBoosted[pawn:GetId()] then
		pawn:SetBoosted(false)
		customSkill.notPreBoosted[pawn:GetId()] = nil
		logger.logInfo(SUBMODULE, "Removed boosted from pawn " .. pawn:GetId())
	end
end

return customSkill

