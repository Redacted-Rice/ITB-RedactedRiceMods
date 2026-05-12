local this = {}

local mod = mod_loader.mods[modApi.currentMod]
local scriptPath = mod.scriptPath

local pilot = {
	Id = "Pilot_Warbot",
	Personality = "Warbot_Personality",
	Name = "Warbot",
	Sex = SEX_MALE,
	Skill = "Combat Protocols",
	Voice = "/voice/ralph",
}

local dialog = require(scriptPath .. "pilots/dialog_warbot")

function this:GetPilot()
	return pilot
end

function this:addVirtualSkills(pilotStruct)
	local virtualSkills = cplus_plus_ex:getVirtualSkills(pilotStruct)
	if #virtualSkills > 0 then
		return
	end

	-- Warbot gains skills equal to their level
	-- At level 1: 1 skill, level 2: 2 skills
	local pilotLevel = pilotStruct:getLevel()
	local skillsToAdd = pilotLevel

	local addedCount = cplus_plus_ex:addRandomVirtualSkillsToPilot(pilotStruct, skillsToAdd)
	if addedCount > 0 then
		LOG("Added " .. addedCount .. " virtual skills to Warbot pilot (Level " .. pilotLevel .. ")")

		virtualSkills = cplus_plus_ex:getVirtualSkills(pilotStruct)
		for i, skillId in ipairs(virtualSkills) do
			LOG("  Virtual Skill " .. i .. ": " .. skillId)
		end
	end
end

function this:init(mod)
	CreatePilot(pilot)

	-- Override GetSkillInfo directly to dynamically show virtual skills
	local originalGetSkillInfo = GetSkillInfo
	function GetSkillInfo(skill)
		if skill == pilot.Skill then
			local description = "Gains random skills equal to level on each level up."

			-- Try to get the Warbot pilot to show their current virtual skills
			if Game then
				local pilots = Game:GetAvailablePilots()
				for _, pilotStruct in ipairs(pilots) do
					if pilotStruct:getIdStr() == pilot.Id then
						-- Get virtual skill objects directly from the pilot struct
						local virtualSkillObjs = cplus_plus_ex:getVirtualSkillObjects(pilotStruct)
						local level = pilotStruct:getLevel()

						description = description .. "\n\nLevel: " .. level

						if #virtualSkillObjs > 0 then
							local skillDetails = {}
							for _, skillObj in ipairs(virtualSkillObjs) do
								-- Get name and description from the skill object
								local name = GetText(skillObj:getFullNameStr())
								local desc = GetText(skillObj:getDescriptionStr())
								table.insert(skillDetails, name .. ": " .. desc)
							end
							description = description .. "\nExtra Skills:\n  • " .. table.concat(skillDetails, "\n  • ")
						else
							description = description .. "\n(No extra skills yet)"
						end
					end
				end
			end

			return PilotSkill(pilot.Skill, description)
		end

		return originalGetSkillInfo(skill)
	end
	LOG("Warbot pilot created")
end

function this:load(options, version)
	-- Use memhack's onPilotChanged event which fires when pilot properties change
	-- Only continue if level changed and the ID matches this pilot's ID
	memhack.events.onPilotChanged:subscribe(function(pilotStruct, changes)
		if not changes.level then
			return
		end
		local pilotId = pilotStruct:getIdStr()
		if pilotId == pilot.Id then
			self:addVirtualSkills(pilotStruct)
		end
	end)

	LOG("Warbot pilot hooks registered")
end

-- Register personality with dialog
CreatePilotPersonality(pilot.Personality, dialog)

Pilot_Warbot_Ref = this
return Pilot_Warbot_Ref
