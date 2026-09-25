
local VERSION = "1.0.2"
local PREFIX = "_custom_anim_%s_"
local PREFIX_ANIM = string.format(PREFIX, "1")
local EVENTS = {
	"onPawnAnimationAdded",
	"onTileAnimationAdded",
	"onPawnAnimationRemoved",
	"onTileAnimationRemoved",
}

local function sum_list(list)
	local accum = 0

	for _, num in ipairs(list) do
		accum = accum + num
	end

	return accum
end

local function list_find(list, key, value)
	for i, v in ipairs(list) do
		if v[key] == value then
			return i
		end
	end

	return -1
end

local function create_new_entry(animId, suffix, desc)
	return {
		id = animId..suffix,
		animId = animId,
		time_start = os.clock(),
		title = desc and desc[1] or nil,
		desc = desc and desc[2] or nil,
	}
end


-- add an animation to a location or a pawnId
-- until it is removed by Rem.
local function add(self, loc, animId, suffix, desc)
	local m = GetCurrentMission()
	if not m then return end

	Assert.Equals('table', type(self), "Check for . vs :")
	Assert.Equals({'number', 'userdata'}, type(loc), "Argument #1")
	Assert.Equals('string', type(animId), "Argument #2")
	Assert.Equals({'nil', 'table'}, type(desc), "Argument #3")
	Assert.Equals('table', type(ANIMS[animId]), "Animation '"..animId.."' does not exist")
	Assert.Equals({'nil', 'string'}, type(suffix), "Argument #4")

	suffix = suffix or ""
	if self:get(loc, animId, suffix) ~= nil then
		return
	end

	if type(loc) == 'number' then
		local pawnId = loc
		m.lmn_pawnAnims = m.lmn_pawnAnims or {}
		m.lmn_pawnAnims[pawnId] = m.lmn_pawnAnims[pawnId] or {}
		table.insert(m.lmn_pawnAnims[pawnId], create_new_entry(animId, suffix, desc))

		self.events.onPawnAnimationAdded:dispatch(pawnId, animId, suffix)
	else
		Assert.TypePoint(loc, "Argument #1")

		local pid = point2index(loc)
		m.lmn_tileAnims = m.lmn_tileAnims or {}
		m.lmn_tileAnims[pid] = m.lmn_tileAnims[pid] or {}
		table.insert(m.lmn_tileAnims[pid], create_new_entry(animId, suffix, desc))

		self.events.onTileAnimationAdded:dispatch(loc, animId, suffix)
	end
end


local function rem(self, loc, animId, suffix)
	mission = GetCurrentMission()
	if not mission then return end

	Assert.Equals('table', type(self), "Check for . vs :")
	Assert.Equals('string', type(animId), "Argument #2")
	Assert.Equals('table', type(ANIMS[animId]), "Animation '"..animId.."' does not exist")
	Assert.Equals({'nil', 'string'}, type(suffix), "Argument #3")

	suffix = suffix or ""

	if type(loc) == 'number' then
		local pawnId = loc
		mission.lmn_pawnAnims = mission.lmn_pawnAnims or {}
		mission.lmn_pawnAnims[pawnId] = mission.lmn_pawnAnims[pawnId] or {}

		local index = list_find(mission.lmn_pawnAnims[pawnId], "id", animId..suffix)
		if index ~= -1 then
			table.remove(mission.lmn_pawnAnims[pawnId], index)
			self.events.onPawnAnimationRemoved:dispatch(pawnId, animId, suffix)
		end
	else
		Assert.TypePoint(loc, "Argument #1")

		local pid = point2index(loc)
		mission.lmn_tileAnims = mission.lmn_tileAnims or {}
		mission.lmn_tileAnims[pid] = mission.lmn_tileAnims[pid] or {}

		local index = list_find(mission.lmn_tileAnims[pid], "id", animId..suffix)
		if index ~= -1 then
			table.remove(mission.lmn_tileAnims[pid], index)
			self.events.onTileAnimationRemoved:dispatch(loc, animId, suffix)
		end
	end
end


local function get(self, loc, animId, suffix)
	mission = GetCurrentMission()
	if not mission then return end

	Assert.Equals('table', type(self), "Check for . vs :")
	Assert.Equals('string', type(animId), "Argument #2")
	Assert.Equals('table', type(ANIMS[animId]), "Animation '"..animId.."' does not exist")
	Assert.Equals({'nil', 'string'}, type(suffix), "Argument #3")

	suffix = suffix or ""

	if type(loc) == 'number' then
		local pawnId = loc
		mission.lmn_pawnAnims = mission.lmn_pawnAnims or {}
		mission.lmn_pawnAnims[pawnId] = mission.lmn_pawnAnims[pawnId] or {}

		local index = list_find(mission.lmn_pawnAnims[pawnId], "id", animId..suffix)
		if index ~= -1 then
			return mission.lmn_pawnAnims[pawnId][index]
		end

		return nil
	else
		Assert.TypePoint(loc, "Argument #1")

		local pid = point2index(loc)
		mission.lmn_tileAnims = mission.lmn_tileAnims or {}
		mission.lmn_tileAnims[pid] = mission.lmn_tileAnims[pid] or {}

		local index = list_find(mission.lmn_tileAnims[pid], "id", animId..suffix)
		if index ~= -1 then
			return mission.lmn_tileAnims[pid][index]
		end

		return nil
	end
