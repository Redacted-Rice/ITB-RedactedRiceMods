modApi:addPalette({
		ID = "starwars_rebels_color",
		Name = "Rebels",
		Image = "img/units/player/wb_eater_ns.png",
		PlateHighlight = { 150, 200, 255 },	--lights
		PlateLight     = { 200, 190,  180 },	--main highlight
		PlateMid       = { 125, 120,  115 },	--main light
		PlateDark      = {  70,  68,  65 },	--main mid
		PlateOutline   = {  28,  21,  14 },	--main dark
		PlateShadow    = {  75,  55,  50 },	--metal dark
		BodyColor      = {  115, 70,  50 },	--metal mid
		BodyHighlight  = {  205, 85, 50 },	--metal light
})
modApi:getPaletteImageOffset("starwars_rebels_color")