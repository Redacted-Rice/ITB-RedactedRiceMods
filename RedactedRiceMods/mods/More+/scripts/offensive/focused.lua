local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrFocused",
	name = "Focused",
	description = "Deal +1 Damage if you have not moved yet",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

customSkill:addCustomTrait()

function customSkill:processEffects(pawn, effects, p2)
	if not pawn then
		return
	end
	local pilot = pawn:GetPilot()
	if pilot and not effects:empty() and cplus_plus_ex:isSkillOnPilot(self.id, pilot) then
		if pawn:IsMovementSpent() then
			LOG("Pawn ".. pawn:GetId().." already moved")
			return
		end
		
		local indexes = cplus_plus_ex:getPilotSkillIndices(self.id, pilot)

		for _, spaceDamage in pairs(extract_table(effects)) do
			local spaceDamageKey = self:hashSpaceDamage(pawn:GetId(), spaceDamage, p2)
			if not self.processedDamages[spaceDamageKey] then
				self.processedDamages[spaceDamageKey] = true

				modApi:runLater(function()
					more_plus.SkillActive.skills[self.id].processedDamages = {}
				end)

				self:modifySpaceDamage(pawn, spaceDamage, indexes)
			end
		end
	end
end

function customSkill:modifySpaceDamage(pawn, spaceDamage, indexes)
	if spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and 
			spaceDamage.iDamage ~= DAMAGE_ZERO then

		for _, idx in ipairs(indexes) do
			more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
					function()
						more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
								more_plus.commonIcons.extraDamage.key.."_"..idx)
					end)

			spaceDamage.iDamage = spaceDamage.iDamage + 1
			LOG("Focused: Added +1 damage enemy at ".. spaceDamage.loc:GetString())
		end
	end
end

return customSkill

