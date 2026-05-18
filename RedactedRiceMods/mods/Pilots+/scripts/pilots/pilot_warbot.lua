local this = {}

local mod = mod_loader.mods[modApi.currentMod]
local path = mod.resourcePath
local scriptPath = mod.scriptPath

local pilot = {
	Id = "Pilot_Warbot",
	Personality = "Warbot_Personality",
	Name = "Warbot",
	Sex = SEX_MALE,
	Skill = "Combat Protocols",
	Voice = "/voice/ralph",
}

local dialog = require(path .. "scripts/pilots/dialog_warbot")

function this:GetPilot()
	return pilot
end

function this:addVirtualSkills(pilotStruct)
	-- Warbot gains skills equal to their level
	-- At level 1: 1 skill, level 2: 2 skills
	local pilotLevel = pilotStruct:getLevel()
	if pilotLevel < 1 then
		return
	end

	local pilotId = pilotStruct:getIdStr()
	local targetSkillCount = pilotLevel == 1 and 1 or 3
	local virtualSkills = cplus_plus_ex:getVirtualSkills(pilotId)
	local currentSkillCount = #virtualSkills

	-- Check if we already have the right number of skills
	if currentSkillCount >= targetSkillCount then
		LOG("Warbot already has " .. currentSkillCount .. " virtual skills (target: " .. targetSkillCount .. ")")
	else
		-- Add the missing skills
		local skillsToAdd = targetSkillCount - currentSkillCount
		LOG("Warbot needs " .. skillsToAdd .. " more virtual skills (current: " .. currentSkillCount .. ", target: " .. targetSkillCount .. ")")

		local addedCount = cplus_plus_ex:addRandomVirtualSkillsToPilot(pilotStruct, skillsToAdd)
		LOG("Added " .. addedCount .. " virtual skills to Warbot pilot (Level " .. pilotLevel .. ")")
	end
	for i, skillId in ipairs(cplus_plus_ex:getVirtualSkills(pilotId)) do
		LOG("  Virtual Skill " .. i .. ": " .. skillId)
	end
end

-- Build skill description showing current virtual skills
-- Uses skill ID to be generic across multiple pilots with this skill
function this:buildSkillDescription()
	local description = "Gains an extra level up skill at level 1 and two more at level 2."

	-- First, try to get virtual skills from active game pilots
	if Game then
		local pilots = Game:GetAvailablePilots()
		for _, pilotStruct in ipairs(pilots) do
			-- Check if this pilot has the Combat Protocols skill (more generic than pilot ID)
			local pilotSkill = pilotStruct:getSkill():get()
			if pilotSkill == pilot.Skill then
				-- Get virtual skill objects by pilot ID
				local pilotId = pilotStruct:getIdStr()
				local virtualSkillObjs = cplus_plus_ex:getVirtualSkillObjects(pilotId)
				if #virtualSkillObjs > 0 then
					local skillDetails = {}
					for _, skillObj in ipairs(virtualSkillObjs) do
						-- Get name and description from the skill object
						local name = GetText(skillObj:getFullNameStr())
						local desc = GetText(skillObj:getDescriptionStr())
						table.insert(skillDetails, name .. "\n" .. desc)
					end
					description = description .. " Extra Skills:\n\n" .. table.concat(skillDetails, "\n\n")
					return description
				end
			end
		end
	end

	-- If not found in Game, check time traveler persistent data (for time traveler selection screen)
	-- This handles the case when viewing a time traveler pilot before starting a new timeline
	if Profile and modApi:isProfilePath() then
		-- Get the pilot ID we're looking for (either from Profile.pilot or just check all Warbots)
		local targetPilotId = (Profile.pilot and Profile.pilot.id) or pilot.Id

		local savedData = {}
		sdlext.config(
			modApi:getCurrentProfilePath().."modcontent.lua",
			function(obj)
				if obj.cplus_plus_ex and obj.cplus_plus_ex.last_run_pilots then
					savedData = obj.cplus_plus_ex.last_run_pilots
				end
			end
		)

		-- Look through saved pilots for matching ID with virtual skills
		for pilotId, pilotData in pairs(savedData) do
			LOG(pilotId)
			-- Check if this is the pilot we're looking for AND it has virtual skills
			if (pilotId == targetPilotId or pilotId == pilot.Id) and
					pilotData.virtualSkills and #pilotData.virtualSkills > 0 then
				local skillDetails = {}
				for _, skillId in ipairs(pilotData.virtualSkills) do
					LOG(skillId)
					-- Get the skill object to show name and description
					local skillData = cplus_plus_ex:getRegisteredSkillInfo(skillId)
					if skillData then
						local name = GetText(skillData.fullName)
						local desc = GetText(skillData.description)
						table.insert(skillDetails, name .. "\n" .. desc)
					end
				end
				if #skillDetails > 0 then
					description = description .. " Extra Skills:\n\n" .. table.concat(skillDetails, "\n\n")
					return description
				end
			end
		end
	end

	-- No virtual skills found
	description = description .. " No extra skills earned yet."
	return description
end

function this:init(mod)
	-- Create the pilot
	CreatePilot(pilot)

	-- Override GetSkillInfo directly to dynamically show virtual skills
	local originalGetSkillInfo = GetSkillInfo
	function GetSkillInfo(skill)
		if skill == pilot.Skill then
			return PilotSkill(pilot.Skill, self:buildSkillDescription())
		end
		return originalGetSkillInfo(skill)
	end
end

-- Handle pilot level changes to add virtual skills
-- Uses skill ID check to work with any pilot that has Combat Protocols
function this:onPilotLevelChanged(pilotStruct, changes)
	if not changes.level then
		return
	end
	-- Check by skill ID to be more generic
	local pilotSkill = pilotStruct:getSkill():get()
	if pilotSkill == pilot.Skill then
		self:addVirtualSkills(pilotStruct)
	end
end

-- Handle skill assignment completion to ensure virtual skills are correct
-- Uses skill ID check to work with any pilot that has Combat Protocols
function this:onSkillsAssigned()
	if not Game then return end

	local pilots = Game:GetAvailablePilots()
	for _, pilotStruct in ipairs(pilots) do
		-- Check by skill ID to be more generic
		local pilotSkill = pilotStruct:getSkill():get()
		if pilotSkill == pilot.Skill then
			self:addVirtualSkills(pilotStruct)
		end
	end
end

function this:load(options, version)
	-- Use memhack's onPilotChanged event which fires when pilot properties change
	memhack.events.onPilotChanged:subscribe(function(pilotStruct, changes)
		self:onPilotLevelChanged(pilotStruct, changes)
	end)

	-- After skills are assigned, ensure warbot has the correct number of virtual skills
	cplus_plus_ex.events.onPostAssigningLvlUpSkills:subscribe(function()
		self:onSkillsAssigned()
	end)
end

-- Register personality with dialog
CreatePilotPersonality(pilot.Personality, dialog)

Pilot_Warbot_Ref = this
return Pilot_Warbot_Ref
