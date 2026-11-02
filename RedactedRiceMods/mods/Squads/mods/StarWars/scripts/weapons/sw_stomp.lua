StarWars_Stomp = Skill:new{
	Name = "Stomp",
	Description = "2 uses per turn: stomp an adjacent tile for 1 damage, push it, then step into the tile if empty. Grants a free action.",
	Class = "Ranged",
	Damage = 1,
	PowerCost = 1,
	Upgrades = 2,
	UpgradeCost = {2, 1},
	Limited = 2,
	Icon = "weapons/artillery_sw_stomp.png",
	LaunchSound = "/impact/generic/mech",
	ImpactSound = "/impact/generic/explosion",
	TipImage = {
		Unit = Point(2, 2),
		Enemy = Point(2, 1),
		Enemy2 = Point(3, 2),
		Target = Point(2, 2),
	},
}

local mod = mod_loader.mods[modApi.currentMod]

Weapon_Texts.StarWars_Stomp_Upgrade1 = "Spikes"
Weapon_Texts.StarWars_Stomp_A_UpgradeDescription = "+1 damage"
StarWars_Stomp_A = StarWars_Stomp:new{
	Damage = 2,
}

Weapon_Texts.StarWars_Stomp_Upgrade2 = "+ Use"
Weapon_Texts.StarWars_Stomp_B_UpgradeDescription = "3 uses per turn instead of 2"
StarWars_Stomp_B = StarWars_Stomp:new{
	Limited = 3,
}

StarWars_Stomp_AB = StarWars_Stomp_A:new{
	Limited = 3,
}

function StarWars_Stomp:reactivateAfter(pawn)
	if not pawn or pawn:IsDead() then
		return
	end

	-- Set it to active so it can attack again and re-select it for convinence
	pawn:SetActive(true)
	Game:SetSelectedPawn(pawn)

	-- If we have more uses left, set it to the active weapon too so we can easily
	-- chain move + attack
	local weapons = pawn:GetBaseWeaponTypes()
	for wIdx = 1, 2 do
		local weaponId = weapons[wIdx]
		if weaponId and weaponId:find("StarWars_Stomp") then
			if pawn:GetWeaponLimitedRemaining(wIdx) > 0 then
				pawn:SetArmedWeaponId(wIdx)
			end
		end
	end
end

function StarWars_Stomp:GetTargetArea(point)
	local ret = PointList()
	for dir = DIR_START, DIR_END do
		local target = point + DIR_VECTORS[dir]
		if Board:IsValid(target) then
			ret:push_back(target)
		end
	end
	return ret
end

function StarWars_Stomp:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	ret:AddBounce(p1, 3)
	ret:AddDelay(0.2)

	-- Damage and push the target tile
	local dir = GetDirection(p2 - p1)
	if Board:IsValid(p2) then
		local damage = SpaceDamage(p2, self.Damage)
		damage.sAnimation = "airpush_" .. dir
		damage.iPush = dir
		ret:AddDamage(damage)
		ret:AddBounce(p2, -1)
	end

	ret:AddDelay(0.5)


	-- Move into the target if empty
	local refund = SpaceDamage(p2)
	refund.sScript = string.format([[
		local p1 = %s
		local p2 = %s

		local pawn = Board:GetPawn(p1)
		modApi:runLater(function()
			StarWars_Stomp:reactivateAfter(pawn)
		end)

		local effect = SkillEffect()
		local path = PointList()
		path:push_back(p1)
		path:push_back(p2)
		effect:AddMove(path, FULL_DELAY)
		Board:AddEffect(effect)

	]], p1:GetString(), p2:GetString())
	ret:AddDamage(refund)

	return ret
end

-- Restore uses each turn
function StarWars_Stomp:GetPassiveSkillEffect_NextTurnHook(mission)
	for pId = 0, 2 do
		-- Board:GetPawn() is nil here for some reason
		local pawn = Game:GetPawn(pId)
		-- for some reason this is nil sometimes in a mission?
		if pawn then
			LOG("PID "..pId .. ", pawn " .. tostring(pawn:GetType()))
			local weapons = pawn:GetBaseWeaponTypes()
			for wIdx = 1, 2 do
				local weaponId = weapons[wIdx]
				if weaponId and weaponId:find("StarWars_Stomp") then
					LOG("FOUND WEAPOIN ID " .. weaponId .. " for pawn " .. pId)
					pawn:SetWeaponLimitedRemaining(wIdx, pawn:GetWeaponLimitedUses(wIdx))
				end
			end
		else
			LOG("PID "..pId .. ", pawn is nil")
		end
	end
end

-- Register the passive effect
local passiveEffect = mod.libs.passiveEffect
passiveEffect:addPassiveEffect(
	"StarWars_Stomp",
	{
		"nextTurnHook",
	},
	true  -- Not passive only
)