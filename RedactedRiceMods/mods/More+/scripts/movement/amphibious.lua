local customSkill = more_plus.SkillActive:new{
	id = "RrAmphibious",
	name = "Amphibious",
	description = "Mech hovers on liquid tiles",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	modified = {}
}

local function bor(a, b)
    local result = 0
    local bit = 1
    while a > 0 or b > 0 do
        local aa = a % 2
        local bb = b % 2
        if aa == 1 or bb == 1 then
            result = result + bit
        end
        a = (a - aa) / 2
        b = (b - bb) / 2
        bit = bit * 2
    end
    return result
end

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onTargetAreaBuild:subscribe(customSkill.moveTargetArea))
	table.insert(customSkill.events, modapiext.events.onPawnPositionChanged:subscribe(customSkill.addFlyingIfNeeded))
	table.insert(customSkill.events, modapiext.events.onPawnSelected:subscribe(customSkill.addFlyingIfNeeded))
end

function customSkill.moveTargetArea(mission, pawn, weaponId, p1, targetArea)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) and customSkill.modified[pawn:GetId()] then
			while not targetArea:empty() do
				targetArea:erase(0)
			end
			
			local passHoles = false
			local passThroughEnemies = "friendly"
			if pawn:IsTeleporter() or pawn:IsJumper() or pawn:IsBurrower() then 
				passHoles = true
				passThroughEnemies = "none"
			end
			
			-- makeAllTerrainMatcher (.., "any") == pass through any pawns
			-- makeAllTerrainMatcher (.., "friendly") == pass through friendly pawns
			more_plus.libs.boardUtils.getReachableInRange(targetArea, pawn:GetBaseMove(), p1,
					-- Potentially pass over holes and enemies if jumping like movement
					more_plus.libs.boardUtils.makeTerrainBasedMatcher(pawn, passThroughEnemies),
					-- Can't land on holes, unpassable, cant land on any pawn
					more_plus.libs.boardUtils.makeTerrainBasedMatcher(pawn, "any", function(point)
								if not passholes and Board:GetTerrain(point) == TERRAIN_HOLE then
									return true
								end
								if 
								local terrain = Board:GetTerrain(point)
								return (not passHoles and Board:GetTerrain(point) == TERRAIN_HOLE) or
										terrain == TERRAIN_BUILDING or terrain == TERRAIN_MOUNTAIN
							end)
		end
	end
end

function customSkill.applyOnMissionEnter()
	for _, mechInfo in pairs(cplus_plus_ex:getMechsWithSkill(customSkill.id)) do
		local pawn = Board:GetPawn(mechInfo.pawnId)
		local terrain = Board:GetTerrain(pawn:GetSpace())
		if terrain == TERRAIN_WATER or terrain == TERRAIN_LAVA then
			pawn:SetFlying(true)
			customSkill.modified[pawn:GetId()] = true
		end
	end
end

function customSkill.addFlyingIfNeeded(mission, pawn)
	if cplus_plus_ex:isSkillOnPawn(customSkill.id, pawn) then
		local terrain = Board:GetTerrain(pawn:GetSpace())
		if terrain == TERRAIN_WATER or terrain == TERRAIN_LAVA then
			pawn:SetFlying(true)
			customSkill.modified[pawn:GetId()] = true
		elseif customSkill.modified[pawn:GetId()] then
			pawn:SetFlying(false)
			customSkill.modified[pawn:GetId()] = false
		end
	end
end

return customSkill