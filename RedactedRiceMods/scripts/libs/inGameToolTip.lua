--[[
InGameToolTip - A small lib meant to easily make vanilla like tool tips for in game

Wiki: https://github.com/Redacted-Rice/ITB-RedactedRiceMods/wiki/%5BLib%5D-InGameToolTip

Author: Das Keifer of Redacted Rice
Discord Server: https://discord.gg/CNjTVrpN4v
]]

local VERSION = "1.0.0"

local isNewestVersion = InGameToolTip == nil
	or modApi:isVersionAbove(VERSION, InGameToolTip.version)

if isNewestVersion then
	LOG("InGameToolTip: Loading version " .. VERSION .. " (previous: "
			.. tostring(InGameToolTip and InGameToolTip.version or "none") .. ")")

	InGameToolTip = InGameToolTip or {}
	InGameToolTip.version = VERSION

	InGameToolTip.DEFAULT_TITLE_PT = 9
	InGameToolTip.DEFAULT_BODY_PT = 8
	InGameToolTip.DEFAULT_TEXT_LIMIT = 26
	InGameToolTip.DEFAULT_EXTRA_PAD_B = 3
	InGameToolTip.DEFAULT_TITLE_FONT_PATH = "fonts/NunitoSans_Bold.ttf"
	InGameToolTip.DEFAULT_BODY_FONT_PATH = "fonts/NunitoSans_Regular.ttf"

	InGameToolTip._defaultWidget = nil
	InGameToolTip._boxSpecs = InGameToolTip._boxSpecs or {}
	InGameToolTip._boxUiByName = {}

	-- Sets the font of a text widget
	function InGameToolTip:_setFont(textWidget, fontOpt, defaultPath, defaultPt)
		if fontOpt == nil then
			textWidget.font = sdlext.font(defaultPath, defaultPt)
		elseif type(fontOpt) == "string" then
			textWidget.font = sdlext.font(fontOpt, defaultPt)
		else
			textWidget.font = fontOpt
		end
	end

	-- Creates a widget to use for the tool tip based on the passed options or defaults if not supplied
	function InGameToolTip:createWidget(options)
		options = options or {}
		local titlePt = options.titlePt or InGameToolTip.DEFAULT_TITLE_PT
		local bodyPt = options.bodyPt or InGameToolTip.DEFAULT_BODY_PT
		local textLimit = options.textLimit or InGameToolTip.DEFAULT_TEXT_LIMIT
		local extraPadB = options.extraPadB or InGameToolTip.DEFAULT_EXTRA_PAD_B
		local titlePath = options.titleFontPath or InGameToolTip.DEFAULT_TITLE_FONT_PATH
		local bodyPath = options.bodyFontPath or InGameToolTip.DEFAULT_BODY_FONT_PATH

		local WidgetClass = Class.inherit(UiTooltip)
		function WidgetClass:new()
			UiTooltip.new(self)

			InGameToolTip:_setFont(self.ui_title, options.titleFont, titlePath, titlePt)
			self.ui_title.textset = options.titleTextset or deco.uifont.tooltipTitle.set
			self.ui_title.limit = textLimit

			InGameToolTip:_setFont(self.ui_text, options.bodyFont, bodyPath, bodyPt)
			self.ui_text.textset = options.bodyTextset or deco.uifont.tooltipText.set
			self.ui_text.limit = textLimit

			self.padb = self.padb + extraPadB
		end

		return WidgetClass()
	end

	-- Returns the default widget to use for tool tips will all the defaults, creating it if needed
	function InGameToolTip:getDefaultWidget()
		if InGameToolTip._defaultWidget == nil then
			InGameToolTip._defaultWidget = InGameToolTip:createWidget()
		end
		return InGameToolTip._defaultWidget
	end

	-- Sets the widget to use for the tool tip
	function InGameToolTip:_setTipWidget(ui, widget)
		local tipWidget = widget or InGameToolTip:getDefaultWidget()
		if tipWidget then
			ui:setCustomTooltip(tipWidget)
		end
	end

	-- Sets the text of the tip and whether it is static (non-static follows the cursor)
	-- static defaults to true
	function InGameToolTip:_setTipContent(ui, body, title, static)
		ui:settooltip(body or "", title or "", static ~= false)
	end

	-- Resolves the box name to the UI element or returns the target (presumably the UI element already)
	function InGameToolTip:_resolveTipTarget(target)
		if type(target) == "string" then
			return InGameToolTip._boxUiByName[target]
		end
		return target
	end

	-- Updates the tip text from getContent fn
	function InGameToolTip:_updateTipTextFromGetContent(ui, spec)
		local title, body = spec.options.getContent()
		InGameToolTip:_setTipContent(ui, body, title, spec.options.static)
	end

	-- Updates the tip text for the tool tip then calls the previous draw fn if there was one
	function InGameToolTip._uiElementDraw(screen)
		if self._inGameToolTipSpec then
			InGameToolTip:_updateTipTextFromGetContent(self, self._inGameToolTipSpec)
		end
		local prevDraw = self._inGameToolTipPrevDraw
		if prevDraw then
			return prevDraw(self, screen)
		end
		return Ui.draw(self, screen)
	end

	-- Installs a hook to update the tip text for draw that preserves any existing
	-- draw fn
	function InGameToolTip:_installUiTipDrawFn(ui, spec)
		if ui._inGameToolTipSpec then
			ui._inGameToolTipSpec = spec
			return
		end
		ui._inGameToolTipSpec = spec
		ui._inGameToolTipPrevDraw = ui.draw
		ui.draw = InGameToolTip._uiElementDraw
	end

	function InGameToolTip:_setTranslucentHover(ui)
		ui.updateHoveredState = function(self)
			if not self.visible or self.ignoreMouse or not self.containsMouse then
				return false
			end
			if self.root then
				self.root:setHoveredChild(self)
			end
			for _, child in ipairs(self.children) do
				if child:updateHoveredState() then
					return true
				end
			end
			return self.hovered
		end
	end

	function InGameToolTip:_passMouseEvent()
		return false
	end

	function InGameToolTip:_setMousePassthrough(ui)
		ui.mousedown = InGameToolTip._passMouseEvent
		ui.mouseup = InGameToolTip._passMouseEvent
		ui.mousemove = InGameToolTip._passMouseEvent
		ui.wheel = InGameToolTip._passMouseEvent
		ui.clicked = InGameToolTip._passMouseEvent
	end

	function InGameToolTip:_getBoxScreenRect(boxName)
		if not boxName or not GetBox then
			return nil
		end
		local box = GetBox(boxName)
		if not box or not box.w or not box.h or box.w <= 0 or box.h <= 0 then
			return nil
		end
		return box.x, box.y, box.w, box.h
	end

	function InGameToolTip:_boxDimensions(boxName)
		local _, _, w, h = InGameToolTip:_getBoxScreenRect(boxName)
		return w, h
	end

	function InGameToolTip:_syncBoxesTable(spec, loc, w, h)
		local sync = spec._boxesSync
		if sync
			and sync.x == loc.x
			and sync.y == loc.y
			and sync.w == w
			and sync.h == h
		then
			return
		end
		Boxes[spec.box] = Rect2D(loc, Point(w, h))
		spec._boxesSync = { x = loc.x, y = loc.y, w = w, h = h }
	end

	function InGameToolTip:_specScreenRect(spec)
		if spec.loc and Location and Location[spec.loc] then
			local loc = Location[spec.loc]
			local w, h = InGameToolTip:_boxDimensions(spec.box)
			w, h = w or 1, h or 1
			InGameToolTip:_syncBoxesTable(spec, loc, w, h)
			return loc.x, loc.y, w, h
		end
		return InGameToolTip:_getBoxScreenRect(spec.box)
	end

	function InGameToolTip:_findBoxSpec(boxName)
		for _, spec in ipairs(InGameToolTip._boxSpecs) do
			if spec.box == boxName then
				return spec
			end
		end
		return nil
	end

	function InGameToolTip:_rectOnScreen(x, y, w, h)
		if x == nil or y == nil or w == nil or h == nil then
			return false
		end
		local screenW, screenH = ScreenSizeX(), ScreenSizeY()
		if x + w <= 0 or y + h <= 0 then
			return false
		end
		if x >= screenW or y >= screenH then
			return false
		end
		return true
	end

	function InGameToolTip:_boxOverlayDraw(screen)
		local spec = self._inGameToolTipSpec
		local x, y, w, h = InGameToolTip:_specScreenRect(spec)
		if not x or not InGameToolTip:_rectOnScreen(x, y, w, h) then
			self.visible = false
			return
		end

		-- If we have dynamic content, refresh it
		if spec and spec.options and spec.options.getContent then
			InGameToolTip:_updateTipTextFromGetContent(self, spec)
		end

		self.visible = true
		self:widthpx(w):heightpx(h)
		self:pospx(x, y)
		Ui.draw(self, screen)
	end

	function InGameToolTip:_tryCreateBoxOverlay(spec)
		if InGameToolTip._boxUiByName[spec.box] then
			return true
		end
		local uiRoot = sdlext.getUiRoot()
		if not uiRoot then
			return false
		end
		InGameToolTip:_createBoxOverlay(uiRoot, spec)
		return true
	end

	function InGameToolTip:_createBoxOverlay(uiRoot, spec)
		if InGameToolTip._boxUiByName[spec.box] then
			return InGameToolTip._boxUiByName[spec.box]
		end

		local w, h = InGameToolTip:_boxDimensions(spec.box)
		w, h = w or 1, h or 1

		local hitbox = Ui()
			:widthpx(w)
			:heightpx(h)
			:addTo(uiRoot)

		hitbox.translucent = true
		hitbox.visible = false
		hitbox._inGameToolTipSpec = spec

		InGameToolTip._boxUiByName[spec.box] = hitbox
		InGameToolTip:_setTipWidget(hitbox, spec.options.widget)
		-- If we are a static tip, set the content now
		if not spec.options.getContent then
			InGameToolTip:_setTipContent(
				hitbox,
				spec.options.body,
				spec.options.title,
				spec.options.static
			)
		end
		InGameToolTip:_setTranslucentHover(hitbox)
		InGameToolTip:_setMousePassthrough(hitbox)
		hitbox.draw = InGameToolTip._boxOverlayDraw

		return hitbox
	end

	-- Registers a box in the vanilla Boxes table for use in forBox api
	function InGameToolTip.registerBox(boxName, origin, size)
		if not boxName or not origin or not size then
			return false
		end
		if Boxes[boxName] ~= nil then
			return false
		end
		Boxes[boxName] = Rect2D(origin, size)
		return true
	end

	-- body/title once, or getContent each sync (not both). options.static defaults to true
	function InGameToolTip.forBox(box, loc, options)
		options = options or {}
		if not box then
			LOG("InGameToolTip.forBox: box is required")
			return
		end
		if options.body and options.getContent then
			LOG("InGameToolTip.forBox: pass body or getContent, not both")
			return
		end

		local existing = InGameToolTip:_findBoxSpec(box)
		if existing then
			LOG("InGameToolTip.forBox: Duplicate registration for box "
				.. tostring(box) .. ". Ignoring duplicate")
			return
		end

		local spec = {
			box = box,
			loc = loc,
			options = options,
		}
		table.insert(InGameToolTip._boxSpecs, spec)

		-- Create the overlay if we have a ui root already. Otherwise it will be created when
		-- the ui root is created
		InGameToolTip:_tryCreateBoxOverlay(spec)
	end

	-- body/title once, or getContent each draw (not both). options.static defaults to true
	function InGameToolTip.forUiElement(ui, options)
		options = options or {}
		if not ui then
			LOG("InGameToolTip.forUiElement: ui is required")
			return
		end
		if options.body and options.getContent then
			LOG("InGameToolTip.forUiElement: pass body or getContent, not both")
			return
		end

		-- We have the UI element so we can just modify directly right now
		InGameToolTip:_setTipWidget(ui, options.widget)

		-- If we have a dynamic getContent, install the hook to update it
		if options.getContent then
			InGameToolTip:_installUiTipDrawFn(ui, { options = options })
		else
			InGameToolTip:_setTipContent(ui, options.body, options.title, options.static)
		end
	end

	-- Manually update the tip content for a non-dynamic tip (getContent not set)
	function InGameToolTip.updateTipContent(target, body, title, static)
		local ui = InGameToolTip:_resolveTipTarget(target)
		if not ui then
			return false
		end

		InGameToolTip:_setTipContent(ui, body, title, static)
		return true
	end

	function InGameToolTip._subscribeToEvents()
		modApi.events.onUiRootCreated:subscribe(function(_, uiRoot)
			-- Clear any cached box ui elements
			InGameToolTip._boxUiByName = {}
			for _, spec in ipairs(InGameToolTip._boxSpecs) do
				InGameToolTip:_createBoxOverlay(uiRoot, spec)
			end
		end)
	end
else
	LOG("InGameToolTip: Skipping version " .. VERSION .. " (already have "
			.. InGameToolTip.version .. ")")
end

local function onModsInitialized()
	if VERSION < InGameToolTip.version then
		return
	end
	if InGameToolTip.initialized then
		return
	end
	InGameToolTip._subscribeToEvents()
	InGameToolTip.initialized = true
end

modApi.events.onModsInitialized:subscribe(onModsInitialized)

return InGameToolTip
