local this = {}

local mod = mod_loader.mods[modApi.currentMod]
local path = mod.resourcePath

local pilot = {
	Id = "Pilot_Darth_Vader",
	Personality = "Darth_Vader_Personality",
	Name = "Darth Vader",
	Sex = SEX_MALE,
	Skill = "Force Choke",
	Voice = "/voice/rust",
}

local dialog = require(path .. "scripts/pilots/dialog_darth_vader")

function this:GetPilot()
	return pilot
end

Vader_ForceChoke_Repair = Skill:new{
	Name = "Force Choke",
	Description = "Deal 1 damage to an adjacent enemy, cancel their attack, and set their speed to 0 for 1 turn.",
	Icon = "weapons/vader_repair.png",
	PathSize = 1,
	Damage = 1,
	LaunchSound = "/weapons/gravwell",
	ImpactSound = "/impact/generic/grapple",
	TipImage = {
		Unit = Point(2, 3),
		Enemy = Point(2, 2),
		Target = Point(2, 2),
	},
}

function Vader_ForceChoke_Repair:GetTargetArea(point)
	local ret = PointList()

	for dir = DIR_START, DIR_END do
		local target = point + DIR_VECTORS[dir]
		if Board:IsValid(target) and Board:IsPawnSpace(target) then
			local targetPawn = Board:GetPawn(target)
			if targetPawn:IsEnemy() then
				ret:push_back(target)
			end
		end
	end

	return ret
end

function Vader_ForceChoke_Repair:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local damage = SpaceDamage(p2, self.Damage)
	ret:AddDamage(damage)
	ret:AddBounce(p2, 1)

	if Board:IsPawnSpace(p2) then
		local targetId = Board:GetPawn(p2):GetId()
		local casterId = Board:GetPawn(p1):GetId()

		damage.sScript = (damage.sScript or "") .. string.format([[
			Board:GetPawn(%d):AddMoveBonus(-99)
		]], targetId)

		if not Board:IsTipImage() then
			damage.sScript = damage.sScript .. string.format([[
				local cast = { main = %d }
				modapiext.dialog:triggerRuledDialog("Vader_ForceChoke", cast)
			]], casterId)
		end
	end

	BoardUtils.addCancelEffect(p2, ret)
	return ret
end

function this:init(mod)
	CreatePilot(pilot)

	ReplaceRepair:addSkill({
		name = "Force Choke",
		description = "Deal 1 damage to an adjacent enemy, cancel their attack, and set their speed to 0 for 1 turn.",
		weapon = "Vader_ForceChoke_Repair",
		icon = "img/weapons/vader_repair.png",
		pilotSkill = pilot.Skill,
	})
end

function this:load(options, version)
	modapiext.dialog:addRuledDialog("Vader_ForceChoke", {
		Odds = 75,
		{ main = "Vader_ForceChoke" },
	})
end

local personality = mod.libs.personality:new{ Label = "Vader" }
personality:AddDialog(dialog)
Personality[pilot.Personality] = personality

Pilot_Darth_Vader_Ref = this
return Pilot_Darth_Vader_Ref
