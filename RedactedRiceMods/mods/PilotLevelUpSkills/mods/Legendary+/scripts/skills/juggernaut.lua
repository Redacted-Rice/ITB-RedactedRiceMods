return {
	id = "RrJuggernaut",
	name = "Juggernaut",
	description = "+5 HP.",
	bonuses = {health = 5},
	constraints = {
		groups = { cplus_plus_ex.GROUPS.ADD_HEALTH, },
		pilotExclusions = {"Pilot_Zoltan", "Pilot_Rock"},
	},
	reusabilityLimit = cplus_plus_ex.REUSABLILITY.REUSABLE,
}