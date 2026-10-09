local WorldBuilders_ResourcePath = mod_loader.mods[modApi.currentMod].resourcePath

--Weapons
modApi:appendAsset("img/weapons/prime_wb_mold.png",    WorldBuilders_ResourcePath .. "img/weapons/prime_wb_mold.png")
modApi:appendAsset("img/weapons/brute_wb_consume.png", WorldBuilders_ResourcePath .. "img/weapons/brute_wb_consume.png")
modApi:appendAsset("img/weapons/science_wb_shift.png", WorldBuilders_ResourcePath .. "img/weapons/science_wb_shift.png")
modApi:appendAsset("img/weapons/passives/passive_wb_move.png",  WorldBuilders_ResourcePath .. "img/weapons/passives/passive_wb_move.png")

modApi:appendAsset("img/combat/tile_icon/tile_wb_shift.png", WorldBuilders_ResourcePath.."img/combat/tile_icon/tile_wb_shift.png")
Location["combat/tile_icon/tile_wb_shift.png"] = Point(-27,2)

modApi:appendAsset("img/combat/icons/icon_wb_emerge_a.png", WorldBuilders_ResourcePath.."img/combat/icons/icon_wb_emerge_a.png")
ANIMS["icon_wb_emerge_a"] = ANIMS.Animation:new{
	Image = "combat/icons/icon_wb_emerge_a.png",
	NumFrames = 10,
	Time = 0.25,
	PosX = -20,
	PosY = -1
}

modApi:appendAsset("img/combat/icons/icon_wb_all_terrain.png", WorldBuilders_ResourcePath.."img/combat/icons/icon_wb_all_terrain.png")

modApi:appendAsset("img/combat/icons/icon_wb_rock.png", WorldBuilders_ResourcePath.."img/combat/icons/icon_wb_rock.png")
Location["combat/icons/icon_wb_rock.png"] = Point(-2, 8)
modApi:appendAsset("img/combat/icons/icon_wb_mountain.png", WorldBuilders_ResourcePath.."img/combat/icons/icon_wb_mountain.png")
Location["combat/icons/icon_wb_mountain.png"] = Point(0, 8)

modApi:appendAsset("img/combat/icons/icon_wb_unknown_item.png", WorldBuilders_ResourcePath.."img/combat/icons/icon_wb_unknown_item.png")
Location["combat/icons/icon_wb_unknown_item.png"] = Point(-2, 8)