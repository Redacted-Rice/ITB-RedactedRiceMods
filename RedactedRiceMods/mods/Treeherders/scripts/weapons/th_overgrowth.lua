Treeherders_Overgrowth = Skill:new
{
	Name = "Summon Ancients",
	Class = "Prime",
	Description = "Create an overgrowth tile with forest tiles surounding it. Flip target's direction",
	Icon = "weapons/prime_th_summonTheAncients.png",
	Rarity = 2,
	
	Explosion = "",
	LaunchSound = "/weapons/titan_fist",
	
	Projectile = false,
    Damage = 2,
    PowerCost = 0,
	Limited = 1,
    Upgrades = 2,
    UpgradeCost = { 1, 1 },
	
	--custom
	ForestPawns = false,
	MovingVek = {},
	
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

	-- Can target anywhere as long as its formable
	for x = 0, 7 do
		for y = 0,7 do
			local point = Point(x, y)
			if forestUtils.isSpaceFloraformable(point) then
				ret:push_back(point)
			end
		end
	end
	
	return ret
end

function Treeherders_Overgrowth:AddEffectForTarget(effect, point)
	forestUtils.addCreateAncientForest(point, self.Damage, effect)
	effect:AddDelay(0.1)
	
	for i = 0, 3 do
		local adj = point + DIR_VECTORS[i]
		-- avoid making the target spaces forests also
		if adj ~= p2 and adj ~= p3 and forestUtils.isSpaceFloraformable(adj) then
			forestUtils:floraformSpace(effect, adj, DAMAGE_ZERO)
		end
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

-- TODO: Really should be with overgrowth tile logic but this is the only way
-- to get them anyways :shrug:
function Treeherders_Overgrowth:GetPassiveSkillEffect_NextTurnHook(mission)
	--LOG("next turn "..Game:GetTeamTurn())
	if Game:GetTeamTurn() == TEAM_PLAYER then
		-- find overgrowth and flip/damage
		local points = forestUtils.findAncientForests()
		for _, point in pairs(points) do
			if Board:IsPawnSpace(point) and not Board:GetPawn(point):IsPlayer() then
				local effect = SkillEffect()
				-- only does 1 damage passively
				effect:AddDamage(SpaceDamage(point, 1, DIR_FLIP))
				effect:AddBounce(point, 3)
				effect:AddBoardShake(0.5)
				effect:AddDelay(0.1)
				Board:AddEffect(effect)
			end
		end
	end
	-- clear any moving vek to prevent pushing them not
	-- to work as expected
	self.MovingVek = {}
end
		
function Treeherders_Overgrowth:GetPassiveSkillEffect_VekMoveStartHook(mission, pawn)
	-- vek move end is fired before the vek actually moves so
	-- just handle clearing here first by setting to a new table
	self.MovingVek = { Pawn = pawn }
	--LOG("moving vek id "..pawn:GetId().." type ".. pawn:GetType() .. " at "..pawn:GetSpace():GetString())
end
		
function Treeherders_Overgrowth:GetPassiveSkillEffect_PawnPositionChangedHook(mission, pawn, oldPos)
	--LOG("PAWN MOVING "..pawn:GetId().." type ".. pawn:GetType() .. " from "..oldPos:GetString()) 
	if self.MovingVek.Pawn and self.MovingVek.Pawn:GetId() == pawn:GetId() then
		--LOG("SELECTED PAWN MOVING")
		local newPos = pawn:GetSpace()
		if self.MovingVek.TrappedSpace and newPos ~= self.MovingVek.TrappedSpace then
			pawn:SetSpace(self.MovingVek.TrappedSpace)
			--LOG("reset vek space")
		elseif forestUtils.isAnAncientForest(newPos) then
			--LOG("TRAPPED!")
			self.MovingVek.TrappedSpace = newPos
		end
	end
end

Treeherders_Overgrowth.passiveEffect:addPassiveEffect("Treeherders_Overgrowth",
		{"nextTurnHook", "vekMoveStartHook", "pawnPositionChangedHook"},
		true) -- not passive only