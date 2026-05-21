local MOVE_BONUS = 2
StarWars_TIEEngineOverdrive = PassiveSkill:new{
	Name = "TIE Overdrive",
	Description = "Increased move by "..MOVE_BONUS.." for the rest of the mission.",
	Class = "Ranged",
	PowerCost = 0,
	Upgrades = 2,
	UpgradeCost = {1, 1},
	Limited = 1,
	Icon = "weapons/ranged_sw_tie_engine.png",
	WebImmune = false,
	BonusMoveAfterAttack = false,
	TipImage = {
		CustomPawn = "StarWars_TIEFighterMech",
		Unit = Point(2, 2),
		Target = Point(2, 2),
	},
}

local mod = mod_loader.mods[modApi.currentMod]

Weapon_Texts.StarWars_TIEEngineOverdrive_Upgrade1 = "Evasive"
Weapon_Texts.StarWars_TIEEngineOverdrive_A_UpgradeDescription = "Mech also becomes web immune"
StarWars_TIEEngineOverdrive_A = StarWars_TIEEngineOverdrive:new{
	WebImmune = true,
}

Weapon_Texts.StarWars_TIEEngineOverdrive_Upgrade2 = "Combat Maneuvers"
Weapon_Texts.StarWars_TIEEngineOverdrive_B_UpgradeDescription = "Mech also gains a " .. MOVE_BONUS .. " range bonus move after each attack"
StarWars_TIEEngineOverdrive_B = StarWars_TIEEngineOverdrive:new{
	BonusMoveAfterAttack = true,
}

StarWars_TIEEngineOverdrive_AB = StarWars_TIEEngineOverdrive_A:new{
	BonusMoveAfterAttack = true,
}

-- TODO: Add icons via trait replace (Maybe flying one this time?)

-- Initialize GAME save data structure
local function initGameSaveData()
	if GAME == nil then
		GAME = {}
	end
	if GAME.starwars == nil then
		GAME.starwars = {}
	end
	if GAME.starwars.tie_overdrive == nil then
		GAME.starwars.tie_overdrive = {}
	end
	if GAME.starwars.tie_overdrive.active_pawns == nil then
		GAME.starwars.tie_overdrive.active_pawns = {}
	end
	if GAME.starwars.tie_overdrive.web_immune_applied == nil then
		GAME.starwars.tie_overdrive.web_immune_applied = {}
	end
end

function StarWars_TIEEngineOverdrive:GetTargetArea(point)
	local ret = PointList()
	ret:push_back(point)
	return ret
end

function StarWars_TIEEngineOverdrive:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	local damage = SpaceDamage(p1, 0)
	damage.sScript = [[
		local pawn = Board:GetPawn(]] .. p1:GetString() .. [[)
		if pawn then
			local pawnId = pawn:GetId()

			-- Initialize save data
			if GAME.starwars == nil then GAME.starwars = {} end
			if GAME.starwars.tie_overdrive == nil then GAME.starwars.tie_overdrive = {} end
			if GAME.starwars.tie_overdrive.active_pawns == nil then GAME.starwars.tie_overdrive.active_pawns = {} end
		]]
	if self.WebImmune then
		damage.sScript = damage.sScript .. [[
			GAME.starwars.tie_overdrive.web_immune_applied[pawnId] = true

			local space = pawn:GetSpace()
            pawn:SetSpace(Point(-1,-1))
            modApi:runLater(function()
                pawn:SetSpace(space)
            end)
		]]
	end
	damage.sScript = damage.sScript .. [[
			-- Mark this pawn as having overdrive active
			GAME.starwars.tie_overdrive.active_pawns[pawnId] = true
			Board:AddAlert(pawn:GetSpace(), "OVERDRIVE")
			Board:Ping(pawn:GetSpace(), GL_Color(0, 0, 255))
			LOG("SET PAWN " .. pawnId .. " TO OVERDRIVE")
		end
	]]
	ret:AddDamage(damage)
	return ret
end



-- Bonus move after attack if upgraded
function StarWars_TIEEngineOverdrive:maybeApplyExtraBonuses(pawn, weaponId)
	if not pawn then return end
	if not Game or not Board or Board:IsTipImage() then return end
	if not self.BonusMoveAfterAttack then return end
	if weaponId == "Move" then return end

	initGameSaveData()

	-- Check if this pawn has overdrive active and the upgrade
	local pawnId = pawn:GetId()
	if GAME.starwars.tie_overdrive.active_pawns[pawnId] then
		-- Grant bonus move
		pawn:SetBonusMove(MOVE_BONUS)
		modApi:runLater(function()
			pawn:SetActive(true)
		end)
		Board:AddAlert(pawn:GetSpace(), "OVERDRIVE")
		Board:Ping(pawn:GetSpace(), GL_Color(0, 0, 255))
	end
end

function StarWars_TIEEngineOverdrive:maybeApplyBaseSpeedBoosts()
	if not Game or not Board or Board:IsTipImage() then return end

	initGameSaveData()

	-- Apply base speed boost
	for pawnId = 0, 2 do
		if GAME.starwars.tie_overdrive.active_pawns[pawnId] then
			local pawn = Board:GetPawn(pawnId)
			pawn:AddMoveBonus(MOVE_BONUS)
			Board:AddAlert(pawn:GetSpace(), "OVERDRIVE")
			Board:Ping(pawn:GetSpace(), GL_Color(0, 0, 255))
		end
	end
end

function StarWars_TIEEngineOverdrive:GetPassiveSkillEffect_SkillEndHook(mission, pawn, weaponId)
	self:maybeApplyExtraBonuses(pawn, weaponId)
end

function StarWars_TIEEngineOverdrive:GetPassiveSkillEffect_FinalEffectEndHook(mission, pawn, weaponId)
	self:maybeApplyExtraBonuses(pawn, weaponId)
end

function StarWars_TIEEngineOverdrive:GetPassiveSkillEffect_NextTurnHook(mission)
	if Game:GetTeamTurn() == TEAM_PLAYER then
		self:maybeApplyBaseSpeedBoosts()
	end
end

function StarWars_TIEEngineOverdrive:GetPassiveSkillEffect_OnPawnIsGrappled(mission, pawn, isGrappled)
	if not Game or not Board or Board:IsTipImage() then return end
	initGameSaveData()
	if isGrappled and GAME.starwars.tie_overdrive.web_immune_applied[pawn:GetId()] then
		-- Thanks Generic for this
		--If removing the web right away it looks really weird. So we'll wait about half a second with this
		modApi:scheduleHook(550,function()
            local space = pawn:GetSpace() --Store the space so we can move it back later
            --It's entirely optional, remove it if you don't like it
            pawn:SetSpace(Point(-1,-1)) --Move the pawn to Point(-1,-1)
            modApi:runLater(function() --This runs a function one frame later so things get updated
                pawn:SetSpace(space) --Move the pawn back, after that one frame. The web will be gone
				Board:AddAlert(space, "OVERDRIVE") 
				Board:Ping(space, GL_Color(0, 0, 255))
            end)
        end)
	end
end

function StarWars_TIEEngineOverdrive:GetPassiveSkillEffect_MissionStartHook(mission)
	GAME.starwars.tie_overdrive = nil
	initGameSaveData()
end

-- Register the passive effect
local passiveEffect = mod.libs.passiveEffect
passiveEffect:addPassiveEffect(
	"StarWars_TIEEngineOverdrive",
	{
		"missionStartHook",
		"skillEndHook", "finalEffectEndHook", 
		"nextTurnHook", "onPawnIsGrappled"
	},
	true  -- Not passive only
)
