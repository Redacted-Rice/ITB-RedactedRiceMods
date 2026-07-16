local mod = {
	id = "redactedrice_SkillChoices",
	name = "Skill Choices",
	icon = "mod_icon.png",
	version = "1.0.1",
	modApiVersion = "2.9.5",
	gameVersion = "1.2.93",
	description = "Choose pilot level up skills from a configurable sized list of options when a pilot levels up.",
	dependencies = {
		redactedrice_memhack = "1.3.0",
		redactedrice_cplus_plus = "1.3.1",
	},
}

function mod:metadata()
	modApi:addGenerationOption(
		"skill_choice_count",
		"Level Up Skill Choices",
		"Number of level up skills offered when a pilot levels up",
		{
			values = { 2, 3, 4, 5, 6, 8, 10, 14, 20, "all" },
			strings = { "2", "3", "4", "5", "6", "8", "10", "14", "20", "All" },
			value = 3,
		}
	)
end

function mod:init(options)
	modApi:appendAsset(
		"img/effects/sc_skillchoices_pause.png",
		self.resourcePath .. "img/effects/sc_skillchoices_pause.png"
	)

	modApi:setText("SkillChoices_PendingSelection_Short", "Pending")
	modApi:setText("SkillChoices_PendingSelection_Full", "Pending Selection")
	modApi:setText("SkillChoices_PendingSelection_Desc", "Awaiting level-up skill choice.")

	cplus_plus_ex:registerSkill("Skill Choices", {
		id = "SkillChoices_PendingSelection",
		shortName = "SkillChoices_PendingSelection_Short",
		fullName = "SkillChoices_PendingSelection_Full",
		description = "SkillChoices_PendingSelection_Desc",
		bonuses = {},
		saveVal = 13,
		reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
		internalSkill = true,
	})

	local skill_choice_ui = require(self.scriptPath .. "skill_choice_ui")
	skill_choice_ui.PENDING_SELECTION_SKILL_ID = "SkillChoices_PendingSelection"
	self.skill_choice_ui = skill_choice_ui
end

function mod:load(options, version)
	-- I want this to be changable mid run so I do this instead of loading
	-- the typical way which is saved with GAME
	local globalOptions = nil
	sdlext.config("modcontent.lua", function(obj)
		if obj.modOptions and obj.modOptions.redactedrice_SkillChoices then
			globalOptions = obj.modOptions.redactedrice_SkillChoices.options
		end
	end)

	self.skill_choice_ui.config_options = {}
	if globalOptions and globalOptions.skill_choice_count then
		self.skill_choice_ui.config_options.skill_choice_count = globalOptions.skill_choice_count.value
	else
		self.skill_choice_ui.config_options.skill_choice_count = 3
	end

	self.skill_choice_ui:load(options, version)
end

return mod
