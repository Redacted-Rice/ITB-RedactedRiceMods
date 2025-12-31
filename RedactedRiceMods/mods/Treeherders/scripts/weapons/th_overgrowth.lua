Treeherders_Overgrowth = Skill:new
{
	Name = "Summon the Ancients",
	Class = "Prime",
	Description = "Create an overgrowth tile with forest tiles surounding it. Flip target's direction",
	Icon = "weapons/prime_th_Overgrowth.png",
	Rarity = 2,
	
	Explosion = "",
	LaunchSound = "/weapons/titan_fist",
	
	Projectile = false,
    Damage = 1,
    PowerCost = 0,
	Limited = 1,
    Upgrades = 2,
    UpgradeCost = { 1, 1 },
	
	--custom
	ForestPawns = false,
	Overgrowth = "overgrowth.png",
	
    TipImage = {
		Unit = Point(2,3),
		Target = Point(2,1),
		Enemy = Point(2,1),
	},
}

local mod = modApi:getCurrentMod()
local cyborg = mod_loader.currentModContent[mod.id].options["th_EntborgCyborg"].value
if cyborg == 1 then
	Treeherders_Overgrowth.Class = "TechnoVek"
end

Treeherders_Overgrowth.passiveEffect = mod_loader.mods[modApi.currentMod].libs.passiveEffect

Weapon_Texts.Treeherders_Overgrowth_Upgrade1 = "+ Target"
Treeherders_Overgrowth_A = Treeherders_Overgrowth:new
{
	UpgradeDescription = "Repeat effect on a second target",
	TwoClick = true,
}

Weapon_Texts.Treeherders_Overgrowth_Upgrade2 = "Extra Forests"
Treeherders_Overgrowth_B = Treeherders_Overgrowth:new
{
	UpgradeDescription = "Grow forests on each tile with pawns",
	ForestPawns = true,
}

Treeherders_Overgrowth_AB = Treeherders_Overgrowth_A:new
{
	ForestPawns = true,
}

function Treeherders_Overgrowth:GetTargetArea(point)
	local ret = PointList()

	-- Can target anywhere
	-- TODO: Exclude some tiles (custom and water and holes)
	for x = 0, 7 do
		for y = 0,7 do
			ret:push_back(Point(x, y))
		end
	end
	
	return ret
end

function Treeherders_Overgrowth:AddEffectForTarget(effect, point)
	local damage = SpaceDamage(point, self.Damage, DIR_FLIP)
	damage.iTerrain = TERRAIN_FOREST
	damage.sScript = [[ Board:SetCustomTile(]] .. point:GetString() .. [[, "]].. self.Overgrowth .. [[")]]
	
	effect:AddDamage(damage)
	effect:AddBounce(point, 6)
	effect:AddBoardShake(0.5)
	effect:AddDelay(0.1)
	
	for i = 0, 3 do
		forestUtils:floraformSpace(effect, point + DIR_VECTORS[i], DAMAGE_ZERO)
	end
end

function Treeherders_Overgrowth:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	self:AddEffectForTarget(ret, p2)
	return ret
end

function Treeherders_Overgrowth:GetSecondTargetArea(p1,p2)
	return self:GetTargetArea(p2)
end

function Treeherders_Overgrowth:GetFinalEffect(p1,p2,p3)
	local ret = SkillEffect()
	self:AddEffectForTarget(ret, p2)
	ret:AddDelay(0.2)
	self:AddEffectForTarget(ret, p3)
	return ret
end


function Treeherders_Overgrowth:GetPassiveSkillEffect_NextTurnHook(mission)
	if Game:GetTeamTurn() == TEAM_PLAYER then
		-- find overgrowth and flip
		for x = 0, 7 do
			for y = 0,7 do
				if Board:GetCustomTile(Point(x, y)) == self.Overgrowth then
					local effect = SkillEffect()
					effect:AddDamage(SpaceDamage(point, self.Damage, DIR_FLIP))
					effect:AddBounce(point, 3)
					effect:AddBoardShake(0.5)
					effect:AddDelay(0.1)
					Board:AddEffect(effect)
				end
			end
		end
	end
end

Treeherders_Overgrowth.passiveEffect:addPassiveEffect("Treeherders_Overgrowth",
		{"nextTurnHook"},
		true) -- not passive only