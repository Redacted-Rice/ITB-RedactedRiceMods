WorldBuilders_Consume = Skill:new
{
	Name = "Consume",
    Class = "Brute",
    Description = "Consume the tile behind you and blast it at the target. The effect & damage varies based on the consumed tile. Can't consume units (except rocks)",
	Icon = "weapons/brute_wb_consume.png",
	Rarity = 1,

	LaunchSound = "/weapons/unstable_cannon",
	ImpactSound = "/impact/rock",

	Range = 2,
    Damage = 1,

	ConsumeBounce = -5,
	ProjectileHitBounce = 3,
	ProjectilePathBounce1 = 2,
	ProjectilePathBounce2 = -1,


    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = { 1, 1 },

	TwoClick = false,

    TipImage = {
		Unit = Point(2,3),
		Target = Point(2,2),
		Enemy = Point(2,2),
	},
}

WorldBuilders_Consume.weaponPreview = mod_loader.mods[modApi.currentMod].libs.weaponPreview

Weapon_Texts.WorldBuilders_Consume_Upgrade1 = "+1 Range"
WorldBuilders_Consume_A = WorldBuilders_Consume:new
{
	UpgradeDescription = "Can fire up to one more tile",
    Range = 3,
    TipImage = {
		Unit = Point(2,3),
		Target = Point(2,1),
		Enemy = Point(2,1),
	},
}

Weapon_Texts.WorldBuilders_Consume_Upgrade2 = "Adj consume"
WorldBuilders_Consume_B = WorldBuilders_Consume:new
{
	UpgradeDescription = "Can consume to left and right spaces instead of only behind space",
	TwoClick = true,
    TipImage = {
		Unit = Point(2,3),
		Target = Point(2,2),
		Foreset = Point(3,3),
		Second_Click = Point(3,3),
		Enemy = Point(2,2),
	},
}

WorldBuilders_Consume_AB = WorldBuilders_Consume_B:new
{
    Range = 3,
    TipImage = {
		Unit = Point(2,3),
		Target = Point(2,1),
		Foreset = Point(3,3),
		Second_Click = Point(3,3),
		Enemy = Point(2,1),
	},
}

function WorldBuilders_Consume:GetTargetArea(point)
	local ret = PointList()

	for dir = DIR_START, DIR_END do
		for i = 1, self.Range do
			local curr = Point(point + DIR_VECTORS[dir] * i)
			if not Board:IsValid(curr) then
				break
			end

			ret:push_back(curr)

			if Board:IsBlocked(curr,PATH_PROJECTILE) or Board:GetTerrain(curr) == TERRAIN_BUILDING then
				break
			end
		end
	end

	return ret
end

-- Choose any adj space too
function WorldBuilders_Consume_B:GetSecondTargetArea(p1, p2)
	local ret = PointList()
	local dir = GetDirection(p2 - p1) % 4
	ret:push_back(p1 + DIR_VECTORS[(dir + 1) % 4])
	ret:push_back(p1 + DIR_VECTORS[(dir + 2) % 4])
	ret:push_back(p1 + DIR_VECTORS[(dir + 3) % 4])
	return ret
end


function WorldBuilders_Consume:Consume_Spawn(skillEffect, p1, consumeSpace, dir)
	self.weaponPreview:AddAnimation(consumeSpace, "icon_wb_emerge_a")

	skillEffect:AddScript([[Board:AddPawn(GetCurrentMission():GetSpawnPointData(]] .. consumeSpace:GetString() .. [[).type, ]] .. consumeSpace:GetString() .. [[)]])
	skillEffect:AddScript([[Board:GetPawn(]] .. consumeSpace:GetString() .. [[):SpawnAnimation()]])
	skillEffect:AddScript([[GetCurrentMission():RemoveSpawnPoint(]] .. consumeSpace:GetString() .. [[)]])
	skillEffect:AddDelay(1)

	local spawnDamage = SpaceDamage(consumeSpace, 1, dir)
	if dir == DIR_LEFT then
		spawnDamage.sImageMark = "combat/arrow_hit_left.png"
	elseif dir == DIR_UP then
		spawnDamage.sImageMark = "combat/arrow_hit_up.png"
	elseif dir == DIR_RIGHT then
		spawnDamage.sImageMark = "combat/arrow_hit_right.png"
	else -- down
		spawnDamage.sImageMark = "combat/arrow_hit_down.png"
	end
	skillEffect:AddDamage(spawnDamage)
end

