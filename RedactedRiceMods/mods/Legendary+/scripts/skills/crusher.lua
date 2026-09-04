local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrCrusher",
	name = "Crusher",
	description = "When moving, crack all eligible tiles adjacent to your destination. Will not crack building, item, uncrackable, or already cracked tiles.",
	crackedByMove = {},
	reusabilityLimit = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("Legendary+", "Crusher", customSkill.DEBUG)

-- Preview icon offset (no weapon preview group — icon is not consolidated with other skills).
customSkill.PREVIEW_OFFSET = Point(-14, 14)
customSkill.NO_CRACK_ANIM = "rr_lp_crusher_no_crack"

legendary_plus:addCustomTraitIcon(customSkill)

if not ANIMS[customSkill.NO_CRACK_ANIM] then
	ANIMS[customSkill.NO_CRACK_ANIM] = ANIMS.Animation:new{
		Image = "advanced/combat/icons/icon_crack_glow_off.png",
		NumFrames = 1,
		Time = 1,
		Loop = true,
		PosX = customSkill.PREVIEW_OFFSET.x,
		PosY = customSkill.PREVIEW_OFFSET.y,
	}
end

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
		elseif Board:IsValid(adj) then
			legendary_plus.libs.weaponPreview.ExecuteWithState(legendary_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
				function()
					legendary_plus.libs.weaponPreview:AddAnimation(adj, customSkill.NO_CRACK_ANIM, nil, nil,
							GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
				end, pawnId
			)
			logger.logDebug(SUBMODULE, "No tiles to crack for pawn %d move to %s, showing placeholder icon",
						pawnId, adj:GetString())
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
