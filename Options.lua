--[[--------------------------------------------------------------------
	PhanxFont
	Simple font replacement.
	Based on tekticles by Tekkub, which is based on ClearFont2 by Kirkburn.
	Copyright (c) 2012-2014 Phanx <addons@phanx.net>. All rights reserved.

	Please DO NOT upload this addon to other websites, or post modified
	versions of it. However, you are welcome to include a copy of it
	WITHOUT CHANGES in compilations posted on Curse and/or WoWInterface.
	You are also welcome to use any/all of its code in your own addon, as
	long as you do not use my name or the name of this addon ANYWHERE in
	your addon, including its name, outside of an optional attribution.
----------------------------------------------------------------------]]

local ADDON, Addon = ...

local L = setmetatable({}, {
	__index = function(t, k)
		local v = tostring(k)
		t[k] = v
		return v
	end
})
if GetLocale() == "deDE" then
	L["Normal Font"] = "Normalschrift"
	L["Bold Font"] = "Fettschrift"
	L["Scale"] = "Größe"
	L["Reload UI"] = "UI neu laden"
	L["Apply"] = "Anwenden"
elseif GetLocale():match("^es") then
	L["Normal Font"] = "Fuente normal"
	L["Bold Font"] = "Fuente en negrita"
	L["Scale"] = "Tamaño"
	L["Reload UI"] = "Recargar IU"
	L["Apply"] = "Aplicar"
end

local Options = CreateFrame("Frame", "PhanxFontOptions", InterfaceOptionsFramePanelContainer)
Options.name = GetAddOnMetadata(ADDON, "Title") or ADDON
Options:Hide()