function WorldBuilders_Consume:GetConsumedItem(consumeSpace)
	local item = Board:GetItem(consumeSpace)
	if item and item ~= "" then
		-- If its a damaging/statusing effect, best guess is its something like a mine. Apply
		-- the effect to each space
		local itemDamage = _G[item].Damage
		if itemDamage.iDamage ~= 0 and itemDamage.iDamage ~= DAMAGE_ZERO then
			return nil, itemDamage
		elseif itemDamage.iAcid ~= EFFECT_NONE or itemDamage.iFire ~= EFFECT_NONE or itemDamage.iFrozen ~= EFFECT_NONE then
			return nil, itemDamage
		elseif itemDamage.iShield ~= EFFECT_NONE or itemDamage.iSmoke ~= EFFECT_NONE then
			return nil, itemDamage
		end
		-- Best guess is its a status like acid - return the item to add to spaces
		return item, nil
	end
	return nil
end

function WorldBuilders_Consume:AddItemOrItemDamage(spaceDamage, item, itemDamage)
	if item then
		spaceDamage.sItem = item
		local p = spaceDamage.loc
		-- if its a pawn space, it will trigger before the board events recognizes
		-- the item so manually trigger it
		if Board:IsPawnSpace(p) then
			spaceDamage.sScript = spaceDamage.sScript .. [[
				BoardEvents.onItemRemoved:dispatch(]] .. p:GetString() .. [[, "]] .. item .. [[")]]
		end
		spaceDamage.sImageMark = "combat/icons/icon_wb_unknown_item.png"
		return
	end

	if not itemDamage then
		return
	end

	if spaceDamage.iDamage ~= DAMAGE_DEATH then
		if itemDamage.iDamage == DAMAGE_DEATH then
			spaceDamage.iDamage = DAMAGE_DEATH
		else
			spaceDamage.iDamage = spaceDamage.iDamage + itemDamage.iDamage
		end
	end
	if itemDamage.iAcid == EFFECT_CREATE then
		spaceDamage.iAcid = EFFECT_CREATE
	end
	if itemDamage.iFire == EFFECT_CREATE then
		spaceDamage.iFire = EFFECT_CREATE
	end
	if itemDamage.iFrozen == EFFECT_CREATE then
		spaceDamage.iFrozen = EFFECT_CREATE
	end
	if itemDamage.iSmoke == EFFECT_CREATE then
		spaceDamage.iSmoke = EFFECT_CREATE
	end
	if itemDamage.iShield == EFFECT_CREATE then
		spaceDamage.iShield = EFFECT_CREATE
	end
end

function WorldBuilders_Consume:AddConsumeDamage(skillEffect, consumeSpace, damage)
	local consumeDamage = SpaceDamage(consumeSpace, damage)
	consumeDamage.iTerrain = TERRAIN_HOLE
	-- Just always remove item. If there is no item this does nothing
	consumeDamage.sScript = consumeDamage.sScript .. [[
				Board:RemoveItem(]] .. consumeDamage.loc:GetString() .. [[)]]
	skillEffect:AddBounce(consumeSpace, self.ConsumeBounce)
	skillEffect:AddDelay(0.2)
	skillEffect:AddDamage(consumeDamage)
	return item, itemDamage
end

