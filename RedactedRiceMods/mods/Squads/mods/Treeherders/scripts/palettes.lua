modApi:addPalette({
		ID = "treeherders_color",
		Name = "Forest Green",
		Image = "img/units/player/th_entborg_ns.png",
		PlateHighlight = { 144, 244, 255 },	--lights
		PlateLight     = { 120, 151,  75 },	--main highlight
		PlateMid       = {  77,  99,  56 },	--main light
		PlateDark      = {  43,  58,  28 },	--main mid
		PlateOutline   = {  28,  21,  14 },	--main dark
		PlateShadow    = {  53,  35,  19 },	--metal dark
		BodyColor      = {  102, 68,  40 },	--metal mid
		BodyHighlight  = {  163, 112, 71 },	--metal light
})
modApi:getPaletteImageOffset("treeherders_color")