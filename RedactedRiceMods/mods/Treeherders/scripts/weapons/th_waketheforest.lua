Treeherders_Passive_WakeTheForest = PassiveSkill:new
{
	Name = "Wake the Forest",
	Description = "Mechs on forest tiles take one less damage. Randomly expands forests two tiles at the start of each mission and each turn",
	Icon = "weapons/passives/passive_th_forestArmor.png",
	Rarity = 2,

	PowerCost = 0,
	Damage = 0,

	Upgrades = 2,
	UpgradeCost = {1, 1},

	-- custom options
	ForestArmor = true,
	ForestsToGen = 2,
	Evacuate = false,
	SeekMech = false,

	TipImage = {
		CustomPawn = "Treeherders_ArbiformerMech",
		Unit = Point(2, 1),
		CustomPawn = "Scorpion1",
		Enemy = Point(2, 2),
		Forest = Point(2, 2),
	},
	Debug = false,
}

Treeherders_Passive_WakeTheForest.passiveEffect = mod_loader.mods[modApi.currentMod].libs.passiveEffect

Weapon_Texts.Treeherders_Passive_WakeTheForest_Upgrade1 = "Tree-vacuate"
Treeherders_Passive_WakeTheForest_A = Treeherders_Passive_WakeTheForest:new
{
	UpgradeDescription = "When a mech takes damage on a forest and would be set on fire, it is pushed to a safe adjacent tile (prefs rel. to atk: right, left, same, opposite)",
	TipImage = {
		CustomPawn = "Treeherders_ArbiformerMech",
		Unit = Point(2, 1),
		CustomPawn = "Scorpion2",
		Enemy = Point(2, 2),
		Forest = Point(2, 2),
	},

	Evacuate = true,
}

Weapon_Texts.Treeherders_Passive_WakeTheForest_Upgrade2 = "Seek Mech"
Treeherders_Passive_WakeTheForest_B = Treeherders_Passive_WakeTheForest:new
{
	UpgradeDescription = "When expanding forests, tiles with mechs will be preferred for expansion",
	TipImage = {
		Unit = Point(2, 2),
		CustomPawn = "Treeherders_ArbiformerMech",
		Forest = Point(2, 3),
	},
	SeekMech = true,
}

Treeherders_Passive_WakeTheForest_AB = Treeherders_Passive_WakeTheForest_B:new
{
	Evacuate = true,
}

------------------- UPGRADE PREVIEWS ---------------------------

--only a preview for passive skills
function Treeherders_Passive_WakeTheForest:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	Board:SetTerrainIcon(Point(2, 2), "forestArmor")

	local spaceDamage = SpaceDamage(Point(2, 2), DAMAGE_ZERO)
	spaceDamage.sAnimation = "SwipeClaw2"
	spaceDamage.sSound = "/enemy/scorpion_soldier_1/attack"
	ret:AddMelee(Point(2, 1), spaceDamage)
	return ret
end

--only a preview for passive skills
function Treeherders_Passive_WakeTheForest_A:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	Board:SetTerrainIcon(Point(2, 2), "forestArmor")

	local spaceDamage = SpaceDamage(Point(2, 2), 2, 3)
	spaceDamage.sAnimation = "SwipeClaw2"
	spaceDamage.sSound = "/enemy/scorpion_soldier_2/attack"
	--Still not quite right
	spaceDamage.sScript = [[Board:SetTerrainIcon(Point(2, 2), "")]]
	ret:AddMelee(Point(2, 1), spaceDamage)

	return ret
end

--only a preview for passive skills
function Treeherders_Passive_WakeTheForest_B:GetSkillEffect(p1,p2)
	local ret = SkillEffect()

	forestUtils:floraformSpace(ret, Point(2, 2))
	forestUtils:floraformSpace(ret, Point(1, 3))

	return ret
end

------------------- FLORAFORM SPACES ---------------------------

