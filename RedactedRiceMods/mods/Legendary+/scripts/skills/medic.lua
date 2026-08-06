local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrMedic",
	name = "Medic",
	description = "When moving, mark your origin tile; a repair pad is placed there at end of turn.",
	constraints = {
		groups = {legendary_plus.GROUPS.ITEM_DROP},
	},
	reusabilityLimit = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false

legendary_plus:addCustomTraitIcon(customSkill)

local MARKER_TOOLTIP = "rr_lp_RrMedic_drop"
TILE_TOOLTIPS[MARKER_TOOLTIP] = {
	"Repair Pad",
	"A repair pad will be placed here at end of turn.",
}

local MOVE_DROP_CONFIG = {
	itemId = "Item_Repair_Mine",
	markerIcon = "advanced/combat/healtile_on.png",
	markerTooltip = MARKER_TOOLTIP,
}

function customSkill:setupEffect()
	legendary_plus.moveDrop:setupSkillEffect(customSkill, MOVE_DROP_CONFIG)
end

return customSkill
