return {
	id = "RrProdigy",
	name = "Prodigy",
	description = "+1 Reactor, +1 Move, +2 HP.",
	bonuses = {cores = 1, move = 1, health = 2},
	constraints = {
		groups = {
			cplus_plus_ex.GROUPS.ADD_HEALTH,
			cplus_plus_ex.GROUPS.ADD_MOVE,
			PlusHelper.GROUPS.ADD_REACTOR,
		},
		pilotExclusions = {"Pilot_Zoltan", "Pilot_Rock"},
	},
	reusabilityLimit = cplus_plus_ex.REUSABLILITY.REUSABLE,
}
