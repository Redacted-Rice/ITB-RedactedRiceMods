
---------------------------------------------------------------------
-- Status effects v2.0 - code library
---------------------------------------------------------------------
-- A library that adds status effects to the game. Weapons and pilot skills can apply status effects.
-- See the wiki for info: https://github.com/Metalocif/Meta-s-Mods/wiki/Status-Library

-- We start by adding the status icons and animations.
-- Then, we overwrite scoring functions for Vek so that Blind/Confusion/Alluring/Targeted/Bloodthirsty can affect them.
-- Afterwards, we create the functions that apply each given status.
-- These typically check whether a pawn with the given ID exists and whether a mission is ongoing, then adds the ID to the status' table and an animation.
-- These tables are checked when relevant in the hooks below.

local VERSION = "2.0.0"

local isNewerVersion = false
    or Status == nil             -- First time loading
    or Status.version == nil     -- Existing version is unversioned
    or VERSION > Status.version  -- This file is newer than what's loaded


modApi:appendAssets("img/libs/status/", "img/libs/status/")

ANIMS.StatusBase = Animation:new{ Image = "", PosX = 0, PosY = 0, NumFrames = 1, Time = 1, Loop = true}
ANIMS.StatusAlluring = ANIMS.StatusBase:new{ Image = "libs/status/alluring.png", NumFrames = 4, Time = 0.3}
ANIMS.StatusBlind = ANIMS.StatusBase:new{ Image = "libs/status/blind.png"}
ANIMS.StatusBloodthirsty = ANIMS.StatusBase:new{ Image = "libs/status/bloodthirsty.png"}
ANIMS.StatusBonded = ANIMS.StatusBase:new{ Image = "libs/status/bonded.png"}
ANIMS.StatusBondedOff = ANIMS.StatusBase:new{ Image = "libs/status/bonded_off.png"}
ANIMS.StatusChill = ANIMS.StatusBase:new{ Image = "libs/status/chill.png", PosX = -10}
ANIMS.StatusConfusion = ANIMS.StatusBase:new{ Image = "libs/status/confusion.png", NumFrames = 2, Time = 0.5}
ANIMS.StatusDreadful = ANIMS.StatusBase:new{ Image = "libs/status/dreadful_icon.png"}
ANIMS.StatusDry = ANIMS.StatusBase:new{ Image = "libs/status/dry.png", NumFrames = 3, Time = 0.3}
ANIMS.StatusDodge1 = ANIMS.StatusBase:new{ Image = "libs/status/dodge1.png"}
ANIMS.StatusDodge2 = ANIMS.StatusBase:new{ Image = "libs/status/dodge2.png"}
ANIMS.StatusDodge3 = ANIMS.StatusBase:new{ Image = "libs/status/dodge3.png"}
ANIMS.StatusDoomed = ANIMS.StatusBase:new{ Image = "libs/status/doomed_icon.png"}
ANIMS.StatusGlory = ANIMS.StatusBase:new{ Image = "libs/status/glory_icon.png", PosX = -5}
ANIMS.StatusGunk = ANIMS.StatusBase:new{ Image = "libs/status/gunk.png", PosX = -5, NumFrames = 6}
ANIMS.StatusHemorrhage = ANIMS.StatusBase:new{ Image = "libs/status/hemorrhage.png", PosX = -5, PosY = 10, NumFrames = 6, Time = 0.2}
ANIMS.StatusLeechSeed = ANIMS.StatusBase:new{ Image = "libs/status/leechseed.png", PosX = -5, PosY = 5}
ANIMS.StatusNecrosis = ANIMS.StatusBase:new{ Image = "libs/status/necrosis_icon.png"}
ANIMS.StatusShatterburst = ANIMS.StatusBase:new{ Image = "libs/status/shatterburst.png"}
ANIMS.StatusShocked = ANIMS.StatusBase:new{ Image = "libs/status/shocked.png", PosX = -5, NumFrames = 4, Time = 0.15}
ANIMS.StatusSleep = ANIMS.StatusBase:new{ Image = "libs/status/sleep.png", PosX = -30, PosY = -20, NumFrames = 7, Time = 0.3}
ANIMS.StatusPowder = ANIMS.StatusBase:new{ Image = "libs/status/powder.png", PosX = -5}
ANIMS.StatusRegen = ANIMS.StatusBase:new{ Image = "libs/status/icon_regen.png"}
ANIMS.StatusReactive = ANIMS.StatusBase:new{ Image = "libs/status/reactive.png", PosX = -7, PosY = 15}
ANIMS.StatusRooted = ANIMS.StatusBase:new{ Image = "libs/status/rooted_icon.png", PosX = -7, PosY = 15}
ANIMS.StatusTargeted = ANIMS.StatusBase:new{ Image = "libs/status/targeted.png"}
ANIMS.StatusToxin = ANIMS.StatusBase:new{ Image = "libs/status/toxin.png", NumFrames = 6, Time = 0.15}
ANIMS.StatusWeaken = ANIMS.StatusBase:new{ Image = "libs/status/weaken.png", PosX = -15, NumFrames = 6, Time = 0.1}
ANIMS.StatusWet = ANIMS.StatusBase:new{ Image = "libs/status/wet.png", PosX = -5, PosY = 10, NumFrames = 6, Time = 0.2}

ANIMS.StatusInsanity1 = ANIMS.StatusBase:new{ Image = "libs/status/Insanity1.png", PosX = -5, PosY = 10}
ANIMS.StatusInsanity2 = ANIMS.StatusInsanity1:new{ Image = "libs/status/Insanity2.png"}
ANIMS.StatusInsanity3 = ANIMS.StatusInsanity1:new{ Image = "libs/status/Insanity3.png"}
ANIMS.StatusInsanity4 = ANIMS.StatusInsanity1:new{ Image = "libs/status/Insanity4.png"}
ANIMS.StatusInsanity5 = ANIMS.StatusInsanity1:new{ Image = "libs/status/Insanity5.png", NumFrames = 8, Frames={0,1,2,3,4,5,6,7,6,5,4,3,2,1,0}, Time = 0.75}


Location["libs/status/alluring_icon.png"] = Point(-5,0)
Location["libs/status/alluring_icon_remove.png"] = Point(-5,0)

Location["libs/status/blind_icon.png"] = Point(-5,0)
Location["libs/status/blind_icon_remove.png"] = Point(-5,0)

Location["libs/status/bloodthirsty_icon.png"] = Point(-5,0)
Location["libs/status/bloodthirsty_icon_remove.png"] = Point(-5,0)

Location["libs/status/bonded_icon.png"] = Point(-5,0)
Location["libs/status/bonded_icon_remove.png"] = Point(-5,0)

Location["libs/status/chill_icon.png"] = Point(-5,0)
Location["libs/status/chill_icon_remove.png"] = Point(-5,0)

Location["libs/status/confusion_icon.png"] = Point(-5,0)
Location["libs/status/confusion_icon_remove.png"] = Point(-5,0)

Location["libs/status/dodge_icon.png"] = Point(-5,0)
Location["libs/status/dodge_icon_remove.png"] = Point(-5,0)

Location["libs/status/doomed_icon.png"] = Point(-5,0)
Location["libs/status/doomed_icon_remove.png"] = Point(-5,0)

Location["libs/status/dreadful_icon.png"] = Point(-5,0)
Location["libs/status/dreadful_icon_remove.png"] = Point(-5,0)

Location["libs/status/dry_icon.png"] = Point(-5,0)
Location["libs/status/dry_icon_remove.png"] = Point(-5,0)

Location["libs/status/glory_icon.png"] = Point(-5,0)
Location["libs/status/glory_icon_remove.png"] = Point(-5,0)

Location["libs/status/hemorrhage_icon.png"] = Point(-5,0)
Location["libs/status/hemorrhage_icon_remove.png"] = Point(-5,0)

Location["libs/status/infested_icon.png"] = Point(-5,0)
Location["libs/status/infested_icon_remove.png"] = Point(-5,0)

Location["libs/status/leechseed_icon.png"] = Point(-5,0)
Location["libs/status/leechseed_icon_remove.png"] = Point(-5,0)

Location["libs/status/necrosis_icon.png"] = Point(-5,0)
Location["libs/status/necrosis_icon_remove.png"] = Point(-5,0)

Location["libs/status/powder_icon.png"] = Point(-5,0)
Location["libs/status/powder_icon_trigger.png"] = Point(-5,0)
Location["libs/status/powder_icon_remove.png"] = Point(-5,0)

Location["libs/status/reactive_icon.png"] = Point(-5,0)
Location["libs/status/reactive_icon_remove.png"] = Point(-5,0)
Location["libs/status/reactive_icon_trigger.png"] = Point(-5,0)

Location["libs/status/regen_icon.png"] = Point(-5,0)
Location["libs/status/regen_icon_remove.png"] = Point(-5,0)

Location["libs/status/rooted_icon.png"] = Point(-5,0)
Location["libs/status/rooted_icon_remove.png"] = Point(-5,0)

Location["libs/status/shatterburst_icon.png"] = Point(-5,0)
Location["libs/status/shatterburst_icon_remove.png"] = Point(-5,0)
Location["libs/status/shatterburst_icon_trigger.png"] = Point(-5,0)

Location["libs/status/shocked_icon.png"] = Point(-5,0)
Location["libs/status/shocked_icon_remove.png"] = Point(-5,0)
Location["libs/status/shocked_icon_trigger.png"] = Point(-5,0)
Location["libs/status/shocked_icon_stun.png"] = Point(-5,0)

Location["libs/status/sleep_icon.png"] = Point(-5,0)
Location["libs/status/sleep_icon_remove.png"] = Point(-5,0)

Location["libs/status/targeted_icon.png"] = Point(-5,0)
Location["libs/status/targeted_icon_remove.png"] = Point(-5,0)

Location["libs/status/toxin_icon.png"] = Point(-5,0)
Location["libs/status/toxin_icon_remove.png"] = Point(-5,0)

Location["libs/status/weaken_icon.png"] = Point(-5,0)
Location["libs/status/weaken_icon_remove.png"] = Point(-5,0)

Location["libs/status/wet_icon.png"] = Point(-5,0)
Location["libs/status/wet_icon_remove.png"] = Point(-5,0)

--Metatable voodoo to enable the syntax dmg.iToxin = EFFECT_CREATE; these values are read later.
local function SetupMetatable()
local mt = getmetatable(SpaceDamage(0))
local oldNewIndex = mt.__newindex

