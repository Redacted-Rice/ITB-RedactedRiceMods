
local selected = nil

local function onPawnSelected(pawn)
	selected = pawn
end

local function onPawnDeselected(pawn)
	selected = nil
end

modApi.events.onPawnSelected:subscribe(onPawnSelected)
modApi.events.onPawnDeselected:subscribe(onPawnDeselected)
modApi.events.onGameExited:subscribe(onPawnDeselected)

local function getSelectedPawn()
	return selected
end

local function isPawnSelected(pawn)
	if pawn == nil then
		return selected == nil
	end

	return selected and pawn:GetId() == selected:GetId()
end

return {
	getSelectedPawn = getSelectedPawn,
	isPawnSelected = isPawnSelected
}
