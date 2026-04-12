local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrAmbusher",
	name = "Ambusher",
	description = "Gain +1 damage if not on road, liquid, or hole.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Ambusher", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(source, attackingPawn, previewState, spaceDamage, indexes, targetPawn)
	-- Check if attacking an enemy
	if source == self.SOURCE_ATTACKER and targetPawn and 
			targetPawn:IsEnemy() and spaceDamage.iDamage > 0 and
			spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then
		local pawnLoc = attackingPawn:GetSpace()
		local terrain = Board:GetTerrain(pawnLoc)

		-- Check if NOT on road, liquid, or hole
		local isOnRoad = (terrain == TERRAIN_ROAD)
		local isOnLiquid = (terrain == TERRAIN_WATER or terrain == TERRAIN_LAVA or terrain == TERRAIN_ACID)
		local isOnHole = (terrain == TERRAIN_HOLE)

		if not isOnRoad and not isOnLiquid and not isOnHole then
			for _, idx in ipairs(indexes) do
				logger.logDebug(SUBMODULE, "Adding ambush damage icon for %s with idx %d",
						spaceDamage.loc:GetString(), idx)
				more_plus.libs.weaponPreview.ExecuteWithState(previewState,
						function()
							more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
									more_plus.commonIcons.extraDamage.key.."_"..idx)
						end)
			end

			spaceDamage.iDamage = spaceDamage.iDamage + 1
			logger.logDebug(SUBMODULE, "Added +1 ambush damage at %s (terrain: %d)",
					spaceDamage.loc:GetString(), terrain)
		else
			logger.logDebug(SUBMODULE, "No ambush bonus - on road/liquid/hole (terrain: %d, hole: %s)",
					terrain, tostring(isOnHole))
		end
	end
	return nil
end

return customSkill
