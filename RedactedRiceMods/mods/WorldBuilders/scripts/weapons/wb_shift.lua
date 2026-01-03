WorldBuilders_Shift = Skill:new{
	Name = "Shift",
	Description = "Swap solid terrain, effects, and items of two tiles. Does not swap unique buildings, holes, liquid, pawns, or time pods",
	Class = "Science",
	Icon = "weapons/science_wb_shift.png",
	Rarity = 1,
	
	Damage = 1,
	PowerCost = 1,
	LaunchSound = "/weapons/swap",
	Explosion = "",
	Upgrades = 2,
	UpgradeCost = { 1, 2 },

	Range = 2,
	-- Start with project
	TwoClick = true,
	TargetDeathTiles = false,
	TargetUniques = false,

	--TipImage
    TipImage = {
		Unit = Point(2,3),
		Building = Point(2,2),
		Target = Point(2,2),
		Forest = Point(3,3),
		Enemy = Point(3,3),
		Second_Click = Point(3,3),
	},
}

WorldBuilders_Shift.weaponPreview = mod_loader.mods[modApi.currentMod].libs.weaponPreview

Weapon_Texts.WorldBuilders_Shift_Upgrade1 = "+ Range"
WorldBuilders_Shift_A = WorldBuilders_Shift:new
{
	UpgradeDescription = "Increase range by 1",
	Range = 3,
}

Weapon_Texts.WorldBuilders_Shift_Upgrade2 = "Deadly"
WorldBuilders_Shift_B = WorldBuilders_Shift:new
{
	UpgradeDescription = "Can swap liquid and holes tiles",
	TargetDeathTiles = true,
    TipImage = {
		Unit = Point(2,3),
		Building = Point(2,2),
		Target = Point(2,2),
		Hole = Point(3,3),
		Second_Click = Point(3,3),
	},
}

WorldBuilders_Shift_AB = WorldBuilders_Shift_B:new
{
	Range = 3,
}

--Is lava doesn't seem to work right
function WorldBuilders_Shift:GetTerrainOrLava(space)
	local terrain = Board:GetTerrain(space)
	-- Lava tiles are handled oddly. They at least often are water terrain
	if terrain == TERRAIN_WATER and (Board:IsFire(space) or Board:IsTerrain(space, TERRAIN_LAVA)) then
		terrain = TERRAIN_LAVA
	end
	return terrain
end

function WorldBuilders_Shift:CanSpaceBeOccupied(point)
	return Board:GetTerrain(point) ~= TERRAIN_BUILDING and Board:GetTerrain(point) ~= TERRAIN_MOUNTAIN
end

function WorldBuilders_Shift:IsOpenForPawn(space)
	return self:CanSpaceBeOccupied(space) and not Board:IsPawnSpace(space)
end

function WorldBuilders_Shift:IsUnshiftableCustomTile(p)
	local customTile = Board:GetCustomTile(p)
	--LOG("Custom terrain: ".. customTile)
	return customTile ~= "" and customTile ~= "snow.png" and customTile ~= "ground_grass.png"
end

function WorldBuilders_Shift:IsInvalidTargetSpace(p)
	-- don't allow swapping custom tiles or buildings
	-- Also just don't swap immovable pawns for simplicity
	return self:IsUnshiftableCustomTile(p) or
		(Board:IsPawnSpace(p) and Board:GetPawn(p):IsGuarding()) or
		(not self.TargetUniques and Board:GetUniqueBuilding(p) ~= "") or
		(not self.TargetDeathTiles and (Board:GetTerrain(p) == TERRAIN_WATER or Board:GetTerrain(p) == TERRAIN_HOLE))
end

function WorldBuilders_Shift:GetTargetArea(center)
	local ret = PointList()

	-- "borrowed" from general_DiamondTarget and modified to not
	-- include point
	local size = self.Range
	local corner = center - Point(size, size)

	local p = Point(corner)

	for i = 0, ((size*2+1)*(size*2+1)) do
		local diff = center - p
		local dist = math.abs(diff.x) + math.abs(diff.y)
		-- If the space is not an invalid target (multispace, non pushable pawn)
		if Board:IsValid(p) and dist <= size and not self:IsInvalidTargetSpace(p) then
			ret:push_back(p)
		end
		p = p + VEC_RIGHT
		if math.abs(p.x - corner.x) == (size*2+1) then
			p.x = p.x - (size*2+1)
			p = p + VEC_DOWN
		end
	end

	return ret
end

