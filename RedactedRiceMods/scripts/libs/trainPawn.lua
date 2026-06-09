--[[
TrainPawn - Linked train movement for squads with TrainPawnType pawn classes

Pawn classes declare TrainPawnType = "engine" | "car", Image for directional anims,
optional Pushable, and TrainPawnEnginelessSpeed on cars when the engine is absent.

Author: Das Keifer of Redacted Rice
Discord Server: https://discord.gg/CNjTVrpN4v
]]

local VERSION = "0.6.1"

local path = GetParentPath(...)
local icon_folder = path .. "trainPawn/"

local ICON_ENGINE = "trainPawn_icon_engine.png"
local ICON_CAR = "trainPawn_icon_car.png"

local TRAIN_PAWN_TYPE_ENGINE = "engine"
local TRAIN_PAWN_TYPE_CAR = "car"

local DEFAULT_DIR = DIR_RIGHT
local DEFAULT_ENGINELESS_CAR_SPEED = 2

local ALIGN_PREFS = {
	(DEFAULT_DIR + 2) % 4,
	(DEFAULT_DIR + 1) % 4,
	(DEFAULT_DIR + 3) % 4,
	DEFAULT_DIR,
}

--------- TRAIN PAWN TRAITS ------------------

local function registerMassiveTraits()
	local libsMod = mod_loader.mods.redactedrice_libs
	if libsMod and libsMod.libs and libsMod.libs.traitReplace then
		libsMod.libs.traitReplace:add{
			targetTrait = "massive",
			func = function(trait, pawn)
				return isEnginePawn(pawn)
			end,
			icon = "img/combat/icons/" .. ICON_ENGINE,
			desc_title = "Train Engine",
			desc_text = "Massive locomotive. Leads the train and pulls all cars along its path.",
		}
		libsMod.libs.traitReplace:add{
			targetTrait = "massive",
			func = function(trait, pawn)
				return isCarPawn(pawn)
			end,
			icon = "img/combat/icons/" .. ICON_CAR,
			desc_title = "Train Car",
			desc_text = "Massive train car. Pulled by the engine when it is on the field.",
		}
	end
end

--------- TRAIN PAWN MISSION STATE HANDLING ------------------

local function initMissionState(mission)
	if not mission.trainPawn then
		mission.trainPawn = {}
	end
	if not mission.trainPawn.facing then
		mission.trainPawn.facing = {}
	end
end

local function setStoredFacing(pawnId, direction)
	local mission = GetCurrentMission()
	if mission then
		initMissionState(mission)
		mission.trainPawn.facing[pawnId] = direction
	end
end

local function getStoredFacing(pawnId)
	local mission = GetCurrentMission()
	if mission and mission.trainPawn and mission.trainPawn.facing then
		return mission.trainPawn.facing[pawnId]
	end
	return nil
end

local function setStoredUndoState(mission, engineId, spaceState)
	initMissionState(mission)
	mission.trainPawn.undoState = {
		engineId = engineId,
		spaceState = spaceState,
	}
end

local function getStoredUndoState(mission)
	if not mission or not mission.trainPawn then
		return nil
	end
	return mission.trainPawn.undoState
end

local function clearStoredUndoState(mission)
	-- no need to init if not there
	if mission and mission.trainPawn then
		mission.trainPawn.undoState = nil
	end
end

--------- TRAIN PAWN GETTER FNs ------------------

local function getTrainPawnType(pawn)
	if not pawn then
		return nil
	end
	local class = _G[pawn:GetType()]
	return class and class.TrainPawnType or nil
end

local function isTrainPawn(pawn)
	local trainPawnType = getTrainPawnType(pawn)
	return trainPawnType == TRAIN_PAWN_TYPE_ENGINE or trainPawnType == TRAIN_PAWN_TYPE_CAR
end

local function isEnginePawn(pawn)
	return getTrainPawnType(pawn) == TRAIN_PAWN_TYPE_ENGINE
end

local function isCarPawn(pawn)
	return getTrainPawnType(pawn) == TRAIN_PAWN_TYPE_CAR
end

local function sortByPawnId(pawns)
	table.sort(pawns, function(a, b)
		return a:GetId() < b:GetId()
	end)
	return pawns
end

local function _getAllTrainPawns(fn)
	local pawns = {}
	if not Board then
		return pawns
	end

	for _, pawnId in pairs(extract_table(Board:GetPawns(TEAM_PLAYER))) do
		local pawn = Board:GetPawn(pawnId)
		if fn(pawn) then
			table.insert(pawns, pawn)
		end
	end
	return sortByPawnId(pawns)
end

local function getAllTrainPawns()
	return _getAllTrainPawns(isTrainPawn)
end

local function getEngines()
	return _getAllTrainPawns(isEnginePawn)
end

