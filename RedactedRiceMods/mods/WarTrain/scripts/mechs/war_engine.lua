local function addDirectionalAnim(animId, variants)
	for variantSuffix, vals in pairs(variants) do
		local suffix = variantSuffix
		if suffix == "base" then
			suffix = ""
		end
		local name = animId .. suffix
		local posX = vals.PosX or 0
		local posY = vals.PosY or 0
		local numFrames = vals.NumFrames or 1
		ANIMS[name] = ANIMS.MechUnit:new{Image = "units/player/" .. name .. ".png", PosX = posX, PosY = posY, NumFrames = numFrames }
	end
end

addDirectionalAnim("wartrain_war_engine", {
	base = {posX = -17, posY = -5},
})
addDirectionalAnim("wartrain_war_engine_dir0", {
	base = {posX = -17, posY = -5},
	--a = {posX = -17, posY = -5},
	_broken = {posX = -17, posY = -5},
	w_broken = {posX = -17, posY = -5},
	_ns = {posX = -17, posY = -5},
})
addDirectionalAnim("wartrain_war_engine_dir1", {
	base = {posX = -17, posY = -5},
	--a = {posX = -17, posY = -5},
	_broken = {posX = -17, posY = -5},
	w_broken = {posX = -17, posY = -5},
	_ns = {posX = -17, posY = -5},
})
addDirectionalAnim("wartrain_war_engine_dir2", {
	base = {posX = -17, posY = -5},
	--a = {posX = -17, posY = -5},
	_broken = {posX = -17, posY = -5},
	w_broken = {posX = -17, posY = -5},
	_ns = {posX = -17, posY = -5},
})
addDirectionalAnim("wartrain_war_engine_dir3", {
	base = {posX = -17, posY = -5},
	--a = {posX = -17, posY = -5},
	_broken = {posX = -17, posY = -5},
	w_broken = {posX = -17, posY = -5},
	_ns = {posX = -17, posY = -5},
})

WarTrain_WarEngineMech = Pawn:new{
	Name = "War Engine",
	Class = "Prime",
	Health = 3,
	MoveSpeed = 4,
	Image = "wartrain_war_engine",
	ImageOffset = modApi:getPaletteImageOffset("wartrain_color"),
	SkillList = { "WarTrain_RammingSpeed" },
	SoundLocation = "/mech/prime/punch_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	Armor = true,
	TrainPawnType = "engine",
}
