--[[
MoveThrough - Snapshot and restore tile/pawn fire and acid during multi-step forced moves.

Wiki: https://github.com/Redacted-Rice/ITB-RedactedRiceMods/wiki/%5BLib%5D-MoveThrough

Author: Das Keifer of Redacted Rice
Discord Server: https://discord.gg/CNjTVrpN4v
]]

local VERSION = "1.1.3"

local isNewestVersion = false
	or MoveThrough == nil
	or modApi:isVersionAbove(VERSION, MoveThrough.version)

if isNewestVersion then
	LOG("MoveThrough: Loading version " .. VERSION .. " (previous: "
			.. tostring(MoveThrough and MoveThrough.version or "none") .. ")")

	MoveThrough = MoveThrough or {}
	MoveThrough.version = VERSION

	function MoveThrough._captureTile(point)
		return {
			fireType = Board:GetFireType(point),
			acid = Board:IsAcid(point),
		}
	end

	function MoveThrough._capturePawn(pawn)
		if not pawn then
			return { fire = false, acid = false }
		end
		return {
			fire = pawn:IsFire(),
			acid = pawn:IsAcid(),
		}
	end

	function MoveThrough.buildPathSnapshots(path, pawn)
		local tiles = {}
		for i = 1, path:size() do
			local point = path:index(i)
			tiles[point:GetString()] = MoveThrough._captureTile(point)
		end
		return tiles, MoveThrough._capturePawn(pawn)
	end

	function MoveThrough._addRestoreTileDamage(tilePoint, savedFireType, savedIsAcid)
		-- Get the current fire type
		local needEffect = false
		local tileDamage = SpaceDamage(tilePoint, DAMAGE_ZERO)

		local savedIsFire = savedFireType ~= FIRE_TYPE_NONE

		local fireType = Board:GetFireType(tilePoint)
		local isFire = Board:IsFire(tilePoint)
		local isAcid = Board:IsAcid(tilePoint)

		if savedIsFire ~= isFire then
			tileDamage.iFire = savedIsFire and EFFECT_CREATE or EFFECT_REMOVE
			if fireType == FIRE_TYPE_FOREST_FIRE then
				tileDamage.iTerrain = TERRAIN_FOREST
			end
			needEffect = true
		end
		if savedIsAcid ~= isAcid then
			tileDamage.iAcid = savedIsAcid and EFFECT_CREATE or EFFECT_REMOVE
			needEffect = true
		end

		if needEffect then
			Board:AddEffect(tileDamage)
		end
	end

	function MoveThrough.restorePreviousTileState(ret, prevTile, tileSnapshots)
		local saved = tileSnapshots[prevTile:GetString()]
		if saved then
			ret:AddScript([[
				MoveThrough._addRestoreTileDamage(]] .. prevTile:GetString() .. [[, ]] .. saved.fireType 
						.. [[, ]] .. tostring(saved.acid) .. [[)
			]])
		end
	end

	-- Called from sScript after each forced move step
	function MoveThrough._addRestorePawnDamage(pawnId, pawnOrigFire, pawnOrigAcid, tileOrigFire, tileOrigAcid, isEndTile)
		local pawn = Board:GetPawn(pawnId)
		if not pawn then
			return
		end

		local loc = pawn:GetSpace()
		local pawnFire = pawn:IsFire()
		local pawnAcid = pawn:IsAcid()

		local pawnDamage = SpaceDamage(loc, DAMAGE_ZERO)
		local changed = false

		-- If the pawn is on fire but was not originally, and its not
		-- on a tile that started on fire, remove the fire
		if pawnFire and not pawnOrigFire and not tileOrigFire then
			pawnDamage.iFire = EFFECT_REMOVE
			if Board:GetFireType(loc) == FIRE_TYPE_FOREST_FIRE then
				pawnDamage.iTerrain = TERRAIN_FOREST
			end
			changed = true
		end

		-- Same for acid
		if pawnAcid and not pawnOrigAcid and not tileOrigAcid then
			pawnDamage.iAcid = EFFECT_REMOVE
			changed = true
		end

		-- If its the last tile, reapply any missing statuses
		if isEndTile then
			if not pawnFire and pawnOrigFire then
				pawnDamage.iFire = EFFECT_CREATE
				changed = true
			end
			if not pawnAcid and pawnOrigAcid then
				pawnDamage.iAcid = EFFECT_CREATE
				changed = true
			end
		end

		if changed then
			Board:DamageSpace(pawnDamage)
		end
	end

	function MoveThrough.restorePawnState(ret, pawnId, pawnSnapshot, landingSnap, isEndTile)
		if not pawnSnapshot then
			return
		end
		ret:AddScript([[
			MoveThrough._addRestorePawnDamage(]] .. pawnId .. [[, ]] 
					.. tostring(pawnSnapshot.fire) .. [[, ]] .. tostring(pawnSnapshot.acid) .. [[, ]] 
					.. tostring(landingSnap.fireType ~= FIRE_TYPE_NONE) .. [[, ]] .. tostring(landingSnap.acid) .. [[, ]]
					.. tostring(isEndTile) .. [[)
		]])
	end

	-- After move + fire at a step: restore tile left behind, then fix pawn hazards
	function MoveThrough.afterStepLeaveTile(ret, pawnId, prevPoint, newPoint, isEndTile, pawnSnapshot, tileSnapshots)
		if prevPoint then
			MoveThrough.restorePreviousTileState(ret, prevPoint, tileSnapshots)
		end
		MoveThrough.restorePawnState(ret, pawnId, pawnSnapshot, tileSnapshots[newPoint:GetString()], isEndTile)
	end
end

return MoveThrough
