Treeherders_ForestFire = Skill:new{
	Name = "Forest Fire",
	Description = "Teleport to any space in the forest then fire dead logs, pushing attacked tiles and growing a forest tile on target and behind this mech. Does not start fires. Range: 2-4",
	Class = "Ranged",
	Icon = "weapons/ranged_th_forestFirer.png",
	Rarity = 1,
	Damage = 1,
	PowerCost = 1,
	--LaunchSound = "/weapons/artillery_volley",
	ShootSound = "/weapons/artillery_volley",
	ImpactSound = "/impact/dynamic/rock",
	UpShot = "effects/shotup_th_deadtree.png",
	UpShotOuter = "effects/shotup_th_deadtree.png",
	Explosion = "",
	BounceAmount = forestUtils.floraformBounce,
	Upgrades = 2,
	UpgradeCost = { 1, 3 },

	TwoClick = true,

	-- Range
	ArtilleryStart = 2,
	ArtillerySize = 4,

	-- Custom
	PushOuter = false,
	DamageOuter = 0,
	BounceOuterAmount = 2,
	BounceCenterAmount = 2,
	BuildingDamage = true,

	--TipImage
    TipImage = {
		Unit = Point(3,3),
		Enemy = Point(2,1),
		Building = Point(3,1),
		Forest = Point(3,3),
		Forest2 = Point(2,3),
		Target = Point(2,3),
		Second_Click = Point(2,1),
	},
}

Weapon_Texts.Treeherders_ForestFire_Upgrade1 = "Spray"
Treeherders_ForestFire_A = Treeherders_ForestFire:new
{
	UpgradeDescription = "Deals 1 damage and pushes tiles to the left and right of the target",
	DamageOuter = 1,
}

--TODO make increase based on adjacent forests?
Weapon_Texts.Treeherders_ForestFire_Upgrade2 = "+2 Damage"
Treeherders_ForestFire_B = Treeherders_ForestFire:new
{
	UpgradeDescription = "Primary target takes two more damage",
	UpShot = "effects/shotup_th_deadtree_3.png",
	Damage = 3,
	BounceCenterAmount = 4,
}

Treeherders_ForestFire_AB = Treeherders_ForestFire_B:new
{
	DamageOuter = 1,
}

-- First action is to move to any space in the forest
function Treeherders_ForestFire:GetTargetArea(point)
	local ret = PointList()

	-- always can just not move
	ret:push_back(point)

	-- if we are on a forest then return the point we can move to in that forest
	-- this is needed with how getGroupingOfSpaces works since it consideres the
	-- point to be of the right type or as part of the boarder
	-- TODO Webbing check?
	if forestUtils.isAForest(point) then
		local forestGroup = forestUtils:getGroupingOfSpaces(point, forestUtils.isAForest)
		for k, v in pairs(forestGroup.group) do
			-- only add if the space isn't occupied already
			if not Board:IsPawnSpace(Point(v)) then
				ret:push_back(Point(v))
			end
		end
	end
	return ret
end

function Treeherders_ForestFire:AddBurrowMove(skillFx, p1, p2)
	-- Add teleport for preview
	skillFx:AddTeleport(p1,p2,NO_DELAY)
	
    -- initial burrow
    skillFx:AddBounce(p1, -5)
	skillFx:AddBurst(p1,"Emitter_Burst_$tile",DIR_NONE)
	skillFx:AddScript(string.format("Board:GetPawn(%s):SetInvisible(true)", Pawn:GetId()))
	
	-- todo get path through forest
	local forestTiles = forestUtils:getGroupingOfSpaces(p1, forestUtils.isAForest)
	LOG("Checking path from ".. p1:GetString() .. " to ".. p2:GetString())
	local path = forestUtils:FindBfsPath(p1, p2, forestTiles.group)
	local wait = 0.1
	for _, p in pairs(path) do
		skillFx:AddDelay(wait)
		skillFx:AddBounce(p,-3)
		skillFx:AddBurst(p,"Emitter_Burst_$tile",DIR_NONE)
	end
	
	-- Emerge
	skillFx:AddBounce(p2, 5)
	skillFx:AddBurst(p2,"Emitter_Burst_$tile",DIR_NONE)
	skillFx:AddScript(string.format("Board:GetPawn(%s):SetInvisible(false)", Pawn:GetId()))
	
	return skillFx
end

function Treeherders_ForestFire:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	if p1 ~= p2 then
		ret = self:AddBurrowMove(ret, p1,p2)
	else
		ret:AddDamage(SpaceDamage(p1,0))
	end
	return ret
end

function Treeherders_ForestFire:GetSecondTargetArea(p1,p2)
	local ret = PointList()

	-- Since we aren't inheriting from the artillery class,
	-- we reimplement the logic for our need
	for dir = DIR_START, DIR_END do
		for i = self.ArtilleryStart, self.ArtillerySize do
			local curr = Point(p2 + DIR_VECTORS[dir] * i)
			if not Board:IsValid(curr) then
				break
			end
			ret:push_back(curr)
		end
	end

	return ret
end

function Treeherders_ForestFire:GetFinalEffect(p1,p2,p3)
	-- Start with the previous partial effect, add a pause and build on it
	local ret = self:GetSkillEffect(p1, p2)
	ret:AddDelay(0.2)

	local attackDir = GetDirection(p3 - p2)

	local pBack = p2 + DIR_VECTORS[(attackDir + 2) % 4]
	if Board:IsValid(pBack) and forestUtils.isSpaceFloraformable(pBack) then
		forestUtils:floraformSpace(ret, pBack)
	end

	local damage = forestUtils:getFloraformSpaceDamage(p3, self.Damage, attackDir, false, not self.BuildingDamage)
	ret:AddBounce(p2, 1)

	-- Add slight delay so sound will play
	ret:AddDelay(0.1)
	
	local mainDelay = FULL_DELAY
	if self.DamageOuter > 0 then
		mainDelay = 0
	end
	damage.sSound = self.ShootSound
	ret:AddArtillery(p2, damage, self.UpShot, mainDelay)

	if self.DamageOuter > 0 then
		dir1 = (attackDir + 1) % 4
		dir2 = (attackDir - 1) % 4

		local side1 = p3 + DIR_VECTORS[dir1]
		local side2 = p3 + DIR_VECTORS[dir2]

		local side1Damage = forestUtils:getSpaceDamageWithoutSettingFire(side1, self.DamageOuter, attackDir, false, not self.BuildingDamage)
		local side2Damage = forestUtils:getSpaceDamageWithoutSettingFire(side2, self.DamageOuter, attackDir, false, not self.BuildingDamage)

		ret:AddArtillery(p2, side1Damage, self.UpShotOuter, 0)
		ret:AddArtillery(p2, side2Damage, self.UpShotOuter, FULL_DELAY)

		if self.BounceOuterAmount ~= 0 then
			ret:AddBounce(side1, self.BounceOuterAmount)
			ret:AddBounce(side2, self.BounceOuterAmount)
		end
	end
	-- Add bounce after any delays
	ret:AddBounce(p3, self.BounceCenterAmount)

	return ret
end