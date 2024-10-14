-- constants

local FULLSCREEN = "FULLSCREEN"
local POPUP = "POPUP"
local CANCEL_PET_BATTLE_POPUP = "CANCEL_PET_BATTLE"

local OPPONENT = 2 -- 2 represents the opponent pet owner

local ITEM_QUALITY_NAMES = { 
    [0] = ITEM_QUALITY0_DESC, -- Poor 
    [1] = ITEM_QUALITY1_DESC, -- Common 
    [2] = ITEM_QUALITY2_DESC, -- Uncommon 
    [3] = ITEM_QUALITY3_DESC, -- Rare 
    [4] = ITEM_QUALITY4_DESC, -- Epic 
    [5] = ITEM_QUALITY5_DESC, -- Legendary 
    --[6] = ITEM_QUALITY6_DESC, -- Artifact 
    --[7] = ITEM_QUALITY7_DESC, -- Heirloom 
}

local TARGET_MARKERS = { -- pre-formatted for efficiency
    [1] = { name = "Star", icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1", chatIcon = "{|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1:0|t}" },
    [2] = { name = "Circle", icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_2", chatIcon = "{|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_2:0|t}" },
    [3] = { name = "Diamond", icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_3", chatIcon = "{|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_3:0|t}" },
    [4] = { name = "Triangle", icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_4", chatIcon = "{|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_4:0|t}" },
    [5] = { name = "Moon", icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_5", chatIcon = "{|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_5:0|t}" },
    [6] = { name = "Square", icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_6", chatIcon = "{|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_6:0|t}" },
    [7] = { name = "Cross", icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_7", chatIcon = "{|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_7:0|t}" },
    [8] = { name = "Skull", icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_8", chatIcon = "{|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_8:0|t}" },
}

-- variables

local FullscreenFrame

local PetUnitGUID
local UnitGUIDs = {}

local CancelPetBattleDisabled = false

-- utility functions

local function GetMarkerNumberByName(markerName)
    if not markerName or type(markerName) ~= "string" then
        return nil
    end
 
    for number, marker in ipairs(TARGET_MARKERS) do
        if string.lower(marker.name) == string.lower(markerName) then
            return number
        end
    end
    return nil
end

local function CancelPetBattleTextPrefix(text)
    return "|cffee82eeCancelPetBattle: |r" .. text
end

local function BuildDialogText(quality, extraText)
    local qualityColor = ITEM_QUALITY_COLORS[quality]
    local qualityName = ITEM_QUALITY_NAMES[quality]
    local formattedText = string.format(
        "|cffff9900No %s%s|r or better pet found.|r|n|n%s",
        qualityColor.hex,
        qualityName,
        extraText or ""
    )
    return formattedText
end

local function CreatePetLink(pet)
    -- C_PetBattles.GetX(petOwner, petIndex)
    local name      = C_PetBattles.GetName(OPPONENT, pet)
    local speciesID = C_PetBattles.GetPetSpeciesID(OPPONENT, pet)
    local level     = C_PetBattles.GetLevel(OPPONENT, pet)
    local quality   = C_PetBattles.GetBreedQuality(OPPONENT, pet)
    local health    = C_PetBattles.GetMaxHealth(OPPONENT, pet)
    local power     = C_PetBattles.GetPower(OPPONENT, pet)
    local speed     = C_PetBattles.GetSpeed(OPPONENT, pet)
    
    return string.format("%s|Hbattlepet:%s:%s:%s:%s:%s:%s:|h[%s]|h|r", ITEM_QUALITY_COLORS[quality].hex, speciesID, level, quality, health, power, speed, name)
end

local function RegisterPetGUID()
    PetUnitGUID = UnitGUID("target")
    UnitGUIDs[PetUnitGUID] = PetUnitGUID
    if UnitGUIDs[PetUnitGUID] then
        print(CancelPetBattleTextPrefix("This pet battle was previously forfeited!"))
    end
end

-- core functions

local function PrepareFullscreen()
    FullscreenFrame = CreateFrame("Button", nil, UIParent)
    FullscreenFrame:Hide()
    FullscreenFrame:SetAllPoints(true)
    FullscreenFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    FullscreenFrame:RegisterForClicks("AnyUp")
    FullscreenFrame:EnableKeyboard(true)

    FullscreenFrame.bg = FullscreenFrame:CreateTexture(nil, "BACKGROUND")
    FullscreenFrame.bg:SetAllPoints(true)
    FullscreenFrame.bg:SetTexture(0, 0, 0, 0.5)

    FullscreenFrame.text = FullscreenFrame:CreateFontString(nil, "OVERLAY", "PVPInfoTextFont")
    FullscreenFrame.text:SetPoint("CENTER")
    FullscreenFrame.text:SetText(BuildDialogText(CPB_QUALITY, "|r|n|n|cffff0000Click anywhere to forfeit.|r|nRight-click to continue the battle anyway."))

    FullscreenFrame:SetScript("OnClick", function(self, button)
            if button == "LeftButton" then
                C_PetBattles.ForfeitGame()
            end
            self:Hide()
        end
    )
    
    FullscreenFrame:SetScript("OnKeyDown", function(self, button)
            if GetBindingFromClick(button) == "TOGGLEGAMEMENU" then
                SELECTED_CHAT_FRAME:AddMessage(CancelPetBattleTextPrefix("Options: If you want to cancel battles by pressing ESCAPE do |cffff0000" .. CHAT_COMMAND .. "dialog|r"))
            end
        end
    )
end

local function PreparePopup()
    StaticPopupDialogs[CANCEL_PET_BATTLE_POPUP] = {
        text = BuildDialogText(CPB_QUALITY),
        button1 = "Stay and battle",
        button2 = "Forfeit",
        whileDead = false,
        showAlert = true,
        OnAccept = function()
            UnitGUIDs[PetUnitGUID] = nil
            PetUnitGUID = nil
        end,
        OnCancel = function()
            C_PetBattles.ForfeitGame()
        end,
        timeout = 0,
        exclusive = 1,
        hideOnEscape = 1,
        preferredIndex = 3
    }
end

local function PromptCancelPetBattle()
    if CPB_MODE == FULLSCREEN then
        PrepareFullscreen()
        FullscreenFrame:Show()
    elseif CPB_MODE == POPUP then
        PreparePopup()
        StaticPopup_Show(CANCEL_PET_BATTLE_POPUP)
    end
end

-- event handlers

local function OnPetBattleOpeningStart()
    if CPB_CHAT then
        local listPetsMessage = CancelPetBattleTextPrefix("Opposing Team: ")
        for i = 1, C_PetBattles.GetNumPets(OPPONENT) do
            listPetsMessage = listPetsMessage .. CreatePetLink(i) .. " "
        end
        SELECTED_CHAT_FRAME:AddMessage(listPetsMessage)
    end

    if CancelPetBattleDisabled then
        print("CancelPetBattle temporarily disabled")
        return
    end

    RegisterPetGUID()

    if C_PetBattles.GetBreedQuality(OPPONENT, 1) < CPB_QUALITY 
    and C_PetBattles.GetBreedQuality(OPPONENT, 2) < CPB_QUALITY 
    and C_PetBattles.GetBreedQuality(OPPONENT, 3) < CPB_QUALITY then
        PromptCancelPetBattle()
    end
end

local function OnUpdateMouseoverUnit()
    local inInstance, instanceType = IsInInstance()
        
    if CPB_MARK
    and not (UnitAffectingCombat("player") or UnitInRaid("player") or IsInInstance() or GetRaidTargetIndex("mouseover"))
    and UnitGUIDs[UnitGUID("mouseover")] then
        SetRaidTarget("mouseover", CPB_TARGET_MARKER)
    end
end

local function OnVariablesLoaded()
    if CPB_CHAT == nil then
        CPB_CHAT = true
    end
    
    if CPB_MODE == nil then
        CPB_MODE = FULLSCREEN
    end
    
    if CPB_MARK == nil then
        CPB_MARK = true
    end
    
    if CPB_TARGET_MARKER == nil then
        CPB_TARGET_MARKER = 2
    end

    if CPB_QUALITY == nil then
        CPB_QUALITY = 3 -- Rare
    end
end

local function HandleRegisteredEvents(frame, event, ...)
    if C_PetBattles.IsWildBattle() and event == "PET_BATTLE_OPENING_START" then
        OnPetBattleOpeningStart()
    end

    if event == "UPDATE_MOUSEOVER_UNIT" then
        OnUpdateMouseoverUnit()
    elseif event == "VARIABLES_LOADED" then
        OnVariablesLoaded()
    end
end

-- addon setup

local CancelPetBattleFrame = CreateFrame("Frame", "CancelPetBattle", UIParent)

CancelPetBattleFrame:RegisterEvent("PET_BATTLE_OPENING_START")
CancelPetBattleFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
CancelPetBattleFrame:RegisterEvent("VARIABLES_LOADED")

CancelPetBattleFrame:SetScript("OnEvent", HandleRegisteredEvents)

PetBattleFrame.BottomFrame.ForfeitButton:SetScript("OnClick", function(...)
        if IsShiftKeyDown() then
            C_PetBattles.ForfeitGame()
        else
            PetBattleForfeitButton_OnClick(...)
        end
    end
)

SLASH_CPB1 = "/cpb"
SlashCmdList["CPB"] = function(message)
    local cmd, arg = message:match("^(%S*)%s*(.-)$")

    if cmd == "chat" then
        if CPB_CHAT then
            SELECTED_CHAT_FRAME:AddMessage(CancelPetBattleTextPrefix("Options|r: chat print turned |cffff0000>OFF<|r"))
            CPB_CHAT = false
        else
            SELECTED_CHAT_FRAME:AddMessage(CancelPetBattleTextPrefix("Options|r: chat print turned |cffff0000>ON<|r"))
            CPB_CHAT = true
        end
    elseif cmd == "popup" then
        if CPB_MODE == POPUP then
            SELECTED_CHAT_FRAME:AddMessage(CancelPetBattleTextPrefix("Options|r: popup mode turned |cffff0000>OFF<|r"))
            CPB_MODE = FULLSCREEN
        else
            SELECTED_CHAT_FRAME:AddMessage(CancelPetBattleTextPrefix("Options|r: popup mode turned |cffff0000>ON<|r"))
            CPB_MODE = POPUP
        end
    elseif cmd == "mark" then
        if CPB_MARK then
            SELECTED_CHAT_FRAME:AddMessage(CancelPetBattleTextPrefix("Options|r: target marking turned |cffff0000>OFF<|r"))
            CPB_MARK = false
        else
            SELECTED_CHAT_FRAME:AddMessage(CancelPetBattleTextPrefix("Options|r: target marking turned |cffff0000>ON<|r"))
            CPB_MARK = true
        end
    elseif cmd == "marker" then
        local marker = tonumber(arg)
        if marker == nil then
            marker = string.lower(arg)
        end
        
        if GetMarkerNumberByName(marker) or TARGET_MARKERS[marker] then
            CPB_TARGET_MARKER = GetMarkerNumberByName(marker) or marker
            local markerName = TARGET_MARKERS[CPB_TARGET_MARKER].name
            SELECTED_CHAT_FRAME:AddMessage(CancelPetBattleTextPrefix("Options|r: target marker set to |cffff0000>" .. markerName .. "<|r"))
        else
            local markers = {}
            for key, marker in ipairs(TARGET_MARKERS) do
                table.insert(markers, marker.chatIcon .. marker.name)
            end
            SELECTED_CHAT_FRAME:AddMessage(CancelPetBattleTextPrefix("Options|r: available target markers are: " .. table.concat(markers, ", ")))
        end
    elseif cmd == "quality" then
        local quality = tonumber(arg)
        if quality == nil then
            quality = string.lower(arg)
        end

        if ITEM_QUALITY_NAMES[quality] then
            CPB_QUALITY = quality
            local qualityName = ITEM_QUALITY_NAMES[quality]
            SELECTED_CHAT_FRAME:AddMessage(CancelPetBattleTextPrefix("Options|r: quality filter set to " .. ITEM_QUALITY_COLORS[quality].hex .. ">" .. qualityName .. "<|r"))
        else
            local qualityOptionsMessage = CancelPetBattleTextPrefix("Options|r: available qualities are: ")
            
            local qualityKeys = {}
            for key in pairs(ITEM_QUALITY_NAMES) do
                table.insert(qualityKeys, key)
            end
            table.sort(qualityKeys)

            for _, key in ipairs(qualityKeys) do
                qualityName = ITEM_QUALITY_NAMES[key]
                qualityOptionsMessage = qualityOptionsMessage .. ITEM_QUALITY_COLORS[key].hex .. key .. "(" .. qualityName .. ")|r, "
            end
            SELECTED_CHAT_FRAME:AddMessage(string.sub(qualityOptionsMessage, 1, -3))
        end
    elseif cmd == "off" then
        if not CancelPetBattleDisabled then
            SELECTED_CHAT_FRAME:AddMessage(CancelPetBattleTextPrefix("Options|r: temporarily |cffff0000>DISABLED<|r. This will reset on the next logon (or UI reload)."))
            CancelPetBattleDisabled = true
        else
            SELECTED_CHAT_FRAME:AddMessage(CancelPetBattleTextPrefix("Options|r: already |cffff0000>DISABLED<|r. Use /cpb on to enable."))
        end
    elseif cmd == "on" then
        SELECTED_CHAT_FRAME:AddMessage(CancelPetBattleTextPrefix("Options|r: |cffff0000>ENABLED<|r"))
        CancelPetBattleDisabled = false
    else
        SELECTED_CHAT_FRAME:AddMessage(CancelPetBattleTextPrefix("Available options|r: chat, popup, mark, marker <marker>, quality <number>, on, off"))
    end
end