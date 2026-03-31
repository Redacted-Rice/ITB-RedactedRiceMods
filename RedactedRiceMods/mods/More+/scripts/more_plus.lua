more_plus = more_plus or {}

more_plus.skillsByCategory = {}
more_plus.libs = {}

local path = GetParentPath(...)

-- Initialize logger
more_plus.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Core", more_plus.DEBUG)

more_plus.SkillTrait = require(path.."skill_trait")
more_plus.SkillActive = require(path.."skill_active")
more_plus.SkillEffectModifier = require(path.."skill_effect_modifier")

function more_plus:scanAndReadSkillFiles()
	logger.logDebug(SUBMODULE, "Scanning subdirs in dir %s", path)

	local numCats = 0
	local numSkills = 0
    local dir = Directory(path)

    if dir:exists() then
        for _, subDir in ipairs(dir:directories()) do
			local subDirPath = subDir:relative_path()
			logger.logDebug(SUBMODULE, "Checking sub dir %s", subDirPath)

			local category = subDir:name()
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
        end
    end
	logger.logDebug(SUBMODULE, "Found %d skills in %d categories", numSkills, numCats)
end

function more_plus:setLastActed(pawn)
	self.lastActed = pawn
	logger.logDebug(SUBMODULE, "SET PAWN %d", pawn:GetId())
end

function more_plus:unsetLastActed()
	if self.lastActed then
		logger.logDebug(SUBMODULE, "UNSET PAWN %d", self.lastActed:GetId())
		self.lastActed = nil
	end
end

more_plus.lastActed = nil
function more_plus:setupLastActedTracking()
	modapiext.events.onSkillStart:subscribe(function(mission, pawn) self:setLastActed(pawn) end)
	modapiext.events.onFinalEffectStart:subscribe(function(mission, pawn) self:setLastActed(pawn) end)
	modapiext.events.onQueuedSkillStart:subscribe(function(mission, pawn) self:setLastActed(pawn) end)
	modapiext.events.onQueuedFinalEffectStart:subscribe(function(mission, pawn) self:setLastActed(pawn) end)
	modApi.events.onSaveGame:subscribe(function() self:unsetLastActed() end)
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
	extraDamage = {key = "rr_extra_damage", img =  "combat/icons/icon_mp_RrExtraDamage.png", pos1 = Point(-25,11), pos2 = Point(-18,-4)},
	crit = {key = "rr_crit", img =  "combat/icons/icon_mp_RrCrit.png", pos1 = Point(-25,11), pos2 = Point(-18,-4)},
	shackle = {key = "rr_shackle", img =  "combat/icons/icon_mp_RrShackle.png", pos1 = Point(-25,11), pos2 = Point(-18,-4)},
	noDamage = {key = "rr_no_damage", img =  "combat/icons/icon_mp_RrNoDamage.png", pos1 = Point(-25,11), pos2 = Point(-18,-4)},
	boost = {key = "rr_boosted", img = "advanced/combat/icons/icon_boosted.png", pos1 = Point(-25,11), pos2 = Point(-18,-4)},
}

function more_plus:addCommonCustomImages()
	for _, iconData in pairs(self.commonIcons) do
		ANIMS[iconData.key .. "_1"] = ANIMS.Animation:new{
			Image = iconData.img,
			NumFrames = 1,
			Time = 1,
			Loop = true,
			PosX = iconData.pos1.x,
			PosY = iconData.pos1.y
		}
		ANIMS[iconData.key .. "_2"] = ANIMS.Animation:new{
			Image = iconData.img,
			NumFrames = 1,
			Time = 1,
			Loop = true,
			PosX = iconData.pos2.x,
			PosY = iconData.pos2.y
		}
	end
end

function more_plus:init()
	modApi:appendAssets("img/combat/icons/", "img/combat/icons/")
	self:addCommonCustomImages()
	self:setupLastActedTracking()
	self.SkillTrait:baseInit()
	self.SkillActive:baseInit()

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

function more_plus:load()
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