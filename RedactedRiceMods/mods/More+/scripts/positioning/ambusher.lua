local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrAmbusher",
	name = "Ambusher",
	description = "+1 damage to enemies if piloted mech is not on a road, liquid, or hole tile.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	constraints = {
		groups = {more_plus.GROUPS.ADD_DAMAGE},
	},
	priority = 80, -- go after doubling
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Ambusher", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	-- Check if attacking an enemy
	if source == self.SOURCE_ATTACKER and targetPawn and
			targetPawn:IsEnemy() and spaceDamage.iDamage > 0 and
			spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then
		-- Intentionally base it off ORIGINAL pawn space so things like charge and jumps
		-- trigger based on the tile the pawn starts the attack on
		local pawnLoc = attackingPawn:GetSpace()
		local terrain = Board:GetTerrain(pawnLoc)

		-- Check if NOT on road, liquid, or hole
		local isOnRoad = (terrain == TERRAIN_ROAD)
		local isOnLiquid = (terrain == TERRAIN_WATER or terrain == TERRAIN_LAVA or terrain == TERRAIN_ACID)
		local isOnHole = (terrain == TERRAIN_HOLE)

		if not isOnRoad and not isOnLiquid and not isOnHole then
			logger.logDebug(SUBMODULE, "Adding ambush damage icon for %s",
					spaceDamage.loc:GetString())
			more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
				function()
					more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, more_plus.commonIcons.extraDamage.key, nil,  -- delay
							more_plus.WEAPON_PREVIEW_GROUP_ID, customSkill.name .. ": " .. customSkill.description)
				end, attackingPawn:GetId()
			)

			spaceDamage.iDamage = spaceDamage.iDamage + 1
			logger.logDebug(SUBMODULE, "Added +1 ambush damage at %s (terrain: %d)",
					spaceDamage.loc:GetString(), terrain)
		else
			logger.logDebug(SUBMODULE, "No ambush bonus - on road/liquid/hole (terrain: %d, hole: %s)",
					terrain, tostring(isOnHole))
		end
	end
end

return customSkill
