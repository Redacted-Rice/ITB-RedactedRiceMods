
local this = {Label = "NULL"}
CreateClass(this)

local function list_isEmpty(list)
	return not next(list)
end

function this:GetPilotDialog(event)
	if self[event] ~= nil then
		if type(self[event]) == "table" then
			return random_element(self[event]) or ""
		end
		
		return self[event]
	end
	
	LOG("No pilot dialog found for "..event.." event in "..self.Label)
	return ""
end

-- substitute unreadable characters.
local function formatTexts(texts)
	for i, text in ipairs(texts) do
		text = string.gsub(text,"“","")
		text = string.gsub(text,"”","")
		text = string.gsub(text,"‘","'")
		text = string.gsub(text,"…","...")
		text = string.gsub(text,"’","'")
		text = string.gsub(text,"–","-")
		texts[i] = text
	end
end

-- adds dialog to a personality (this).
-- if flag is nil or true, old dialog will be overwritten.
function this:AddDialog(t, flag)
	assert(type(t) == 'table')
	
	for event, texts in pairs(t) do
		if
			type(texts) == 'string' and
			type(texts) ~= 'table'
		then
			texts = {texts}
		end
		
		assert(type(texts) == 'table')
		formatTexts(texts)
		
		if flag == false then
			self[event] = self[event] or {}
			for i, v in ipairs(texts) do
				self[event][i] = v
			end
		else
			self[event] = texts
		end
		
		if list_isEmpty(self[event]) then
			self[event] = nil
		end
	end
end

return this