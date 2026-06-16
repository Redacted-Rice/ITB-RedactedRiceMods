modApi:addPalette({
		ID = "starwars_rebels_color",
		Name = "Rebels",
		Image = "img/units/player/wb_eater_ns.png",
		PlateHighlight = { 150, 200, 255 },	--lights
		PlateLight     = { 200, 190, 180 }, --main highlight
		PlateMid       = { 125, 120, 115 }, --main light
		PlateDark      = {  70,  68,  65 },	--main mid
		PlateOutline   = {  28,  21,  14 },	--main dark
		PlateShadow    = {  75,  55,  50 },	--metal dark
		BodyColor      = {  115, 70,  50 },	--metal mid
		BodyHighlight  = {  205, 85,  50 },	--metal light
})
modApi:getPaletteImageOffset("starwars_rebels_color")

modApi:addPalette({
		ID = "starwars_empire_color",
		Name = "Empire",
		Image = "img/units/player/wb_eater_ns.png",
		PlateHighlight = { 211,  59,  59 },	--lights
		PlateLight     = { 163, 163, 163 },	--main highlight
		PlateMid       = {  76,  76,  76 },	--main light
		PlateDark      = {  47,  47,  47 },	--main mid
		PlateOutline   = {  10,  10,  10 },	--main dark
		PlateShadow    = {  25,  23,  20 },	--metal dark
		BodyColor      = {  45,  42,  36 },	--metal mid
		BodyHighlight  = {  79,  73,  62 },	--metal light
})
modApi:getPaletteImageOffset("starwars_empire_color")