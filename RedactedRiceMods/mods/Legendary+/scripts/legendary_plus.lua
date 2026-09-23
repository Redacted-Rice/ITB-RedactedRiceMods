legendary_plus = legendary_plus or {}

local path = GetParentPath(...)

legendary_plus.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("Legendary+", "Core", legendary_plus.DEBUG)

legendary_plus.libs = legendary_plus.libs or {}
legendary_plus.config_options = {
	alwaysShowQueuedPreviewIcons = true,
}

-- Use same group IDs and offsets as More+ so icons consolidate together.
legendary_plus.WEAPON_PREVIEW_GROUP_ID = "more_plus_levelup_skills"
legendary_plus.WEAPON_PREVIEW_QUEUED_GROUP_ID = "more_plus_levelup_skills_queued"
legendary_plus.WEAPON_PREVIEW_GROUP_OFFSET = Point(-25, 11)
legendary_plus.WEAPON_PREVIEW_QUEUED_GROUP_OFFSET = Point(-18, -4)
legendary_plus.CATEGORY = "Legendary+"
legendary_plus.skills = {}

-- Shared defaults for all Legendary+ skills
legendary_plus.DEFAULTS = {
	reusability = cplus_plus_ex.REUSABLILITY.PER_RUN,
	reusabilityLimit = cplus_plus_ex.REUSABLILITY.REUSABLE,
	slotRestriction = cplus_plus_ex.SLOT_RESTRICTION.SECOND,
	weight = 0.4,
}

-- Group name strings match More+ so skills share exclusion pools when both mods are enabled
legendary_plus.GROUPS = {
	ADD_HEALTH = "Add Health",
	ADD_MOVE = "Add Move",
	ADD_GRID_DEF = "Add Grid Def",
	ADD_REACTOR = "Add Reactor",
	MOVE_TYPE = "Move Type",
	ADD_DAMAGE = "Add Damage",
	SHIELD = "Shield",
	ITEM_DROP = "Item Drop",
	REVIVE = "Revive",
}

legendary_plus.commonIcons = {
	-- Same key/image as More+ so weapon preview treats them as one icon
	extraDamage = {key = "rr_extra_damage", img = "combat/icons/icon_mp_RrExtraDamage_glow.png"},
}

legendary_plus.DISABLED_BY_DEFAULT = {
	"RrComeback",
	"RrGridHero",
	"RrMedic",
}

function legendary_plus:addCommonCustomImages()
	for _, iconData in pairs(self.commonIcons) do
		if not ANIMS[iconData.key] then
			ANIMS[iconData.key] = ANIMS.Animation:new{
				Image = iconData.img,
				NumFrames = 1,
				Time = 1,
				Loop = true,
			}
		end
	end
end

-- Convert DamageModifierLib phase enum to weaponPreview STATE_*.
function legendary_plus.convertPhase(phase)
	local damageModifierLib = legendary_plus.libs.damageModifierLib
	local weaponPreview = legendary_plus.libs.weaponPreview

	if phase == damageModifierLib.PHASE_NONE then
		return weaponPreview.STATE_NONE
	elseif phase == damageModifierLib.PHASE_SKILL_EFFECT then
		return weaponPreview.STATE_SKILL_EFFECT
	elseif phase == damageModifierLib.PHASE_TARGET_AREA then
		return weaponPreview.STATE_TARGET_AREA
	elseif phase == damageModifierLib.PHASE_QUEUED_SKILL then
		return weaponPreview.STATE_QUEUED_SKILL
	elseif phase == damageModifierLib.PHASE_SECOND_TARGET_AREA then
		return weaponPreview.STATE_SECOND_TARGET_AREA
	elseif phase == damageModifierLib.PHASE_FINAL_EFFECT then
		return weaponPreview.STATE_FINAL_EFFECT
	elseif phase == damageModifierLib.PHASE_QUEUED_FINAL_EFFECT then
		return weaponPreview.STATE_QUEUED_FINAL_EFFECT
	end

	-- Phases are numeric and already aligned with STATE_*; pass through
	if type(phase) == "number" then
		return phase
	end

	logger.logWarn(SUBMODULE, "Unknown phase: %s", tostring(phase))
	return weaponPreview.STATE_NONE
end

