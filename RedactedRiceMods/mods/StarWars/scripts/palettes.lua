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

modApi:addPalette({
		ID = "starwars_empire_color",
		Name = "Empire",
		Image = "img/units/player/wb_eater_ns.png",
		PlateHighlight = { 200, 50, 50 },	--lights
		PlateLight     = { 180, 180, 180 },	--main highlight
		PlateMid       = { 100, 100, 100 },	--main light
		PlateDark      = {  40,  40,  40 },	--main mid
		PlateOutline   = {  10,  10,  10 },	--main dark
		PlateShadow    = {  30,  30,  30 },	--metal dark
		BodyColor      = {  60,  60,  60 },	--metal mid
		BodyHighlight  = { 120,  50,  50 },	--metal light
})
modApi:getPaletteImageOffset("starwars_empire_color")