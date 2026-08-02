local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrAmbusher",
	name = "Ambusher",
	description = "+1 damage to enemies if piloted mech is not on a ground, liquid, or hole tile.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	constraints = {
		groups = {more_plus.GROUPS.ADD_DAMAGE},
	},
	priority = 80, -- go after doubling
	modifiesKillDamage = true,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Ambusher", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

local function isAmbushTile(pawnLoc)
	local terrain = Board:GetTerrain(pawnLoc)
	-- Check if NOT on road, liquid, or hole
	return terrain ~= TERRAIN_ROAD and terrain ~= TERRAIN_WATER and terrain ~= TERRAIN_LAVA and
			terrain ~= TERRAIN_ACID and terrain ~= TERRAIN_HOLE
end

function customSkill:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, currentDamage)
	-- Check if attacking an enemy
	if source == customSkill.SOURCE_ATTACKER and targetPawn and targetPawn:IsEnemy() and
			currentDamage > 0 and currentDamage ~= DAMAGE_DEATH and currentDamage ~= DAMAGE_ZERO then
		-- Intentionally base it off ORIGINAL pawn space so things like charge and jumps
		-- trigger based on the tile the pawn starts the attack on
		if isAmbushTile(attackingPawn:GetSpace()) then
			return currentDamage + 1
		end
	end
	return currentDamage
end

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	local newDamage = self:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, spaceDamage.iDamage)
	if newDamage == spaceDamage.iDamage then
		return
	end

	logger.logDebug(SUBMODULE, "Adding ambush damage icon for %s", spaceDamage.loc:GetString())
	more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
		function()
			more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, more_plus.commonIcons.extraDamage.key, nil,  -- delay
					more_plus.WEAPON_PREVIEW_GROUP_ID, GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
		end, attackingPawn:GetId()
	)
	spaceDamage.iDamage = newDamage
	local terrain = Board:GetTerrain(attackingPawn:GetSpace())
	logger.logDebug(SUBMODULE, "Added +1 ambush damage at %s (terrain: %d)",
			spaceDamage.loc:GetString(), terrain)
end

return customSkill
