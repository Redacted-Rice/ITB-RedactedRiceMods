local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrTrapper",
	name = "Trapper",
	description = "When moving, mark your original tile for an explosive mine to be deployed at turn end.",
	constraints = {
		groups = {legendary_plus.GROUPS.ITEM_DROP},
	},
	reusabilityLimit = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false

legendary_plus:addCustomTraitIcon(customSkill)

local MARKER_TOOLTIP = "rr_lp_RrTrapper_drop"
TILE_TOOLTIPS[MARKER_TOOLTIP] = {
	"Explosive Mine",
	"An explosive mine will be placed here at end of turn.",
}

local MOVE_DROP_CONFIG = {
	itemId = "Item_Mine",
	markerIcon = "combat/mine.png",
	markerTooltip = MARKER_TOOLTIP,
}

function customSkill:setupEffect()
	legendary_plus.moveDrop:setupSkillEffect(customSkill, MOVE_DROP_CONFIG)
end

return customSkill