local function getEngine()
	local engines = getEngines()
	if #engines == 0 then
		return nil
	end
	return engines[1]
end

local function isLinkedTrainMode()
	return getEngine() ~= nil
end

local function getCars()
	return _getAllTrainPawns(isCarPawn)
end

local function getTrainChain()
	local chain = {}
	local engine = getEngine()
	if engine then
		table.insert(chain, {id = engine:GetId(), pawn = engine})
	end
	for _, car in ipairs(getCars()) do
		table.insert(chain, {id = car:GetId(), pawn = car})
	end
	return chain
end

--------- TRAIN PAWN DIRECTIONAL IMAGES ------------------

local function setPawnFacing(pawn, direction , skipSave)
	if direction == nil then
		return
	end
	if not skipSave then
		-- TODO: Make a temporary
		setStoredFacing(pawn:GetId(), direction)
	end
	local class = _G[pawn:GetType()]
	local image = class and class.Image
	if not image then
		return
	end
	local animId = image .. "_dir" .. direction
	if ANIMS[animId] then
		pawn:SetCustomAnim(animId)
	end
end

local function setAllPawnFacingToDefault()
	for _, pawnData in ipairs(getTrainChain()) do
		setPawnFacing(pawnData.pawn, DEFAULT_DIR)
	end
end

local function refreshAllPawnVisuals()
	if not Board or not isLinkedTrainMode() then
		return
	end

	local prevPawn = nil
	for _, pawnData in ipairs(getTrainChain()) do
		local direction = getStoredFacing(pawnData.id)
		if direction == nil then
			if prevPawn == nil then
				local engine = getEngine()
				local cars = getCars()
				if cars[1] then
					direction = GetDirection(engine:GetSpace() - cars[1]:GetSpace())
				else
					direction = DEFAULT_DIR
				end
			else
				direction = GetDirection(prevPawn:GetSpace() - pawnData.pawn:GetSpace())
			end
		end
		setPawnFacing(pawnData.pawn, direction)
		prevPawn = pawnData.pawn
	end
end

--------- CAR PAWN MOVE SKILL EFFECT ------------------

TrainPawn_FollowerMove = Move:new{}

function TrainPawn_FollowerMove:GetTargetArea(point)
	return PointList()
end

function TrainPawn_FollowerMove:GetSkillEffect(p1, p2)
	return SkillEffect()
end

function TrainPawn_FollowerMove:GetDescription()
	return "Can't move by itself. Only pulled by the engine."
end

--------- TRAIN PAWN STATE SETUP ------------------

local function applyTrainPawnState()
	local linkedMode = isLinkedTrainMode()

	for _, pawn in ipairs(getAllTrainPawns()) do
		local class = _G[pawn:GetType()]

		if linkedMode then
			pawn:SetPushable(false)
			if isCarPawn(pawn) then
				pawn:SetMoveSpeed(0)
			end
		else
			if class.Pushable ~= nil then
				pawn:SetPushable(class.Pushable)
			end
			if isCarPawn(pawn) then
				pawn:SetMoveSpeed(class.TrainPawnEnginelessSpeed or DEFAULT_ENGINELESS_CAR_SPEED)
			end
		end
	end
end

--------- TRAIN PAWN MOVE FUNCTIONS ------------------

local function addStep(effect, path, fromIndex, toIndex, pawnId)
	local from = path:index(fromIndex)
	local to = path:index(toIndex)
	local dir = GetDirection(to - from)

	-- Switch image direction
	effect:AddScript( [[
		Board:GetPawn(]]..pawnId..[[):SetSpace(]]..to:GetString()..[[)
	]])
	TrainPawn.setPawnFacing(Board:GetPawn(pawnId), dir, true)
end

local function buildNextFollowerPath(prevPawnPath, pawnPos)
	local newPath = PointList()
	newPath:push_back(pawnPos)
	for i = 1, prevPawnPath:size() - 1 do
		newPath:push_back(prevPawnPath:index(i))
	end
	return newPath
end

local function buildTrainMoveEffect(engine, p1, p2)
	local ret = SkillEffect()
	local enginePath = Board:GetPath(p1, p2, engine:GetPathProf())
	ret:AddMove(enginePath, NO_DELAY)

	-- train pawn states captured on skill start

	local paths = { [0] = enginePath }
	local cars = getCars()
	local lastPawn = #cars
	for i, car in ipairs(cars) do
		paths[i] = buildNextFollowerPath(paths[i - 1], car:GetSpace())
		ret:AddMove(paths[i], NO_DELAY)
	end

	-- Add move for display purposes. This won't let us move onto unmovable spaces reliably

	for step = 2, enginePath:size() do
		addStep(ret, paths[0], step - 1, step, engine:GetId())
		for i, car in ipairs(cars) do
			addStep(ret, paths[i], step - 1, step, car:GetId())
		end
		ret:AddDelay(0.1)
	end
	return ret