function Treeherders_Passive_WakeTheForest:FloraformSpaces()

	local randId = "Treeherders_Passive_WakeTheForest"..tostring(Pawn:GetId())

	local effect = SkillEffect()

	local candidates = forestUtils:getSpacesThatBorder(forestUtils.isAForest)

	--floraform and see if we floraformed enough
	local additionalNeeded = self.ForestsToGen - forestUtils.arrayLength(
				forestUtils:floraformNumOfRandomSpaces(effect, randId, candidates, self.ForestsToGen, DAMAGE_ZERO, nil, true, true, true, self.SeekMech))

	--If there are not enough spaces, do some random ones
	if additionalNeeded > 0 then
		--get all floraformable points to use as candidates
		local newCandidates = forestUtils:getSpaces(forestUtils.isSpaceFloraformable)

		local toRemove = {}
		--remove any points that are already forests or forest fires
		for k, v in pairs(newCandidates) do
			if forestUtils.isAForest(v) then
				table.insert(toRemove, k)
			end
		end

		--remove any of them that were in the old list
		for k, _ in pairs(candidates) do
			if newCandidates[k] then
				table.insert(toRemove, k)
			end
		end

		--do it in two loops to ensure the iterator isn't messed up by removing items mid iteration
		for _, v in pairs(toRemove) do
			newCandidates[v] = nil
		end

		--floraform the number left (or how ever many we can)
		forestUtils:floraformNumOfRandomSpaces(effect, randId, newCandidates, additionalNeeded, DAMAGE_ZERO, nil, true, true, true, self.SeekMech)
	end

	--add the effect to the board
	Board:AddEffect(effect)
end

------------------- FOREST ARMOR AND TREEVAC ---------------------------
Treeherders_Passive_WakeTheForest.storedForestArmorIcon = {}

function Treeherders_Passive_WakeTheForest:SetForestArmorIcon(id, point)
	self:UnsetPrevForestArmorIcon(id)

	if self.Evacuate then
		Board:SetTerrainIcon(point, "forestArmor_treevac")
	else
		Board:SetTerrainIcon(point, "forestArmor")
	end

	self.storedForestArmorIcon[id] = point
end

function Treeherders_Passive_WakeTheForest:UnsetPrevForestArmorIcon(id)
	if self.storedForestArmorIcon[id] then
		Board:SetTerrainIcon(self.storedForestArmorIcon[id], "")
		self.storedForestArmorIcon[id] = nil;
	end
end

function Treeherders_Passive_WakeTheForest:UpdateForestArmorForMechAtSpace(id, point)
	if forestUtils.isAForest(point) then
		self:SetForestArmorIcon(id, point)
	else
		self:UnsetPrevForestArmorIcon(id)
	end
end

function Treeherders_Passive_WakeTheForest.EligibleForForestArmor(pawn)
	if pawn:IsMech() and not pawn:IsDead() then
		return true
	end
	return false
end

function Treeherders_Passive_WakeTheForest:RefreshForestArmorIconToAllMechs()
	local mechs = Board:GetPawns(TEAM_MECH)
	for _, mechId in pairs(extract_table(mechs)) do
		local space = Board:GetPawnSpace(mechId)
		self:UpdateForestArmorForMechAtSpace(mechId, space)
	end
end

function Treeherders_Passive_WakeTheForest:ApplyForestArmorToSpaceDamage(spaceDamage)
	if self.ForestArmor then
		if spaceDamage.iDamage ~= DAMAGE_ZERO and spaceDamage.iDamage ~= DAMAGE_DEATH then
			if spaceDamage.iDamage ~= 1 then
				spaceDamage.iDamage = spaceDamage.iDamage - 1
			else
				spaceDamage.iDamage = DAMAGE_ZERO
			end
		end
	end
end

