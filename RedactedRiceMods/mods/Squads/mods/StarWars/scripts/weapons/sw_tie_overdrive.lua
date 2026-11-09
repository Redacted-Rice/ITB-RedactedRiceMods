StarWars_TieOverdrive = PassiveSkill:new{
	Name = "TIE Tuning",
	Description = "Each use: +1 move for the rest of the mission (stacks).",
	Class = "Brute",
	PowerCost = 0,
	Upgrades = 2,
	UpgradeCost = {1, 1},
	Icon = "weapons/brute_sw_tie_engine.png",
	Sound = "/weapons/area_shield",
	WebImmune = false,
	BonusMoveAfterAttack = false,
	TipImage = {
		CustomPawn = "StarWars_TIEFighterMech",
		Unit = Point(2, 2),
		Target = Point(2, 2),
	},
}

local mod = mod_loader.mods[modApi.currentMod]

Weapon_Texts.StarWars_TieOverdrive_Upgrade1 = "Evasive"
Weapon_Texts.StarWars_TieOverdrive_A_UpgradeDescription = "Mech becomes web immune after first use each mission"
StarWars_TieOverdrive_A = StarWars_TieOverdrive:new{
	WebImmune = true,
}

Weapon_Texts.StarWars_TieOverdrive_Upgrade2 = "Combat Maneuvers"
Weapon_Texts.StarWars_TieOverdrive_B_UpgradeDescription = "Also grants +1 move after each attack (stacks)"
StarWars_TieOverdrive_B = StarWars_TieOverdrive:new{
	BonusMoveAfterAttack = true,
}

StarWars_TieOverdrive_AB = StarWars_TieOverdrive_A:new{
	BonusMoveAfterAttack = true,
}

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
	if GAME.starwars.tie_overdrive.move_stacks == nil then
		GAME.starwars.tie_overdrive.move_stacks = {}
	end
	if GAME.starwars.tie_overdrive.after_attack_move == nil then
		GAME.starwars.tie_overdrive.after_attack_move = {}
	end
	if GAME.starwars.tie_overdrive.web_immune_applied == nil then
		GAME.starwars.tie_overdrive.web_immune_applied = {}
	end
end

-- Helper function to check if a pawn has TIE Overdrive active
local function pawnHasTieOverdrive(pawn)
	if not pawn or not pawn:IsMech() then return false end
	if not Game or not Board or Board:IsTipImage() then return false end

	initGameSaveData()
	local pawnId = pawn:GetId()
	local moveStacks = GAME.starwars.tie_overdrive.move_stacks[pawnId] or 0
	return moveStacks > 0
end

-- Add stateful trait icon showing active vs inactive state
mod.libs.traitReplace:addStateful{
	targetTrait = "massive",
	func = function(trait, pawn)
		if not pawnHasTieOverdrive(pawn) then
			return 0  -- Don't display
		end
		return 1  -- Active state
	end,
	states = {
		{
			icon = "img/combat/icons/icon_sw_tie_overdrive.png",
			desc_title = "TIE Tuning",
			desc_text = function(pawn)
				initGameSaveData()

				local pawnId = pawn:GetId()
				local stacks = GAME.starwars.tie_overdrive.move_stacks[pawnId] or 0
				local text = "+" .. stacks.. " move "

				if GAME.starwars.tie_overdrive.after_attack_move[pawnId] then
					text = text .. " and +" .. stacks .. " move after each attack "
				end
				text = text .. "from TIE Tuning."

				-- Check for web immunity
				if GAME.starwars.tie_overdrive.web_immune_applied[pawnId] then
					text = text .. " Web immune."
				end

				return text
			end,
		},
	}
}

function StarWars_TieOverdrive:GetTargetArea(point)
	local ret = PointList()
	ret:push_back(point)
	return ret
end

