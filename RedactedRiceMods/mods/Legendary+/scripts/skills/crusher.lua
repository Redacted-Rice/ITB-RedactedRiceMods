local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrCrusher",
	name = "Crusher",
	description = "When moving, crack all tiles adjacent to your destination.",
	crackedByMove = {},
	reusabilityLimit = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("Legendary+", "Crusher", customSkill.DEBUG)

legendary_plus:addCustomTraitIcon(customSkill)

function customSkill.canCrack(loc)
	return Board:IsValid(loc) and not Board:IsBuilding(loc) and
			not Board:IsPod(loc) and not Board:IsItem(loc) and not Board:IsCracked(loc) and
			Board:GetTerrain(loc) ~= TERRAIN_WATER and Board:GetTerrain(loc) ~= TERRAIN_LAVA and
			Board:GetTerrain(loc) ~= TERRAIN_ACID and Board:GetTerrain(loc) ~= TERRAIN_HOLE
end

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
	table.insert(customSkill.events, modapiext.events.onPawnUndoMove:subscribe(customSkill.undoCracked))
end

function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId ~= "Move" then
		return
	end

	local pilot = pawn:GetPilot()
	if not pilot or not cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
		return
	end

	local pawnId = pawn:GetId()
	local pointStrings = {}

	for dir = DIR_START, DIR_END do
		local adj = p2 + DIR_VECTORS[dir]
		if customSkill.canCrack(adj) then
			local damageC = SpaceDamage(adj, 0)
			damageC.iCrack = EFFECT_CREATE
			skillEffect:AddDamage(damageC)
			table.insert(pointStrings, adj:GetString())
			logger.logDebug(SUBMODULE, "Will crack %s for Crusher move by pawn %d", adj:GetString(), pawnId)
		end
	end

	if #pointStrings > 0 then
		local trackDamage = SpaceDamage(p2, 0)
		trackDamage.sScript = string.format(
			[[cplus_plus_ex.baseClasses.SkillActive.skills.RrCrusher.crackedByMove[%d] = {%s}]],
			pawnId,
			table.concat(pointStrings, ", ")
		)
		skillEffect:AddDamage(trackDamage)
	end
end

function customSkill.undoCracked(mission, pawn, undonePosition)
	local pawnId = pawn:GetId()
	local cracked = customSkill.crackedByMove[pawnId]
	if not cracked then
		return
	end

	for _, loc in ipairs(cracked) do
		if Board:IsCracked(loc) then
			Board:SetCracked(loc, false)
			logger.logDebug(SUBMODULE, "Uncracked %s for pawn %d (undo)", loc:GetString(), pawnId)
		end
	end
	customSkill.crackedByMove[pawnId] = nil
end

return customSkill
