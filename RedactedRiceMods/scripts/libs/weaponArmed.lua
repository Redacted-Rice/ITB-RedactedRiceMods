
--[[

	Weapon Armed v2.1 - code library by Lemonymous


	events:
		.events.onWeaponArmed
		.events.onWeaponUnarmed

	methods:
		.getArmedWeapon
		.isWeaponArmed
		.isAnyWeaponArmed

	examples:
		local mod = mod_loader.mods[modApi.currentMod]
		local scriptPath = mod.scriptPath
		local weaponArmed = require(scriptPath.."libs/weaponArmed")

		weaponArmed.events.onWeaponArmed:subscribe(function(skill, pawnId)
			local pawn = Game:GetPawn(pawnId)
			LOGF("Pawn %s armed weapon %s",
				tostring(pawn:GetMechName()),
				tostring(skill.__Id)
			)
		end)

		weaponArmed.events.onWeaponUnarmed:subscribe(function(skill, pawnId)
			-- A weapon can be unarmed from exiting to main menu,
			-- so pawn might not exist.
			local pawn = Game and Game:GetPawn(pawnId) or nil
			LOGF("Pawn %s unarmed weapon %s",
				tostring(pawn and pawn:GetMechName() or nil),
				tostring(skill.__Id)
			)
		end)

		local armedWeapon = weaponArmed:getArmedWeapon()
		LOGF("Current armed weapon is %s", tostring(armedWeapon))

		local isWeaponArmed = weaponArmed:isWeaponArmed(Prime_Punchmech)
		LOGF("Prime_Punchmech is armed is %s", tostring(isWeaponArmed))

		local isAnyWeaponArmed = weaponArmed:isAnyWeaponArmed()
		LOGF("Any weapon is armed is %s", tostring(isAnyWeaponArmed))

]]

local lib = {
	events = {
		onWeaponArmed = Event(),
		onWeaponUnarmed = Event()
	}
}

local armedWeaponCurrent = nil
local armedWeaponLast = nil
local selectedPawnIdCurrent = nil
local selectedPawnIdLast = nil

function lib:getArmedWeapon()
	return armedWeaponLast, selectedPawnIdLast
end

function lib:isWeaponArmed(skill)
	return armedWeaponLast == skill
end

function lib:isAnyWeaponArmed()
	return armedWeaponLast ~= nil
end

modApi.events.onFrameDrawStart:subscribe(function()
	if Board then
		selectedPawnIdCurrent = Board:GetSelectedPawnId()
		if selectedPawnIdCurrent then
			armedWeaponCurrent = Board:GetPawn(selectedPawnIdCurrent):GetArmedWeapon()
			armedWeaponCurrent = armedWeaponCurrent and _G[armedWeaponCurrent] or nil
		else
			armedWeaponCurrent = nil
		end
	else
		selectedPawnIdCurrent = nil
		armedWeaponCurrent = nil
	end

	if selectedPawnIdCurrent ~= selectedPawnIdLast or armedWeaponCurrent ~= armedWeaponLast then
		if armedWeaponLast then
			lib.events.onWeaponUnarmed:dispatch(armedWeaponLast, Game and selectedPawnIdLast or nil)
		end

		if armedWeaponCurrent then
			lib.events.onWeaponArmed:dispatch(armedWeaponCurrent, selectedPawnIdCurrent)
		end
	end

	armedWeaponLast = armedWeaponCurrent
	selectedPawnIdLast = selectedPawnIdCurrent
end)

return lib
