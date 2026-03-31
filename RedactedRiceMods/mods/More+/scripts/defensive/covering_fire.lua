local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrCoveringFire",
	name = "Covering Fire",
	description = "Enemies attacked lose half their movement for a turn (rounded down).",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "CoveringFire", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes)
	local targetPawn = Board:GetPawn(spaceDamage.loc)
	
	if targetPawn and targetPawn:IsEnemy() then
		local previewState = isFinalEffect and more_plus.libs.weaponPreview.STATE_FINAL_EFFECT or
				more_plus.libs.weaponPreview.STATE_SKILL_EFFECT
		for _, idx in ipairs(indexes) do
			logger.logDebug(SUBMODULE, "Adding icon for %s with idx %d", spaceDamage.loc:GetString(), idx)
			more_plus.libs.weaponPreview.ExecuteWithState(previewState,
					function()
						more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
								more_plus.commonIcons.shackle.key.."_"..idx)
					end)
		end

		local baseMoveSpeed = _G[targetPawn:GetType()].MoveSpeed
		local targetMoveSpeed = math.floor(baseMoveSpeed / 2)
		local moveReduction = targetPawn:GetMoveSpeed() - targetMoveSpeed

		spaceDamage.sScript = "Board:GetPawn("..targetPawn:GetId().."):AddMoveBonus(-"..moveReduction..")"
		logger.logDebug(SUBMODULE, "Will reduce movement of enemy at %s to %d (base: %d, reduction: %d)",
				spaceDamage.loc:GetString(), targetMoveSpeed, baseMoveSpeed, moveReduction)
	else
		logger.logDebug(SUBMODULE, "No target pawn found for %s", spaceDamage.loc:GetString())
	end
end

return customSkill