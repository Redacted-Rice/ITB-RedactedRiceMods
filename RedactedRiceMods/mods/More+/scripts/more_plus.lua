more_plus = more_plus or {}

more_plus.skillsByCategory = {}
more_plus.DEBUG = true

local path = GetParentPath(...)

more_plus.SkillTrait = require(path.."skill_trait")
more_plus.SkillActive = require(path.."skill_active")

function more_plus:scanAndReadSkillFiles()
	if self.DEBUG then LOG("More+: Scanning subdirs in dir " .. path) end
	
	local numCats = 0
	local numSkills = 0
    local dir = Directory(path)
    
    if dir:exists() then
        for _, subDir in ipairs(dir:directories()) do
			local subDirPath = subDir:relative_path()
			if self.DEBUG then LOG("More+: Checking sub dir " .. subDirPath) end
			
			local category = subDir:name()
			local skillObjs = {}
			for _, file in ipairs(subDir:files()) do
				local filename = file:name():match("(.+)%.lua$") or file:name()
				if self.DEBUG then LOG("More+: Found skill file " .. filename) end
				
				local requirePath = subDirPath .. filename				
				local success, skillObj = pcall(require, requirePath)
				if success and type(skillObj) == "table" then
					skillObj.file = requirePath
					skillObj.category = category
					table.insert(skillObjs, skillObj)
					numSkills = numSkills + 1
				else
					LOG("More+: Failed to load " .. requirePath .. ": " .. tostring(skillObj))
				end
			end
			self.skillsByCategory[category] = skillObjs
			numCats = numCats + 1
        end
    end
	if self.DEBUG then LOG("More+: Found " .. numSkills .. " in " .. numCats .. " categories") end
end

function more_plus:init()
	self.SkillTrait:baseInit()
	self.SkillActive:baseInit()

	if self.DEBUG then LOG("Finding all skills...") end
	more_plus:scanAndReadSkillFiles(basePath)
	
	if self.DEBUG then LOG("Creating all skills...") end
	-- Then go through and create the skills
	for category, skills in pairs(self.skillsByCategory) do
		if self.DEBUG then LOG("Creating skills for category " .. category) end
		local cplusCategory = "Rr" .. category
		for _, skill in pairs(skills) do
			-- simulate continue with an added loop level
		    repeat
				if self.DEBUG then LOG("Creating skill " .. skill.id) end
				-- make sure we have the required fields
				if not skill.id then
					LOG("More+: Failed to find id for skill at: " .. skill.path)
					break
				end
				if not skill.description then
					LOG("More+: Failed to description for skill at: " .. skill.path)
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
					LOG("More+: Failed to find name or short name and full name for skill at: " .. skill.path)
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
				if self.DEBUG then LOG("Initializing skill " .. skill.id) end
				if skill.init then
					skill:init()
				end
				break
			until true
		end
	end
end

function more_plus:load()
	if self.DEBUG then LOG("Loading all skills...") end
	for category, skills in pairs(more_plus.skillsByCategory) do
		if self.DEBUG then LOG("Loading skills for category " .. category) end
		for _, skill in pairs(skills) do
			if self.DEBUG then LOG("Loading skill " .. skill.id) end
			-- Call load on the function if it exists
			if skill.load then
				skill:load()
			end
		end
	end
end

return more_plus