--Intercepts writes; stores whatever is assigned to a nonexistent key of a SpaceDamage.
mt.__newindex = function(SpaceDamageInstance, key, value)
	if not (SpaceDamageInstance and SpaceDamageInstance.loc) then return oldNewIndex(SpaceDamageInstance, key, value) end
	local pawn = Board:GetPawn(SpaceDamageInstance.loc)
	--Handle applying status effects to empty spaces
	if not pawn then 
		if key == "iWet" then
			if not Board:IsBlocked(SpaceDamageInstance.loc, PATH_GROUND) then SpaceDamageInstance.sItem = "Status_Puddle" end
			return
		elseif key == "iPowder" then
			if Board:IsFire(SpaceDamageInstance.loc) then
				SpaceDamageInstance.sImageMark = "libs/status/powder_icon_trigger.png"
				SpaceDamageInstance.sScript = string.format("Status.ApplyPowder(%q)", SpaceDamageInstance.loc.x.."_"..SpaceDamageInstance.loc.y)
				return
			else
				SpaceDamageInstance.sImageMark = "libs/status/powder_icon.png"
				SpaceDamageInstance.sScript = string.format("Status.ApplyPowder(%q)", SpaceDamageInstance.loc.x.."_"..SpaceDamageInstance.loc.y)
				return
			end
		else
			return oldNewIndex(SpaceDamageInstance, key, value)
		end
	end
	
	local id = pawn:GetId()
	
	--Handle vanilla status triggering custom status
	if key == "iFire" and value == 1 then
		local fullScript = ""
		if Status.GetStatus(id, "Chill") then
			SpaceDamageInstance.sImageMark = "libs/status/chill_icon_remove.png"
			fullScript = fullScript..string.format("Status.RemoveStatus(%q, %s)", "Chill", id)
			SpaceDamageInstance.sScript = fullScript
		end
		if Status.GetStatus(id, "Hemorrhage") then
			SpaceDamageInstance.sImageMark = "libs/status/hemorrhage_icon_remove.png"
			fullScript = fullScript..string.format("Status.RemoveStatus(%q, %s)", "Hemorrhage", id)
			SpaceDamageInstance.sScript = fullScript
		end
		if Status.GetStatus(id, "LeechSeed") then
			SpaceDamageInstance.sImageMark = "libs/status/leechseed_icon_remove.png"
			fullScript = fullScript..string.format("Status.RemoveStatus(%q, %s)", "LeechSeed", id)
			SpaceDamageInstance.sScript = fullScript
		end
		if Status.GetStatus(id, "Rooted") then
			SpaceDamageInstance.sImageMark = "libs/status/rooted_icon_remove.png"
			fullScript = fullScript..string.format("Status.RemoveStatus(%q, %s)", "Rooted", id)
			SpaceDamageInstance.sScript = fullScript
		end
		if Status.GetStatus(id, "Wet") then
			SpaceDamageInstance.iSmoke = 1
			SpaceDamageInstance.sImageMark = "libs/status/wet_icon_remove.png"
			fullScript = fullScript..string.format("Status.RemoveStatus(%q, %s)", "Wet", id)
			SpaceDamageInstance.sScript = fullScript
			return oldNewIndex(SpaceDamageInstance, key, 0)
		end
		--handle Dry -> damage + 1 here?
	end
	if key == "iAcid" and value == 1 then
		if Status.GetStatus(id, "Toxin") then
			SpaceDamageInstance.sImageMark = "libs/status/toxin_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Toxin", id)
		end
		if Status.GetStatus(id, "Reactive") then
			SpaceDamageInstance.sImageMark = "libs/status/reactive_icon_trigger.png"
			SpaceDamageInstance.sScript = string.format([[Status.RemoveStatus(%q, %s)
			local p = %s
			for i = DIR_START, DIR_END do
				Board:AddSmoke(p + DIR_VECTORS[i])
			end]], "Reactive", id, SpaceDamageInstance.loc)
			return oldNewIndex(SpaceDamageInstance, key, 0)
		end
	end
	if key == "iFreeze" and value == 1 then
		if Status.GetStatus(id, "Shatterburst") then
			SpaceDamageInstance.sImageMark = "libs/status/shatterburst_icon_trigger.png"
			SpaceDamageInstance.sScript = string.format([[Status.RemoveStatus(%q, %s)
			local p = %s
			for i = DIR_START, DIR_END do
				Board:DamageSpace(SpaceDamage(p + DIR_VECTORS[i], 1))
			end]], "Shatterburst", id, SpaceDamageInstance.loc)
			return oldNewIndex(SpaceDamageInstance, key, 0)
		end
	end
	
    if key == "iAlluring" then
		if value then
			SpaceDamageInstance.sImageMark = "libs/status/alluring_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyAlluring(%s, %s)", id, value)
		else
			SpaceDamageInstance.sImageMark = "libs/status/alluring_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Alluring", id, value)
		end
        return
	elseif key == "iBlind" then
		if value > 0 then
			SpaceDamageInstance.sImageMark = "libs/status/blind_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyBlind(%s, value)", id, value)
		else
			SpaceDamageInstance.sImageMark = "libs/status/blind_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Blind", id)
		end
        return
	elseif key == "iBloodthirsty" then
		if value then
			SpaceDamageInstance.sImageMark = "libs/status/bloodthirsty_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyBloodthirsty(%s, %s)", id, value)
		else
			SpaceDamageInstance.sImageMark = "libs/status/bloodthirsty_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Bloodthirsty", id)
		end
        return
	elseif key == "iBonded" then
		if value then
			SpaceDamageInstance.sImageMark = "libs/status/bonded_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyBonded(%s, %s)", id, value)
		else
			SpaceDamageInstance.sImageMark = "libs/status/bonded_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Bonded", id)
		end
        return
	elseif key == "iChill" or key == "iChilled" then
		if value == 1 and not pawn:IsFire() and not pawn:IsFrozen() then
			if Status.GetStatus(id, "Chill") then
				SpaceDamageInstance.iFrozen = 1
				return oldNewIndex(SpaceDamageInstance, key, 0)
			else
				SpaceDamageInstance.sImageMark = "libs/status/chill_icon.png"
				SpaceDamageInstance.sScript = string.format("modApi:runLater(function() Status.ApplyChill(%s, %s) end)", id, value)
			end
		elseif not pawn:IsFrozen() then
			SpaceDamageInstance.sImageMark = "libs/status/chill_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Chill", id)
		end
        return
	elseif key == "iConfusion" then
		if value and value > 0 then
			SpaceDamageInstance.sImageMark = "libs/status/confusion_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyConfusion(%s, %s)", id, value)
		else
			SpaceDamageInstance.sImageMark = "libs/status/confusion_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Confusion", id)
		end
        return
	elseif key == "iDodge" then
		if value and value ~= 0 then
			SpaceDamageInstance.sImageMark = "libs/status/dodge_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyDodge(%s, %s)", id, value)
		else
			SpaceDamageInstance.sImageMark = "libs/status/dodge_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Dodge", id)
		end
        return
	elseif key == "iDoomed" or key == "iDoom" then
		if value then
			if type(value) == "table" then 
				value.amount = value.amount or 1
			else
				value = {source = -1, amount = value or 1 }
			end
			SpaceDamageInstance.sImageMark = "libs/status/doomed_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyDoomed(%s, %s, %s)", id, value.source, value.amount)
		else
			SpaceDamageInstance.sImageMark = "libs/status/doomed_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Doomed", id)
		end
        return
	elseif key == "iDreadful" then
		if value then
			SpaceDamageInstance.sImageMark = "libs/status/dreadful_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyDreadful(%s, %s)", id, value)
		else
			SpaceDamageInstance.sImageMark = "libs/status/dreadful_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Dreadful", id)
		end
        return
	elseif key == "iDry" then		--removes Wet instead of applying; deals 1 damage to pawns on fire; does nothing on pawns in water
		if value then
			if Status.GetStatus(id, "Wet") then
				SpaceDamageInstance.sImageMark = "libs/status/wet_icon_remove.png"
				SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Wet", id)
				return oldNewIndex(SpaceDamageInstance, key, 0)
			elseif pawn:IsFire() then
				if SpaceDamageInstance.iDamage ~= DAMAGE_DEATH then
					if SpaceDamageInstance.iDamage == DAMAGE_ZERO then 
						SpaceDamageInstance.iDamage = 1 
					else
						SpaceDamageInstance.iDamage = SpaceDamageInstance.iDamage + 1
					end
					SpaceDamageInstance.sImageMark = "libs/status/dry_icon_trigger.png"
				end
			elseif Board:GetTerrain(pawn:GetSpace()) == TERRAIN_WATER then
				SpaceDamageInstance.sImageMark = "libs/status/dry_icon_remove.png"
			else
				SpaceDamageInstance.sImageMark = "libs/status/dry_icon.png"
				SpaceDamageInstance.sScript = string.format("Status.ApplyDry(%s)", id)
			end
		else
			SpaceDamageInstance.sImageMark = "libs/status/dry_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Dry", id)
		end
        return
	elseif key == "iGlory" then
        if value > 0 then
			SpaceDamageInstance.sImageMark = "libs/status/glory_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyGlory(%s, %s)", id, value)
		else
			SpaceDamageInstance.sImageMark = "libs/status/glory_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Glory", id)
		end
        return
	elseif key == "iHemorrhage" then
        if value == 1 and not pawn:IsFire() then
			SpaceDamageInstance.sImageMark = "libs/status/hemorrhage_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyHemorrhage(%s)", id)
		else
			SpaceDamageInstance.sImageMark = "libs/status/hemorrhage_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Hemorrhage", id)
		end
        return
	elseif key == "iInfested" then
        if value == 1 and not pawn:IsFire() then
			SpaceDamageInstance.sImageMark = "libs/status/hemorrhage_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyHemorrhage(%s)", id)
		else
			SpaceDamageInstance.sImageMark = "libs/status/hemorrhage_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Hemorrhage", id)
		end
        return
	elseif key == "iLeechSeed" then
        if value >= 0 and not pawn:IsFire() then
			SpaceDamageInstance.sImageMark = "libs/status/leechseed_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyLeechSeed(%s, %s)", id, value)
		else
			SpaceDamageInstance.sImageMark = "libs/status/leechseed_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "LeechSeed", id)
		end
        return
	elseif key == "iNecrosis" then
        if value == 1 then
			SpaceDamageInstance.sImageMark = "libs/status/necrosis_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyNecrosis(%s)", id)
		else
			SpaceDamageInstance.sImageMark = "libs/status/necrosis_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Necrosis", id)
		end
        return
	
	elseif key == "iPowder" then
        if value == 1 and not Status.GetStatus(id, "Wet") then
			if pawn:IsFire() then
				SpaceDamageInstance.sImageMark = "libs/status/powder_icon_trigger.png"
				SpaceDamageInstance.sScript = string.format("Status.ApplyPowder(%s)", id)
				--increase damage amount here?
			else
				SpaceDamageInstance.sImageMark = "libs/status/powder_icon.png"
				SpaceDamageInstance.sScript = string.format("Status.ApplyPowder(%s)", id)
			end
		else
			SpaceDamageInstance.sImageMark = "libs/status/powder_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Powder", id)
		end
        return
	elseif key == "iReactive" then
        if value == 1 then
			if pawn:IsAcid() then
				SpaceDamageInstance.sImageMark = "libs/status/reactive_icon_trigger.png"
				SpaceDamageInstance.sScript = string.format("Status.ApplyReactive(%s)", id)
			else
				SpaceDamageInstance.sImageMark = "libs/status/reactive_icon.png"
				SpaceDamageInstance.sScript = string.format("Status.ApplyReactive(%s)", id)
			end
		else
			SpaceDamageInstance.sImageMark = "libs/status/reactive_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Reactive", id)
		end
        return
	elseif key == "iRegen" then
        if value > 0 then
			SpaceDamageInstance.sImageMark = "libs/status/regen_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyRegen(%s, %s)", id, value)
		else
			SpaceDamageInstance.sImageMark = "libs/status/regen_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Regen", id)
		end
        return
	elseif key == "iRooted" then
        if value and not pawn:IsFire() then
			SpaceDamageInstance.sImageMark = "libs/status/rooted_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyRooted(%s, %s)", id, value)
		else
			SpaceDamageInstance.sImageMark = "libs/status/rooted_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Rooted", id)
		end
        return
	elseif key == "iShatterburst" then
        if value == 1 then
			SpaceDamageInstance.sImageMark = "libs/status/shatterburst_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyShatterburst(%s)", id)
		else
			SpaceDamageInstance.sImageMark = "libs/status/shatterburst_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Shatterburst", id)
		end
        return
	elseif key == "iShocked" then
        if value == 1 then
			if Status.GetStatus(id, "Wet") or Status.GetStatus(id, "Shocked") then
				SpaceDamageInstance.sImageMark = "libs/status/shocked_icon_stun.png"
				SpaceDamageInstance.sScript = string.format("Board:GetPawn(%s):ClearQueued() Status.ApplyShocked(%s, %s)", id, id, tostring(not (SpaceDamageInstance.iDamage > 0 and SpaceDamageInstance.iDamage ~= DAMAGE_ZERO)))
			else
				SpaceDamageInstance.sImageMark = "libs/status/shocked_icon.png"
				SpaceDamageInstance.sScript = string.format("Status.ApplyShocked(%s, %s)", id, tostring(not (SpaceDamageInstance.iDamage > 0 and SpaceDamageInstance.iDamage ~= DAMAGE_ZERO)))
			end
		else
			SpaceDamageInstance.sImageMark = "libs/status/shocked_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Shocked", id)
		end
        return
	elseif key == "iSleep" then
        if type(value) == "number" and value == 2 then
			SpaceDamageInstance.sImageMark = "libs/status/sleep_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Sleep", id)
		else
			if type(value) == "table" then 
				value.turns = value.turns or 1
			else
				value = {turns = value or 1, addTurns = false }
			end
			SpaceDamageInstance.sImageMark = "libs/status/sleep_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplySleep(%s, %s, %s)", id, value.turns, tostring(value.addTurns))
		end
        return
	elseif key == "iTargeted" then
        if value > 0 then
			SpaceDamageInstance.sImageMark = "libs/status/targeted_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyTargeted(%s, %s)", id, value)
		else
			SpaceDamageInstance.sImageMark = "libs/status/targeted_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Targeted", id)
		end
        return
    elseif key == "iToxin" then
        if value == 1 and not pawn:IsAcid() then
			SpaceDamageInstance.sImageMark = "libs/status/toxin_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyToxin(%s)", id)
		else
			SpaceDamageInstance.sImageMark = "libs/status/toxin_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Toxin", id)
		end
        return
	elseif key == "iWeaken" or key == "iWeak" then
		if value then
			if type(value) == "table" then 
				value.amount = value.amount or 1
				value.recoverPerTurn = value.recoverPerTurn or 0
			else
				value = {recoverPerTurn = 0, amount = value or 1 }
			end
			SpaceDamageInstance.sImageMark = "libs/status/weaken_icon.png"
			SpaceDamageInstance.sScript = string.format("Status.ApplyWeaken(%s, %s, %s)", id, value.amount, value.recoverPerTurn)
		else
			SpaceDamageInstance.sImageMark = "libs/status/weaken_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Weaken", id)
		end
        return
	elseif key == "iWet" then
        if value then
			if pawn:IsFire() then
				SpaceDamageInstance.iSmoke = 1
			elseif Status.GetStatus(id, "Chill") then
				SpaceDamageInstance.iFrozen = 1
			elseif Status.GetStatus(id, "Shocked") then
				SpaceDamageInstance.sImageMark = "libs/status/shocked_icon_stun.png"
				SpaceDamageInstance.sScript = string.format("Board:GetPawn(%s):ClearQueued() Status.ApplyWet(%s)", id, id)
			else
				SpaceDamageInstance.sImageMark = "libs/status/wet_icon.png"
				SpaceDamageInstance.sScript = string.format("Status.ApplyWet(%s)", id)
			end
		else
			SpaceDamageInstance.sImageMark = "libs/status/wet_icon_remove.png"
			SpaceDamageInstance.sScript = string.format("Status.RemoveStatus(%q, %s)", "Wet", id)
		end
        return
    end
	return oldNewIndex(SpaceDamageInstance, key, value)
