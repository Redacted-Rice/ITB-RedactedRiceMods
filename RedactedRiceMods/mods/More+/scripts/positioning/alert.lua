local customSkill = more_plus.SkillActive:new{
	id = "RrAlert",
	name = "Alert",
	description = "Gain armor while adjacent to a vek.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Alert", customSkill.DEBUG)

-- Excluse Abe with his innate armor
cplus_plus_ex:registerPilotSkillExclusions("Pilot_Assassin", customSkill.id)

customSkill:addCustomTrait()

function customSkill:setupEffect()
	-- Track move skill builds to show icons when moving adjacent to vek. Actually armor will be
	-- applied once moved via other callbacks
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))

	-- Any time a new pawn comes or a pawn changes positions, just recalculate all
	-- pawns with the skill
	table.insert(customSkill.events, modapiext.events.onPawnPositionChanged:subscribe(customSkill.pawnsChanged))
	table.insert(customSkill.events, modapiext.events.onPawnTracked:subscribe(customSkill.pawnsChanged))
	table.insert(customSkill.events, modapiext.events.onPawnUntracked:subscribe(customSkill.pawnsChanged))

	-- Track mission end to remove any remaining temp armor
	table.insert(customSkill.events, modapiext.events.onMissionEnd:subscribe(customSkill.onMissionEnd))
end

-- Check if a location is adjacent to any vek
function customSkill.isAdjacentToVek(loc)
	for dir = DIR_START, DIR_END do
		local adjacentLoc = loc + DIR_VECTORS[dir]
		if Board:IsValid(adjacentLoc) then
			local adjacentPawn = Board:GetPawn(adjacentLoc)
			if adjacentPawn and adjacentPawn:IsEnemy() then
				return true
			end
		end
	end
	return false
end

-- Apply or remove armor based on adjacency to vek
function customSkill.updateArmorForPawn(pawn)
	-- only pawns with skill will have this called so we don't need to check again

	-- Check if the pawn innately has armor (via _G[pawn:GetType()]) and if so, skip
	local pawnType = _G[pawn:GetType()]
	if pawnType and pawnType.Armor then
		logger.logDebug(SUBMODULE, "Pawn %d (%s) has innate armor (%d), skipping Alert skill",
				pawn:GetId(), pawn:GetType(), pawnType.Armor)
		return
	end

	local pawnLoc = pawn:GetSpace()
	local shouldHaveArmor = customSkill.isAdjacentToVek(pawnLoc)
	-- TODO: Not implemented yet. Need to investigate and add via memhack
	pawn:SetArmor(shouldHaveArmor)
	if shouldHaveArmor then
		logger.logDebug(SUBMODULE, "Added armor to pawn %d at %s", pawn:GetId(), pawnLoc:GetString())
	else
		logger.logDebug(SUBMODULE, "Removed armor from pawn %d at %s", pawn:GetId(), pawnLoc:GetString())
	end
end

-- Show icon when moving to a location adjacent to vek
function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			local willBeAdjacentToVek = customSkill.isAdjacentToVek(p2)

			-- Show icon if gaining armor
			if willBeAdjacentToVek then
				more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
						function()
							more_plus.libs.weaponPreview:AddAnimation(p2,
									more_plus.commonIcons.armor.key.."_1")
						end)
				logger.logDebug(SUBMODULE, "Pawn %d moving to %s adjacent to vek, showing armor icon",
						pawn:GetId(), p2:GetString())
			end
		end
	end
end

-- Handle new pawns being tracked or position changes
function customSkill.pawnsChanged(mission, pawn)
	-- Get all pawns with the Alert skill and update their armor
	local pawnsWithSkill = cplus_plus_ex:getMechsWithSkill(customSkill.id, true)

	logger.logDebug(SUBMODULE, "Pawns changed event - updating %d pawns with Alert skill", #pawnsWithSkill)

	for _, alertPawn in ipairs(pawnsWithSkill) do
		customSkill.updateArmorForPawn(alertPawn)
	end
end

-- Remove armor on mission end for all pawns with skill
function customSkill.onMissionEnd(mission)
	-- Get all pawns with the Alert skill using CPLUS+ function
	local pawnsWithSkill = cplus_plus_ex:getMechsWithSkill(customSkill.id, true)

	logger.logDebug(SUBMODULE, "Mission ending - removing armor from %d pawns with Alert skill", #pawnsWithSkill)

	for _, alertPawn in ipairs(pawnsWithSkill) do
		-- Check if the pawn innately has armor
		local pawnType = _G[alertPawn:GetType()]
		local hasInnateArmor = pawnType and pawnType.Armor

		if not hasInnateArmor then
			-- Remove any armor granted by the skill
			alertPawn:SetArmor(false)
			logger.logDebug(SUBMODULE, "Removed Alert armor from pawn %d at mission end", alertPawn:GetId())
		else
			logger.logDebug(SUBMODULE, "Pawn %d has innate armor, not removing", alertPawn:GetId())
		end
	end
end

return customSkill
