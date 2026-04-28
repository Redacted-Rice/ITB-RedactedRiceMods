
local VERSION = "1.2.0"
---------------------------------------------------
-- Artillery Arc - code library
--
-- by Lemonymous
---------------------------------------------------
-- When Artillery Arc has executed, skills can set
-- the following fields to automatically adjust
-- artillery height, both when they are armed, and
-- when viewed in the tooltip:
--
--    Skill.ArtilleryHeight - if defined,
-- specifies the height of any artillery attack in
-- the skill.
--
--    Skill.GetArtilleryHeight - function variant
-- of Skill.ArtilleryHeight.
--
--    Skill.UpdateArtilleryHeight - if defined,
-- this function will be called each update when
-- the skill is armed or viewed in the tipimage,
-- allowing you to set a conditional artillery
-- height. The library will handle resetting the
-- value automatically.
--
-- requires
--    modApiExt
--    weaponArmed
--
---------------------------------------------------

local mod = modApi:getCurrentMod()
local path = GetParentPath(...)
local weaponArmed = require(path.."weaponArmed")
local modApiExt = modapiext or require(mod.scriptPath.."modApiExt/modApiExt")
local DEFAULT_HEIGHT = 18

local function onModsInitialized()
	if VERSION < ArtilleryArc.version then
		return
	end

	if ArtilleryArc.initialized then
		return
	end

	ArtilleryArc:finalizeInit()
	ArtilleryArc.initialized = true
end

modApi:addModsInitializedHook(onModsInitialized)


local isNewestVersion = false
	or ArtilleryArc == nil
	or modApi:isVersion(VERSION, ArtilleryArc.version) == false

if isNewestVersion then
	ArtilleryArc = ArtilleryArc or {}
	ArtilleryArc.version = VERSION

	local function resetArtilleryHeight()
		Values.y_velocity = DEFAULT_HEIGHT
	end

	local function setSkillArtilleryHeight(skill)
		local artilleryHeight
		if type(skill.GetArtilleryHeight) == 'function' then
			artilleryHeight = skill:GetArtilleryHeight()
		end

		if type(artilleryHeight) ~= 'number' then
			artilleryHeight = skill.ArtilleryHeight
		end

		if type(artilleryHeight) == 'number' then
			Values.y_velocity = artilleryHeight
		else
			resetArtilleryHeight()
		end
	end

	ArtilleryArc.onWeaponArmed = function(armedSkill)
		local hoveredSkill = modApi:getHoveredSkill()
		if hoveredSkill then return end

		setSkillArtilleryHeight(armedSkill)
	end

	ArtilleryArc.onWeaponUnarmed = function(skill)
		local hoveredSkill = modApi:getHoveredSkill()
		if hoveredSkill then return end

		resetArtilleryHeight()
	end

	ArtilleryArc.onSkillEnd = function(mission, pawn, weaponId, p1, p2)
		local hoveredSkill = modApi:getHoveredSkill()
		if hoveredSkill then return end

		local armedSkill = weaponArmed:getArmedWeapon()
		if armedSkill then
			setSkillArtilleryHeight(armedSkill)
		else
			resetArtilleryHeight()
		end
	end

	ArtilleryArc.onTipImageShown = function(hoveredSkill)
		setSkillArtilleryHeight(hoveredSkill)
	end

	ArtilleryArc.onTipImageHidden = function(skill)
		local armedSkill = weaponArmed:getArmedWeapon()
		if armedSkill then
			setSkillArtilleryHeight(armedSkill)
		else
			resetArtilleryHeight()
		end
	end

	ArtilleryArc.onMissionUpdate = function(mission)
		local skill = modApi:getHoveredSkill() or weaponArmed:getArmedWeapon()
		if skill then
			if type(skill.UpdateArtilleryHeight) == 'function' then
				skill.UpdateArtilleryHeight()
			end
		end
	end

	function ArtilleryArc:finalizeInit()
		weaponArmed.events.onWeaponArmed:subscribe(self.onWeaponArmed)
		weaponArmed.events.onWeaponUnarmed:subscribe(self.onWeaponUnarmed)
		modApiExt.events.onSkillEnd:subscribe(self.onSkillEnd)
		modApi.events.onTipImageShown:subscribe(self.onTipImageShown)
		modApi.events.onTipImageHidden:subscribe(self.onTipImageHidden)
		modApi.events.onMissionUpdate:subscribe(self.onMissionUpdate)
	end
end
