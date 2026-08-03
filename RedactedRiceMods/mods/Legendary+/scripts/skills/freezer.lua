local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrFreezer",
	name = "Freezer",
	description = "When moving, mark your origin tile; a freeze mine is placed there at end of turn.",
	constraints = {
		groups = {legendary_plus.GROUPS.ITEM_DROP},
	},
	reusabilityLimit = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false

legendary_plus:addCustomTraitIcon(customSkill)

local MARKER_TOOLTIP = "rr_lp_RrFreezer_drop"
TILE_TOOLTIPS[MARKER_TOOLTIP] = {
	"Freeze Mine",
	"A freeze mine will be placed here at end of turn.",
}

local MOVE_DROP_CONFIG = {
	itemId = "Freeze_Mine",
	markerIcon = "combat/icons/icon_frozenmine_glow.png",
	markerTooltip = MARKER_TOOLTIP,
}

function customSkill:setupEffect()
	legendary_plus.moveDrop:setupSkillEffect(customSkill, MOVE_DROP_CONFIG)
end

return customSkill
