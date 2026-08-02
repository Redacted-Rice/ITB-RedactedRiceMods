local ITEM_ID = "Item_Mine"

local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrTrapper",
	name = "Trapper",
	description = "When moving, drop an explosive mine on a free tile next to your origin (relative to the direction back toward it).",
	minesByMove = {},
	reusabilityLimit = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("Legendary+", "Trapper", customSkill.DEBUG)

legendary_plus:addCustomTraitIcon(customSkill)

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
	table.insert(customSkill.events, modapiext.events.onPawnUndoMove:subscribe(customSkill.undoMine))
end

function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId ~= "Move" then
		return
	end

	local pilot = pawn:GetPilot()
	if not pilot or not cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
		return
	end

	local mineLoc = legendary_plus.findMoveDropTile(p1, p2)
	if not mineLoc then
		logger.logDebug(SUBMODULE, "No valid mine tile next to origin %s for pawn %d",
				p1:GetString(), pawn:GetId())
		return
	end

	local pawnId = pawn:GetId()
	local mineDamage = SpaceDamage(mineLoc, 0)
	mineDamage.sItem = ITEM_ID
	mineDamage.sScript = string.format(
		[[cplus_plus_ex.baseClasses.SkillActive.skills.RrTrapper.minesByMove[%d] = %s]],
		pawnId, mineLoc:GetString()
	)
	skillEffect:AddDamage(mineDamage)
	logger.logDebug(SUBMODULE, "Will drop mine at %s (origin %s -> %s) for pawn %d",
			mineLoc:GetString(), p1:GetString(), p2:GetString(), pawnId)
end

function customSkill.undoMine(mission, pawn, undonePosition)
	local pawnId = pawn:GetId()
	local mineLoc = customSkill.minesByMove[pawnId]
	if not mineLoc then
		return
	end

	if Board:IsItem(mineLoc) and Board:GetItem(mineLoc) == ITEM_ID then
		Board:RemoveItem(mineLoc)
		logger.logDebug(SUBMODULE, "Removed mine at %s for pawn %d (undo)", mineLoc:GetString(), pawnId)
	end
	customSkill.minesByMove[pawnId] = nil
end

return customSkill
