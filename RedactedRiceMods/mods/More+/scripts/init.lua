local mod = {
	id = "redactedrice_More+",
	name = "More Lvl Up Skills",
	icon = "mod_icon.png",
	version = "2.2.1",
	modApiVersion = "2.9.5",
	gameVersion = "1.2.93",
	dependencies = {
        redactedrice_memhack = "1.3.0",
        redactedrice_cplus_plus = "1.3.1",
    }
}

function mod:init()
	local more_plus = require(self.scriptPath .. "more_plus")
	-- Common Redacted Rice Libs
	for libId, lib in pairs(mod_loader.mods.redactedrice_libs.libs) do
		more_plus.libs[libId] = lib
	end

	more_plus:init()

	-- Add config option to reset weapon preview tooltips
	modApi:addGenerationOption(
		"resetWeaponPreviewTooltips",
		"Reset Weapon Preview Tips",
		"Check to reset the tutorial tips for weapon preview effects (multi-icon and description tooltips).",
		{ enabled = false }
	)
end

function mod:load(options, version)
	more_plus:load()

	-- Reset weapon preview tooltips if requested
	if options.resetWeaponPreviewTooltips and options.resetWeaponPreviewTooltips.enabled then
		-- Initialize tutorial tips with weapon preview lib to clear that field
		local tutorialTips = more_plus.libs["tutorialTips"]:Init("WeaponPreviewLib")
		tutorialTips:Reset("WeaponPreview_MultiIconNotification")
		tutorialTips:Reset("WeaponPreview_DescriptionNotification")
		options.resetWeaponPreviewTooltips.enabled = false
	end
end

return mod