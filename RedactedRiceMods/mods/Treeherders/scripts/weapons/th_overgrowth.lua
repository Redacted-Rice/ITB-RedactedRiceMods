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

function Treeherders_Overgrowth:init() 
	local tileset = easyEdit.tileset:get("grass")
	tileset:appendAssets("img/combat/tile_icon")
	tileset:addTile("overgrowth", Point(-28,-3))
	easyEdit.tileset:get("grass"):setTileTooltip{
		tile = "overgrowth",
		title = "Ancient Forest",
		text = "Damages vek and confuses them causing them to attack opposite direction"
	}
end

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
	local damage = SpaceDamage(point, self.Damage, DIR_FLIP)
	damage.iTerrain = TERRAIN_ROAD
	damage.sScript = [[ Board:SetCustomTile(]] .. point:GetString() .. [[, "]].. self.Overgrowth .. [[")]]
	
	effect:AddDamage(damage)
	effect:AddBounce(point, 6)
	effect:AddBoardShake(0.5)
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


function Treeherders_Overgrowth:GetPassiveSkillEffect_NextTurnHook(mission)
	LOG("next turn "..Game:GetTeamTurn())
	if Game:GetTeamTurn() == TEAM_PLAYER then
		-- find overgrowth and flip
		for x = 0, 7 do
			for y = 0,7 do
				local point = Point(x, y)
				if Board:GetCustomTile(point) == self.Overgrowth and Board:IsPawnSpace(point) and not Board:GetPawn(point):IsPlayer() then
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

Treeherders_Overgrowth.movingVek = {}
function Treeherders_Overgrowth:GetPassiveSkillEffect_VekMoveStartHook(mission, pawn)
	self.movingVek.pawn = pawn
	self.movingVek.startSpace = pawn:GetSpace()
	LOG("moving vek id "..pawn:GetId().." type ".. pawn:GetType() .. " at "..self.movingVek.startSpace:GetString())
end

function Treeherders_Overgrowth:GetPassiveSkillEffect_VekMoveEndHook(mission, pawn)
	LOG("End moving vek")
	-- TODO: Clear on turn end instead
	--self.movingVek = {}
end

-- todo: still not working great
function Treeherders_Overgrowth:GetPassiveSkillEffect_PawnPositionChangedHook(mission, pawn, oldPos)
	LOG("PAWN MOVING "..pawn:GetId().." type ".. pawn:GetType() .. " from "..oldPos:GetString()) 
	if self.movingVek.pawn and self.movingVek.pawn:GetId() == pawn:GetId() then
		LOG("SELECTED PAWN MOVING")
		if oldPos ~= self.movingVek.startSpace and Board:GetCustomTile(oldPos) == self.Overgrowth then
			pawn:SetSpace(oldPos)
			LOG("reset vek space")
		end
	end
end

Treeherders_Overgrowth.passiveEffect:addPassiveEffect("Treeherders_Overgrowth",
		{"nextTurnHook", "vekMoveStartHook", "vekMoveEndHook", "pawnPositionChangedHook"},
		true) -- not passive only