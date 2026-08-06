legendary_plus = legendary_plus or {}

local path = GetParentPath(...)

legendary_plus.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("Legendary+", "Core", legendary_plus.DEBUG)

legendary_plus.libs = legendary_plus.libs or {}

-- Use same group ID as More+
legendary_plus.WEAPON_PREVIEW_GROUP_ID = "more_plus_levelup_skills"
legendary_plus.CATEGORY = "Legendary+"
legendary_plus.skills = {}

-- Shared defaults for all Legendary+ skills
legendary_plus.DEFAULTS = {
	reusability = cplus_plus_ex.REUSABLILITY.PER_RUN,
	reusabilityLimit = cplus_plus_ex.REUSABLILITY.REUSABLE,
	slotRestriction = cplus_plus_ex.SLOT_RESTRICTION.SECOND,
	weight = cplus_plus_ex.DEFAULT_WEIGHT / 2,
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
	"RrGridHero",
	"RrComeback",
	"RrJuggernaut",
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

function legendary_plus:previewExtraDamage(phase, loc, pawnId, skill)
	local weaponPreview = (more_plus and more_plus.libs and more_plus.libs.weaponPreview)
			or self.libs.weaponPreview
	if not weaponPreview then
		return
	end

	local tipName = skill._name or skill.name or ""
	local tipDesc = skill._description or ""
	weaponPreview.ExecuteWithState(phase,
		function()
			weaponPreview:AddAnimation(loc, self.commonIcons.extraDamage.key, nil,
					self.WEAPON_PREVIEW_GROUP_ID, tipName .. ": " .. tipDesc)
		end, pawnId
	)
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
	-- Register More+ weapon preview group with offset and multi-icon
	WeaponPreview:RegisterGroup(self.WEAPON_PREVIEW_GROUP_ID, Point(-25, 11))
	logger.logDebug(SUBMODULE, "Registered Legendary+ weapon preview group")

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
