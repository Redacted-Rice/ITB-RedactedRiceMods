return {
	id = "RrJuggernaut",
	name = "Juggernaut",
	description = "+5 HP.",
	bonuses = {health = 5},
	constraints = {
		groups = { legendary_plus.GROUPS.ADD_HEALTH, },
		pilotExclusions = {"Pilot_Zoltan", "Pilot_Rock"},
	},
}