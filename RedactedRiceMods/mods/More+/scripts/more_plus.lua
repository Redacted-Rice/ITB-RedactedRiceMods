more_plus = more_plus or {}

more_plus.skills = {}
more_plus.DEBUG = true

local path = GetParentPath(...)

function more_plus.getDirs(path)
    local p = io.popen('dir "' .. path .. '" /b /ad')
    local dirs = {}

    for entry in p:lines() do
        table.insert(dirs, entry)
    end

    p:close()
    return dirs
end

function more_plus.getLuaFiles(path)
    local p = io.popen('dir "' .. path .. '" /b')
    local files = {}

    for file in p:lines() do
        if file:match("%.lua$") then
            table.insert(files, file)
        end
    end

    p:close()
    return files
end

function more_plus:findAllSkills()
	local basePath = path .. "scripts"
	local categories =  more_plus.getDirs(basePath)
	LOG(categories)
	
	-- auto gather all categories and skills
	for _, category in pairs(categories) do
		local folderPath = basePath .. "/" .. category
		if self.DEBUG then LOG("Checking folder " .. folderPath) end
		
		local skillObjs = {}
		local files = more_plus.getLuaFiles(folderPath)
		LOG(files)
		for _, file in pairs(files) do
			local filepath = folderPath .. "/" .. file
			if self.DEBUG then LOG("Adding file " .. filepath) end
			
			local skillObj = require(filepath)
			skillObj.file = filepath
			table.insert(skillObjs, skillObj)
		end
		self.skills[category] = skillObjs
	end
end

function more_plus:init()
	if self.DEBUG then LOG("Finding all skills...") end
	self:findAllSkills()
	
	if self.DEBUG then LOG("Creating all skills...") end
	-- Then go through and create the skills
	for _, cateogry in pairs(self.skills) do
		if self.DEBUG then LOG("Creating skills for category " .. cateogry) end
		local cplusCategory = "Rr" .. cateogry
		for _, skill in pairs(cateogry) do
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