end


local function createAnim(id, animId)
	local base = ANIMS[animId]

	-- chop up animation to single frame units.
	if not ANIMS[PREFIX_ANIM..id] then
		local frames = base.Frames
		local lengths = base.Lengths

		if not frames then
			frames = {}
			for i = 1, base.NumFrames do
				frames[i] = i - 1
			end
		end

		if not lengths then
			lengths = {}
			for i = 1, #frames do
				lengths[i] = base.Time
			end
		end

		for i, frame in ipairs(frames) do
			local prefix = string.format(PREFIX, i)
			ANIMS[prefix..id] = base:new{
				__NumFrames = #frames,
				__Lengths = lengths,
				__SumLengths = sum_list(lengths),
				Frames = { frame },
				Lengths = nil,
				Loop = false,
				Time = 0.0,
			}
		end
	end
end


local function updateAnims(loc, anims, time_now)
	if Board:IsValid(loc) then
		for _, entry in ipairs(anims) do
			createAnim(entry.id, entry.animId)
			local anim = ANIMS[PREFIX_ANIM..entry.id]

			-- Wrap time to be within the length of the full animation
			time_now = (entry.time_start + time_now) % anim.__SumLengths

			local frame_end_time = 0
			for i = 1, anim.__NumFrames do
				frame_end_time = frame_end_time + anim.__Lengths[i]
				if frame_end_time > time_now or i == anim.__NumFrames then
					local prefix = string.format(PREFIX, i)
					Board:AddAnimation(loc, prefix..entry.id, ANIM_NO_DELAY)
					break
				end
			end
		end
	end
end


local function updateDesc(loc, anims)
	if Board:IsValid(loc) then
		for _, entry in ipairs(anims) do
			if entry.title and entry.desc then

				local tooltipId = PREFIX_ANIM..entry.animId
				if not TILE_TOOLTIPS[tooltipId] then
					TILE_TOOLTIPS[tooltipId] = {entry.title, entry.desc}
				end

				Board:MarkSpaceDesc(loc, tooltipId)
			end
		end
	end
end


local function onMissionUpdate(mission)
	local mission = GetCurrentMission()
	if not mission or not Board then return end

	mission.lmn_pawnAnims = mission.lmn_pawnAnims or {}
	mission.lmn_tileAnims = mission.lmn_tileAnims or {}

	local t = os.clock()
	local rem = {}

	for pawnId, anims in pairs(mission.lmn_pawnAnims) do

		local pawn = Board:GetPawn(pawnId)
		if pawn then
			updateAnims(pawn:GetSpace(), anims, t)
		else
			rem[#rem+1] = pawnId
		end
	end

	for pid, anims in pairs(mission.lmn_tileAnims) do
		updateAnims(index2point(pid), anims, t)
	end

	for i = #rem, 1, -1 do
		table.remove(mission.lmn_pawnAnims, #rem)
	end

	mission.lmn_pawnAnims = mission.lmn_pawnAnims or {}
	mission.lmn_tileAnims = mission.lmn_tileAnims or {}

	for pawnId, anims in pairs(mission.lmn_pawnAnims) do
		local pawn = Board:GetPawn(pawnId)
		if pawn then
			updateDesc(pawn:GetSpace(), anims)
		end
	end

	for pid, anims in pairs(mission.lmn_tileAnims) do
		updateDesc(index2point(pid), anims)
	end
end


local function initEvents()
	CustomAnim.events = CustomAnim.events or {}

	for _, eventId in ipairs(EVENTS) do
		if CustomAnim.events[eventId] == nil then
			CustomAnim.events[eventId] = Event()
		end
	end
end


local function finalizeInit(self)
	modApi.events.onMissionUpdate:subscribe(onMissionUpdate)

	self.add = add
	self.rem = rem
	self.get = get
end


local function onModsInitialized()
	local isHighestVersion = true
		and CustomAnim.initialized ~= true
		and CustomAnim.version == VERSION

	if isHighestVersion then
		CustomAnim:finalizeInit()
		CustomAnim.initialized = true
	end
end


local isNewerVersion = false
	or CustomAnim == nil
	or VERSION > CustomAnim.version


if isNewerVersion then
	CustomAnim = CustomAnim or {}
	CustomAnim.version = VERSION
	CustomAnim.finalizeInit = finalizeInit

	modApi.events.onModsInitialized:subscribe(onModsInitialized)

	initEvents()
end


return CustomAnim
