return {
	id = "RrProdigy",
	name = "Prodigy",
	description = "+1 Reactor, +1 Move, +2 HP.",
	bonuses = {cores = 1, move = 1, health = 2},
	constraints = {
		groups = {
			legendary_plus.GROUPS.ADD_HEALTH,
			legendary_plus.GROUPS.ADD_MOVE,
			legendary_plus.GROUPS.ADD_REACTOR,
		},
		pilotExclusions = {"Pilot_Zoltan", "Pilot_Rock"},
	},
	reusabilityLimit = cplus_plus_ex.REUSABLILITY.REUSABLE,
}