end
end


local function AlterScoringFunctions()
local oldScorePositioning = ScorePositioning
function ScorePositioning(point, pawn)
	point = point or Point(-1, -1)
	local mission = GetCurrentMission()
	if not mission then return oldScorePositioning(point, pawn) end
	mission.AdjScoreTable = mission.AdjScoreTable or {}
	mission.BlindTable = mission.BlindTable or {}
	if mission.BlindTable[pawn:GetId()] and point:Manhattan(pawn:GetSpace()) > 2 then return -100 end
	--if the pawn is blind, don't move beyond 2 spaces
	return oldScorePositioning(point, pawn) + (mission.AdjScoreTable[point:GetString()] or 0)
	--nil check for Vek outside the board
end

local oldScoreList = Skill:ScoreList()
function Skill:ScoreList(list, queued)
	local mission = GetCurrentMission()
	if not mission then return oldScoreList(list, queued) end
	
	local id = Pawn:GetId()
	local pos = Pawn:GetSpace()
	local score = 0
	local posScore = 0
	
	mission.BlindTable = mission.BlindTable or {}
	mission.BloodthirstyTable = mission.BloodthirstyTable or {}
	mission.ConfusionTable = mission.ConfusionTable or {}
	mission.TargetedTable = mission.TargetedTable or {}
	
	local isBlind = mission.BlindTable[id]
	local bloodthirstAmount = mission.BloodthirstyTable[id] or 0
	
	if isBlind then LOG(Pawn:GetType().." in "..pos:GetString().." is blind.") end

	for i = 1, list:size() do
		local spaceDamage = list:index(i)
		local target = spaceDamage.loc
		if pos:Manhattan(target) <= 2 or not isBlind then
			local damage = spaceDamage.iDamage 
			local moving = spaceDamage:IsMovement() and spaceDamage:MoveStart() == pos
			
			if Board:IsValid(target) or moving then	
				local foundPawn = Board:GetPawn(target)
				if spaceDamage:IsMovement() then
					posScore = posScore + ScorePositioning(spaceDamage:MoveEnd(), Pawn)
				elseif foundPawn and foundPawn:IsNonGridStructure() then
					score = score + self.ScoreBuilding
				elseif Board:GetPawnTeam(target) == Pawn:GetTeam() and damage > 0 then
					if Board:IsFrozen(target) and not Board:IsTargeted(target) then
						score = score + self.ScoreEnemy
					else
						score = score + self.ScoreFriendlyDamage
					end
				elseif isEnemy(Board:GetPawnTeam(target),Pawn:GetTeam()) then
					if foundPawn:IsDead() or foundPawn:IsTempUnit() then 
						score = score + self.ScoreNothing
					else
						score = score + self.ScoreEnemy + bloodthirstAmount
					end
				elseif Board:IsBuilding(target) and Board:IsPowered(target) and (damage > 0 and damage ~= DAMAGE_ZERO) then
					score = score + self.ScoreBuilding
				elseif Board:IsPod(target) and not queued and ((damage > 0 and damage ~= DAMAGE_ZERO) or spaceDamage.sPawn ~= "") then
					return -100
				else
					score = score + self.ScoreNothing
				end
				if foundPawn and mission.TargetedTable[foundPawn:GetId()] then score = score + mission.TargetedTable[foundPawn:GetId()] end
			end
		elseif isBlind then 
			LOG("Blinded to a damage in "..target:GetString()..".") 
		end
	end
	if mission.ConfusionTable[id] then 
		if posScore > -50 then posScore = -posScore end	--don't get confused into stepping on pods/ignoring blindness range restriction
		if score > -50 then score = -score end			--don't get confused into spawning unqueued stuff on top of pods
	end
	if posScore < -5 then return posScore end
	return score
end
end

local function CreateStatusFunctions()
function Status.IsImmuneTo(pawn, status)
	if not pawn or not status or status == "" then return false end
	if _G[pawn:GetType()][status.."Immune"] then return true end
	if pawn:GetAbility() ~= "" and modapiext.pawn:getPilotId(pawn:GetId()) and _G[modapiext.pawn:getPilotId(pawn:GetId())] and
	_G[modapiext.pawn:getPilotId(pawn:GetId())][status.."Immune"] then return true end
	return false
end

function Status.ApplyAlluring(id, amount)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Alluring") then return end
	amount = amount or 10
	if amount == 0 then return end
	mission.AlluringTable[id] = amount
	CustomAnim:add(id, "StatusTargeted")
end

function Status.ApplyBlind(id, turns, addTurns)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Blind") then return end
	turns = turns or 1
	if addTurns and mission.BlindTable[id] then 
		mission.BlindTable[id] = mission.BlindTable[id] + turns
	else
		mission.BlindTable[id] = turns
	end
	CustomAnim:add(id, "StatusBlind")
end

function Status.ApplyBloodthirsty(id, amount)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Bloodthirsty") then return end
	amount = amount or 10
	mission.BloodthirstyTable[id] = amount
	CustomAnim:add(id, "StatusBloodthirsty")
end

function Status.ApplyBonded(id)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Bonded") then return end
	mission.BondedTable[id] = true
	CustomAnim:add(id, "StatusBonded")
	CustomAnim:rem(id, "StatusBondedOff")	--that way applying the status refreshes it
end

function Status.ApplyChill(id, clearQueued)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Chill") then return end
	if pawn:IsFire() then CustomAnim:rem(id, "StatusChill") return end
	if CustomAnim:get(id, "StatusChill") then
		CustomAnim:rem(id, "StatusChill")
		pawn:SetFrozen(true)
	elseif CustomAnim:get(id, "StatusWet") then
		CustomAnim:rem(id, "StatusWet")
		pawn:SetFrozen(true)
	else
		CustomAnim:add(id, "StatusChill")
		mission.ChillTable[id] = true
	end
	if clearQueued then pawn:ClearQueued() end
end

function Status.ApplyConfusion(id, turns)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Confusion") then return end
	turns = turns or 1
	mission.ConfusionTable[id] = turns
	CustomAnim:add(id, "StatusConfusion")
end


function Status.ApplyDodge(id, amount, distance, movementType, smart)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Dodge") then return end
	amount = math.min(amount or 1, 3)
	distance = distance or 1
	movementType = movementType or "Walk"
	if movementType ~= "Walk" and movementType ~= "Leap" and movementType ~= "Burrow" and movementType ~= "Teleport" then movementType = "Walk" end
	--smart means "try to reposition in a non-suicidal way"
	if mission.DodgeTable[id] then
		CustomAnim:rem(id, "StatusDodge"..mission.DodgeTable[id].amount)
		mission.DodgeTable[id].amount = math.min(mission.DodgeTable[id].amount + amount, 3)
		CustomAnim:add(id, "StatusDodge"..mission.DodgeTable[id].amount)
	else	
		mission.DodgeTable[id] = {amount = amount, distance = distance, movementType = movementType, smart = smart}
		CustomAnim:add(id, "StatusDodge"..amount)
	end
end

function Status.LowerDodge(id)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if not mission.DodgeTable[id] then return end
	if not mission.DodgeTable[id].amount then return end
	CustomAnim:rem(id, "StatusDodge"..mission.DodgeTable[id].amount)
	mission.DodgeTable[id].amount = mission.DodgeTable[id].amount - 1
	if mission.DodgeTable[id].amount <= 0 then 
		mission.DodgeTable[id] = nil 
	else
		CustomAnim:add(id, "StatusDodge"..mission.DodgeTable[id].amount)
	end
end

function Status.ApplyDoomed(id, source, amount)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Doomed") then return end
	source = source or -1
	amount = amount or 1
	mission.DoomedTable[id] = {amount = amount, source = source}
	CustomAnim:add(id, "StatusDoomed")
end

function Status.ApplyDreadful(id, amount)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Dreadful") then return end
	amount = amount or -10
	mission.DreadfulTable[id] = amount
	CustomAnim:add(id, "StatusDreadful")
end

function Status.ApplyDry(id)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Dry") then return end
	if CustomAnim:get(id, "StatusWet") then
		Status.RemoveStatus(id, "Wet")
	else
		mission.DryTable[id] = true
		CustomAnim:add(id, "StatusDry")
	end
end

