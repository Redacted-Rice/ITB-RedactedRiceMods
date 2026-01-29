local mod = {
	id = "redactedrice_More+",
	name = "More Lvl Up Skills",
	icon = "mod_icon.png",
	version = "1.0.0",
	modApiVersion = "2.9.4",
	gameVersion = "1.2.93",
	dependencies = {
        redactedrice_memhack = "0.1.0", -- TBD
        redactedrice_cplus_plus = "0.1.0", -- TBD
    }
}

function mod:init()
	local more_plus = require(self.scriptPath .. "more_plus")
	more_plus:init()
end

function mod:load(options, version)
	more_plus:load()

end

return mod