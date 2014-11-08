--[[--------------------------------------------------------------------
	ShamanChi
	Displays Maelstrom Weapon and Lightning Shield like monks' Chi.
	Copyright (c) 2014 Phanx <addons@phanx.net>. All rights reserved.
	http://www.wowinterface.com/downloads/info22714-ShamanChi.html
	http://www.curse.com/addons/wow/shamanchi

	Please DO NOT upload this addon to other websites, or post modified
	versions of it. However, you are welcome to use any/all of its code
	in your own addon, as long as you do not use my name or the name of
	this addon ANYWHERE in your addon, including in its name, outside of
	an optional attribution. You are also welcome to include this addon
	WITHOUT CHANGES in compilations posted on Curse and/or WoWInterface.
----------------------------------------------------------------------]]

local _, class = UnitClass("player")
if class ~= "SHAMAN" then return end

------------------------------------------------------------------------

local buff

-- Get the localized buff names without hardcoding them:
local MAELSTROM_WEAPON = GetSpellInfo(53817)
local LIGHTNING_SHIELD = GetSpellInfo(324)

-- Upvalue some globals for speed:
local Bar = MonkHarmonyBar
local Set = MonkHarmonyBar_SetEnergy
local Orbs = Bar.LightEnergy or {}

for i = 1, 5 do
	local Orb = Bar.LightEnergy[i] or CreateFrame("Frame", nil, MonkHarmonyBar, "MonkLightEnergyTemplate")
	Orbs[i] = Orb

	-- Adapted from MonkHarmonyBar_UpdateMaxPower:
	Orb.Glow:SetAtlas("MonkUI-LightOrb", true)
	Orb.OrbOff:SetAtlas("MonkUI-OrbOff", true)

	-- Give the foreground a more shaman-y color:
	local _, texture = Orb:GetRegions()
	texture:SetVertexColor(0.5, 1, 1)

	-- Fix the funky animation:
	Orb.spin:GetAnimations():SetOrigin("CENTER", 0, 0)
	
	-- Remove irrelevant tooltip:
	Orb:SetScript("OnEnter", nil)
	
	-- Adapted from MonkHarmonyBar_Update:
	if i > 1 then
		Orb:SetPoint("LEFT", Orbs[i-1], "RIGHT", 1, 0)
	else
		Orb:SetPoint("LEFT", -46, 1)
	end
	Orb:Show()
end

-- Replace MonkHarmonyBar_OnEvent with shaman-specific stuff:
function Bar:Update()
	if not buff then
		return self:Hide()
	end

	local _, _, _, count = UnitBuff("player", buff)
	if not count then
		count = 0
	elseif buff == LIGHTNING_SHIELD then
		count = count / 3
	end

	local full = count == 5 and ShamanChiSpin
	self.hasHarmony = full

	for i = 1, 5 do
		local Orb = Orbs[i]
		Set(Orb, i <= count)
		if full then
			Orb.spin:Play()
		else
			Orb.spin:Finish()
		end
	end
end

Bar:SetScript("OnEvent", function(self, event)
	if event ~= "UNIT_AURA" then
		local spec, level = GetSpecialization(), UnitLevel("player")
		if spec == 1 and level >= 20 then -- Elemental
			buff = LIGHTNING_SHIELD
			Bar:Show()
		elseif spec == 2 and level >= 50 then -- Enhancement
			buff = MAELSTROM_WEAPON
			Bar:Show()
		else -- Restoration, or low level, or no spec
			buff = nil
			return Bar:Hide()
		end
	end
	Bar:Update()
end)

-- Adapted from MonkHarmonyBar_OnLoad:
Bar:HookScript("OnShow", function(self)
	--print("ShamanChi OnShow")
	self:SetFrameLevel(self:GetParent():GetFrameLevel() + 2)
	self:RegisterUnitEvent("UNIT_AURA", "player")
	self:Update()
	-- Move totem buttons down so they don't overlap:
	TotemFrame:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", 96, 18)
	-- Move the cast bar down too:
	PlayerFrame_AdjustAttachments()
end)

Bar:HookScript("OnHide", function(self)
	--print("ShamanChi OnHide")
	self:UnregisterEvent("UNIT_AURA")
	-- Move totem buttons back to their original position:
	TotemFrame:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", 99, 38)
	-- And move the cast bar back too:
	PlayerFrame_AdjustAttachments()
end)

hooksecurefunc("PlayerFrame_AdjustAttachments", function()
	if PLAYER_FRAME_CASTBARS_SHOWN and Bar:IsShown() then
		local a, b, c, x, y = CastingBarFrame:GetPoint(1)
		CastingBarFrame:SetPoint(a, b, c, x, y - 11)
	end
end)

hooksecurefunc("PlayerFrame_ShowVehicleTexture", function()
	Bar:Hide()
end)

hooksecurefunc("PlayerFrame_HideVehicleTexture", function()
	Bar:SetShown(buff and PlayerFrame:IsShown())
end)

Bar:RegisterEvent("PLAYER_ENTERING_WORLD")
Bar:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

------------------------------------------------------------------------
-- Settings

ShamanChiSpin = true

local PREFIX = "|cff00ddba" .. GetAddOnMetadata("ShamanChi", "Title") .. ":|r "
local HELP_LINE = "- |cffffff7f%s|r - %s (%s)"

local L = {
	ON = "|cff7fff7fenabled|r"
	OFF = "|cffff7f7fdisabled|r"
	HELP = "Version %s loaded. Use '/shamanchi' with the following commands:"
	SPIN = "spin"
	SPIN_HELP = "toggle the spin animation with full stacks"
	SPIN_SET = "Animation now %s."
	TOOLTIP = "tooltip"
	TOOLTIP_HELP = "toggle the tooltip on mouseover"
	TOOLTIP_SET = "Tooltip is now %s."
}

if GetLocale() == "deDE" then
	--{{ Deutsch, von Phanx übersetzt
	L.ON = "|cffff7f7fdeaktiviert|r"
	L.OFF = "|cffff7f7fdeaktiviert|r"
	L.HELP = "Version %s geladen. Benutzt '/shamanchi' mit diesen Befehlen:"
	L.SPIN = "drehen"
	L.SPIN_HELP = "die Kugeln bei vollen Stapel drehen"
	L.SPIN_SET = "Animation ist jetzt %s."
	--}}
elseif GetLocale() == "esES" or GetLocale() == "esMX" then
	--{{ Español, traducido por Phanx
	L.ON = "|cff7fff7factivado|r"
	L.OFF = "|cffff7f7fdesactivado|r"
	L.HELP = "Versión %s cargado. Use '/shamanchi' con estos comandos:"
	L.SPIN = "girar"
	L.SPIN_HELP = "girar los orbes a las pilas máximas"
	L.SPIN_SET = "Animación está ahora %s."
	--}}
end

SLASH_SHAMANCHI1 = "/shamanchi"
SlashCmdList["SHAMANCHI"] = function(cmd)
	cmd = strlower(strtrim(cmd or ""))
	if cmd == "spin" or cmd == L.SPIN then
		ShamanChiSpin = not ShamanChiSpin

		if not ShamanChiSpin then
			Bar.hasHarmony = false
		end

		return DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. format(L.SPIN_SET, ShamanChiSpin and ON or OFF))
	end
	DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. format(L.HELP, GetAddOnMetadata("ShamanChi", "Version")))
	DEFAULT_CHAT_FRAME:AddMessage(format(HELP_LINE, L.SPIN, L.SPIN_HELP, ShamanChiSpin and ON or OFF))
end