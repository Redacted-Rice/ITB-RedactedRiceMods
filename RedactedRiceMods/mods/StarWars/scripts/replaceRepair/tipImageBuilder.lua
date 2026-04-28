
local path = GetParentPath(...)
local selected = require(path.."lib/selected")
local getSelectedPawn = selected.getSelectedPawn

local tipImageBuilder = {}

local function AddPawn(loc, pawnType, damaged)
	if not Board:IsPawnSpace(loc) then
		local pawn = PAWN_FACTORY:CreatePawn(pawnType)
		Board:AddPawn(pawn, loc)
		if damaged then
			Board:DamageSpace(SpaceDamage(loc, pawn:GetHealth() - 1))
		end
	end
end

local function AddEffect(loc, effect)
	local d = SpaceDamage(loc)
	d[effect] = EFFECT_CREATE
	Board:DamageSpace(d)
end

-- clears the board.
function tipImageBuilder:clear()
	local size = Board:GetSize()
	for x = 0, size.x - 1 do
		for y = 0, size.y - 1 do
			local p = Point(x, y)
			Board:ClearSpace(p)
		end
	end
end

-- setups the board according to a skill's TipImage.
function tipImageBuilder:setup(skill)
	if _G[skill].CustomTipImage ~= "" then
		skill = _G[skill].CustomTipImage
	end
	
	-- do not attempt to build an incomplete TipImage.
	if self:verify(skill).incomplete then return end
	
	local t = _G[skill].TipImage
	local selected = getSelectedPawn() or Game:GetPawn(0)
	local pawnType = t.CustomPawn or selected:GetType()
	local pawn = PAWN_FACTORY:CreatePawn(pawnType)
	Board:AddPawn(pawn, t.Unit or t.Unit_Damaged)
	
	if t.Unit_Damaged then
		Board:DamageSpace(SpaceDamage(pawn:GetSpace(), pawn:GetHealth() - 1))
	end
	
	local mechId = selected:GetId()
	local enemy = t.CustomEnemy or "Scorpion2"
	for k, loc in pairs(t) do
		mechId = (mechId + 1) % 3
		local mech = Game:GetPawn(mechId)
		mech = mech and mech:GetType() or "PunchMech"
		mech = t.CustomFriendly or mech
		
		if k:sub(1,5) == "Enemy" then
			AddPawn(loc, enemy, k:sub(-7,-1) == "Damaged")
		elseif k:sub(1,8) == "Friendly" then
			AddPawn(loc, mech, k:sub(-7,-1) == "Damaged")
		elseif k:sub(1,8) == "Building" then
			Board:SetTerrain(loc, 1)
		elseif k:sub(1,6) == "Rubble" then
			Board:SetTerrain(loc, 2)
		elseif k:sub(1,5) == "Water" then
			Board:SetTerrain(loc, 3)
		elseif k:sub(1,8) == "Mountain" then
			Board:SetTerrain(loc, 4)
		elseif k:sub(1,3) == "Ice" then
			Board:SetTerrain(loc, 5)
		elseif k:sub(1,6) == "Forest" then
			Board:SetTerrain(loc, 6)
		elseif k:sub(1,4) == "Sand" then
			Board:SetTerrain(loc, 7)
		elseif k:sub(1,4) == "Hole" then
			Board:SetTerrain(loc, 9)
		elseif k:sub(1,4) == "Lava" then
			Board:SetTerrain(loc, 14)
		elseif k:sub(1,4) == "Fire" then
			AddEffect(loc, "iFire")
		elseif k:sub(1,5) == "Smoke" then
			AddEffect(loc, "iSmoke")
		elseif k:sub(1,4) == "Acid" then
			AddEffect(loc, "iAcid")
		elseif k:sub(1,5) == "Spawn" then
			Board:SpawnPawn(enemy, loc)
		end
	end
end

function tipImageBuilder:verify(skill)
	local ret = {}
	local Skill = _G[skill]
	
	if Skill and Skill.TipImage then
		ret.unit = Skill.TipImage.Unit or Skill.TipImage.Unit_Damaged
		ret.target = Skill.TipImage.Target
	else
		ret.incomplete = true
	end
	
	if not ret.unit or not ret.target then
		ret.incomplete = true
	end
	
	return ret
end

return tipImageBuilder