-- Active vs queued use separate group offsets so icons on the same tile don't overlap.
function legendary_plus.getWeaponPreviewGroupId(phase)
	local state = legendary_plus.convertPhase(phase)
	local weaponPreview = legendary_plus.libs.weaponPreview
	if state == weaponPreview.STATE_QUEUED_SKILL
			or state == weaponPreview.STATE_QUEUED_FINAL_EFFECT then
		return legendary_plus.WEAPON_PREVIEW_QUEUED_GROUP_ID
	end
	return legendary_plus.WEAPON_PREVIEW_GROUP_ID
end

function legendary_plus.isQueuedWeaponPreview(phase)
	local state = legendary_plus.convertPhase(phase)
	return state == legendary_plus.libs.weaponPreview.STATE_QUEUED_SKILL
			or state == legendary_plus.libs.weaponPreview.STATE_QUEUED_FINAL_EFFECT
end

-- Read from modcontent.lua (not GAME.modOptions) so this can change mid run.
-- Uses the More+ mod option since both mods share the same preview groups.
function legendary_plus.refreshConfigOptions()
	local globalOptions = nil
	sdlext.config("modcontent.lua", function(obj)
		if obj.modOptions and obj.modOptions["redactedrice_More+"] then
			globalOptions = obj.modOptions["redactedrice_More+"].options
		end
	end)

	legendary_plus.config_options = legendary_plus.config_options or {}
	if globalOptions and globalOptions.alwaysShowQueuedPreviewIcons then
		legendary_plus.config_options.alwaysShowQueuedPreviewIcons =
				globalOptions.alwaysShowQueuedPreviewIcons.enabled == true
	else
		legendary_plus.config_options.alwaysShowQueuedPreviewIcons = true
	end
end

-- Queued icons can alwaysShow so they stay visible without source/target hover.
function legendary_plus.addWeaponPreviewIcon(phase, loc, animKey, description)
	local alwaysShow = false
	if legendary_plus.isQueuedWeaponPreview(phase) then
		alwaysShow = legendary_plus.config_options.alwaysShowQueuedPreviewIcons
	end
	legendary_plus.libs.weaponPreview:AddAnimation(loc, animKey, nil,
			legendary_plus.getWeaponPreviewGroupId(phase), description, alwaysShow)
end

function legendary_plus:addCustomTraitIcon(skill)
	local iconImg = skill.icon or ("img/combat/icons/icon_lp_" .. skill.id .. ".png")
	skill.icon = iconImg
	logger.logDebug(SUBMODULE, "Adding trait icon %s at %s", skill.id, iconImg)

	if not self.libs.traitReplace then
		logger.logWarn(SUBMODULE, "traitReplace lib unavailable; skipping trait icon for %s", skill.id)
		return
	end

	self.libs.traitReplace:add{
		targetTrait = "massive",
		func = function(trait, pawn)
			if cplus_plus_ex:isSkillOnPawn(skill.id, pawn) then
				return true
			end
			return false
		end,
		icon = iconImg,
		desc_title = skill.name,
		desc_text = skill.description,
	}
end

-- Add vanilla skills to groups
function legendary_plus:addVanillaSkillsToGroups()
	logger.logDebug(SUBMODULE, "Adding vanilla skills to groups...")

	-- Add Health group
	cplus_plus_ex:registerSkillToGroup("Health", self.GROUPS.ADD_HEALTH)
	cplus_plus_ex:registerSkillToGroup("Skilled", self.GROUPS.ADD_HEALTH)

	-- Add Move group
	cplus_plus_ex:registerSkillToGroup("Move", self.GROUPS.ADD_MOVE)
	cplus_plus_ex:registerSkillToGroup("Skilled", self.GROUPS.ADD_MOVE)
	cplus_plus_ex:registerSkillToGroup("Adrenaline", self.GROUPS.ADD_MOVE)

	-- Add Grid Def group
	cplus_plus_ex:registerSkillToGroup("Grid", self.GROUPS.ADD_GRID_DEF)

	-- Add Reactor group
	cplus_plus_ex:registerSkillToGroup("Reactor", self.GROUPS.ADD_REACTOR)

	logger.logDebug(SUBMODULE, "Vanilla skills added to groups")
end