end

local function addMoveOverrides()
	local original_MoveGetTargetArea = Move.GetTargetArea
	local original_MoveGetSkillEffect = Move.GetSkillEffect
	local original_MoveGetDescription = Move.GetDescription

	function Move:GetDescription()
		if isLinkedTrainMode() and isCarPawn(Pawn) then
			return TrainPawn_FollowerMove:GetDescription()
		end
		return original_MoveGetDescription(self)
	end

	function Move:GetTargetArea(point)
		if isLinkedTrainMode() and isCarPawn(Pawn) then
			return TrainPawn_FollowerMove:GetTargetArea(point)
		end
		return original_MoveGetTargetArea(self, point)
	end

	function Move:GetSkillEffect(p1, p2)
		if isLinkedTrainMode() and isCarPawn(Pawn) then
			return TrainPawn_FollowerMove:GetSkillEffect(p1, p2)
		end

		local engine = getEngine()
		if engine and Pawn:GetId() == engine:GetId() then
			return buildTrainMoveEffect(engine, p1, p2)
		end

		return original_MoveGetSkillEffect(self, p1, p2)
	end
end

--------- TRAIN PAWN UNDO MOVEMENT FNs ------------------

local function captureTrainMoveUndoState(mission, engine)
	-- Validity checked by caller
	local cars = getCars()
	local undoPawns = { engine }
	for _, car in ipairs(cars) do
		table.insert(undoPawns, car)
	end

	local spaceStates = {}
	for _, pawn in ipairs(undoPawns) do
		local id = pawn:GetId()
		spaceStates[id] = {
			position = pawn:GetSpace(),
			facing = getStoredFacing(id) or DEFAULT_DIR
		}
	end
	-- init and store the undo state
	setStoredUndoState(mission, engine:GetId(), spaceStates)
end

local function onTrainMoveStart(mission, pawn, weaponId)
	if not mission or weaponId ~= "Move" or Board:IsTipImage() then
		return
	end

	-- If there is an engine, we are in linked mode
	local engine = getEngine()
	if not engine or pawn:GetId() ~= engine:GetId() then
		return
	end

	captureTrainMoveUndoState(mission, engine)
end

local function onTrainMoveEnd(mission, pawn, weaponId)
	--TODO: Save temp facing state
end

local function onTrainUndoMove(mission, pawn, undonePosition)
	if not mission then
		return
	end

	-- Engine will be nil if not in linked mode
	local engine = getEngine()
	if not engine or pawn:GetId() ~= engine:GetId() then
		return
	end
	local engineId = engine:GetId()

	local undoData = getStoredUndoState(mission)
	if not undoData or undoData.engineId ~= engineId then
		return
	end

	-- Restore pawn positons
	for pawnId, spaceState in pairs(undoData.spaceState) do
		if pawnId ~= engineId then
			local carPawn = Board:GetPawn(pawnId)
			carPawn:SetSpace(spaceState.position)
			setPawnFacing(carPawn, spaceState.facing)
		end
	end

	-- Clear the state. Technically not needed
	clearStoredUndoState(mission)
end

--------- DEPLOYMENT HANDLING ------------------

local function canOccupyForDeploy(point)
	return Board:IsValid(point) and not Board:IsBlocked(point, PATH_GROUND)
end

local function findDeploySlot(prevCarSpace, searchingCarSpace)
	local firstCandidate = nil
	for _, dir in ipairs(ALIGN_PREFS) do
		local candidate = prevCarSpace + DIR_VECTORS[dir]
		if searchingCarSpace == candidate then
			return candidate, true
		end
		if not firstCandidate and canOccupyForDeploy(candidate) then
			firstCandidate = candidate
		end
	end
	return firstCandidate, false
end

local function alignTrainPawn(pawn)
	if not Board or not isTrainPawn(pawn) or not isLinkedTrainMode() then
		return
	end

	local pawnId = pawn:GetId()
	local trainChain = getTrainChain()
	local engine = trainChain[1].pawn

	local inTrain = false
	local prevPawn = nil
	for _, pawnData in ipairs(trainChain) do
		if pawnData.id == pawnId then
			inTrain = true
			break
		end
		prevPawn = pawnData.pawn
	end

	-- If its not in the train or its the first pawn (the engine), just set to default direction
	if not inTrain or prevPawn == nil then
		setPawnFacing(pawn, DEFAULT_DIR)
		return
	end

	-- If its a car we need to move and face
	local deploySpace, alreadyThere = findDeploySlot(prevPawn:GetSpace(), pawn:GetSpace())
	if deploySpace == nil then
		-- Can't add anything. Just keep where it is and do our best to continue
		setPawnFacing(pawn, DEFAULT_DIR)
		return
    else
		local facing = GetDirection(prevPawn:GetSpace() - pawn:GetSpace())
		-- Adjust the engine facing if the next car is already in the right position
		if alreadyThere and prevPawn:GetId() == engine:GetId() then
			setPawnFacing(engine, facing)
		end
		setPawnFacing(pawn, facing)
		pawn:SetSpace(deploySpace)
	end
