
--[[
	small library providing functions to check when the menu is open and closed.
	menu is considered open outside of missions.
]]

local closed, nextClosed = false, false

local function isOpen()
	return not closed
end

local function isClosed()
	return closed
end

local function onFrameDrawStart()
	closed = nextClosed
	nextClosed = false
end

local function onMissionUpdate()
	nextClosed = true
end

modApi.events.onFrameDrawStart:subscribe(onFrameDrawStart)
modApi.events.onMissionUpdate:subscribe(onMissionUpdate)

return {
	isOpen = isOpen,
	isClosed = isClosed
}
