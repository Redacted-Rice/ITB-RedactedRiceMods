modApi:addPalette({
		ID = "worldbuilders_color",
		Name = "Earthbound",
		Image = "img/units/player/wb_eater_ns.png",
		PlateHighlight = { 220, 60, 70 }, -- dusty light, like cracked stone
		PlateLight     = { 91, 81, 65 },  -- sandstone / soil highlight
		PlateMid       = { 71, 62, 52 },   -- muted earth midtone
		PlateDark      = { 57, 49, 47 },    -- deep rock shadow
		PlateOutline   = { 2, 2, 1 },    -- outline, basalt-like
		PlateShadow    = { 42, 37, 39 },    -- shadow, ash brown
		BodyColor      = { 99, 91, 79 },  -- body mid, soil/rock
		BodyHighlight  = { 160, 156, 145 },  -- body light, clay tone
})
modApi:getPaletteImageOffset("worldbuilders_color")