function legendary_plus:loadSkills()
	local skillsDir = Directory(path .. "skills")
	if not skillsDir:exists() then
		logger.logError(SUBMODULE, "Skills directory does not exist: %sskills", path)
		return
	end

	local subDirPath = skillsDir:relative_path()
	for _, file in ipairs(skillsDir:files()) do
		local filename = file:name():match("(.+)%.lua$")
		if filename then
			local requirePath = subDirPath .. filename
			local success, skillObj = pcall(require, requirePath)
			if success and type(skillObj) == "table" then
				table.insert(self.skills, skillObj)
				logger.logDebug(SUBMODULE, "Loaded skill %s", tostring(skillObj.id))
			else
				logger.logError(SUBMODULE, "Failed to load %s: %s", requirePath, tostring(skillObj))
			end
		end
	end
end

function legendary_plus:applyDefaults(skill)
	if skill.reusability == nil then
		skill.reusability = self.DEFAULTS.reusability
	end
	if skill.reusabilityLimit == nil then
		skill.reusabilityLimit = self.DEFAULTS.reusabilityLimit
	end
	if skill.slotRestriction == nil then
		skill.slotRestriction = self.DEFAULTS.slotRestriction
	end
	if skill.weight == nil then
		skill.weight = self.DEFAULTS.weight
	end
end

function legendary_plus:registerSkill(skill)
	self:applyDefaults(skill)

	skill._name = skill.name
	skill.shortName = "LegendaryPlus_" .. skill.id .. "_Name"
	skill.fullName = skill.shortName
	modApi:setText(skill.shortName, skill._name)

	skill._description = skill.description
	skill.description = "LegendaryPlus_" .. skill.id .. "_Description"
	modApi:setText(skill.description, skill._description)

	if skill.icon == nil then
		skill.icon = "img/combat/icons/icon_lp_" .. skill.id .. ".png"
	end

	cplus_plus_ex:registerSkill(self.CATEGORY, skill)
	logger.logDebug(SUBMODULE, "Registered skill %s", skill.id)

	if skill.init then
		skill:init()
	end
end

function legendary_plus:init()
	modApi:appendAssets("img/combat/icons/", "img/combat/icons/")
	self:addCommonCustomImages()

	require(path .. "move_drop"):init()

	self:loadSkills()
	for _, skill in ipairs(self.skills) do
		self:registerSkill(skill)
	end
	self:addVanillaSkillsToGroups()

	-- Trapper, Medic, and Freezer all drop items on move and conflict with each other
	cplus_plus_ex:registerSkillExclusion("RrTrapper", "RrMedic")
	cplus_plus_ex:registerSkillExclusion("RrTrapper", "RrFreezer")
	cplus_plus_ex:registerSkillExclusion("RrMedic", "RrFreezer")
end

function legendary_plus:disableDefaultSkills()
	logger.logDebug(SUBMODULE, "Disabling default disabled skills...")
	for _, skillId in ipairs(self.DISABLED_BY_DEFAULT) do
		logger.logDebug(SUBMODULE, "Disabling skill %s", skillId)
		cplus_plus_ex:disableSkill(skillId)
	end
	logger.logDebug(SUBMODULE, "Disabled %d skills", #self.DISABLED_BY_DEFAULT)
end

function legendary_plus:load()
	-- Config options that can change mid run (shared More+ mod option)
	self:refreshConfigOptions()

	-- Register active + queued preview groups (same offsets as More+)
	WeaponPreview:RegisterGroup(self.WEAPON_PREVIEW_GROUP_ID, self.WEAPON_PREVIEW_GROUP_OFFSET)
	WeaponPreview:RegisterGroup(self.WEAPON_PREVIEW_QUEUED_GROUP_ID, self.WEAPON_PREVIEW_QUEUED_GROUP_OFFSET)
	logger.logDebug(SUBMODULE, "Registered Legendary+ weapon preview groups")

	-- Add vanilla skills to groups after CPLUS+_Ex has registered them
	logger.logDebug(SUBMODULE, "Adding vanilla skills to groups...")
	self:addVanillaSkillsToGroups()

	self:disableDefaultSkills()

	logger.logDebug(SUBMODULE, "Loading all skills for Legendary+...")
	for _, skill in ipairs(self.skills) do
		logger.logDebug(SUBMODULE, "Loading skill %s", skill.id)
		if skill.load then
			skill:load()
		end
	end
end

return legendary_plus