function Status.ApplyGlory(id, turns)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Glory") then return end
	turns = turns or 1
	if mission.GloryTable[id] ~= nil then
		mission.GloryTable[id].turns = mission.GloryTable[id].turns + turns
	else
		mission.GloryTable[id] = {turns=turns,weapons = pawn:GetEquippedWeapons()}
		CustomAnim:add(id, "StatusGlory")
		Board:Ping(pawn:GetSpace(), GL_Color(255, 255, 100))
		local weaponCount = pawn:GetWeaponCount()
		for i = weaponCount, 1, -1 do
			local weapon = pawn:GetWeaponBaseType(i)
			pawn:RemoveWeapon(i)
			if _G[weapon] then
				if _G[weapon].Upgrades == 2 and _G[weapon.."_AB"] ~= nil then
					weapon = weapon.."_AB"
				elseif _G[weapon].Upgrades == 1 and _G[weapon.."_A"] ~= nil then
					weapon = weapon.."_A"
				elseif _G[weapon].Class == "Enemy" then
					if _G[string.sub(weapon, 1, -2).."B"] ~= nil then 
						weapon = string.sub(weapon, 1, -2).."B"
					elseif _G[string.sub(weapon, 1, -2).."2"] ~= nil then 
						weapon = string.sub(weapon, 1, -2).."2"
					end
				end
			end
			pawn:AddWeapon(weapon, true)
		end
	end
end

function Status.ApplyGunk(id, anim)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	anim = anim or "StatusGunk"
	if Status.IsImmuneTo(pawn, "Gunk") then return end
	if _G[pawn:GetType()].OnAppliedGunk then
		_G[pawn:GetType()].OnAppliedGunk(id)
		return
	end
	mission.GunkTable[id] = true
	CustomAnim:add(id, anim)
end

function Status.ApplyHemorrhage(id, turns)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Hemorrhage") then return end
	turns = turns or 1
	mission.HemorrhageTable[id] = turns
	CustomAnim:add(id, "StatusHemorrhage")
end

function Status.ApplyInfested(id, turns)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Infested") then return end
	turns = turns or 1
	mission.InfestedTable[id] = turns
	pawn:SetInfected(true)
end

function Status.ApplyLeechSeed(id, source)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	if pawn:IsFire() then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "LeechSeed") then return end
	if Pawn then source = source or Pawn:GetId() end
	if not source then return end
	mission.LeechSeedTable[id] = source
	CustomAnim:add(id, "StatusLeechSeed")
end

function Status.ApplyNecrosis(id)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Necrosis") then return end
	mission.NecrosisTable[id] = true
	CustomAnim:add(id, "StatusNecrosis")
end

function Status.ApplyPowder(id)
	local pawn, point
	if type(id) == "number" then
		LOG("powdering a pawn")
		pawn = Board:GetPawn(id)
	else
		point = Point(tonumber(string.sub(id, 1, 1)), tonumber(string.sub(id, -1)))
		LOG("powdering a point:"..point:GetString())
	end
	if not (pawn or point) then LOG("no powder") return end
	local mission = GetCurrentMission()
	if not mission then return end
	
	local ret = SkillEffect()
	if point and Board:IsFire(point) then
		local explosionDamage = SpaceDamage(point, 1)
		explosionDamage.sAnimation = "ExploAir1"
		ret:AddDamage(explosionDamage)
		for i = DIR_START, DIR_END do
			local damage = SpaceDamage(point+DIR_VECTORS[i], 1)
			damage.sAnimation = "explopush1_"..i
			ret:AddDamage(damage)
		end
		Board:AddEffect(ret)
	elseif pawn then
		if Status.IsImmuneTo(pawn, "Powder") then return end
		if pawn:IsFire() then
			local amount = 1
			if Status.GetStatus(id, "Dry") then amount = 2 end
			local explosionDamage = SpaceDamage(pawn:GetSpace(), amount)
			explosionDamage.sAnimation = "ExploAir"..amount
			ret:AddDamage(explosionDamage)
			for i = DIR_START, DIR_END do
				local damage = SpaceDamage(pawn:GetSpace()+DIR_VECTORS[i], amount)
				damage.sAnimation = "explopush"..amount.."_"..i
				ret:AddDamage(damage)
			end
			Board:AddEffect(ret)
			return
		end
		if mission.WetTable[id] then return end
		mission.PowderTable[id] = true
		CustomAnim:add(id, "StatusPowder")
	end
end

function Status.ApplySleep(id, turns, addTurns)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Sleep") then return end
	turns = turns or 1
	if turns > 0 then
		pawn:SetPowered(false)
		pawn:ClearQueued()
		if ANIMS[pawn:GetCustomAnim().."_sleep"] ~= nil then
		--this is to make it work with Pokemon evolutions and similar things
			pawn:SetCustomAnim(pawn:GetCustomAnim().."_sleep")
		elseif ANIMS[_G[pawn:GetType()].Image.."_sleep"] ~= nil then
			pawn:SetCustomAnim(_G[pawn:GetType()].Image.."_sleep")
		elseif not CustomAnim:get(id, "StatusSleep") then
			CustomAnim:add(id, "StatusSleep")
		end
		if addTurns and mission.SleepTable[id] then 
			mission.SleepTable[id] = mission.SleepTable[id] + turns
		else
			mission.SleepTable[id] = turns
		end
	elseif turns < 0 and addTurns and mission.SleepTable[id] then
		mission.SleepTable[id] = mission.SleepTable[id] + turns
		if mission.SleepTable[id] < 0 then 
			Status.RemoveStatus(id, "Sleep")
		end
	end
end

function Status.ApplyShatterburst(id)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Shatterburst") then return end
	mission.ShatterburstTable[id] = true
	CustomAnim:add(id, "StatusShatterburst")
end

function Status.ApplyShocked(id, doFirstFlip)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Shocked") then return end
	if Status.GetStatus(id, "Shocked") or Status.GetStatus(id, "Wet") then 
		pawn:ClearQueued()
		Board:AddAnimation(pawn:GetSpace(),"Lightning_Hit",1)
	else
		CustomAnim:add(id, "StatusShocked")
		if doFirstFlip then mission.ShockedTable[id] = 1 else mission.ShockedTable[id] = 2 end
	end
end

function Status.ApplyRegen(id, amount)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Regen") then return end
	amount = amount or 1
	if amount <= 0 then return end
	mission.RegenTable[id] = amount
	CustomAnim:add(id, "StatusRegen")
end

function Status.ApplyReactive(id)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Reactive") then return end
	mission.ReactiveTable[id] = true
	CustomAnim:add(id, "StatusReactive")
end

function Status.ApplyRooted(id, amount)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	if pawn:IsFire() or Board:IsFire(pawn:GetSpace()) then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Rooted") then return end
	amount = amount or 0
	mission.RootedTable[id] = {amount = amount, wasPushable = not pawn:IsGuarding(), oldMoveSpeed = pawn:GetMoveSpeed()}
	CustomAnim:add(id, "StatusRooted")
	pawn:SetPushable(false)
	pawn:SetMoveSpeed(0)
end

function Status.ApplyTargeted(id, amount)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Targeted") then return end
	amount = amount or 10
	if amount == 0 then return end
	mission.TargetedTable[id] = amount
	CustomAnim:add(id, "StatusTargeted")
end

function Status.ApplyToxin(id)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Toxin") then return end
	mission.ToxinTable[id] = true
	CustomAnim:add(id, "StatusToxin")
end

function Status.ApplyWeaken(id, amount, recoverPerTurn)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	if pawn:GetTeam() ~= TEAM_ENEMY then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Weaken") then return end
	recoverPerTurn = recoverPerTurn or 0
	amount = amount or 1
	if amount == 0 then return end
	for i = pawn:GetWeaponCount(), 1, -1 do
		local weapon = pawn:GetWeaponBaseType(i)
		if string.match(weapon, "^%dweaker") then
			amount = amount + tonumber(string.sub(weapon,1,1))
			weapon = string.sub(weapon, 8)
		end
		if amount > _G[pawn:GetWeaponBaseType(i)].Damage then amount = _G[weapon].Damage end
		local newWeapon = amount.."weaker"..weapon
		if amount <= 0 then newWeapon = weapon end
		pawn:RemoveWeapon(i)
		pawn:AddWeapon(newWeapon)
	end
	CustomAnim:add(id, "StatusWeaken")
	if mission.WeakenTable[id] == nil then mission.WeakenTable[id] = 0 end
	mission.WeakenTable[id] = mission.WeakenTable[id] + recoverPerTurn
	-- LOG("WeakenTable["..id.."] = "..mission.WeakenTable[id])
	-- if mission.WeakenTable[id] == 0 then mission.WeakenTable[id] = nil end
end	

function Status.ApplyWet(id)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	if Status.IsImmuneTo(pawn, "Wet") then return end
	if pawn:IsFire() then
		pawn:SetFire(false)
	elseif CustomAnim:get(id, "StatusChill") then
		pawn:SetFrozen(true)
	elseif CustomAnim:get(id, "StatusDry") then
		Status.RemoveStatus(id, "Dry")
	else
		mission.WetTable[id] = true
		CustomAnim:add(id, "StatusWet")
		Status.RemoveStatus(id, "Powder")
	end
end

function Status.ApplyInsanity(id, amount, setToValue)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	amount = amount or 1
	if amount == 0 then return end
	if Status.IsImmuneTo(pawn, "Insanity") then return end
	if pawn:GetPersonality() == "Artificial" then return end
	if mission.InsanityTable[id] == nil or mission.InsanityTable[id] == 0 then
		for i = 1, 5 do		--try to get back the amount of insanity in case it's gone
			if CustomAnim:get(id, "StatusInsanity"..i) ~= nil then mission.InsanityTable[id] = i break end
		end
	end
	local insanityCount = mission.InsanityTable[id] or 0
	if setToValue then insanityCount = amount end
	local newInsanityCount = math.min(amount + insanityCount, 5)
	if newInsanityCount <= 0 then Status.RemoveStatus(id, "Insanity") return end
	mission.InsanityTable[id] = newInsanityCount
	if insanityCount > 0 and CustomAnim:get(id, "StatusInsanity"..insanityCount) then CustomAnim:rem(id, "StatusInsanity"..insanityCount) end
	CustomAnim:add(id, "StatusInsanity"..newInsanityCount)
	if newInsanityCount >= 5 then 
		local fx = SkillEffect()
		fx:AddVoice("Meta_GoingInsane"..math.random(1,14), id)
		Board:AddEffect(fx)
	end
end


function Status.RemoveStatus(id, status)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	mission[status.."Table"] = mission[status.."Table"] or {}
	if not mission[status.."Table"][id] then return end
	if status == "Rooted" then 
		pawn:SetPushable(mission["RootedTable"][id].wasPushable) 
		pawn:SetMoveSpeed(mission["RootedTable"][id].oldMoveSpeed)
	end
	if status == "Sleep" then
		pawn:SetPowered(true)
		if pawn:GetCustomAnim():sub(-6, -1) == "_sleep" then
			if pawn:GetCustomAnim():sub(-13, -1) == "special_sleep" then
				pawn:SetCustomAnim(pawn:GetCustomAnim():sub(1, -14))
			else
				pawn:SetCustomAnim(pawn:GetCustomAnim():sub(1, -7))
			end
		else
			CustomAnim:rem(id, "StatusSleep")
		end
		mission.SleepTable[id] = nil
	elseif status == "Glory" then
		for i = pawn:GetWeaponCount(), 1, -1 do
			pawn:RemoveWeapon(i)
		end
		local weaponCount = #mission.GloryTable[id].weapons
		for i = 1, weaponCount do
			pawn:AddWeapon(mission.GloryTable[id].weapons[i], true)
		end
		CustomAnim:rem(id, "StatusGlory")
		mission["GloryTable"][id] = nil 
	elseif status == "Insanity" then
		CustomAnim:rem(id, "StatusInsanity"..mission["InsanityTable"][id])
		mission["InsanityTable"][id] = nil 
	elseif status == "Weaken" then
		for i = pawn:GetWeaponCount(), 1, -1 do
			local weapon = pawn:GetWeaponBaseType(i)
			if string.match(weapon, "^%dweaker") then
				weapon = string.sub(weapon, 8)
				pawn:RemoveWeapon(i)
				pawn:AddWeapon(weapon)
			end
		end
	else
		CustomAnim:rem(id, "Status"..status)
		mission[status.."Table"][id] = nil 
	end
