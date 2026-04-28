
local path = GetParentPath(...)
local selected = require(path.."lib/selected")
local tipImageBuilder = require(path.."tipImageBuilder")
local getSelectedPawn = selected.getSelectedPawn

-- overriding most of these fields,
-- even if they won't make an impact on the tipimage.
local fields = {
	"Name",				-- displays
	"Description",		-- displays
	--"Class",			-- no display. Causes bizarre crashes
	"PathSize",
	"MinDamage",		-- displays?
	"Damage",			-- displays
	"SelfDamage",		-- displays
	--"Limited",		-- shows up on tooltip, but doesn't seem to do anything. Causes bizarre crashes
	"LaunchSound",		-- no sound in tipimage
	"ImpactSound",		-- no sound in tipimage
	"ProjectileArt",
	"Web",
	"Push",
	"Acid",
	"Range",
	"Smoke",
	"Fire",
	"Shield",
	"TargetArea",
	"SkillEffect"
	--"TipImage"		-- GetTipImage is called once, so overriding is useless.
}

local weaponTexts = {
	"Name",
	"Description"
}

local function getTargetArea(skill, p, ...)
	local Skill = _G[skill]

	if Board:IsTipImage() then
		tipImageBuilder:clear()
		tipImageBuilder:setup(skill)

		-- call original GetTargetArea to ensure
		-- GetSkillEffect is called.
		return Skill_Repair_Orig:GetTargetArea(p, ...)
	end
	
	return Skill:GetTargetArea(p, ...)
end

local function getSkillEffect(skill, p1, p2, _, ...)
	local Skill = _G[skill]
	
	if Board:IsTipImage() then
		if Skill.CustomTipImage ~= "" then
			skill = Skill.CustomTipImage
		end
		
		local check = tipImageBuilder:verify(skill)
		if check.incomplete then
			return lmn_TipImageNotFound:GetSkillEffect(
				p1,
				p2,
				lmn_TipImageNotFound,
				not check.unit,
				not check.target
			)
		end
		
		local Skill = _G[skill]
		local t = Skill.TipImage
		p1 = t.Unit or t.Unit_Damaged
		p2 = t.Target
	end
	
	return Skill:GetSkillEffect(p1, p2, Skill, ...)
end

local function getField(skill, field, ...)
	local Skill = _G[skill]
	if not Skill then
		skill = "lmn_RepairNotFound"
		Skill = lmn_RepairNotFound
	end
	
	-- need some special consideration for
	-- GetTargetArea and GetSkillEffect.
	if field == "TargetArea" then
		return getTargetArea(skill, ...)
	elseif field == "SkillEffect" then
		return getSkillEffect(skill, ...)
	end
	
	-- check Weapon_Texts for data and return
	-- those names and description if available.
	-- (could be done cleaner with gsub?)
	if list_contains(weaponTexts, field) then
		if
			skill:sub(-2,-1) == "_A" or 
			skill:sub(-2,-1) == "_B"
		then
			skill = skill:sub(1,-3)
		elseif skill:sub(-3,-1) == "_AB" then
			skill = skill:sub(1,-4)
		end
		
		local ret = Weapon_Texts[skill .."_".. field]
		if ret then return ret end
	end
	
	-- return other Get- functions.
	if type(Skill["Get".. field]) == 'function' then
		local ret = Skill["Get".. field](Skill, ...)
		if ret then return ret end
	end
	
	-- return fields without Get- functions.
	return Skill[field]
end

local function OverrideGetFuncs(field)
	Skill_Repair["Get".. field] = function(self, ...)
		local pawn = Board:IsTipImage() and getSelectedPawn() or Pawn
		if pawn then
			for _, repairSkill in ipairs(ReplaceRepair.repairSkills) do
				if repairSkill:isActive(pawn) then
					return getField(repairSkill.weapon, field, ...)
				end
			end
		end
		
		return getField("Skill_Repair_Orig", field, ...)
	end
end

local function overrideGetSkillInfo()
	local vanillaGetSkillInfo = GetSkillInfo

	function GetSkillInfo(skill)
		local repairSkill = ReplaceRepair:getCurrentSkill()

		if repairSkill and repairSkill.pilotSkill then
			return PilotSkill(
				repairSkill.name or "RR_NoNameFound",
				repairSkill.description or "RR_NoDescFound"
			)
		else
			for _, repairSkill in ipairs(ReplaceRepair.repairSkills) do
				if skill == repairSkill.pilotSkill then
					return PilotSkill(
						repairSkill.name or "RR_NoNameFound",
						repairSkill.description or "RR_NoDescFound"
					)
				end
			end
		end

		return vanillaGetSkillInfo(skill)
	end
end

local function overrideRepairSkill()
	Skill_Repair_Orig = Skill_Repair
	Skill_Repair = Skill_Repair:new{}

	-- Weapon_Texts for Skill_Repair needs to be cleared
	-- in order to rename Name and Description for custom skills.
	Weapon_Texts.Skill_Repair_Orig_Name = Weapon_Texts.Skill_Repair_Name
	Weapon_Texts.Skill_Repair_Orig_Description = Weapon_Texts.Skill_Repair_Description
	Weapon_Texts.Skill_Repair_Name = nil
	Weapon_Texts.Skill_Repair_Description = nil

	for _, field in ipairs(fields) do
		OverrideGetFuncs(field)
	end

	Skill_Repair.TipImage = copy_table(Skill_Repair.TipImage)
	Skill_Repair.TipImage.Fire = nil
end

local function overrideGetText()
	local vanillaGetText = GetText
	function GetText(id, ...)
		local result = vanillaGetText(id, ...)

		if id:match("^Skill_Repair") then
			local repairSkill = ReplaceRepair:getCurrentSkill()

			if repairSkill then
				if id:match("Name$") then
					result = _G[repairSkill.weapon]:GetName()
				elseif id:match("Description$") then
					result = _G[repairSkill.weapon]:GetDescription()
				end
			end
		end

		return result
	end
end

overrideGetSkillInfo()
overrideRepairSkill()
overrideGetText()