function WorldBuilders_Shift:GetSecondTargetArea(center, target1)
	local ret = PointList()

	-- "borrowed" from general_DiamondTarget and modified to not
	-- include point
	local size = self.Range
	local corner = center - Point(size, size)

	local target2 = Point(corner)

	for i = 0, ((size*2+1)*(size*2+1)) do
		local diff = center - target2
		local dist = math.abs(diff.x) + math.abs(diff.y)
		-- If the space is not an invalid target (multispace, non pushable pawn)
		if Board:IsValid(target2) and dist <= size and target2 ~= target1 and not self:IsInvalidTargetSpace(target2) then
			local goodTarget = true
			-- if the space we are swapping in can't be occupied
			if not self:CanSpaceBeOccupied(target2) then
				-- if its a pod or item, don't allow it -- too much work to swap pods as its mostly hardcoded in the game and I don't want to deal with memedit and no way to unset and item
				if Board:IsPawnSpace(target1) and self:GetPushDirToOpenSpace(target1, target2) == DIR_NONE then
					goodTarget = false
				end
			end
			if not self:CanSpaceBeOccupied(target1) then
				-- if its a pod or item, don't allow it -- too much work to swap pods as its mostly hardcoded in the game and I don't want to deal with memedit and no way to unset and item
				if Board:IsPawnSpace(target2) and self:GetPushDirToOpenSpace(target2, target1) == DIR_NONE then
					goodTarget = false
				end
			end

			if goodTarget then
				ret:push_back(target2)
			end
		end

		target2 = target2 + VEC_RIGHT
		if math.abs(target2.x - corner.x) == (size*2+1) then
			target2.x = target2.x - (size*2+1)
			target2 = target2 + VEC_DOWN
		end
	end

	return ret
end

function WorldBuilders_Shift:PushIfUnoccupiableSpace(p1, p2, terrainDamage, pushDamage)
	if Board:IsPawnSpace(p1) and not self:CanSpaceBeOccupied(p2) then
		local pushDir = self:GetPushDirToOpenSpace(p1, p2)
		-- for some reason trying to apply a building too causes it
		-- to not push so we add it twice. Also hide the push so it
		-- won't show us colliding in the preview
		pushDamage.iPush = pushDir
		pushDamage.bHide = true

		if pushDir == DIR_LEFT then
			terrainDamage.sImageMark = "combat/arrow_left.png"
		elseif pushDir == DIR_UP then
			terrainDamage.sImageMark = "combat/arrow_up.png"
		elseif pushDir == DIR_RIGHT then
			terrainDamage.sImageMark = "combat/arrow_right.png"
		else -- down
			terrainDamage.sImageMark = "combat/arrow_down.png"
		end
	end
end

function WorldBuilders_Shift:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	self.weaponPreview:AddImage(p2, "combat/tile_icon/tile_wb_shift.png", GL_Color(255,226,88,0.75))
	ret:AddDamage(SpaceDamage(p2, 0))
	return ret
end

function WorldBuilders_Shift:GetFinalEffect(p1,p2,p3)
	local ret = SkillEffect()

	self.weaponPreview:AddImage(p2, "combat/tile_icon/tile_wb_shift.png", GL_Color(255,226,88,0.75))
	self.weaponPreview:AddImage(p3, "combat/tile_icon/tile_wb_shift.png", GL_Color(255,226,88,0.75))

	local p2Data = self:GetTerrainAndEffectData(p2)
	local p3Data = self:GetTerrainAndEffectData(p3)

	local p2TerrainPre = SpaceDamage(p2, 0)
	local p2Damage = SpaceDamage(p2, 0)
	local p2Push = SpaceDamage(p2, 0)
	self:ApplyEffect(p2Damage, p3Data, p2Data)
	self:ApplyTerrain(p2Damage, p2TerrainPre, p3Data, p2Data, true)
	self:PushIfUnoccupiableSpace(p2, p3, p2Damage, p2Push)

	local p3TerrainPre = SpaceDamage(p3, 0)
	local p3Damage = SpaceDamage(p3, 0)
	local p3Push = SpaceDamage(p3, 0)
	self:ApplyEffect(p3Damage, p2Data, p3Data)
	self:ApplyTerrain(p3Damage, p3TerrainPre, p2Data, p3Data, false)
	self:PushIfUnoccupiableSpace(p3, p2, p3Damage, p3Push)

	-- todo add space symbol and/or animation
	ret:AddDamage(p2Push)
	ret:AddBounce(p2, -5)
	ret:AddDamage(p3Push)
	ret:AddBounce(p3, -5)

	ret:AddDamage(p2TerrainPre)
	ret:AddDamage(p3TerrainPre)
	ret:AddDamage(p2Push)
	ret:AddDamage(p3Push)
	ret:AddDamage(p2Damage)
	ret:AddDamage(p3Damage)

	return ret