end

function Status.GetStatus(id, status)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	return (mission[status.."Table"] ~= nil and mission[status.."Table"][id]) or false
end

function Status.List(pawn)
	if not pawn then
		return {"Alluring","Blind","Bloodthirsty","Bonded","Chill","Confusion","Dodge","Doomed","Dreadful","Dry","Glory","Gunk","Hemorrhage","Infested","LeechSeed","Necrosis","Powder","Reactive","Regen","Rooted","Shatterburst","Shocked","Sleep","Targeted","Toxin","Weaken","Wet","Insanity"}
	else
		local result = {}
		local mission = GetCurrentMission()
		for _, status in ipairs(Status.List()) do
			if mission[status.."Table"][pawn:GetId()] ~= nil then table.insert(result, status) end
		end
		return result
	end
end

function Status.Count(id)
	local pawn = Board:GetPawn(id)
	if not pawn then return end
	local mission = GetCurrentMission()
	if not mission then return end
	local count = 0
	for _, status in Status.List() do
		if mission[status.."Table"][id] ~= nil then count = count + 1 end
	end
	return count
end

function Status.HealFromGunk(id, overheal, alwaysOverheal)
	local blob = Board:GetPawn(id)
	if not blob then return end
	if overheal then
		Status.Overheal(id, 1, alwaysOverheal)
	else
		Board:DamageSpace(SpaceDamage(blob:GetSpace(), -1))
	end
	if Status.GetStatus(id, "Gunk") then Status.RemoveStatus(id, "Gunk") end
end

function Status.Overheal(id, amount, alwaysOverheal)
	local pawn = Board:GetPawn(id)
	local mission = GetCurrentMission()
	if not pawn or not mission then return end
	mission.StatusOverhealTable = mission.StatusOverhealTable or {}		--create empty table if it does not exist
	mission.StatusOverhealTable[id] = mission.StatusOverhealTable[id] or 0
	if alwaysOverheal or amount + pawn:GetHealth() > pawn:GetMaxBaseHealth() then			--if we are not overhealing, just heal
		if pawn:IsDamaged() then										--if we are healing, heal and reduce amount
			if not alwaysOverheal then amount = amount - (pawn:GetMaxBaseHealth() - pawn:GetHealth()) end
			Board:DamageSpace(SpaceDamage(pawn:GetSpace(), -amount))
		end
		mission.StatusOverhealTable[id] = mission.StatusOverhealTable[id] + amount
		
		pawn:SetMaxBaseHealth(pawn:GetMaxBaseHealth() + amount)
		pawn:SetMaxHealth(pawn:GetMaxHealth() + amount)
		local ret = SkillEffect()
		ret:AddDamage(SpaceDamage(pawn:GetSpace(),-amount))
		Board:AddEffect(ret)
	else
		Board:DamageSpace(SpaceDamage(pawn:GetSpace(), -amount))
	end
end

end



local function ReapplyOverheal()
	local mission = GetCurrentMission()
	if not mission then return end
	mission.StatusOverhealTable = mission.StatusOverhealTable or {}
	for pawnId, overhealAmount in pairs(mission.StatusOverhealTable) do
		local pawn = Board:GetPawn(pawnId)
		if pawn then
			local origMaxHealth = pawn:GetMaxHealth()
			local newMaxHealth = origMaxHealth + overhealAmount
			modApi:runLater(function() pawn:SetMaxHealth(newMaxHealth) end)
		end
	end
end

local function ResetOverheal()
	local mission = GetCurrentMission()
	if not mission then return end
	mission.StatusOverhealTable = mission.StatusOverhealTable or {}
	for pawnId, overhealAmount in pairs(mission.StatusOverhealTable) do
		local pawn = Board:GetPawn(pawnId)
		if pawn then
			pawn:SetMaxBaseHealth(pawn:GetMaxBaseHealth() - overhealAmount)
		end
	end
end
TILE_TOOLTIPS.Meta_BlobGunk_Text = {"Gunk", "Blobs heal 1 damage. Other units are inflicted with Gunk."}
TILE_TOOLTIPS.Status_Puddle_Text = {"Puddle", "Extinguishes fires, then turns into smoke."}

Meta_BlobGunk = { Image = "libs/status/gunk.png", Damage = SpaceDamage(0), Tooltip = "Meta_BlobGunk_Text", Icon = "libs/status/gunk.png", UsedImage = "libs/status/gunkused.png"}
Status_Puddle = { Image = "libs/status/item_puddle.png", Damage = SpaceDamage(0), Tooltip = "Status_Puddle_Text", Icon = "libs/status/item_puddle.png", UsedImage = ""}
Location["libs/status/gunk.png"] = Point(-22,6)
Location["libs/status/gunkused.png"] = Point(-22,6)
Location["libs/status/item_puddle.png"] = Point(-22,6)

BoardEvents.onItemRemoved:subscribe(function(loc, removed_item)
    local pawn = Board:GetPawn(loc)
	if removed_item == "Status_Puddle" then
		if (pawn and pawn:IsFire()) or Board:IsFire(loc) then
			local smokeDamage = SpaceDamage(loc)
			smokeDamage.iSmoke = 1
			Board:DamageSpace(smokeDamage)
		elseif pawn then
			Status.ApplyWet(pawn:GetId())
		end
	elseif removed_item == "Meta_BlobGunk" then
        local pawn = Board:GetPawn(loc)
        if pawn then Status.ApplyGunk(pawn:GetId()) end
		Board:AddAnimation(loc, "Djinn_explo_gunkpuddle", ANIM_NO_DELAY)
    end
end)


local function getWeaponKey(id, key)		--helper function to generate the extra Weaken weapons
	Assert.Equals("string", type(id), "ID must be a string")
	Assert.Equals("string", type(key), "Key must be a string")
	local textId = id .. "_" .. key
	if IsLocalizedText(textId) then
		return GetLocalizedText(textId)
	end
	return _G[id] and _G[id][key] or id
end

local function GenerateWeakenWeapons()
	for id, weapon in pairs(_G) do
		if weapon and type(weapon) == "table" and weapon.Damage and weapon.Class and weapon.Damage > 0 and (weapon.Class == "Enemy" or weapon.Class == "") and weapon.Original == nil then
			local i = 1
			local amount = 1
			if weapon.Damage == DAMAGE_DEATH then amount = 991 end
			repeat
				--for an alpha firefly's weapon weakened 3 times, its ID is 3weakerFireflyAtk2
				_G[i.."weaker"..id] =  _G[id]:new{ Damage = _G[id].Damage - amount, Original = id, }
				_G[i.."weaker"..id].GetName = function(self) return getWeaponKey(self.Original, "Name") end
				_G[i.."weaker"..id].GetDescription = function(self) return getWeaponKey(self.Original, "Description") end
				_G[i.."weaker"..id].GetIcon = function(self) return "weapons/enemy_scorpion1.png" end
				_G[i.."weaker"..id].GetClass = function(self) return "Enemy" end
				setmetatable(_G[i.."weaker"..id], {__index = _G[id]})
				--no idea why we need both that and the rest but we do
				i = i + 1
				amount = amount + 1
			until weapon.Damage - amount < 0 or i > 9
		end
	end
end

local function PrepareTables()						--setup all status tables here so we don't need to check everywhere
	modApi:conditionalHook(function()			--we need the conditional hook for some reason
		return true and Game ~= nil and GAME ~= nil and (GetCurrentMission() ~= nil)
	end, 
	function()
		local mission = GetCurrentMission()
		if not mission then 
			LOG("Delayed status tables for some reason.")
			modApi:runLater(function() PrepareTables() end)
		end
		local tablesList = Status.List()
		for i = 1, #tablesList do
			mission[tablesList[i].."Table"] = mission[tablesList[i].."Table"] or {}
		end
		mission["AdjScoreTable"] = mission["AdjScoreTable"] or {}
		if Game:GetTurnCount() == 0 and Game:GetTeamTurn() == TEAM_ENEMY then	--make sure this only runs on mission start?
			for i = 0, 2 do
				local pawn = Board:GetPawn(i)
				if pawn then pawn:SetPowered(true) end		--cancels out the sleep status that carries over for some reason
			end
		end
		LOG("Created status tables.")

	end)
end

local function WakeUp()
	for i = 0, 2 do
		Status.RemoveStatus(i, "Sleep")
	end
end

local function StoreInsanity()
	local mission = GetCurrentMission()
	if not mission then return end
	if GAME.InsanityTable == nil then GAME.InsanityTable = {} end
	for i = 0, 2 do
		local pawn = Board:GetPawn(i)
		if pawn and mission.InsanityTable[pawn:GetId()] and mission.InsanityTable[pawn:GetId()] > 0 then
			GAME.InsanityTable[pawn:GetPersonality()..pawn:GetPilotName(NAME_NORMAL)] = mission.InsanityTable[pawn:GetId()]
		end
	end
end

local function ReaddInsanity()
	modApi:conditionalHook(function()			--we need the conditional hook to wait for PrepareTables
		return true and Game ~= nil and GAME ~= nil and (GetCurrentMission() ~= nil or IsTestMechScenario()) and GetCurrentMission().InsanityTable ~= nil
	end, 
	function()
		local mission = GetCurrentMission()
		for i = 0, 2 do
			local pawn = Board:GetPawn(i)
			if pawn and GAME.InsanityTable ~= nil and GAME.InsanityTable[pawn:GetPersonality()..pawn:GetPilotName(NAME_NORMAL)] and GAME.InsanityTable[pawn:GetPersonality()..pawn:GetPilotName(NAME_NORMAL)] > 0 then
				Status.ApplyInsanity(pawn:GetId(), GAME.InsanityTable[pawn:GetPersonality()..pawn:GetPilotName(NAME_NORMAL)], true)
				GAME.InsanityTable[pawn:GetPersonality()..pawn:GetPilotName(NAME_NORMAL)] = nil
			end
		end
	end)
end



