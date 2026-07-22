legendary_plus = legendary_plus or {}

local path = GetParentPath(...)

legendary_plus.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("Legendary+", "Core", legendary_plus.DEBUG)

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

legendary_plus.GROUPS = {
	ADD_HEALTH = "Add Health",
	ADD_MOVE = "Add Move",
	ADD_GRID_DEF = "Add Grid Def",
	ADD_REACTOR = "Add Reactor",
}

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

	self:loadSkills()
	for _, skill in ipairs(self.skills) do
		self:registerSkill(skill)
	end
	self:addVanillaSkillsToGroups()
end

function legendary_plus:load()
	-- Register More+ weapon preview group with offset and multi-icon
	WeaponPreview:RegisterGroup(self.WEAPON_PREVIEW_GROUP_ID,Point(-25, 11))
	logger.logDebug(SUBMODULE, "Registered More+ weapon preview group with WeaponPreview")

	-- Add vanilla skills to groups after CPLUS+_Ex has registered them
	logger.logDebug(SUBMODULE, "Adding vanilla skills to groups...")
	self:addVanillaSkillsToGroups()
	
	logger.logDebug(SUBMODULE, "Loading all skills for Legendary+...")
	for _, skill in ipairs(self.skills) do
		logger.logDebug(SUBMODULE, "Loading skill %s", skill.id)
		if skill.load then
			skill:load()
		end
	end
end

return legendary_plus
