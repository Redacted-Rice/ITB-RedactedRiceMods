local Treeherders_ResourcePath = mod_loader.mods[modApi.currentMod].resourcePath

--Weapons
modApi:appendAsset("img/weapons/ranged_th_forestFirer.png",            Treeherders_ResourcePath .. "img/weapons/ranged_th_forestFirer.png")
modApi:appendAsset("img/weapons/prime_th_treevenge.png",               Treeherders_ResourcePath .. "img/weapons/prime_th_treevenge.png")
modApi:appendAsset("img/weapons/science_th_violentGrowth.png",         Treeherders_ResourcePath .. "img/weapons/science_th_violentGrowth.png")
modApi:appendAsset("img/weapons/passives/passive_th_forestArmor.png",  Treeherders_ResourcePath .. "img/weapons/passives/passive_th_forestArmor.png")


--Effect Icons
local oldGetStatusTooltip = GetStatusTooltip

local forestArmorDescription = "Weapon damage to this unit is reduced by 1."
local forestArmorTreevacDescriptionP1 = "\n"..forestArmorDescription.." When attacked, this unit will be pushed in the "
local forestArmorTreevacDescriptionP2 = " direction before catching fire (prefs rel. to atk: right, left, same, oppo.)"

local forestArmorName = "Forest Armor"
local forestArmorTreevacName = forestArmorName.." +\nTree-vacuate"

function GetStatusTooltip(id)
	if id == "forestArmor" then
		return {forestArmorName, forestArmorDescription.." All other damage (Push, Blocking, Fire, etc.) is unaffected."};
	elseif id == "forestArmor_treevac" then
		return {forestArmorTreevacName, "\n"..forestArmorDescription.." If damaged this unit is pushed to an adjacent tile before catching fire (prefs rel. to atk: right, left, same, oppo.)" };
	elseif id == "forestArmor_push_0" then
		return {forestArmorTreevacName, forestArmorTreevacDescriptionP1.."up-right"..forestArmorTreevacDescriptionP2 };
	elseif id == "forestArmor_push_1" then
		return {forestArmorTreevacName, forestArmorTreevacDescriptionP1.."down-right"..forestArmorTreevacDescriptionP2 };
	elseif id == "forestArmor_push_2" then
		return {forestArmorTreevacName, forestArmorTreevacDescriptionP1.."down-left"..forestArmorTreevacDescriptionP2 };
	elseif id == "forestArmor_push_3" then
		return {forestArmorTreevacName, forestArmorTreevacDescriptionP1.."up-left"..forestArmorTreevacDescriptionP2 };
	else
		return oldGetStatusTooltip(id)
	end
end

modApi:appendAsset("img/combat/icons/icon_forestArmor.png", Treeherders_ResourcePath.."img/combat/icons/icon_forestArmor.png")
modApi:appendAsset("img/combat/icons/icon_forestArmor_glow.png", Treeherders_ResourcePath.."img/combat/icons/icon_forestArmor_glow.png")
Location["combat/icons/icon_forestArmor.png"] = Point(-12, 22)
Location["combat/icons/icon_forestArmor_glow.png"] = Location["combat/icons/icon_forestArmor.png"]

modApi:appendAsset("img/combat/icons/icon_forestArmor_treevac.png", Treeherders_ResourcePath.."img/combat/icons/icon_forestArmor_treevac.png")
modApi:appendAsset("img/combat/icons/icon_forestArmor_treevac_glow.png", Treeherders_ResourcePath.."img/combat/icons/icon_forestArmor_treevac_glow.png")
Location["combat/icons/icon_forestArmor_treevac.png"] = Location["combat/icons/icon_forestArmor.png"]
Location["combat/icons/icon_forestArmor_treevac_glow.png"] = Location["combat/icons/icon_forestArmor.png"]
--load the directional icons
for i = 1, 4 do
	local dir = i - 1
	modApi:appendAsset("img/combat/icons/icon_forestArmor_push_"..dir..".png", Treeherders_ResourcePath.."img/combat/icons/icon_forestArmor_push_"..dir..".png")
	modApi:appendAsset("img/combat/icons/icon_forestArmor_push_"..dir.."_glow.png", Treeherders_ResourcePath.."img/combat/icons/icon_forestArmor_push_"..dir.."_glow.png")
	Location["combat/icons/icon_forestArmor_push_"..dir..".png"] = Location["combat/icons/icon_forestArmor.png"]
	Location["combat/icons/icon_forestArmor_push_"..dir.."_glow.png"] = Location["combat/icons/icon_forestArmor.png"]
end

modApi:appendAsset("img/combat/icons/damage_floraform.png", Treeherders_ResourcePath.."img/combat/icons/damage_floraform.png")
Location["combat/icons/damage_floraform.png"] = Point(-12, 22)

modApi:appendAsset("img/combat/icons/icon_th_forest_burn_cover.png", Treeherders_ResourcePath.."img/combat/icons/icon_th_forest_burn_cover.png")
Location["combat/icons/icon_th_forest_burn_cover.png"] = Point(-12, 22)


--Projectiles
modApi:appendAsset("img/effects/shotup_th_deadtree.png", Treeherders_ResourcePath.."img/effects/shotup_th_deadtree.png")
modApi:appendAsset("img/effects/shotup_th_deadtree_3.png", Treeherders_ResourcePath.."img/effects/shotup_th_deadtree_3.png")
Location["effects/shotup_th_deadtree.png"] = Point(-30, 30) --changing these doesn't appear to do anything for projectiles...
Location["effects/shotup_th_deadtree_3.png"] = Point(-30, 30) --changing these doesn't appear to do anything for projectiles...