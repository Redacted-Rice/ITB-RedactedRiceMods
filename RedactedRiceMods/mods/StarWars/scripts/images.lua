local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath

--Weapons
modApi:appendAsset("img/weapons/brute_sw_paired_cannons.png",   resourcePath .. "img/weapons/brute_sw_paired_cannons.png")
modApi:appendAsset("img/weapons/brute_sw_proton_torpedo.png",   resourcePath .. "img/weapons/brute_sw_proton_torpedo.png")
modApi:appendAsset("img/weapons/brute_sw_quad_cannons.png",     resourcePath .. "img/weapons/brute_sw_quad_cannons.png")
modApi:appendAsset("img/weapons/science_sw_cannon_turrets.png", resourcePath .. "img/weapons/science_sw_cannon_turrets.png")
--modApi:appendAsset("img/weapons/passives/passive_wb_move.png",  resourcePath .. "img/weapons/passives/passive_wb_move.png")

--modApi:appendAssets("img/weapons/", "img/weapons/")
modApi:appendAssets("img/effects/", "img/effects/")