function Treeherders_Passive_WakeTheForest:ApplyEvacuateToSpaceDamage(spaceDamage, damagedPawn, attackOrigin, pToIgnore)
	--If the pawn is not on fire and on a forest and is taking damage
	if self.Evacuate and spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_ZERO and spaceDamage.iDamage ~= DAMAGE_DEATH and
					not (damagedPawn:IsShield() or damagedPawn:IsFire() or forestUtils.isAForestFire(spaceDamage.loc)) then
		local attackDir = GetDirection(spaceDamage.loc - attackOrigin)
		local dirPreferences = { (attackDir - 1) % 4, (attackDir + 1) % 4, attackDir, (attackDir + 2) % 4 }
		for _, dir in pairs(dirPreferences) do

			--if we already found a spot then don't check
			if (not spaceDamage.iPush) or spaceDamage.iPush >= 4 then

				local p = spaceDamage.loc + DIR_VECTORS[dir]
				local terrain = Board:GetTerrain(p)
				local pointHash = forestUtils:getSpaceHash(p)

				--only push to it if we are not already pushing someone there
				if not pToIgnore[pointHash] then
					--If its a non blocking and non harmful terrain
					if terrain ~= TERRAIN_MOUNTAIN and terrain ~= TERRAIN_BUILDING and terrain ~= TERRAIN_ACID and terrain ~= TERRAIN_LAVA then
						--If its non harmful based on the units attributes
						if (terrain ~= TERRAIN_EMPTY or damagedPawn:IsFlying()) and (terrain ~= TERRAIN_WATER or damagedPawn.Massive) then
							--If its unocupied and not in danger
							if not (Board:IsPawnSpace(p) or Board:IsFire(p) or Board:IsAcid(p) or Board:IsSpawning(p) or Board:IsDangerous(p) or Board:IsEnvironmentDanger(p)) then
								--we found a good spot to push the pawn to
								spaceDamage.iPush = dir
								return p + DIR_VECTORS[dir]
							end
						end
					end
				end
			end
		end
	end
end

function Treeherders_Passive_WakeTheForest:ApplyForestArmorAndEvacuate(effect, attackOrigin)
	if (self.ForestArmor or self.Evacuate) and not effect:empty() then

		local evacuatedToOrAttackedSpaces = {}

		--determine what spaces are being attacked
		for _, spaceDamage in pairs(extract_table(effect)) do
			evacuatedToOrAttackedSpaces[forestUtils:getSpaceHash(spaceDamage.loc)] = spaceDamage.loc
		end

		for _, spaceDamage in pairs(extract_table(effect)) do
			local damagedPawn = Board:GetPawn(spaceDamage.loc)
			if damagedPawn and forestUtils.isAForest(spaceDamage.loc) and
						spaceDamage.iDamage > 0 and self.EligibleForForestArmor(damagedPawn) then

				self:ApplyForestArmorToSpaceDamage(spaceDamage)

				local p = self:ApplyEvacuateToSpaceDamage(spaceDamage, damagedPawn,
								attackOrigin, evacuatedToOrAttackedSpaces)
				if p then
					evacuatedToOrAttackedSpaces[forestUtils:getSpaceHash(p)] = p
				end
			end
		end
	end
end

------------------- MAIN HOOK FUNCTIONS ---------------------------

-- function to handle the postEnvironment hook functionality
-- When post environment is called, it appears the board isn't updated at that point
-- It doesn't recognize that tiles became water in the flood event. next turn hook can
-- be used but it happens after vek attack so it defeats the point of the seek mech
-- ability
function Treeherders_Passive_WakeTheForest:GetPassiveSkillEffect_PreEnvironmentHook(mission)	
	--floraform the spaces
	self:FloraformSpaces()
end

function Treeherders_Passive_WakeTheForest:GetPassiveSkillEffect_MissionStartHook(mission)
	--Fire on mission start as well
	self:FloraformSpaces()
end

-- Skill build hooks
function Treeherders_Passive_WakeTheForest:SkillBuildHook(weaponId, p1, p2, skillFx)
	-- Sometimes the skill is nil? Not sure why
	if weaponId ~= "Move" and skillFx ~= nil then
		-- Just try both. AFAIK it will only be one but it doesn't hurt and we guarantee 
		-- covering all cases
		self:ApplyForestArmorAndEvacuate(skillFx.effect, p1)
		self:ApplyForestArmorAndEvacuate(skillFx.q_effect, p1)
	end
	self:RefreshForestArmorIconToAllMechs()
end

function Treeherders_Passive_WakeTheForest:GetPassiveSkillEffect_SkillBuildHook(mission, pawn, weaponId, p1, p2, skillFx)
	return self:SkillBuildHook(weaponId, p1, p2, skillFx)
end

function Treeherders_Passive_WakeTheForest:GetPassiveSkillEffect_FinalEffectBuildHook(mission, pawn, weaponId, p1, p2, p3, skillEffect)
	return self:SkillBuildHook(weaponId, p1, p2, skillFx)
end


Treeherders_Passive_WakeTheForest.passiveEffect:addPassiveEffect("Treeherders_Passive_WakeTheForest",
		{"skillBuildHook",  "finalEffectBuildHook", "preEnvironmentHook", "missionStartHook"})
