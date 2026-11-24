-- This lib allows for "orbital pawns", pawns that stay outside of the board.
-- Orbital icon / tooltip not included, use the orbitalIcon lib for that
-- To use it, just add Orbital = true to your pawn table and it will take care of the rest.
-- You can also define OrbitalAnim and OrbitalSound to add an animation and a sound for your pawn in the landing phase
-- Orbital pawns can only use Orbital weapons. To make a weapon usable by them, add Orbital = true to the weapon's table

local version = 1.1

if not orbitalPawn or orbitalPawn < version then
	
	orbitalPawn = version
	
	-------------
	-- WEAPONS --
	-------------
	
	local weapons_list = {
		-- vanilla
		'Skill_Repair',
		'Support_SmokeDrop',
		'Support_Repair',
		'Support_Missiles',
		'Support_Wind',
		'Support_Force',
		-- AE
		'Support_Waterdrill',
		'Support_TC_GridAtk',
		'Support_TC_Bombline',
		-- modded
		'tosx_sat_archive_w',
		'tosx_sat_detritus_w',
		'tosx_sat_pinnacle_w',
		'tosx_sat_rst_w',
	}
	
	---------------
	-- Functions --
	---------------
	
	-- move pawn to outside the board
	local function move_outside(pawn)
		pawn:SetSpace(Point(-1,-1))
		pawn:SetInvisible(false)
		pawn:SetFlying(false)
	end
	
	-- move pawn to inside the board
	local function move_inside(pawn,p)
		pawn:SetFlying(true)
		pawn:SetInvisible(true)
		pawn:SetSpace(p)
	end
	
	-- find a safe board location for orbital pawns using weapons
	local function get_safe_space(pawn, effect)
		-- list for spaces being affected by skills to avoid
		local dangerTable = {}
		if effect then
			local safe = true
			for i = 1, effect:size() do
				local p = effect:index(i).loc
				dangerTable[p.x + p.y*10] = true
			end
		end
		-- pick safe space
		local backup = false
		for x = 0,7 do
			for y = 0,7 do
				local p = Point(x,y)
				if (
					Board:IsTerrain(p,TERRAIN_ROAD)
					or Board:IsTerrain(p,TERRAIN_RUBBLE)
					or Board:IsTerrain(p,TERRAIN_MOUNTAIN)
					-- or Board:IsTerrain(p,TERRAIN_SAND) -- sand trait appears
					-- or Board:IsTerrain(p,TERRAIN_FOREST) -- forest trait appears
					or Board:IsTerrain(p,TERRAIN_BUILDING) -- webs affect movement based skills, but tiles with adjacent pawns are excluded
					or (pawn:IsFlying() and (Board:IsTerrain(p,TERRAIN_WATER)) or (Board:IsTerrain(p,TERRAIN_HOLE)))
					)
					and not Board:IsPawnSpace(p)
					and not Board:IsFire(p)
					and not Board:IsAcid(p)
					and not Board:IsSmoke(p)
					and not Board:IsPod(p)
					and not Board:IsItem(p)
					and Board:GetCustomTile(p) == ""
				then
					local noPawns = true
					for dir = DIR_START, DIR_END do
						if Board:IsPawnSpace(p+DIR_VECTORS[dir]) then noPawns = false end
					end
					if noPawns then -- exclude tiles with adjacent pawns
						if effect then
							if not dangerTable[p.x + p.y*10] then
								return p
							end
						else
							return p
						end
					else
						if not backup then  -- add tiles with adjacent pawns if out of options
							backup = p
						end
					end
				end
			end
		end
		if backup then
			return backup
		else
			return Point(0,0) -- last resort to avoid errors
		end
	end
	
	-- try to identify unlisted compatible weapons
	local function is_orbital(weaponId)
		if _G[weaponId].Orbital then return true end
		if Board and weaponId ~= "Move" then
			local list1 = _G[weaponId]:GetTargetArea(Point(0,0))
			local list2 = _G[weaponId]:GetTargetArea(Point(6,4))
			if list1 and list2 then
				if list1:index(1) == list2:index(1) and list1:back() == list2:back() then
					_G[weaponId].Orbital = true
				end
			end
			if not _G[weaponId].Orbital then
				_G[weaponId].Orbital = false
			end
		end
		return _G[weaponId].Orbital
	end
	
	-- move pawn inside the board to aim skills
	local function EVENT_MissionUpdate(mission)
		if Pawn and _G[Pawn:GetType()].Orbital and Board and Board:GetTurn() > 0 then
			Pawn:SetFlying(true)
			Pawn:SetHealth(Pawn:GetMaxHealth())
			if Pawn:GetSpace() == Point(-1,-1) and Pawn:GetArmedWeaponType() and Pawn:GetArmedWeaponType() ~= "Move" then
				if is_orbital(Pawn:GetArmedWeaponType()) then
					local p = get_safe_space(Pawn)
					move_inside(Pawn,p)
				end
			elseif not Pawn:GetArmedWeaponType() then
				move_outside(Pawn)
			end
		end
	end
	
	-- hide pawn when landing (do not move outside because of gana) and add animations
	local function EVENT_PawnLanding(pawnId)
		local pawn = Board:GetPawn(pawnId)
		local ptype = pawn:GetType()
		if pawn and _G[ptype].Orbital and pawn:GetSpace() ~= Point(-1,-1) then
			pawn:SetInvisible(true)
			if _G[ptype].OrbitalAnim then
				Board:AddAnimation(pawn:GetSpace(),_G[ptype].OrbitalAnim,1)
			end
			if _G[ptype].OrbitalSound then
				Game:TriggerSound(_G[ptype].OrbitalSound)
			end
		end
	end
	
	-- move pawn outside the board on turn start
	local function EVENT_NextTurn()
		if Board then
			local pawnList = extract_table(Board:GetPawns(TEAM_ANY))
			for _,p in ipairs(pawnList) do
				local pawn = Board:GetPawn(p)
				if pawn and _G[pawn:GetType()].Orbital then
					move_outside(pawn)
				end
			end
		end
	end
	
	-- move pawn outside the board when skills start
	local function EVENT_SkillStart(mission, pawn, weaponId, p1, p2)
		if pawn and _G[pawn:GetType()].Orbital then
			move_outside(pawn)
		end
	end
	
	-- move pawn outside the board when deselected
	local function EVENT_PawnDeselected(mission, pawn)
		if pawn and _G[pawn:GetType()].Orbital and Board and Board:GetTurn() > 0 then
			move_outside(pawn)
		end
	end
	
	-- move pawn outside the board on load
	local function EVENT_PostLoadGame()
		modApi:scheduleHook(100, function()
			if Board then
				local pawnList = extract_table(Board:GetPawns(TEAM_ANY))
				for _,p in ipairs(pawnList) do
					local pawn = Board:GetPawn(p)
					if pawn and _G[pawn:GetType()].Orbital then
						move_outside(pawn)
					end
				end
			end
		end)
	end
	
	-- remove mites and turn visible on mission start
	local function EVENT_MissionStart(mission)
		modApi:scheduleHook(100, function()
			if Board then
				local pawnList = extract_table(Board:GetPawns(TEAM_ANY))
				for _,p in ipairs(pawnList) do
					local pawn = Board:GetPawn(p)
					if pawn and _G[pawn:GetType()].Orbital then
						pawn:SetInfected(false)
						pawn:SetInvisible(false)
						pawn:SetFlying(true)
						pawn:SetHealth(pawn:GetMaxHealth())
					end
				end
			end
		end)
	end
	
	-- move pawn outside the board on final mission landing
	local orbitalN = 0
	local function EVENT_MissionNextPhaseCreated(prevMission, nextMission)
		modApi:scheduleHook(100, function()
			if Board then
				local pawnList = extract_table(Board:GetPawns(TEAM_ANY))
				for _,p in ipairs(pawnList) do
					local pawn = Board:GetPawn(p)
					if pawn and _G[pawn:GetType()].Orbital then
						orbitalN = orbitalN + 1
					end
				end
			end
		end)
	end
	
	local function EVENT_PawnPositionChanged(mission, pawn, oldPosition)
		if orbitalN > 0 and mission and pawn and _G[pawn:GetType()].Orbital and pawn:GetSpace() ~= Point(-1,-1) then
			move_outside(pawn)
			orbitalN = math.max(0,orbitalN-1)
		end
	end
	
	-- remove flight
	local function EVENT_MissionEnd(mission)
		if Board then
			local pawnList = extract_table(Board:GetPawns(TEAM_ANY))
			for _,p in ipairs(pawnList) do
				local pawn = Board:GetPawn(p)
				if pawn and _G[pawn:GetType()].Orbital then
					pawn:SetFlying(false)
				end
			end
		end
	end
	
	-- move pawn around and hide effects to avoid bad previews
	local function fix_preview(pawn,skillEffect,queued)
		if pawn and _G[pawn:GetType()].Orbital then
			local effect = queued and skillEffect.q_effect or skillEffect.effect
			if effect == nil then
				return
			end
			for i = 1, effect:size() do
				local spaceDamage = effect:index(i)
				if pawn:GetSpace() == spaceDamage.loc and spaceDamage.iPush < 4 then
					spaceDamage.bHide = true
					local p = get_safe_space(pawn, effect)
					move_inside(pawn,p)
				end
			end
		end
	end
	
	local function EVENT_SkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
		fix_preview(pawn,skillEffect,false)
		fix_preview(pawn,skillEffect,true)
	end
	
	local function EVENT_FinalEffectBuild(mission, pawn, weaponId, p1, p2, p3, skillEffect)
		fix_preview(pawn,skillEffect,false)
		fix_preview(pawn,skillEffect,true)
	end
	
	-- hide incompatible weapons when pawn is on the board
	local function EVENT_TargetAreaBuild(mission, pawn, weaponId, p1, targetArea)
		if pawn and _G[pawn:GetType()].Orbital and not _G[weaponId].Orbital then
			while not targetArea:empty() do
				targetArea:erase(0)
			end
			move_outside(pawn)
		end
	end
	
	-- incompatible weapons warning text and sound
	local function EVENT_TipImageShown(skillType)
		if Game then
			-- warning text
			for i = 0, 2 do
				local pawn = Board and Board:GetPawn(i) or Game:GetPawn(i)
				if pawn then
					for i = 1, pawn:GetWeaponCount() do
						local weapon = pawn:GetWeaponBaseType(i)
						-- if _G[pawn:GetType()].Orbital and _G[weapon].Passive == '' and not _G[weapon].Orbital then
						if _G[pawn:GetType()].Orbital and _G[weapon].Passive == '' and not is_orbital(weapon) then
							_G[weapon].oldClass = _G[weapon].Class
							if _G[weapon].Orbital == false then
								_G[weapon].Class = 'NonOrbital'
							else
								_G[weapon].Class = 'MaybeOrbital'
							end
						end
					end
				end
			end
			-- annoying warning sound
			if not GetCurrentMission() then
				local skillId = skillType.__skill.__Id
				if _G[skillId].Class:find('Orbital') then
					Game:TriggerSound("/ui/battle/critical_damage")
				end
			end
		end
	end
	
	-- restore incompatible weapons old class text
	local function EVENT_TipImageHidden()
		if Game then
			for i = 0, 2 do
				local pawn = Board and Board:GetPawn(i) or Game:GetPawn(i)
				if pawn then
					for i = 1, pawn:GetWeaponCount() do
						local weapon = pawn:GetWeaponBaseType(i)
						if _G[weapon].oldClass then
							_G[weapon].Class = _G[weapon].oldClass
						end
					end
				end
			end
		end
	end
	
	-- restore full health on damage
	local EVENT_PawnDamaged = function(mission, pawn, damageTaken)
		if _G[pawn:GetType()].Orbital then
			pawn:SetHealth(pawn:GetMaxHealth())
		end
	end
	
	-------------
	-- EVENTS ---
	-------------
	
	local function EVENT_onModsFirstLoaded()
		if version == orbitalPawn then
			-- stop other libs with the same version, but keep value as string
			orbitalPawn = ''..orbitalPawn
			-- class texts
			Global_Texts['Skill_ClassMaybeOrbital'] = "Warning: Test before using. May not be an Orbital"
			Global_Texts['Skill_ClassNonOrbital'] = "Incompatible even if powered. Non-Orbital"
			-- make listed weapons orbital
			for _,weapon in pairs(weapons_list) do
				if _G[weapon] then
					_G[weapon].Orbital = true
				end
			end
			-- subscribe to events
			modApi.events.onMissionUpdate:subscribe(EVENT_MissionUpdate)
			modApi.events.onPawnLanding:subscribe(EVENT_PawnLanding)
			modApi.events.onMissionStart:subscribe(EVENT_MissionStart)
			modApi.events.onMissionNextPhaseCreated:subscribe(EVENT_MissionNextPhaseCreated)
			modApi.events.onMissionEnd:subscribe(EVENT_MissionEnd)
			modApi.events.onTipImageShown:subscribe(EVENT_TipImageShown)
			modApi.events.onTipImageHidden:subscribe(EVENT_TipImageHidden)
			modApi.events.onPostLoadGame:subscribe(EVENT_PostLoadGame)
			modApi.events.onNextTurn:subscribe(EVENT_NextTurn)
			
			modapiext.events.onSkillStart:subscribe(EVENT_SkillStart)
			modapiext.events.onFinalEffectStart:subscribe(EVENT_SkillStart)
			modapiext.events.onSkillBuild:subscribe(EVENT_SkillBuild)
			modapiext.events.onFinalEffectBuild:subscribe(EVENT_FinalEffectBuild)
			modapiext.events.onTargetAreaBuild:subscribe(EVENT_TargetAreaBuild)
			modapiext.events.onPawnDamaged:subscribe(EVENT_PawnDamaged)
			modapiext.events.onPawnPositionChanged:subscribe(EVENT_PawnPositionChanged)
			modapiext.events.onPawnDeselected:subscribe(EVENT_PawnDeselected)
		end
	end
	
	modApi.events.onModsFirstLoaded:subscribe(EVENT_onModsFirstLoaded)
	
end