end

function WorldBuilders_Shift:GetTerrainAndEffectData(space)
	return {
		origSpace = space,
		terrain = self:GetTerrainOrLava(space),
		customTile = Board:GetCustomTile(space),
		item = Board:GetItem(space),
		populated = Board:IsPowered(space),
		shielded = Board:IsShield(space),
		cracked = Board:IsCracked(space),
		currHealth = Board:GetHealth(space),
		maxHealth = Board:GetMaxHealth(space),
		fireType = Board:GetFireType(space),
		frozen = Board:IsFrozen(space),
		acid = Board:IsAcid(space),
		smoke = Board:IsSmoke(space),
		emerging = Board:IsSpawning(space),
		people1 = Board:GetPeoplePopulated(space),
		unique = Board:GetUniqueBuilding(space),
	}
end

function WorldBuilders_Shift:ApplyEffect(spaceDamage, spaceData, oldSpaceData)
-- handled by setFireType now
--[[	if spaceData.fireType == FIRE_TYPE_NORMAL_FIRE then
		spaceDamage.iFire = EFFECT_CREATE
	elseif oldSpaceData.fireType ~= FIRE_TYPE_NONE then
		spaceDamage.iFire = EFFECT_REMOVE
	end]]--

	if spaceData.acid then
		spaceDamage.iAcid = EFFECT_CREATE
	elseif oldSpaceData.acid then
		spaceDamage.iAcid = EFFECT_REMOVE
	end

	if spaceData.smoke then
		spaceDamage.iSmoke = EFFECT_CREATE
	elseif oldSpaceData.smoke then
		spaceDamage.iSmoke = EFFECT_REMOVE
	end
end

