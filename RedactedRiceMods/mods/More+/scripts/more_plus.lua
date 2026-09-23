more_plus = more_plus or {}

more_plus.skillsByCategory = {}
more_plus.libs = {}
more_plus.config_options = {
	alwaysShowQueuedPreviewIcons = true,
}

local path = GetParentPath(...)

-- Initialize logger
more_plus.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Core", more_plus.DEBUG)

function more_plus.refreshConfigOptions()
	more_plus.config_options.alwaysShowQueuedPreviewIcons =
			PlusHelper.readAlwaysShowQueuedPreviewIcons("redactedrice_More+", true)
end

function more_plus.addWeaponPreviewIcon(phase, loc, animKey, description)
	PlusHelper.addWeaponPreviewIconForMod(phase, loc, animKey, description,
			more_plus.config_options.alwaysShowQueuedPreviewIcons)
end

more_plus.DISABLED_BY_DEFAULT = {
	-- Vanilla skills to disable
	"Grid",
	"GridPlus", -- rebal core is enabled
	"Health",
	"Move",
	"Closer",
	"Popular",
	"Invulnerable",
	"Adrenaline", -- Similar to hyper and accelerator
	"Conservative", -- Pretty RNG/niche as you need a limited use

	-- More+ to disable by default
	-- Defensive
	"RrCheapPlating",
	"RrDefiant",
	"RrFoolhardy",
	"RrImpervious",
	"RrStreetwise",
	-- Movement
	"RrGuarded",
	"RrPontoons",
	"RrSupporter",
	-- Offensive
	"RrCalculatedShot",
	"RrFocused",
	"RrKillShot",
	-- Positioning
	"RrMilitia",
	"RrUrban",
	-- Trade Offs
	"RrHyper",
	"RrReflect",
	"RrShatterstep",
	"RrVindictive",
}

function more_plus:scanAndReadSkillFiles()
	logger.logDebug(SUBMODULE, "Scanning subdirs in dir %s", path)

	local numCats = 0
	local numSkills = 0
    local dir = Directory(path)

    if dir:exists() then
        for _, subDir in ipairs(dir:directories()) do
			local category = subDir:name()

			-- Skip libs folder - it contains libraries, not skills
			if category ~= "libs" then
				local subDirPath = subDir:relative_path()
				logger.logDebug(SUBMODULE, "Checking sub dir %s", subDirPath)

				local skillObjs = {}
				for _, file in ipairs(subDir:files()) do
					local filename = file:name():match("(.+)%.lua$") or file:name()
					logger.logDebug(SUBMODULE, "Found skill file %s", filename)

					local requirePath = subDirPath .. filename
					local success, skillObj = pcall(require, requirePath)
					if success and type(skillObj) == "table" then
						skillObj.file = requirePath
						skillObj.category = category
						table.insert(skillObjs, skillObj)
						numSkills = numSkills + 1
					else
						logger.logError(SUBMODULE, string.format("Failed to load %s: %s", requirePath, tostring(skillObj)))
					end
				end
				self.skillsByCategory[category] = skillObjs
				numCats = numCats + 1
			else
				logger.logDebug(SUBMODULE, "Skipping libs folder")
			end
        end
    end
	logger.logDebug(SUBMODULE, "Found %d skills in %d categories", numSkills, numCats)
end


