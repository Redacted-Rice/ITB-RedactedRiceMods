more_plus = more_plus or {}

more_plus.skillsByCategory = {}
more_plus.DEBUG = true

local path = GetParentPath(...)

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
	if self.DEBUG then LOG("Finding all skills...") end
	more_plus:scanAndReadSkillFiles(basePath)
	
	if self.DEBUG then LOG("Creating all skills...") end
	-- Then go through and create the skills
	for category, skills in pairs(self.skillsByCategory) do
		if self.DEBUG then LOG("Creating skills for category " .. cateogry) end
		local cplusCategory = "Rr" .. cateogry
		for _, skill in pairs(skills) do
			-- simulate continue with an added loop level
		    repeat
				if self.DEBUG then LOG("Creating skill " .. skill.id) end
				-- make sure we have the required fields
				if not skill.id then
					LOG("More+: Failed to find id for skill at: " .. skill.path)
					break
				end
				if not skill.desc then
					LOG("More+: Failed to description for skill at: " .. skill.path)
					break
				end
				
				-- If we just use name, set short and full name
				-- Also create the text in modloader
				local shortName = ""
				local fullName = ""
				if skill.name then
					skill.shortName = skill.name
					skill.fullName = skill.name
					shortName = "MorePlus_" .. skill.name .. "_Name"
					fullName = shortName
					modApi:setText(shortName, name)
				elseif skill.shortName and skill.fullName then
					shortName = "MorePlus_" .. skill.shortName .. "_ShortName"
					fullName = "MorePlus_" .. skill.fullName .. "_FullName"
					modApi:setText(shortName, skill.shortName)
					modApi:setText(fullName, skill.fullName)
				else
					LOG("More+: Failed to find name or short name and full name for skill at: " .. skill.path)
					break
				end
				
				-- Make description text in modloader. Not necessary but does allow for easier
				-- text replacing
				local desc = "MorePlus_" .. skill.desc .. "_Description"
				modApi:setText(desc, skill.desc)
				
				-- Actually register the skill
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
	for _, cateogry in pairs(self.skills) do
		if self.DEBUG then LOG("Loading skills for category " .. cateogry) end
		for _, skill in pairs(cateogry) do
			if self.DEBUG then LOG("Loading skill " .. skill) end
			-- Call load on the function if it exists
			if skill.load then
				skill:load()
			end
		end
	end
end

return more_plus