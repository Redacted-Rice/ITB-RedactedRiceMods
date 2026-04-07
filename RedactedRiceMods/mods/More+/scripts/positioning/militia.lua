local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrMilitia",
	name = "Militia",
	description = "Gain +1 damage against enemies adjacent to buildings.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Militia", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes, spacePawn)
	-- Check if this is damage to an enemy
	if spacePawn and spacePawn:IsEnemy() and spaceDamage.iDamage > 0 and 
	   spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then
		
		-- Check if target is adjacent to any building
		local targetLoc = spaceDamage.loc
		local isAdjacentToBuilding = false
		
		for dir = DIR_START, DIR_END do
			local adjacentLoc = targetLoc + DIR_VECTORS[dir]
			if Board:IsValid(adjacentLoc) and Board:IsBuilding(adjacentLoc) then
				isAdjacentToBuilding = true
				logger.logDebug(SUBMODULE, "Target at %s is adjacent to building at %s", 
					targetLoc:GetString(), adjacentLoc:GetString())
				break
			end
		end
		
		if isAdjacentToBuilding then
			local previewState = isFinalEffect and more_plus.libs.weaponPreview.STATE_FINAL_EFFECT or
					more_plus.libs.weaponPreview.STATE_SKILL_EFFECT
			
			for _, idx in ipairs(indexes) do
				logger.logDebug(SUBMODULE, "Adding militia damage icon for %s with idx %d", 
					spaceDamage.loc:GetString(), idx)
				more_plus.libs.weaponPreview.ExecuteWithState(previewState,
						function()
							more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
									more_plus.commonIcons.extraDamage.key.."_"..idx)
						end)
			end
			
			spaceDamage.iDamage = spaceDamage.iDamage + 1
			logger.logDebug(SUBMODULE, "Added +1 militia damage to enemy at %s (adjacent to building)", 
				spaceDamage.loc:GetString())
		else
			logger.logDebug(SUBMODULE, "No militia bonus - target not adjacent to building")
		end
	end
	
	return nil
end

return customSkill
