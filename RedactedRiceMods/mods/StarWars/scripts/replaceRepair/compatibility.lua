
local nullfunction = function() end
local compatibility = {}

compatibility.SetRepairSkill = ReplaceRepair.addSkill
compatibility.SetPilotRepairSkill = ReplaceRepair.addSkill
compatibility.SetMechRepairSkill = ReplaceRepair.addSkill
compatibility.GetCurrentSkill = function() return ReplaceRepair:getCurrentSkill() end
compatibility.GetVersion = ReplaceRepair.getVersion
compatibility.GetHighestVersion = ReplaceRepair.getVersion
compatibility.mostRecent = ReplaceRepair
compatibility.init = nullfunction
compatibility.load = nullfunction
compatibility.internal_init = nullfunction

if lmn_replaceRepair then
	if lmn_replaceRepair.swaps ~= ReplaceRepair.queued then
		for _, entry in ipairs(lmn_replaceRepair.swaps) do
			table.insert(ReplaceRepair.queued, entry)
		end
	end
end

lmn_replaceRepair = {}
lmn_replaceRepair.swaps = ReplaceRepair.queued

if replaceRepair_internal == nil then
	replaceRepair_internal = {}

	replaceRepair_internal.RootGetTargetArea = Skill_Repair.GetTargetArea
	replaceRepair_internal.RootGetSkillEffect = Skill_Repair.GetSkillEffect
	replaceRepair_internal.OrigGetTargetArea = Skill_Repair.GetTargetArea
	replaceRepair_internal.OrigGetSkillEffect = Skill_Repair.GetSkillEffect
	replaceRepair_internal.OrigTipImage = Skill_Repair.TipImage
	replaceRepair_internal.OrigName = Weapon_Texts.Skill_Repair_Name
	replaceRepair_internal.OrigDescription = Weapon_Texts.Skill_Repair_Description
end

setmetatable(ReplaceRepair, { __index = compatibility })
setmetatable(lmn_replaceRepair, { __index = ReplaceRepair })
setmetatable(replaceRepair_internal, { __index = ReplaceRepair })

function compatibility:ForPilot(sPilotSkill, sWeapon, sPilotTooltip, sIcon)
	Assert.ModInitializingOrLoading()

	self:addSkill{
		name = sPilotTooltip[1],
		description = sPilotTooltip[2],
		pilotSkill = sPilotSkill,
		weapon = sWeapon,
		icon = sIcon
	}
end

function compatibility:ForMech(sMech, sWeapon, sIcon)
	Assert.ModInitializingOrLoading()

	self:addSkill{
		mechType = sMech,
		weapon = sWeapon,
		icon = sIcon
	}
end