function WorldBuilders_Consume:Consume_Building(skillEffect, p1, p2, consumeSpace, dir)
	self:AddConsumeDamage(skillEffect, consumeSpace, DAMAGE_DEATH)

	local chainDamage = 0
	if Board:IsPod(consumeSpace) or Board:IsUniqueBuilding(consumeSpace) then
		chainDamage = DAMAGE_DEATH
	else
		chainDamage = 2 * Board:GetHealth(consumeSpace)
	end

	-- lightning from building to mech
	--skillEffect:AddAnimation(consumeSpace,"Lightning_Hit")

	local spaceInfront = p1 + DIR_VECTORS[dir]

	-- modified from vanilla lightning mech
	local hash = function(point) return point.x + point.y*10 end

	local explored = {[hash(p1)] = true}
	skillEffect:AddAnimation(p1, "Lightning_Attack_" .. dir)
	skillEffect:AddAnimation(p1, "Lightning_Hit")

	while Board:IsValid(spaceInfront) and spaceInfront ~= p2 do
		explored[hash(spaceInfront)] = true
		skillEffect:AddAnimation(spaceInfront, "Lightning_Attack_" .. dir)

		spaceInfront = Point(spaceInfront + DIR_VECTORS[dir])
	end

	local damage = SpaceDamage(spaceInfront, chainDamage)
	local origin = { [hash(spaceInfront)] = p1 }
	local todo = {spaceInfront}

	skillEffect:AddAnimation(p2,"Lightning_Hit")
	skillEffect:AddAnimation(p2, "Lightning_Attack_" .. dir)

	while #todo ~= 0 do
		local current = pop_back(todo)

		if not explored[hash(current)] then
			explored[hash(current)] = true

			if Board:IsPawnSpace(current) or Board:IsBuilding(current) then

				local direction = GetDirection(current - origin[hash(current)])
				damage.sAnimation = "Lightning_Attack_"..direction
				damage.loc = current
				damage.iDamage = Board:IsBuilding(current) and DAMAGE_ZERO or chainDamage
				skillEffect:AddDamage(damage)

				if not Board:IsBuilding(current) then
					skillEffect:AddAnimation(current,"Lightning_Hit")
				end

				for i = DIR_START, DIR_END do
					local neighbor = current + DIR_VECTORS[i]
					if not explored[hash(neighbor)] then
						todo[#todo + 1] = neighbor
						origin[hash(neighbor)] = current
					end
				end
			end
		end
	end
end

function WorldBuilders_Consume:Consume_Terrain(skillEffect, projectileDamage, target, consumeSpace, dir, consumablePawn)
	local consumedTerrain = Board:GetTerrain(consumeSpace)
	if consumedTerrain ~= TERRAIN_HOLE then
		self:AddConsumeDamage(skillEffect, consumeSpace, 0)
	end

	local projImg = "effects/shot_pull"
	ImpactSound = "/impact/rock"

	-- hole is the default effect

	-- Determine effect
	-- "Liquid" effects
	if consumedTerrain == TERRAIN_WATER or consumedTerrain == TERRAIN_ICE or consumedTerrain == TERRAIN_ACID or consumedTerrain == TERRAIN_LAVA then
		local side1Damage = SpaceDamage(target + DIR_VECTORS[(dir + 1) % 4], 0, dir)
		local side2Damage = SpaceDamage(target + DIR_VECTORS[(dir - 1) % 4], 0, dir)

		-- water
		projImg = "effects/shot_firefly"
		ImpactSound = "/impact/water"

		-- water is the default effect
		-- For some reason get terrain seems to always return water. We have the isXXXX check to handle this but
		-- left the terrain check in case something fixes this in the future
		if consumedTerrain == TERRAIN_ICE then
			projectileDamage.iDamage = 1
			side1Damage.iDamage = 1
			side2Damage.iDamage = 1
			projImg = "effects/shot_tankice"
			ImpactSound = "/impact/generic/ice"

		elseif consumedTerrain == TERRAIN_ACID or Board:IsAcid(consumeSpace) then
			projectileDamage.iAcid = EFFECT_CREATE
			side1Damage.iAcid = EFFECT_CREATE
			side2Damage.iAcid = EFFECT_CREATE
			projImg = "effects/shot_firefly2"

		elseif consumedTerrain == TERRAIN_LAVA or Board:IsFire(consumeSpace) or Board:IsTerrain(consumeSpace, TERRAIN_LAVA) then
			projectileDamage.iFire = EFFECT_CREATE
			side1Damage.iFire = EFFECT_CREATE
			side2Damage.iFire = EFFECT_CREATE
			projImg = "effects/shot_fireflyB"
		end

		return projImg, {side1Damage, side2Damage}

	-- "land" effects - also apply fire, acid, smoke
	else
		if consumedTerrain == TERRAIN_ROAD or consumedTerrain == TERRAIN_RUBBLE then
			projectileDamage.iDamage = 1
			projImg = "effects/shot_mechrock"

		elseif consumedTerrain == TERRAIN_SAND then
			projectileDamage.iDamage = 1
			local smokeDamage = SpaceDamage(consumeSpace, 0)
			smokeDamage.iSmoke = EFFECT_CREATE
			skillEffect:AddDamage(smokeDamage)
			projImg = "effects/shot_mechrock"

		elseif consumedTerrain == TERRAIN_MOUNTAIN then
			projectileDamage.iDamage = 3
			projImg = "effects/shot_mechrock"

		elseif consumedTerrain == TERRAIN_FOREST then
			projectileDamage.iDamage = 2
			projImg = "effects/shot_mechrock"
		end

		-- Fire
		if Board:IsFire(consumeSpace) or consumedTerrain == TERRAIN_FIRE then
			projectileDamage.iFire = EFFECT_CREATE
			projImg = "effects/shot_fireflyB"
		end

		-- acid
		if Board:IsAcid(consumeSpace) then
			projectileDamage.iAcid = EFFECT_CREATE
			projImg = "effects/shot_firefly2"
		end

		-- smoke
		if Board:IsSmoke(consumeSpace) or consumedTerrain == TERRAIN_SAND then
			projectileDamage.iSmoke = EFFECT_CREATE
		end

		-- forest fire is a special tile, not a forest and a fire
		if Board:IsForestFire(consumeSpace) then
			projectileDamage.iDamage = 2
			projectileDamage.iFire = EFFECT_CREATE
			projImg = "effects/shot_fireflyB"
		end

		if consumablePawn ~= nil then
			projectileDamage.iDamage = projectileDamage.iDamage + 1
		end
		return projImg
	end
end

function WorldBuilders_Consume:GetSkillEffect(p1, p2)
	local dir = GetDirection(p2 - p1) % 4
	local consumeSpace = p1 + DIR_VECTORS[(dir + 2) % 4]
	return self:GetFinalEffect(p1, p2, consumeSpace)
end

function WorldBuilders_Consume:GetFinalEffect(p1,p2,consumeSpace)
	local ret = SkillEffect()

	ret:AddBoardShake(0.1)
	ret:AddDelay(0.1)

	-- Note that this will be a valid space since we already checked in in get target area
	local dir = GetDirection(p2 - p1) % 4

	-- always at least push the space (except for building consume) - may be modified later
	local projectileDamage = SpaceDamage(p2, 0, dir)

	-- if its a pawn, do special things
	local wasSpecialAnim = false
	local extraDamage = nil
	local pawnMaybe = Board:GetPawn(consumeSpace)
	if Board:IsValid(consumeSpace) then
		if pawnMaybe ~= nil and pawnMaybe:GetType() ~= "Wall" and pawnMaybe:GetType() ~= "RockThrown" then
			ret:AddDamage(SpaceDamage(consumeSpace, 1, dir))
		elseif Board:IsSpawning(consumeSpace) then
			self:Consume_Spawn(ret, p1, consumeSpace, dir)
		elseif Board:GetTerrain(consumeSpace) == TERRAIN_BUILDING or Board:IsPod(consumeSpace) then
			-- remove the push
			projectileDamage.iPush = DIR_NONE
			self:Consume_Building(ret, p1, p2, consumeSpace, dir)
			wasSpecialAnim = true
		else -- terrain
			img, extraDamage = self:Consume_Terrain(ret, projectileDamage, p2, consumeSpace, dir, pawnMaybe)
		end
	end
	-- if its not valid, it will be like a void space

	local item, itemDamage = self:GetConsumedItem(consumeSpace)
	self:AddItemOrItemDamage(projectileDamage, item, itemDamage)

	-- in between spaces
	local spaceInfront = p1 + DIR_VECTORS[dir]
	while spaceInfront ~= p2 and Board:IsValid(spaceInfront) do
		local effectDamage = SpaceDamage(spaceInfront, 0)
		if projectileDamage.iFire == EFFECT_CREATE then
			effectDamage.iFire = EFFECT_CREATE
		end
		if projectileDamage.iAcid == EFFECT_CREATE then
			effectDamage.iAcid = EFFECT_CREATE
		end
		if projectileDamage.iSmoke == EFFECT_CREATE then
			effectDamage.iSmoke = EFFECT_CREATE
		end
		self:AddItemOrItemDamage(effectDamage, item, itemDamage)

		ret:AddBounce(spaceInfront, self.ProjectilePathBounce1)
		ret:AddDamage(effectDamage)
		ret:AddDelay(0.1)
		ret:AddBounce(spaceInfront, self.ProjectilePathBounce2)

		spaceInfront = spaceInfront + DIR_VECTORS[dir]
	end

	ret:AddBounce(p2, self.ProjectileHitBounce)
	if wasSpecialAnim then
		ret:AddDamage(projectileDamage)
	else
		ret:AddProjectile(projectileDamage, img)
	end

	if extraDamage ~= nil then
		for _, damage in ipairs(extraDamage) do
			self:AddItemOrItemDamage(damage, item, itemDamage)
			ret:AddDamage(damage)
			ret:AddBounce(damage.loc, self.ProjectileHitBounce)
		end
	end

	return ret
end