function StarWars_TieOverdrive:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	-- Push all adjacent tiles
	local damage = SpaceDamage(p1)
	for dir = DIR_START, DIR_END do
		local target = p1 + DIR_VECTORS[dir]
		if Board:IsValid(target) then
			local push = SpaceDamage(target, 0, dir)
			push.sAnimation = "airpush_" .. dir
			ret:AddDamage(push)
			ret:AddBounce(target, 1)
		end
	end

	damage.sScript = [[
		local pawn = Board:GetPawn(]] .. p1:GetString() .. [[)
		if pawn then
			local pawnId = pawn:GetId()

			-- Initialize save data
			if GAME.starwars == nil then GAME.starwars = {} end
			if GAME.starwars.tie_overdrive == nil then GAME.starwars.tie_overdrive = {} end
			if GAME.starwars.tie_overdrive.move_stacks == nil then GAME.starwars.tie_overdrive.move_stacks = {} end
		]]
	if self.WebImmune then
		damage.sScript = damage.sScript .. [[
			if GAME.starwars.tie_overdrive.web_immune_applied == nil then GAME.starwars.tie_overdrive.web_immune_applied = {} end
			GAME.starwars.tie_overdrive.web_immune_applied[pawnId] = true

			local space = pawn:GetSpace()
            pawn:SetSpace(Point(-1,-1))
            modApi:runLater(function()
                pawn:SetSpace(space)
            end)
		]]
	end

	if self.BonusMoveAfterAttack then
		damage.sScript = damage.sScript .. [[
			if GAME.starwars.tie_overdrive.after_attack_move == nil then GAME.starwars.tie_overdrive.after_attack_move = {} end
			GAME.starwars.tie_overdrive.after_attack_move[pawnId] = true
		]]
	end
	
	damage.sScript = damage.sScript .. [[
			-- Increase the move stacks
			if GAME.starwars.tie_overdrive.move_stacks == nil then GAME.starwars.tie_overdrive.move_stacks = {} end
			GAME.starwars.tie_overdrive.move_stacks[pawnId] = (GAME.starwars.tie_overdrive.move_stacks[pawnId] or 0) + 1
		end
	]]

	ret:AddSound(self.Sound)
	ret:AddDamage(damage)
	return ret
end

-- Bonus move after attack if upgraded
function StarWars_TieOverdrive:maybeApplyExtraBonuses(pawn, weaponId)
	LOG("maybeApplyExtraBonuses")
	if not pawn then return end
	if not Game or not Board or Board:IsTipImage() then return end
	if weaponId == "Move" then return end

	initGameSaveData()

	local pawnId = pawn:GetId()
	if not GAME.starwars.tie_overdrive.after_attack_move[pawnId] then return end

	-- Check if this pawn has overdrive active and the upgrade
	local moveStacks = GAME.starwars.tie_overdrive.move_stacks[pawnId] or 0
	if moveStacks > 0 then
		-- Grant bonus move
		pawn:SetBonusMove(moveStacks)
		modApi:runLater(function()
			pawn:SetActive(true)
		end)
		Board:AddAlert(pawn:GetSpace(), "OVERDRIVE")
		Board:Ping(pawn:GetSpace(), GL_Color(0, 0, 255))
	end
end

function StarWars_TieOverdrive:maybeApplyBaseSpeedBoosts()
	if not Game or not Board or Board:IsTipImage() then return end

	initGameSaveData()

	-- Apply base speed boost
	for pawnId = 0, 2 do
		local moveStacks = GAME.starwars.tie_overdrive.move_stacks[pawnId] or 0
		if moveStacks > 0 then
			local pawn = Board:GetPawn(pawnId)
			pawn:AddMoveBonus(moveStacks)
			Board:AddAlert(pawn:GetSpace(), "OVERDRIVE")
			Board:Ping(pawn:GetSpace(), GL_Color(0, 0, 255))
		end
	end
end

function StarWars_TieOverdrive:GetPassiveSkillEffect_SkillEndHook(mission, pawn, weaponId)
	self:maybeApplyExtraBonuses(pawn, weaponId)
end

function StarWars_TieOverdrive:GetPassiveSkillEffect_FinalEffectEndHook(mission, pawn, weaponId)
	self:maybeApplyExtraBonuses(pawn, weaponId)
end

function StarWars_TieOverdrive:GetPassiveSkillEffect_NextTurnHook(mission)
	if Game:GetTeamTurn() == TEAM_PLAYER then
		self:maybeApplyBaseSpeedBoosts()
	end
end

function StarWars_TieOverdrive:GetPassiveSkillEffect_OnPawnIsGrappled(mission, pawn, isGrappled)
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

function StarWars_TieOverdrive:GetPassiveSkillEffect_MissionStartHook(mission)
	initGameSaveData()
	GAME.starwars.tie_overdrive = nil
	initGameSaveData()
end

-- Register the passive effect
local passiveEffect = mod.libs.passiveEffect
passiveEffect:addPassiveEffect(
	"StarWars_TieOverdrive",
	{
		"missionStartHook",
		"skillEndHook", "finalEffectEndHook",
		"nextTurnHook", "onPawnIsGrappled"
	},
	true  -- Not passive only
)
