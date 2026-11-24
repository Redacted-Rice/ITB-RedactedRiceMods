
lmn_RepairNotFound = Skill:new{
	Name = "No Such Weapon",
	Description = "Replace Repair looked everywhere, but the weapon you listed does not exist.",
	PathSize = 0,
}

lmn_TipImageNotFound = Skill:new{
	PathSize = 0,
	TipImage = {
		Unit = Point(2,2),
		Target = Point(2,2)
	}
}

function lmn_TipImageNotFound:GetSkillEffect(p1, p2, _, unitMissing, targetMissing)
	local ret = SkillEffect()
	
	if unitMissing then
		ret:AddScript("Board:AddAlert(Point(1,3), 'NO TIPIMAGE UNIT!')")
	end
	
	if targetMissing then
		ret:AddScript("Board:AddAlert(Point(2,4), 'NO TIPIMAGE TARGET!')")
	end
	
	return ret
end
