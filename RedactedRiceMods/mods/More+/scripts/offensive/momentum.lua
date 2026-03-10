local MIN_DISTANCE = 4

local customSkill = more_plus.SkillActive:new{
	id = "RrMomentum",
	name = "Momentum",
	description = "Gains boosted after moving at least 4 tiles",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	notPreBoosted = {},
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.checkMove))
	table.insert(customSkill.events, modapiext.events.onPawnUndoMove:subscribe(customSkill.undoBoosted))
end

function customSkill.checkMove(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			local distance = math.abs(p2.x - p1.x) + math.abs(p2.y - p1.y)
			LOGF("Momentum: Pawn %d moving %d tiles (from %s to %s)", pawn:GetId(), distance, p1:GetString(), p2:GetString())

			if distance >= MIN_DISTANCE then
				if not pawn:IsBoosted() then
					local pawnId = pawn:GetId()
					local boostDamage = SpaceDamage(p2, 0)
					boostDamage.sScript = [[
						Board:GetPawn(]]..pawnId..[[):SetBoosted(true)
						more_plus.SkillActive.skills.RrMomentum.notPreBoosted[]]..pawnId..[[] = true
					]]
					skillEffect:AddDamage(boostDamage)
					LOGF("Momentum: Will apply boosted to pawn %d (moving %d tiles)", pawnId, distance)
				end
			end
		end
	end
end

function customSkill.undoBoosted(mission, pawn, undonePosition)
	if customSkill.notPreBoosted[pawn:GetId()] then
		pawn:SetBoosted(false)
		customSkill.notPreBoosted[pawn:GetId()] = nil
		LOG("Momentum: Removed boosted from pawn " .. pawn:GetId())
	end
end

return customSkill