end

--------- HELPER FNS (TODO) ------------------

function addTrainCharge(effect, enginePath, delay)
	return effect
end

--------- HOOKS/EVENTS ------------------

local function onMissionStart(mission)
	applyTrainPawnState()
	setAllPawnFacingToDefault()
end

local function onPostLoadGame()
	-- TODO: Do I need to postpone? Need to test
	modApi:scheduleHook(1, function()
		applyTrainPawnState()
		refreshAllPawnVisuals()
	end)
end

local function onPawnLanding(pawnId)
	if not isLinkedTrainMode() then
		return
	end
	local pawn = Board:GetPawn(pawnId)
	if pawn and isTrainPawn(pawn) then
		alignTrainPawn(pawn)
	end
end

--[[local function onPawnPositionChanged(mission, pawn, oldPosition)
	-- Todo: need to handle in case they move engine by other effects
end]]

local function registerEvents()
	modApi.events.onPawnLanding:subscribe(onPawnLanding)
end

local function registerHooks()
	modApi:addMissionStartHook(onMissionStart)
	modApi:addPostLoadGameHook(onPostLoadGame)

	modapiext:addSkillStartHook(onTrainMoveStart)
	modapiext:addSkillEndHook(onTrainMoveEnd)
	modapiext:addPawnUndoMoveHook(onTrainUndoMove)

	--modapiext:addPawnPositionChangedHook(onPawnPositionChanged)

	modapiext:addPawnUnselectedHook(refreshAllPawnVisuals)
end

local function onModsInitialized()
	if VERSION < TrainPawn.version then
		return
	end

	if TrainPawn.initialized then
		return
	end

	TrainPawn:finalizeInit()
	TrainPawn.initialized = true
end

local function onModsLoaded()
	if VERSION < TrainPawn.version then
		return
	end

	if TrainPawn.loaded then
		return
	end

	TrainPawn:finalizeLoad()
	TrainPawn.loaded = true
end

modApi.events.onModsInitialized:subscribe(onModsInitialized)
modApi.events.onModsLoaded:subscribe(onModsLoaded)

local isNewestVersion = false
	or TrainPawn == nil
	or modApi:isVersion(VERSION, TrainPawn.version) == false

if isNewestVersion then
	LOG("TrainPawn: Loading version " .. VERSION .. " (previous: " .. tostring(TrainPawn and TrainPawn.version or "none") .. ")")

	TrainPawn = TrainPawn or {}
	TrainPawn.version = VERSION
	TrainPawn.initialized = false
	TrainPawn.loaded = false

	function TrainPawn:finalizeInit()
		modApi:appendAsset("img/combat/icons/" .. ICON_ENGINE, icon_folder.."/"..ICON_ENGINE)
		modApi:appendAsset("img/combat/icons/" .. ICON_CAR, icon_folder.."/"..ICON_CAR)

		TrainPawn.TRAIN_PAWN_TYPE_ENGINE = TRAIN_PAWN_TYPE_ENGINE
		TrainPawn.TRAIN_PAWN_TYPE_CAR = TRAIN_PAWN_TYPE_CAR

		TrainPawn.getTrainPawnType = getTrainPawnType
		TrainPawn.isTrainPawn = isTrainPawn
		TrainPawn.isEnginePawn = isEnginePawn
		TrainPawn.isCarPawn = isCarPawn
		TrainPawn.isLinkedTrainMode = isLinkedTrainMode
		TrainPawn.getAllTrainPawns = getAllTrainPawns
		TrainPawn.getEngine = getEngine
		TrainPawn.getCars = getCars
		TrainPawn.getTrainChain = getTrainChain
		TrainPawn.applyTrainPawnState = applyTrainPawnState
		TrainPawn.setPawnFacing = setPawnFacing
		TrainPawn.refreshAllPawnVisuals = refreshAllPawnVisuals
		TrainPawn.addTrainCharge = addTrainCharge
		TrainPawn.buildTrainMoveEffect = buildTrainMoveEffect
		TrainPawn.alignTrainPawn = alignTrainPawn
		TrainPawn.registerMassiveTraits = registerMassiveTraits

		addMoveOverrides()
		registerEvents()
	end

	function TrainPawn:finalizeLoad()
		registerHooks()
	end
else
	LOG("TrainPawn: Skipping version " .. VERSION .. " (already have " .. TrainPawn.version .. ")")
end

return TrainPawn
