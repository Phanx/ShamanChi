--[[--------------------------------------------------------------------
	ShamanChi
	Displays Maelstrom Weapon and Lightning Shield like monks' Chi.
	Copyright 2014 Phanx. All rights reserved.
	See the accompanying README and LICENSE files for more information.
	http://www.wowinterface.com/downloads/info22714-ShamanChi.html
	http://www.curse.com/addons/wow/shamanchi
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

local function OnEnter(self)
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:SetSpellByID(buff == LIGHTNING_SHIELD and 88766 or 51530) -- Fulmination / Maelstrom Weapon
end

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
	
	-- Make the tooltip more relevant:
	Orb:SetScript("OnEnter", OnEnter)
	
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
local L_HELP_LINE = "- |cffffff7f%s|r - %s (%s)"

local ON, OFF = "|cff7fff7fenabled|r", "|cffff7f7fdisabled|r"
local L_HELP = "Version %s loaded. Use '/shamanchi' with the following commands:"
local L_SPIN = "spin"
local L_SPIN_HELP = "toggle the spin animation with full stacks"
local L_SPIN_SET = "Animation now %s."

if GetLocale() == "deDE" then
	--{{ Deutsch, von Phanx übersetzt
	ON, OFF = "|cff7fff7faktiviert|r", "|cffff7f7fdeaktiviert|r"
	L_HELP = "Version %s geladen. Benutzt '/shamanchi' mit diesen Befehlen:"
	L_SPIN = "drehen"
	L_SPIN_HELP = "die Kugeln bei vollen Stapel drehen"
	L_SPIN_SET = "Animation ist jetzt %s."
	L_TOOLTIP = "tooltipp"
	L_TOOLTIP_HELP = "der Tooltip bei Mouseover anzuzeigen"
	L_TOOLTIP_SET = "Tooltip ist jetzt %s."
	--}}
elseif GetLocale() == "esES" or GetLocale() == "esMX" then
	--{{ Español, traducido por Phanx
	ON, OFF = "|cff7fff7factivado|r", "|cffff7f7fdesactivado|r"
	L_HELP = "Versión %s cargado. Use '/shamanchi' con estos comandos:"
	L_SPIN = "girar"
	L_SPIN_HELP = "girar los orbes a las pilas máximas"
	L_SPIN_SET = "Animación está ahora %s."
	L_TOOLTIP = "tooltip"
	L_TOOLTIP_HELP = "mostrar el tooltip al pasar del ratón"
	L_TOOLTIP_SET = "Tooltip está ahora %s."
	--}}
end

SLASH_SHAMANCHI1 = "/shamanchi"
SlashCmdList["SHAMANCHI"] = function(cmd)
	cmd = strlower(strtrim(cmd or ""))
	if cmd == "spin" then
		ShamanChiSpin = not ShamanChiSpin

		if not ShamanChiSpin then
			Bar.hasHarmony = false
		end

		return DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. format(L_SPIN_SET, ShamanChiSpin and ON or OFF))
	end
	DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. format(L_HELP, GetAddOnMetadata("ShamanChi", "Version")))
	DEFAULT_CHAT_FRAME:AddMessage(format(L_HELP_LINE, L_SPIN, L_SPIN_HELP, ShamanChiSpin and ON or OFF))
end