Options:SetScript("OnShow", function(self)
	local Title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	Title:SetPoint("TOPLEFT", 16, -16)
	Title:SetText(self.name)

	local Notes = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	Notes:SetPoint("TOPLEFT", Title, "BOTTOMLEFT", 0, -8)
	Notes:SetPoint("RIGHT", -32, 0)
	Notes:SetHeight(32)
	Notes:SetJustifyH("LEFT")
	Notes:SetJustifyV("TOP")
	Notes:SetText(GetAddOnMetadata(ADDON, "Notes"))

	local UpdatePreviews, SampleText

	----------

	local NormalFont = LibStub("PhanxConfig-MediaDropdown"):New(self, L["Normal Font"], nil,"font")
	NormalFont:SetPoint("TOPLEFT", Notes, "BOTTOMLEFT", 0, -8)
	NormalFont:SetPoint("TOPRIGHT", Notes, "BOTTOM", -8, -8)

	function NormalFont:OnValueChanged(value)
		PhanxFontDB.normal = value
		UpdatePreviews()
	end

	----------

	local BoldFont = LibStub("PhanxConfig-MediaDropdown"):New(self, L["Bold Font"], nil, "font")
	BoldFont:SetPoint("TOPLEFT", NormalFont, "BOTTOMLEFT", 0, -16)
	BoldFont:SetPoint("TOPRIGHT", NormalFont, "BOTTOMRIGHT", 0, -16)

	function BoldFont:OnValueChanged(value)
		PhanxFontDB.bold = value
		UpdatePreviews()
	end

	----------

	local Scale = LibStub("PhanxConfig-Slider"):New(self, L["Scale"], nil, 0.5, 2, 0.05, true)
	Scale:SetPoint("TOPLEFT", BoldFont, "BOTTOMLEFT", 0, -16)
	Scale:SetPoint("TOPRIGHT", BoldFont, "BOTTOMRIGHT", 0, -16)

	function Scale:OnValueChanged(value)
		PhanxFontDB.scale = value
		UpdatePreviews()
	end

	----------

	local ReloadButton = CreateFrame("Button", "$parentReloadButton", self, "UIPanelButtonTemplate")
	ReloadButton:SetPoint("BOTTOMLEFT", 16, 16)
	ReloadButton:SetSize(96, 22)
	ReloadButton:SetText(L["Reload UI"])
	ReloadButton:SetScript("OnClick", ReloadUI)

	local ApplyButton = CreateFrame("Button", "$parentApplyButton", self, "UIPanelButtonTemplate")
	ApplyButton:SetPoint("BOTTOMLEFT", ReloadButton, "BOTTOMRIGHT")
	ApplyButton:SetSize(96, 22)
	ApplyButton:SetText(L["Apply"])
	ApplyButton:SetScript("OnClick", Addon.SetFonts)

	----------

	SampleText = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	SampleText:SetPoint("TOPLEFT", BoldFont, "BOTTOMLEFT", 0, -16)
	SampleText:SetPoint("TOPRIGHT", BoldFont, "BOTTOMRIGHT", 0, -16)
	SampleText:SetPoint("BOTTOMLEFT", ReloadButton, "TOPLEFT", 0, 16)
	SampleText:SetJustifyH("LEFT")
	SampleText:SetText("The quick brown fox jumps over the lazy dog.\n\nÁá Ää Éé Íí Ññ Óó Öö ß Úú Üü\n¡! ¿? # $ € % & ° – —\n“q” ‘q’ „q“ ‚q‘ «q» ‹q›\n^ ● ")

	----------

	local ScrollBG = CreateFrame("Frame", nil, self)
	ScrollBG:SetPoint("TOPLEFT", Notes, "BOTTOM", 8, 0)
	ScrollBG:SetPoint("BOTTOMRIGHT", self, -16, 16)
	ScrollBG:SetBackdrop({ bgFile = "Interface\\BUTTONS\\WHITE8X8", tile = true, tileSize = 8, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
	ScrollBG:SetBackdropColor(0, 0, 0, 0.4)
	ScrollBG:SetBackdropBorderColor(1, 1, 1, 0.6)

	local ScrollFrame = CreateFrame("ScrollFrame", "$parentScrollFrame", ScrollBG, "UIPanelScrollFrameTemplate")
	ScrollFrame:SetPoint("TOPLEFT", ScrollBG, 5, -5)
	ScrollFrame:SetPoint("BOTTOMRIGHT", ScrollBG, -27, 5)

	local ScrollBarBG = ScrollFrame.ScrollBar:CreateTexture(nil, "BACKGROUND")
	ScrollBarBG:SetAllPoints(true)
	ScrollBarBG:SetTexture(0, 0, 0, 0.4)

	local ScrollChild = CreateFrame("Frame", "$parentScrollChildFrame", ScrollFrame)
	ScrollChild:SetPoint("TOPLEFT")
	ScrollChild:SetWidth(ScrollFrame:GetWidth())
	ScrollChild:SetHeight(500) -- temp
--[[
	local ScrollChildBG = ScrollChild:CreateTexture(nil, "BACKGROUND")
	ScrollChildBG:SetAllPoints(true)
	ScrollChildBG:SetTexture(0, 0, 0, 0.2)
]]
	ScrollFrame:SetScrollChild(ScrollChild)
	ScrollFrame:SetScript("OnSizeChanged", function(_, width, height)
		ScrollChild:SetWidth(width)
	end)

	-----

	local fonts = {
		"GameFontNormal",
		"GameFontHighlight",
		"GameFontDisable",
		"GameFontNormalSmall",
		"GameFontHighlightExtraSmall",
		"GameFontHighlightMedium",
		"GameFontNormalLarge",
		"GameFontNormalHuge",
		"GameFont_Gigantic",
		"BossEmoteNormalHuge",
		"NumberFontNormal",
		"NumberFontNormalSmall",
		"NumberFontNormalLarge",
		"NumberFontNormalHuge",
		"ChatFontNormal",
		"ChatFontSmall",
		"DialogButtonNormalText",
		"ZoneTextFont",
		"SubZoneTextFont",
		"PVPInfoTextFont",
		"QuestFont_Super_Huge",
		"QuestFont_Shadow_Small",
		"ErrorFont",
		"TextStatusBarText",
		"CombatLogFont",
		"GameTooltipText",
		"GameTooltipTextSmall",
		"GameTooltipHeaderText",
	}
	local bolds = {
		GameFontNormalHuge = true,
		GameFont_Gigantic = true,
		BossEmoteNormalHuge = true,
		NumberFontNormal = true,
		NumberFontNormalSmall = true,
		NumberFontNormalLarge = true,
		NumberFontNormalHuge = true,
		ZoneTextFont = true,
		SubZoneTextFont = true,
		QuestFont_Super_Huge = true,
		TextStatusBarText = true,
		GameTooltipHeaderText = true,
	}

	for i = 1, #fonts do
		local font = fonts[i]
		local fs = ScrollChild:CreateFontString(nil, "ARTWORK")
		if i == 1 then
			fs:SetPoint("TOPLEFT", ScrollChild, 5, -5)
		else
			fs:SetPoint("TOPLEFT", fonts[i-1], "BOTTOMLEFT", 0, -5)
		end
		fs:SetFontObject(font)
		fs:SetText(font)
		fs.font = font
		fonts[i] = fs
	end

	function UpdatePreviews(width)
		-- print(strjoin(" | ", "UpdatePreviews", PhanxFontDB.normal, PhanxFontDB.bold, PhanxFontDB.scale))
		local Media = LibStub("LibSharedMedia-3.0")
		local NORMAL = Media:Fetch("font", PhanxFontDB.normal)
		local BOLD = Media:Fetch("font", PhanxFontDB.bold)
		SampleText:SetFont(NORMAL, 14 * PhanxFontDB.scale)

		local height = 5
		for i = 1, #fonts do
			local fs = fonts[i]
			local file = bolds[fs.font] and BOLD or NORMAL
			local _, size, flag = fs:GetFont()
			fs:SetFont(file, size, flag)
			height = height + fs:GetHeight() + 5
		end
		ScrollChild:SetHeight(height)
	end

	function self:refresh()
		NormalFont:SetValue(PhanxFontDB.normal)
		BoldFont:SetValue(PhanxFontDB.bold)
		Scale:SetValue(PhanxFontDB.scale)
		UpdatePreviews(width)
	end

	self:SetScript("OnShow", nil)
	self:refresh()
end)

InterfaceOptions_AddCategory(Options)

SLASH_PHANXFONT1 = "/font"
SLASH_PHANXFONT2 = "/schrift"
SlashCmdList.PHANXFONT = function()
	InterfaceOptionsFrame_OpenToCategory(Options)
	InterfaceOptionsFrame_OpenToCategory(Options)
end