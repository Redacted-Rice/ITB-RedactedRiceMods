WarTrain_RammingSpeed = Skill:new{
	Name = "Ramming Speed",
	Description = "Charge in a straight line, dealing 3 damage and pushing the target. The whole train moves with the War Engine.",
	Class = "Prime",
	Icon = "weapons/prime_wartrain_ram.png",
	Rarity = 1,
	Damage = 3,
	Push = 1,
	PowerCost = 0,
	Upgrades = 0,
	LaunchSound = "/weapons/charge",
	ImpactSound = "/weapons/charge_impact",
	ZoneTargeting = ZONE_DIR,
	TipImage = {
		Unit = Point(2, 3),
		Enemy = Point(2, 1),
		Target = Point(2, 1),
		CustomPawn = "WarTrain_WarEngineMech",
	},
}

function WarTrain_RammingSpeed:GetTargetArea(point)
	local ret = PointList()
	for i = DIR_START, DIR_END do
		local curr = point + DIR_VECTORS[i]
		while Board:IsValid(curr) and not Board:IsBlocked(curr, PATH_PROJECTILE) do
			ret:push_back(curr)
			curr = curr + DIR_VECTORS[i]
		end
		if Board:IsValid(curr) then
			ret:push_back(curr)
		end
	end
	return ret
end

function WarTrain_RammingSpeed:GetSkillEffect(p1, p2)
	local direction = GetDirection(p2 - p1)

	local target = GetProjectileEnd(p1, p2, PATH_PROJECTILE)
	if not Board:IsBlocked(target, PATH_PROJECTILE) then
		target = target + DIR_VECTORS[direction]
	end

	local chargeEnd = target - DIR_VECTORS[direction]
	if chargeEnd == p1 then
		chargeEnd = p1 + DIR_VECTORS[direction]
	end

	local enginePath = PointList()
	enginePath:push_back(p1)
	local curr = p1
	while curr ~= chargeEnd do
		curr = curr + DIR_VECTORS[direction]
		enginePath:push_back(curr)
	end

	local damage = SpaceDamage(target, self.Damage, direction)
	damage.sSound = self.ImpactSound
	damage.sAnimation = "ExploAir2"

	local ret = SkillEffect()
	TrainPawn.addTrainCharge(ret, enginePath, NO_DELAY)

	if p1:Manhattan(target) == 1 then
		ret:AddMelee(p1, damage, NO_DELAY)
	else
		ret:AddDamage(damage)
	end

	return ret
end
