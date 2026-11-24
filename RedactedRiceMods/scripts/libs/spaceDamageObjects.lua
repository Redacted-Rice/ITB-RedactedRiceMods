---------------------------------------------------------------------
-- DamageSpace Extended v1.0 - code library
---------------------------------------------------------------------
-- adds functions for creating spaceDamage objects,
-- that can be passed to Board.DamageSpace,
-- in order to execute them immediately
-- without waiting for the current SkillEffect to finish.

local this = {}

local function Add(name)
	this[name] = function(...)
		local fx = SkillEffect()
		fx["Add".. name](fx, ...)
		return fx.effect:index(1)
	end
end

Add("Emitter")
Add("BoardShake")
Add("Grapple")
Add("Voice")

--Add("Script")		-- works, but seems pointless to run an instant script
--Add("Sound")		-- works, but Game:TriggerSound does the same thing
--Add("Delay")		-- nothing happens. no effect to delay
--Add("Airstrike")	-- nothing happens
--Add("Move")		-- nothing happens
--Add("Charge")		-- nothing happens. charge not in spaceDamage object
--Add("Leap")		-- nothing happens. leap not in spaceDamage object
--Add("Melee")		-- damage happens. melee origin not in spaceDamage object
--Add("Projectile")	-- damage happens, but no projectile, as origin is in SkillEffect
--Add("Artillery")	-- damage happens, but no artillery, as origin is in SkillEffect
--Add("Dropper")	-- damage happens. dropper image not in spaceDamage object

return this