local function EVENT_onModsLoaded()
	modapiext:addPawnSelectedHook(function(mission, pawn)	--explanations
		if not (pawn and sdlext.isShiftDown()) then return end
		local pawnStatuses = Status.List(pawn)
		if #pawnStatuses == 0 then return end
		local id = pawn:GetId()
		local desc = ""
		for k, status in ipairs(pawnStatuses) do	--I'd rather this were a table, but I need to insert data and stuff.
			local statusDesc = ""
			if status == "Alluring" then statusDesc = "Makes Vek want to be adjacent to this pawn." end
			if status == "Blind" then statusDesc = "Makes units unable to target beyond two tiles ("..mission.BlindTable[id].." turns left)." end
			if status == "Bloodthirsty" then statusDesc = "Bloodthirsty Vek will prioritize enemies over buildings." end
			if status == "Bonded" then statusDesc = "Bonded units will take 1 damage when other bonded units take damage. Can trigger once per turn." end
			if status == "Chill" then statusDesc = "Chilled units will become frozen when chilled again. Chill + Wet also freezes. Removed when frozen or on fire." end
			if status == "Confusion" then 
				if pawn:GetTeam() == TEAM_ENEMY then
					statusDesc = "Confused Vek will choose their worst option, typically attacking allies, instead of their best option."
				else
					statusDesc = "Confused mechs will move to a random destination at the start of the player's turn."
				end
				statusDesc = statusDesc.." ("..mission.ConfusionTable[id].." turns left)."
			end
			if status == "Dodge" then statusDesc = "Dodges incoming instant attacks by moving to a nearby tile. Vek queued attacks are unaffected." end
			if status == "Doomed" then 
				if mission.DoomedTable[id].amount > 0 then statusDesc = "Takes "..mission.DoomedTable[id].amount.." damage every turn. " end
				statusDesc = statusDesc.."On death, the pawn's tile turns into lava. "
				if Board:GetPawn(mission.DoomedTable[id].source) then
					statusDesc = statusDesc.."Removed by killing the source of the status (."..Board:GetPawn(mission.DoomedTable[id].source):GetName()..")." 
				end
			end
			if status == "Dreadful" then statusDesc = "Prevents Vek from queuing attacks adjacent to this pawn and makes them avoid being adjacent to this pawn." end
			if status == "Dry" then statusDesc = "Takes 1 extra damage from fire. Removed by Wet." end
			if status == "Glory" then 
				if pawn:GetTeam() == TEAM_ENEMY then
					statusDesc = "Glory turns Vek weapons into the boss version."
				else
					statusDesc = "Glory fully upgrades mech weapons."
				end
				statusDesc = statusDesc.." ("..mission.GloryTable[id].turns.." turns left)."
			end
			if status == "Gunk" then statusDesc = "Covered in sticky gunk, which does nothing by itself but is consumed by some effects." end
			if status == "Hemorrhage" then statusDesc = "When a hemorrhaging unit would heal, they take that much damage instead." end
			if status == "Infested" then statusDesc = "Will die after "..mission.InfestedTable[id].." turns. Removed by damage, fire, and A.C.I.D.." end
			if status == "Insanity" then statusDesc = "When a hemorrhaging unit would heal, they take that much damage instead." end
			if status == "LeechSeed" then statusDesc = "Takes 1 damage every turn, healing the unit that applied the leech seed, if any. Removed by fire." end
			if status == "Necrosis" then statusDesc = "Prevents healing." end
			if status == "Powder" then statusDesc = "When a unit has both fire and powder, they explode, taking 1 damage and dealing 1 damage to adjacent tiles, doubled if Dry. Removed by Wet." end
			if status == "Regen" then statusDesc = "Heals "..mission.RegenTable[id].." damage per turn." end
			if status == "Reactive" then statusDesc = "When applied A.C.I.D., removes it and smokes adjacent tiles." end
			if status == "Rooted" then
				if mission.RootedTable[id] > 0 then statusDesc = "Immobilizes this unit and deals "..mission.RootedTable[id].." damage to them every turn. Removed by fire." end
				if mission.RootedTable[id] < 0 then statusDesc = "Immobilizes this unit and heals "..mission.RootedTable[id].." damage every turn. Removed by fire." end
				if mission.RootedTable[id] == 0 then statusDesc = "Immobilizes this unit. Removed by fire." end
			end
			if status == "Shatterburst" then statusDesc = "When frozen, deals 1 damage to adjacent tiles and frees the unit." end
			if status == "Shocked" then statusDesc = "Flips attack direction on damage. When applied a second time or Wet, clears queued actions." end
			if status == "Sleep" then statusDesc = "Prevents this unit from acting. Removed when the unit takes damage ("..mission.SleepTable[id].." turns left)." end
			if status == "Targeted" then statusDesc = "Makes Vek want to attack that unit." end
			if status == "Toxin" then statusDesc = "After its turn, a unit with Toxin takes damage equal to its missing health; if this kills, adjacent units are applied Toxin. Removed by A.C.I.D. and healing." end
			if status == "Weaken" then
				local amount = tonumber(string.sub(pawn:GetWeaponBaseType(1),1,1))
				if mission.WeakenTable[id] > 0 then statusDesc = "Lowers damage dealt by "..amount..". Effect decreases by "..mission.WeakenTable[id].." every turn." end
				if mission.WeakenTable[id] < 0 then statusDesc = "Lowers damage dealt by "..amount..". Effect increases by "..mission.WeakenTable[id].." every turn." end
				if mission.WeakenTable[id] == 0 then statusDesc = "Lowers damage dealt by "..amount.."." end
			end
			if status == "Wet" then statusDesc = "Cancels fire, dry, and powder. Wet + Chill freezes. Wet + Shocked clears queued actions." end
			
			if statusDesc ~= "" then desc = desc.."\n"..status..": "..statusDesc end
		end
		
		Global_Texts["StatusLib_TempExplanation_Title"] = "Statuses"
		Global_Texts["StatusLib_TempExplanation_Text"] = desc
		Game:AddTip("StatusLib_TempExplanation", pawn:GetSpace())
		Global_Texts["StatusLib_TempExplanation_Title"] = nil		--for some reason the game keeps reusing previous tip contents if I don't delete entries
		Global_Texts["StatusLib_TempExplanation_Text"] = nil		--something something caching
	end)
	modapiext:addPawnHealedHook(function(mission, pawn, healingTaken)	--necrosis/hemorrhage/toxin
		local id = pawn:GetId()
		if mission.NecrosisTable[id] then
			if pawn:GetHealth() - healingTaken <= 0 then 
				pawn:Kill(false)
			else
				pawn:SetHealth(pawn:GetHealth() - healingTaken)
			end
		elseif mission.HemorrhageTable[id] then
			pawn:SetHealth(pawn:GetHealth() - healingTaken * 2)
		elseif mission.ToxinTable[id] then		--only get cured if healing was not prevented
			Status.RemoveStatus(id, "Toxin")
		end
		-- modApi:runLater(function() ReapplyOverheal() end)
	end)
	modapiext:addPawnIsFireHook(function(mission, pawn, isFire)			--powder/dry/wet, remove chill/hemorrhage/roots/leechseed
		if not (mission and pawn and isFire) then return end
		local id = pawn:GetId()
		local point = pawn:GetSpace()
		if mission.WetTable and mission.WetTable[id] then
			pawn:SetFire(false)
			Board:SetSmoke(point, true, true)
			Status.RemoveStatus(id, "Wet")
		end
		if mission.PowderTable[id] then
			Status.RemoveStatus(id, "Powder")
			
			local amount = 1
			if mission.DryTable[id] ~= nil then
				amount = 2
				Status.RemoveStatus(id, "Dry")
			end
			Board:DamageSpace(SpaceDamage(point, amount))
			Board:AddAnimation(point, "ExploAir"..amount, 1)
			for i = DIR_START, DIR_END do
				Board:DamageSpace(SpaceDamage(point + DIR_VECTORS[i], 1))
				Board:AddAnimation(point, "explopush"..amount.."_"..i, 1)
			end
		elseif mission.DryTable[id] ~= nil then
			Board:DamageSpace(SpaceDamage(point, 1))
			Status.RemoveStatus(id, "Dry")
		end
		Status.RemoveStatus(id, "Hemorrhage")
		Status.RemoveStatus(id, "Chill")
		Status.RemoveStatus(id, "Rooted")
		Status.RemoveStatus(id, "LeechSeed")
	end)
	modapiext:addPawnIsAcidHook(function(mission, pawn, isAcid)			--reactive, remove toxin
		if not (mission and pawn and isAcid) then return end
		local id = pawn:GetId()
		if mission.ReactiveTable[id] then
			Status.RemoveStatus(id, "Reactive")
			local point = pawn:GetSpace()
			for i = DIR_START, DIR_END do
				local damage = SpaceDamage(point + DIR_VECTORS[i])
				damage.iSmoke = 1
				Board:DamageSpace(damage)
			end
		end
		Status.RemoveStatus(id, "Toxin")
	end)
	modapiext:addPawnIsFrozenHook(function(mission, pawn, isFrozen)		--shatterburst, remove chill
		if not (mission and pawn and isFrozen) then return end
		local id = pawn:GetId()
		Status.RemoveStatus(id, "Chill")
		if mission.ShatterburstTable[id] then
			Status.RemoveStatus(id, "Shatterburst")
			local point = pawn:GetSpace()
			Board:DamageSpace(SpaceDamage(point, 1))
			Board:AddAnimation(point, "ExplIce1", 1)
			for i = DIR_START, DIR_END do
				Board:DamageSpace(SpaceDamage(point + DIR_VECTORS[i], 1))
			end
		end
	end)
	modapiext:addPawnDamagedHook(function(mission, pawn, damageTaken)	--bonded/shocked, remove sleep
		if not (mission and pawn) then return end
		local id = pawn:GetId()
		if Status.GetStatus(id, "Bonded") and not CustomAnim:get(id, "StatusBondedOff") then
			for bonded, _ in pairs(mission.BondedTable) do
				if bonded ~= id and CustomAnim:get(bonded, "StatusBonded") and not CustomAnim:get(bonded, "StatusBondedOff") then
					modApi:runLater(function() Board:GetPawn(bonded):ApplyDamage(SpaceDamage(Board:GetPawn(bonded):GetSpace(), 1)) end)
					CustomAnim:add(bonded, "StatusBondedOff")
				end
			end
			CustomAnim:add(id, "StatusBondedOff")
		end
		if Status.GetStatus(id, "Shocked") then 
			if Status.GetStatus(id, "Shocked") == 1 then
				pawn:ApplyDamage(SpaceDamage(pawn:GetSpace(), 0, DIR_FLIP)) 
			else 
				mission.ShockedTable[id] = 1
			end
		end
		Status.RemoveStatus(id, "Sleep")
	end)
	modapiext:addPawnKilledHook(function(mission, pawn)					--doomed, refresh overheal
		if not (mission and pawn) then return end
		local id = pawn:GetId()
		if mission.DoomedTable[id] ~= nil then
			local damage = SpaceDamage(pawn:GetSpace(), DAMAGE_DEATH)
			damage.sAnimation = "tentacles"
			damage.iTerrain = TERRAIN_LAVA
			damage.sSound = "/props/tentacle"
			Board:DamageSpace(damage)
		end
		mission.DodgeTable[id] = nil
		for doomedID, doomedInformation in pairs(mission.DoomedTable) do
			if id == doomedInformation.source then Status.RemoveStatus(doomedID, "Doomed") end
		end
		if _G[pawn:GetType()].Leader == LEADER_BOSS or _G[pawn:GetType()].Leader == LEADER_HEALTH then 
			modApi:runLater(function() ReapplyOverheal() end)
		end
	end)
	
	modApi:addPostStartGameHook(GenerateWeakenWeapons)					--generate the weapons Weaken replaces Vek weapons by
	modApi:addPreLoadGameHook(GenerateWeakenWeapons)					--also do it on reload otherwise the game is not happy
	
	modApi:addMissionStartHook(PrepareTables)							--create tables for all statuses so we don't have to check everywhere
	modApi:addMissionStartHook(ReaddInsanity)							
	modApi:addMissionNextPhaseCreatedHook(PrepareTables)				--also do it on next phase otherwise it won't work
	
	modApi:addMissionNextPhaseCreatedHook(function()
		modApi:conditionalHook(function()								--we need the conditional hook for some reason
			return true and Game ~= nil and GAME ~= nil and GetCurrentMission() ~= nil
		end, 
		function()
			ReapplyOverheal()
		end)
	end)				--Health boosts are lost on game refresh
	modApi:addPostLoadGameHook(PrepareTables)		
	modApi:addPostLoadGameHook(ReapplyOverheal)		
	modapiext:addResetTurnHook(function()
		modApi:scheduleHook(2000, PrepareTables)
		--Apparently this doesn't prepare tables properly, assigning them to the mission object before cleanup
	end)
	modapiext:addResetTurnHook(ReapplyOverheal)		
	
	modApi:addTestMechEnteredHook(PrepareTables)						--also do it on test environment entered
	
	modApi:addMissionEndHook(WakeUp)									--remove sleep status because unpowered carries over
	modApi:addMissionEndHook(StoreInsanity)	
	modApi:addMissionEndHook(ResetOverheal)	
	
	modApi:addPreEnvironmentHook(function(mission)						--this is for status that triggers before Vek actions
		for _, p in ipairs(Board) do
			mission.AdjScoreTable[p:GetString()] = 0
		end
		--we reset the entire table every turn, then reload it with alluring/dreadful pawns
		--it's used in the scoring functions
		for id, score in pairs(mission.AlluringTable) do
			local pawn = Board:GetPawn(id)
			if pawn then
				local tile = pawn:GetSpace()
				for i = DIR_START, DIR_END do
					local curr = tile + DIR_VECTORS[i]
					mission.AdjScoreTable[curr:GetString()] = mission.AdjScoreTable[curr:GetString()] + score
				end
			end
		end
		for id, score in pairs(mission.DreadfulTable) do
			local pawn = Board:GetPawn(id)
			if pawn then
				local tile = pawn:GetSpace()
				for i = DIR_START, DIR_END do
					local curr = tile + DIR_VECTORS[i]
					mission.AdjScoreTable[curr:GetString()] = mission.AdjScoreTable[curr:GetString()] + score
					if Board:GetPawn(curr) then Board:GetPawn(curr):ClearQueued() end
				end
			end
		end
		for id, doomedInformation in pairs(mission.DoomedTable) do
			local pawn = Board:GetPawn(id)
			if pawn then
				if pawn:IsDead() or (type(doomedInformation.source) == "number" and doomedInformation.source ~= -1 and 
				(not Board:GetPawn(doomedInformation.source) or Board:GetPawn(doomedInformation.source):IsDead())) then			
				--doublechecking with pawnIsKilled, but something could have removed the pawn without killing
					Status.RemoveStatus(id, "Doomed")
				else
					local damage = SpaceDamage(pawn:GetSpace(), doomedInformation.amount)
					damage.sAnimation = "PsionAttack_Back"
					Board:AddAnimation(pawn:GetSpace(), "PsionAttack_Front", ANIM_NO_DELAY)
					if Board:GetTerrain(pawn:GetSpace()) == TERRAIN_WATER and Board:IsAcid(pawn:GetSpace()) then
						Board:AddAnimation(pawn:GetSpace(), "Splash_acid", ANIM_NO_DELAY)
					elseif Board:IsTerrain(pawn:GetSpace(),TERRAIN_LAVA) then
						Board:AddAnimation(pawn:GetSpace(), "Splash_lava", ANIM_NO_DELAY)
					elseif Board:GetTerrain(pawn:GetSpace()) == TERRAIN_WATER then
						Board:AddAnimation(pawn:GetSpace(), "Splash", ANIM_NO_DELAY)
					end
					pawn:ApplyDamage(damage)
					if type(doomedInformation.source) == "number" and doomedInformation.source ~= -1 and Board:GetPawn(doomedInformation.source) then Board:Ping(Board:GetPawn(doomedInformation.source):GetSpace(), GL_Color(100, 100, 0)) end
					--here to let the player visualise the source of the effect
				end
			end
		end
		for id, sleepTurnsLeft in pairs(mission.SleepTable) do
			local pawn = Board:GetPawn(id)
			if pawn then
				LOG(pawn:GetType().." has "..sleepTurnsLeft.." turn(s) left to sleep.")
				if sleepTurnsLeft <= 0 then 
					pawn:SetPowered(true) 
					mission.SleepTable[id] = nil
					if pawn:GetCustomAnim():sub(-6, -1) == "_sleep" then
						if pawn:GetCustomAnim():sub(-13, -1) == "special_sleep" then
						--this lets pawns have two different anims for sleeping
							LOG(pawn:GetCustomAnim():sub(1, -15))
							pawn:SetCustomAnim(pawn:GetCustomAnim():sub(1, -15))
						else
							pawn:SetCustomAnim(pawn:GetCustomAnim():sub(1, -7))
						end
					else
						CustomAnim:rem(id, "StatusSleep")
					end
					
				end
				mission.SleepTable[id] = sleepTurnsLeft - 1
			end
		end
		local fx = SkillEffect()
		for id, leecherId in pairs(mission.LeechSeedTable) do
			local pawn = Board:GetPawn(id)
			local leecher = Board:GetPawn(leecherId)
			if pawn and leecher and id ~= leecherId then
				fx:AddSafeDamage(SpaceDamage(pawn:GetSpace(), 1))
				fx:AddArtillery(pawn:GetSpace(), SpaceDamage(leecher:GetSpace(), -1), "effects/shotup_grid.png", NO_DELAY)
			end
		end
		Board:AddEffect(fx)
		for id, blindTurns in pairs(mission.BlindTable) do
			local pawn = Board:GetPawn(id)
			if pawn then mission.BlindTable[id] = blindTurns - 1 end
			if mission.BlindTable[id] < 0 then Status.RemoveStatus(id, "Blind") end
		end
		for id, confusionTurns in pairs(mission.ConfusionTable) do
			local pawn = Board:GetPawn(id)
			if pawn then mission.ConfusionTable[id] = confusionTurns - 1 end
			if mission.ConfusionTable[id] < 0 then Status.RemoveStatus(id, "Confusion") end
		end
		for id, info in pairs(mission.RootedTable) do
			local pawn = Board:GetPawn(id)
			if pawn and info.amount ~= 0 then pawn:ApplyDamage(SpaceDamage(pawn:GetSpace(), info.amount)) end
		end
		for id, _ in pairs(mission.RegenTable) do
			local pawn = Board:GetPawn(id)
			if pawn then pawn:ApplyDamage(SpaceDamage(pawn:GetSpace(), -1)) end
		end
		for id, _ in pairs(mission.InfestedTable) do
			local pawn = Board:GetPawn(id)
			if pawn then
				if not pawn:IsInfected() then
					mission.InfestedTable[id] = nil
				elseif mission.InfestedTable[id] > 0 then
					mission.InfestedTable[id] = mission.InfestedTable[id] - 1
				elseif mission.InfestedTable[id] <= 0 then
					pawn:Kill(false)
					Board:AddBurst(pawn:GetSpace(), "Emitter_Infected", DIR_NONE)
					Board:AddBurst(pawn:GetSpace(), "Emitter_Infected", DIR_NONE)
					Board:AddBurst(pawn:GetSpace(), "Emitter_Infected", DIR_NONE)
					mission.InfestedTable[id] = nil
				end
			end
		end
	end)
	modApi:addNextTurnHook(function(mission)							--this is for status that triggers each turn/after Vek actions
		for id, _ in pairs(mission.NecrosisTable) do
			local pawn = Board:GetPawn(id)
			if pawn and not pawn:IsDead() then pawn:SetMaxHealth(pawn:GetHealth()) end
		end
		for id, _ in pairs(mission.BondedTable) do
			local pawn = Board:GetPawn(id)
			if pawn then CustomAnim:rem(id, "StatusBondedOff") end
		end
		for id, gloryInfo in pairs(mission.GloryTable) do				--must happen after Vek performed queued actions
			local pawn = Board:GetPawn(id)
			if pawn and Game:GetTeamTurn() == pawn:GetTeam() then mission.GloryTable[id].turns = mission.GloryTable[id].turns - 1 end
			if mission.GloryTable[id].turns < 0 then Status.RemoveStatus(id, "Glory") end
		end
		if Game:GetTeamTurn() == TEAM_PLAYER then						--do confusion on player mechs: they move somewhere random
			for i = 0, 2 do
				local pawn = Board:GetPawn(i)
				if mission.ConfusionTable[i] ~= nil and pawn and not pawn:IsDead() then
					local targets = extract_table(Board:GetReachable(pawn:GetSpace(), pawn:GetMoveSpeed(), pawn:GetPathProf()))
					local target = random_removal(targets)
					if target == pawn:GetSpace() and #targets > 0 then target = random_removal(targets) end
					--try to force actual movement if possible
					if target ~= pawn:GetSpace() then
						local ret = SkillEffect()
						ret:AddMove(Board:GetPath(pawn:GetSpace(), target, pawn:GetPathProf()), FULL_DELAY)
						Board:AddEffect(ret)
						pawn:SetMovementSpent(true)
					end
				end
			end
		else															--do toxin check to propagate it		
			for id, _ in pairs(mission.ToxinTable) do
				local pawn = Board:GetPawn(id)
				if (not pawn) or pawn:IsDead() then
					mission.ToxinTable[id] = nil
				elseif pawn:IsDamaged() then
					local damage = SpaceDamage(pawn:GetSpace(), pawn:GetMaxHealth() - pawn:GetHealth())
					if Board:IsDeadly(damage, pawn) then
						Board:Ping(pawn:GetSpace(), GL_Color(100, 200, 100))
						Board:AddAlert(pawn:GetSpace(), "Toxin Damage")
						CustomAnim:rem(id, "StatusToxin")				--anim disappears after Vek emerge otherwise, which looks weird
						for i = DIR_START, DIR_END do
							local curr = pawn:GetSpace() + DIR_VECTORS[i]
							local spreadTo = Board:GetPawn(curr)
							if spreadTo then 
								modApi:runLater(function() Status.ApplyToxin(spreadTo:GetId()) end)
							end
							
						end
					else
						Status.RemoveStatus(id, "Toxin")
					end
					Board:DamageSpace(damage)
				end
			end
		end
		for id, recoverPerTurn in pairs(mission.WeakenTable) do
			local pawn = Board:GetPawn(id)
			if pawn and Game:GetTeamTurn() == pawn:GetTeam() and recoverPerTurn ~= 0 then
				local hasWeakenedWeapon = false
				for i = pawn:GetWeaponCount(), 1, -1 do
					local weapon = pawn:GetWeaponBaseType(i)
					if string.match(weapon, "^%dweaker") then 
						local baseWeapon = _G[weapon].Original
						local amount = tonumber(string.sub(weapon,1,1)) - recoverPerTurn
						local newWeapon
						if amount <= 0 then 
							newWeapon = baseWeapon 
						else 
							newWeapon = amount.."weaker"..baseWeapon 
							hasWeakenedWeapon = true
						end
						local target = pawn:GetQueuedTarget()
						local indexQueued = pawn:GetQueuedWeaponId()
						pawn:RemoveWeapon(i)
						pawn:AddWeapon(newWeapon)
						pawn:FireWeapon(target, indexQueued)
					end
				end
				if not hasWeakenedWeapon then CustomAnim:rem(id, "StatusWeaken") end
			end
		end
	end)
	local calculatingDodge = false
	
	local function DoDodge(mission, pawn, skillEffect)
		if not pawn or not mission then return end
		if calculatingDodge then return end
		local pawnsWhoDodged = {}	--we make sure one pawn cannot jump into another instance of damage from the same skill effect and dodge it again
		local dodgersCount = 0
		mission.DodgeTable = mission.DodgeTable or {}
		for id, infos in pairs(mission.DodgeTable) do	--quick check early to avoid running stuff pointlessly
			if Board:GetPawn(id) then dodgersCount = dodgersCount + 1 end
		end
		if dodgersCount == 0 then return end
		
		local hash = function(point) return point.x * 10 + point.y end
		local affectedTiles = {}	--store tiles the skillEffect will hit so we don't dodge into another one
		
		for _, fx in ipairs(extract_table(skillEffect.effect)) do
			affectedTiles[hash(fx.loc)] = fx.iDamage
		end
		
		for _, fx in ipairs(extract_table(skillEffect.effect)) do
			local target = Board:GetPawn(fx.loc)
			
			local dodgeInfo = (target ~= nil) and Status.GetStatus(target:GetId(), "Dodge") or nil
			if dodgeInfo and not pawnsWhoDodged[target:GetId()] then	--don't dodge the same attack twice either
				local targetWasQueued = target:GetQueuedTarget() ~= Point(-1, -1) and target:GetTeam() == TEAM_ENEMY	--used to requeue attack for Vek
				
				local PawnBackup = Pawn; Pawn = pawn
				local weapon = pawn:GetQueuedWeapon() or pawn:GetWeapons()[1] or _G[pawn:GetType()].SkillList[1]
	
				local actions = {}
				local pathProfile = pawn:GetPathProf()
				if dodgeInfo.movementType ~= "Walk" then pathProfile = PATH_FLYER end
				local reachable = extract_table(Board:GetReachable(fx.loc, dodgeInfo.distance, pathProfile))
				
				-- create a list of all possible moves.
				calculatingDodge = true
				for _, loc in ipairs(reachable) do
					-- move score
					local moveScore = 0
					if dodgeInfo.smart then moveScore = ScorePositioning(loc, pawn) end
					if affectedTiles[hash(loc)] ~= DAMAGE_ZERO then moveScore = -100 end	--don't dodge into more damage
					if Board:IsBlocked(loc, pawn:GetPathProf()) then moveScore = -100 end	--don't dodge into a tile you can't stand in
					if targetWasQueued then
						local targets = extract_table(weapon:GetTargetArea(loc))
						for _, target in ipairs(targets) do
							if Board:IsValid(target) then
								-- attack score
								local attackScore = 0
								if dodgeInfo.smart and targetWasQueued then attackScore = weapon:GetTargetScore(loc, target) end
								
								table.insert(
									actions,
									{
										loc = loc,
										target = target,
										score = moveScore + attackScore
									}
								)
							end
						end
					else
						table.insert(
							actions,
							{
								loc = loc,
								target = nil,
								score = moveScore
							}
						)
					end
				end
				calculatingDodge = false
				Pawn = PawnBackup
				
				if #actions == 0 then return end
				
				-- sort scores from high to low.
				table.sort(actions, function(a,b) return a.score > b.score end)
				
				-- count #indices with same top score.
				local i = 1
				while(actions[i+1] and actions[i+1].score == actions[1].score) do
					i = i + 1
				end
				
				-- pick one top score at random.
				math.randomseed(Game:GetTurnCount() + target:GetId() + dodgeInfo.amount)
				local bestAction = actions[math.random(1, i)]
				
				--Save old effect
				local oldEffect = skillEffect.effect or DamageList()
				local oldQEffect = skillEffect.q_effect or DamageList()
				local oldEffectCopy = DamageList()
				local oldQEffectCopy = DamageList()
				--Make a copy
				if oldEffect then 
					for i = 1, oldEffect:size() do
						local oldDamage = oldEffect:index(i);
						oldEffectCopy:push_back(oldDamage)
					end
				end
				if oldQEffect then 
					for i = 1, oldQEffect:size() do
						local oldDamage = oldQEffect:index(i);
						oldQEffectCopy:push_back(oldDamage)
					end
				end
				--Reset
				skillEffect.effect = DamageList()
				skillEffect.q_effect = DamageList()
				--Insert
				
				if bestAction then 
					-- move away from danger
					skillEffect:AddScript(string.format("Status.LowerDodge(%s)", target:GetId()))
					if dodgeInfo.movementType == "Teleport" then
						skillEffect:AddTeleport(fx.loc, bestAction.loc, NO_DELAY)
					elseif dodgeInfo.movementType == "Leap" then
						local leapMovement = PointList()
						leapMovement:push_back(fx.loc)
						leapMovement:push_back(bestAction.loc)
						skillEffect:AddLeap(leapMovement, NO_DELAY)
					elseif dodgeInfo.movementType == "Burrow" then
						skillEffect:AddBurrow(Board:GetPath(fx.loc, bestAction.loc, PATH_FLYER), NO_DELAY)
					else
						skillEffect:AddMove(Board:GetPath(fx.loc, bestAction.loc, target:GetPathType()), NO_DELAY)
					end
				end
				--Add in old effects
				for i = 1, oldEffectCopy:size() do
					local oldDamage = oldEffectCopy:index(i);
					skillEffect.effect:push_back(oldDamage)
				end
				for i = 1, oldQEffectCopy:size() do
					local oldDamage = oldQEffectCopy:index(i);
					skillEffect.q_effect:push_back(oldDamage)
				end
				
				if bestAction and targetWasQueued then
					-- fire the pawn's weapon in the chosen direction
					skillEffect:AddScript(string.format([[
						modApi:runLater(function()
							local pawn = Board:GetPawn(%s)
							if pawn then pawn:FireWeapon(%s, 1) end
						end)
					]], target:GetId(), bestAction.target:GetString()))
				end
				pawnsWhoDodged[target:GetId()] = true
			end
		end
	end
	modapiext:addSkillBuildHook(function(mission, pawn, weaponId, p1, p2, skillEffect)
		DoDodge(mission, pawn, skillEffect)
	end)
	modapiext:addFinalEffectBuildHook(function(mission, pawn, weaponId, p1, p2, p3, skillEffect)
		DoDodge(mission, pawn, skillEffect)
	end)

	modapiext:addTargetAreaBuildHook(function(mission, pawn, weaponId, p1, targetArea)
		if pawn:IsMech() and Status.GetStatus(pawn:GetId(), "Blind") and weaponId ~= "Move" then
			local targets = extract_table(targetArea)
			local closeTargets = {}
			for _, point in pairs(targets) do
				if point:Manhattan(p1) <= 2 then table.insert(closeTargets, point) end
			end
			if #closeTargets == #targets then return end
			while not targetArea:empty() do
				targetArea:erase(0)
			end
			for _, point in ipairs(closeTargets) do
				targetArea:push_back(point)
			end
		end
	end)
	modapiext:addSecondTargetAreaBuildHook(function(mission, pawn, weaponId, p1, p2, targetArea)
		if pawn:IsMech() and Status.GetStatus(pawn:GetId(), "Blind") and weaponId ~= "Move" then
			local targets = extract_table(targetArea)
			local closeTargets = {}
			for _, point in pairs(targets) do
				if point:Manhattan(p2) <= 2 then table.insert(closeTargets, point) end
			end
			if #closeTargets == #targets then return end
			while not targetArea:empty() do
				targetArea:erase(0)
			end
			for _, point in ipairs(closeTargets) do
				targetArea:push_back(point)
			end
		end
	end)
	LOG("Status Library added its hooks.")