-- If swapping a building in, the tile terrain doesn't always update rigth. For example, if
-- its a water tile, it will remain visually a water tile until its swapped with land
-- despite being ocnsidered a road tile. To get around we do a pre damage to change it
-- to road and then do the normal changes
function WorldBuilders_Shift:ApplyTerrain(spaceDamage, spaceDamagePreform, spaceData, oldSpaceData, isFirst)
	-- Buildings will literally crash if we set to iTerrain and a pawn is on
	-- it so we have to do it via script instead.
	-- We also have oddities with setting terrain so we just do it via post script.
	-- for whatever reason this works better

	spaceDamagePreform.sScript = ""
	-- Destroy the pod if the terrain is a no go. Simply switching to mountains does not
	-- destroy the pod and when testing various terrains, water works well for this
	if (Board:IsPod(spaceDamage.loc) or Board:IsItem(spaceDamage.loc)) and not self:CanSpaceBeOccupied(spaceData.origSpace) then
		spaceDamagePreform.iTerrain = TERRAIN_WATER
	-- If it was a building, change it to a road first and clear the building info
	elseif oldSpaceData.terrain == TERRAIN_BUILDING then
		spaceDamagePreform.sScript = [[
				Board:UnsetScoredBuilding(]] .. spaceDamagePreform.loc:GetString() .. [[, ]].. TERRAIN_ROAD ..[[)]]
		if oldSpaceData.unique ~= nil then
			spaceDamagePreform.sScript = [[
					Board:SetUniqueBuilding(]] .. spaceDamagePreform.loc:GetString() .. [[, "")]]
		end
		spaceDamagePreform.iTerrain = TERRAIN_ROAD
	end

	-- If it was lava or acid or frozen we need to unset it or else it visually is different
	if oldSpaceData.terrain == TERRAIN_LAVA and spaceData.terrain ~= TERRAIN_LAVA then
		spaceDamagePreform.sScript = spaceDamage.sScript .. [[
				Board:SetLava(]] .. spaceDamage.loc:GetString() .. [[, false)]]
	end

	if oldSpaceData.acid and not spaceData.acid then
		spaceDamage.sScript = spaceDamage.sScript .. [[
				Board:SetAcid(]] .. spaceDamage.loc:GetString() .. [[,false)]]
	end

	-- Unset frozen first
	if not spaceData.frozen then
		spaceDamage.sScript = spaceDamage.sScript .. [[
				Board:SetFrozen(]] .. spaceDamage.loc:GetString() .. [[,false,no_animation)]]
	end

	-- Set the terrain to the new terrain
	spaceDamage.sScript = spaceDamage.sScript .. [[
			Board:SetTerrain(]] .. spaceDamage.loc:GetString() .. [[,]] .. spaceData.terrain .. [[)]]

	-- And set frozen after
	if spaceData.frozen then
					-- if the space was already frozen, unfreeze it to break any ice
 	if oldSpaceData.frozen then
		  spaceDamage.sScript = spaceDamage.sScript .. [[
 				Board:SetFrozen(]] .. spaceDamage.loc:GetString() .. [[,false,no_animation)]]
	 end
		spaceDamage.sScript = spaceDamage.sScript .. [[
				Board:SetFrozen(]] .. spaceDamage.loc:GetString() .. [[,true,no_animation)]]
	end

	-- Set fire type
	spaceDamage.sScript = spaceDamage.sScript .. [[
			Board:SetFireType(]] .. spaceDamage.loc:GetString() .. [[,]] .. spaceData.fireType .. [[)]]

	spaceDamage.sScript = spaceDamage.sScript .. [[
			Board:SetHealth(]] .. spaceDamage.loc:GetString() .. [[,]] .. spaceData.currHealth .. [[,]] .. spaceData.maxHealth .. [[)]]

	-- Handle all the building cases
	if spaceData.terrain == TERRAIN_BUILDING then
		if spaceData.populated then
			-- Have to set the populated and the poeple1 for scoring to work
			spaceDamage.sScript = spaceDamage.sScript .. [[
					Board:SetPopulated(true]] .. [[,]] .. spaceDamage.loc:GetString() .. [[)]]
		end
		if spaceData.unique ~= nil then
		spaceDamage.sScript = spaceDamage.sScript .. [[
				Board:SetUniqueBuilding(]] .. spaceDamage.loc:GetString() .. [[, "]] .. spaceData.unique .. [[")
				Board:SetPeoplePopulated(]] .. spaceDamage.loc:GetString() .. [[, ]] .. spaceData.people1 .. [[)]]
		end

	end

	-- If it should be shielded but isn't already
	if spaceData.shielded and not Board:IsShield(spaceDamage.loc) and not (Board:GetPawn(spaceDamage.loc) and Board:GetPawn(spaceDamage.loc):IsShield()) then
		spaceDamage.sScript = spaceDamage.sScript .. [[
				Board:SetShield(]] .. spaceDamage.loc:GetString() .. [[, true)]]
	-- if it should not be shielded and it is
	elseif not spaceData.shielded and (Board:IsShield(spaceDamage.loc) or (Board:GetPawn(spaceDamage.loc) and Board:GetPawn(spaceDamage.loc):IsShield())) then
		spaceDamage.sScript = spaceDamage.sScript .. [[
				Board:SetShield(]] .. spaceDamage.loc:GetString() .. [[, false)]]
	end

	if spaceData.cracked then
		spaceDamage.iCrack = EFFECT_CREATE
	elseif Board:IsCracked(spaceDamage.loc) and spaceData.terrain ~= TERRAIN_BUILDING then
		-- with testing, water seems to be the magic one that makes it work...
		spaceDamagePreform.iTerrain = TERRAIN_WATER
	end

	if spaceData.item == "" then
		spaceDamage.sScript = spaceDamage.sScript .. [[
				Board:RemoveItem(]] .. spaceDamage.loc:GetString() .. [[)]]
	else
		spaceDamage.sScript = spaceDamage.sScript .. [[
				Board:SetItem(]] .. spaceDamage.loc:GetString() .. [[,"]] .. spaceData.item .. [[")]]
	end

	-- handle swappable custom tiles (e.g. grass tiles on the final level)
	spaceDamage.sScript = spaceDamage.sScript .. [[
				Board:SetCustomTile(]] .. spaceDamage.loc:GetString() .. [[,"]].. spaceData.customTile .. [[")]]

	-- trying to swap pawns had all sorts of issues. Realistically it doesn't matter anyways as the player
	-- would have no way of knowing if this was done or not
	--LOG("script: "..spaceDamage.sScript)
end

-- For some reason when swapping buildings the push doesn't
-- go through on execution despite showing so we use a separate
-- push to get around this that should be applied before the
-- actual space damage
function WorldBuilders_Shift:GetPushDirToOpenSpace(p1, p2)
	local baseDir = GetDirection(p1 - p2)
	local dirs = {baseDir, (baseDir + 2) % 4, (baseDir + 1) % 4, (baseDir - 1) % 4}

	for _, dir in pairs(dirs) do
		local pushSpace = Point(p1 + DIR_VECTORS[dir])
		-- if its a valid space and either is open for the pawn or its the other space and that space
		-- can be occupied
		if Board:IsValid(pushSpace) and (self:IsOpenForPawn(pushSpace) or (pushSpace == p2 and self:CanSpaceBeOccupied(p1))) then
			return dir
		end
	end

	return DIR_NONE
end