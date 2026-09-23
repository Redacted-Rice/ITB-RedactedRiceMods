local Treeherders_ResourcePath = mod_loader.mods[modApi.currentMod].resourcePath

--Weapons
modApi:appendAsset("img/weapons/ranged_th_forestFirer.png",            Treeherders_ResourcePath .. "img/weapons/ranged_th_forestFirer.png")
modApi:appendAsset("img/weapons/prime_th_treevenge.png",               Treeherders_ResourcePath .. "img/weapons/prime_th_treevenge.png")
modApi:appendAsset("img/weapons/prime_th_summonTheAncients.png",               Treeherders_ResourcePath .. "img/weapons/prime_th_summonTheAncients.png")
modApi:appendAsset("img/weapons/science_th_violentGrowth.png",         Treeherders_ResourcePath .. "img/weapons/science_th_violentGrowth.png")
modApi:appendAsset("img/weapons/passives/passive_th_forestArmor.png",  Treeherders_ResourcePath .. "img/weapons/passives/passive_th_forestArmor.png")


--Effect Icons
modApi:appendAsset("img/combat/icons/icon_forestArmor.png", Treeherders_ResourcePath.."img/combat/icons/icon_forestArmor.png")
modApi:appendAsset("img/combat/icons/icon_forestArmor_glow.png", Treeherders_ResourcePath.."img/combat/icons/icon_forestArmor_glow.png")
Location["combat/icons/icon_forestArmor.png"] = Point(-12, 25)
Location["combat/icons/icon_forestArmor_glow.png"] = Location["combat/icons/icon_forestArmor.png"]

modApi:appendAsset("img/combat/icons/icon_forestArmor_ancient.png", Treeherders_ResourcePath.."img/combat/icons/icon_forestArmor_ancient.png")
modApi:appendAsset("img/combat/icons/icon_forestArmor_ancient_glow.png", Treeherders_ResourcePath.."img/combat/icons/icon_forestArmor_ancient_glow.png")
Location["combat/icons/icon_forestArmor_ancient.png"] = Location["combat/icons/icon_forestArmor.png"]
Location["combat/icons/icon_forestArmor_ancient_glow.png"] = Location["combat/icons/icon_forestArmor_ancient.png"]

modApi:appendAsset("img/combat/icons/icon_forestArmor_treevac.png", Treeherders_ResourcePath.."img/combat/icons/icon_forestArmor_treevac.png")
modApi:appendAsset("img/combat/icons/icon_forestArmor_treevac_glow.png", Treeherders_ResourcePath.."img/combat/icons/icon_forestArmor_treevac_glow.png")
Location["combat/icons/icon_forestArmor_treevac.png"] = Location["combat/icons/icon_forestArmor.png"]
Location["combat/icons/icon_forestArmor_treevac_glow.png"] = Location["combat/icons/icon_forestArmor.png"]

modApi:appendAsset("img/combat/icons/damage_floraform.png", Treeherders_ResourcePath.."img/combat/icons/damage_floraform.png")
Location["combat/icons/damage_floraform.png"] = Point(-12, 21)

modApi:appendAsset("img/combat/icons/damage_floraform_ancient.png", Treeherders_ResourcePath.."img/combat/icons/damage_floraform_ancient.png")
Location["combat/icons/damage_floraform_ancient.png"] = Location["combat/icons/damage_floraform.png"]

modApi:appendAsset("img/combat/icons/icon_th_forest_burn_cover.png", Treeherders_ResourcePath.."img/combat/icons/icon_th_forest_burn_cover.png")
Location["combat/icons/icon_th_forest_burn_cover.png"] = Location["combat/icons/icon_forestArmor.png"]

modApi:appendAsset("img/combat/icons/icon_th_ancientForest_burn_cover.png", Treeherders_ResourcePath.."img/combat/icons/icon_th_ancientForest_burn_cover.png")
Location["combat/icons/icon_th_ancientForest_burn_cover.png"] = Location["combat/icons/icon_forestArmor.png"]


--Projectiles
modApi:appendAsset("img/effects/shotup_th_deadtree.png", Treeherders_ResourcePath.."img/effects/shotup_th_deadtree.png")
modApi:appendAsset("img/effects/shotup_th_deadtree_3.png", Treeherders_ResourcePath.."img/effects/shotup_th_deadtree_3.png")
Location["effects/shotup_th_deadtree.png"] = Point(-30, 30) --changing these doesn't appear to do anything for projectiles...
Location["effects/shotup_th_deadtree_3.png"] = Point(-30, 30) --changing these doesn't appear to do anything for projectiles...