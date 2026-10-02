
local this = {}

function this.Add(id, tooltip)
	assert(type(id) == 'string')
	assert(type(tooltip) == 'userdata')
	assert(type(tooltip.name) == 'string')
	assert(type(tooltip.desc) == 'string')
	
	local oldFunc = GetSkillInfo
	function GetSkillInfo(skill)
		if skill == id then return tooltip end
		return oldFunc(skill)
	end
end

return this