end

-- modApi.events.onModsLoaded:subscribe(EVENT_onModsLoaded)

--fixes for Glory: replaces junk leaper boss weapon from vanilla, adds weapons to Moth and Burrower
--we check whether another mod added boss versions of Moth and Burrower first though

LeaperAtkB = LeaperAtk1:new{ --just a weaker mosquito boss
	Damage = DAMAGE_DEATH,
	Class = "Enemy",
	Name = "Vorpal Fangs",
	Description = "Web a target, preparing to stab it with a devastating attack. Kills target.",
}

if _G["MothAtkB"] == nil then --ranged bouncer boss attack
	MothAtkB = MothAtk1:new{
		Class = "Enemy",
		Name = "Abhorrent Pellets",
		Description = "Launch an artillery attack at three tiles in a row, pushing shooter and targets.",
		Damage = 3,
	}
	function MothAtkB:GetSkillEffect(p1, p2)
		local ret = SkillEffect()
		local dir = GetDirection(p2-p1)
		local dirback = GetDirection(p1-p2)
		
		local damage = SpaceDamage(p1, 0, dirback)
		damage.sAnimation = "airpush_"..dirback
		ret:AddQueuedDamage(damage)
		
		ret:AddQueuedArtillery(SpaceDamage(p2, self.Damage, dir), self.Projectile)
		ret:AddQueuedArtillery(SpaceDamage(p2 + DIR_VECTORS[(dir+1)%4], self.Damage, dir), self.Projectile)
		ret:AddQueuedArtillery(SpaceDamage(p2 + DIR_VECTORS[(dir-1)%4], self.Damage, dir), self.Projectile)
		return ret
	end
