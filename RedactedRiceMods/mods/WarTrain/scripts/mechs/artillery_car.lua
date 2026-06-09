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

addDirectionalAnim("wartrain_artillery_car", {
	base = {posX = -17, posY = -5},
})
addDirectionalAnim("wartrain_artillery_car_dir0", {
	base = {posX = -17, posY = -5},
	--a = {posX = -17, posY = -5},
	_broken = {posX = -17, posY = -5},
	w_broken = {posX = -17, posY = -5},
	_ns = {posX = -17, posY = -5},
})
addDirectionalAnim("wartrain_artillery_car_dir1", {
	base = {posX = -17, posY = -5},
	--a = {posX = -17, posY = -5},
	_broken = {posX = -17, posY = -5},
	w_broken = {posX = -17, posY = -5},
	_ns = {posX = -17, posY = -5},
})
addDirectionalAnim("wartrain_artillery_car_dir2", {
	base = {posX = -17, posY = -5},
	--a = {posX = -17, posY = -5},
	_broken = {posX = -17, posY = -5},
	w_broken = {posX = -17, posY = -5},
	_ns = {posX = -17, posY = -5},
})
addDirectionalAnim("wartrain_artillery_car_dir3", {
	base = {posX = -17, posY = -5},
	--a = {posX = -17, posY = -5},
	_broken = {posX = -17, posY = -5},
	w_broken = {posX = -17, posY = -5},
	_ns = {posX = -17, posY = -5},
})

WarTrain_ArtilleryCarMech = Pawn:new{
	Name = "Artillery Car",
	Class = "Ranged",
	Health = 2,
	MoveSpeed = 0,
	Image = "wartrain_artillery_car",
	ImageOffset = modApi:getPaletteImageOffset("wartrain_color"),
	SkillList = {"Ranged_Artillerymech"},
	SoundLocation = "/mech/distance/artillery/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	TrainPawnType = "car",
	TrainPawnEnginelessSpeed = 2,
}