function more_plus:folderToDisplayName(str)
    -- underscores to spaces
    str = str:gsub("_", " ")

    -- capitalize first letter of each word
    str = str:gsub("(%a)(%w*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)

	-- prepend RR
    return "More+ " .. str
end

more_plus.commonIcons = {
	extraDamage = {key = "rr_extra_damage", img =  "combat/icons/icon_mp_RrExtraDamage_glow.png"},
	crit = {key = "rr_crit", img =  "combat/icons/icon_mp_RrCrit_glow.png"},
	shackle = {key = "rr_shackle", img =  "combat/icons/icon_mp_RrShackle_glow.png"},
	noDamage = {key = "rr_no_damage", img =  "combat/icons/icon_mp_RrNoDamage_glow.png"},
	boost = {key = "rr_boosted", img = "advanced/combat/icons/icon_boosted_glow.png"},
	shield = {key = "rr_shield", img = "combat/icons/icon_shield_glow.png"},
	armor1 = {key = "rr_armor_one", img = "combat/icons/icon_mp_RrArmorOne_glow.png"},
	armor3 = {key = "rr_armor_three", img = "combat/icons/icon_mp_RrArmorThree_glow.png"},
	reflect = {key = "rr_Reflect", img = "combat/icons/icon_mp_RrReflect_glow.png"},
	vampire = {key = "rr_vampire", img = "combat/icons/icon_mp_RrVampire_glow.png"},
}

function more_plus:addCustomTraitIcon(skill)
	local iconImg = "img/combat/icons/icon_mp_" .. skill.id .. ".png"
	skill.icon = iconImg
	logger.logDebug(SUBMODULE, "Adding trait icon %s at %s", skill.id, iconImg)
	self.libs.traitReplace:add{
		targetTrait = "massive",
		func = function(trait, pawn)
			if cplus_plus_ex:isSkillOnPawn(skill.id, pawn) then
				return true
			end
			return false
		end,
		icon = iconImg,
		desc_title = skill.fullName or skill.name,
		desc_text = skill.description,
	}
end

function more_plus:init()
	modApi:appendAssets("img/combat/icons/", "img/combat/icons/")
	PlusHelper.registerIconList(self.commonIcons)

	logger.logDebug(SUBMODULE, "Loading libraries...")
	require(path .. "libs/customAnim")
	require(path .. "libs/status")

	logger.logDebug(SUBMODULE, "Finding all skills...")
	more_plus:scanAndReadSkillFiles(basePath)

	logger.logDebug(SUBMODULE, "Creating all skills...")
	-- Then go through and create the skills
	for category, skills in pairs(self.skillsByCategory) do
		logger.logDebug(SUBMODULE, "Creating skills for category %s", category)
		local cplusCategory = self:folderToDisplayName(category)
		for _, skill in pairs(skills) do
			-- simulate continue with an added loop level
		    repeat
				logger.logDebug(SUBMODULE, "Creating skill %s", skill.id)
				-- make sure we have the required fields
				if not skill.id then
					logger.logError(SUBMODULE, "Failed to find id for skill at: " .. skill.path)
					break
				end
				if not skill.description then
					logger.logError(SUBMODULE, "Failed to find description for skill at: " .. skill.path)
					break
				end

				-- If we just use name, set short and full name
				-- Also create the text in modloader
				if skill.name then
					-- store original values
					skill._name = skill.name
					skill._shortName = skill.name
					skill._fullName = skill.name

					-- Create a dictionary entry to use instead
					-- for the expected fields
					skill.shortName = "MorePlus_" .. skill.id .. "_Name"
					skill.fullName = "MorePlus_" .. skill.id .. "_Name"
					modApi:setText(skill.shortName, skill._name)
				elseif skill.shortName and skill.fullName then
					-- store original values
					skill._shortName = skill.shortName
					skill._fullName = skill.fullName

					-- Create a dictionary entry to use instead
					-- for the expected fields
					skill.shortName = "MorePlus_" .. skill.id .. "_ShortName"
					skill.fullName = "MorePlus_" .. skill.id .. "_FullName"
					modApi:setText(skill.shortName, skill._shortName)
					modApi:setText(skill.fullName, skill._fullName)
				else
					logger.logError(SUBMODULE, "Failed to find name or short name and full name for skill at: " .. skill.path)
					break
				end

				-- Make description text in modloader. Not necessary but does allow for easier
				-- text replacing
				skill._description = skill.description
				skill.description = "MorePlus_" .. skill.id .. "_Description"
				modApi:setText(skill.description, skill._description)

				-- Actually register the skill now we have it all set up
				cplus_plus_ex:registerSkill(cplusCategory, skill)

				-- Call init on the function if it exists
				logger.logDebug(SUBMODULE, "Initializing skill %s", skill.id)
				if skill.init then
					skill:init()
				end
				break
			until true
		end
	end
end

function more_plus:disableDefaultSkills()
	logger.logDebug(SUBMODULE, "Disabling default disabled skills...")
	for _, skillId in ipairs(self.DISABLED_BY_DEFAULT) do
		logger.logDebug(SUBMODULE, "Disabling skill %s", skillId)
		cplus_plus_ex:disableSkill(skillId)
	end
	logger.logDebug(SUBMODULE, "Disabled %d skills", #self.DISABLED_BY_DEFAULT)
end

function more_plus:load()
	more_plus.refreshConfigOptions()

	-- Disable skills that should be disabled by default
	self:disableDefaultSkills()

	logger.logDebug(SUBMODULE, "Loading all skills...")
	for category, skills in pairs(more_plus.skillsByCategory) do
		logger.logDebug(SUBMODULE, "Loading skills for category %s", category)
		for _, skill in pairs(skills) do
			logger.logDebug(SUBMODULE, "Loading skill %s", skill.id)
			-- Call load on the function if it exists
			if skill.load then
				skill:load()
			end
		end
	end
end

return more_plus