end

if _G["BurrowerAtkB"] == nil and _G["BurrowerAtk2"] ~= nil then
	BurrowerAtkB = BurrowerAtk2:new{
		Class = "Enemy",
		Name = "Eviscerating Carapace",
		Description = "Slam against 5 tiles in a row, hitting each for 2 damage.",
	}

	function BurrowerAtkB:GetSkillEffect(p1,p2)
		local ret = SkillEffect()
		local direction = GetDirection(p2 - p1)
		local damage = SpaceDamage(p2,self.Damage)
		damage.sSound = self.SoundBase.."attack"
		ret:AddQueuedDamage(SpaceDamage(p2 + DIR_VECTORS[(direction + 1)% 4], self.Damage))
		ret:AddQueuedDamage(SpaceDamage(p2 + DIR_VECTORS[(direction + 1)% 4] * 2, self.Damage))
		ret:AddQueuedDamage(SpaceDamage(p2 - DIR_VECTORS[(direction + 1)% 4], self.Damage))
		ret:AddQueuedDamage(SpaceDamage(p2 - DIR_VECTORS[(direction + 1)% 4] * 2, self.Damage))
		return ret
	end
end

--voice lines for reaching insanity 5
for k, v in pairs(Personality) do
	if v["Meta_GoingInsane1"] == nil then
		v["Meta_GoingInsane1"] = "Ïa! Ïa!"
		v["Meta_GoingInsane2"] = "Cthulhu fhtagn!"
		v["Meta_GoingInsane3"] = "Impossible shapes and cyclopean obelisks!"
		v["Meta_GoingInsane4"] = "A billion eyes stare at me from a billion seals!"
		v["Meta_GoingInsane5"] = "It comes from the gateless gate!"
		v["Meta_GoingInsane6"] = "The seal is breaking apart!"
		v["Meta_GoingInsane7"] = "We are nothing!"
		v["Meta_GoingInsane8"] = "The Deep Ones demand sacrifice!"
		v["Meta_GoingInsane9"] = "Shatter the buildings! Feed the civilians to the sea!"
		v["Meta_GoingInsane10"] = "The dreams seep in on the edges of my sight!"
		v["Meta_GoingInsane11"] = "The light of the North Star, breaking the minds of children!"
		v["Meta_GoingInsane12"] = "We are like lambs to the slaughter! No - ants trampled underfoot!"
		v["Meta_GoingInsane13"] = "Doom, ruin, and dust!"
		v["Meta_GoingInsane14"] = "Ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn! Ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn! Ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn!"
	end
end




if isNewerVersion then
    Status = Status or {}
    Status.version = VERSION

    Status.finalizeInit = function(self)
        modApi.events.onModsLoaded:subscribe(EVENT_onModsLoaded)
		SetupMetatable()
		CreateStatusFunctions()
        LOG("Status Library Version " .. self.version .. " finalized.")
    end
    local function onModsInitialized()
        local isHighestVersion = true
            and Status.initialized ~= true
            and Status.version == VERSION

        if isHighestVersion then
            Status:finalizeInit()
            Status.initialized = true
        end
    end
    modApi.events.onModsInitialized:subscribe(onModsInitialized)
end

StatusLibLoaded = true
return true	