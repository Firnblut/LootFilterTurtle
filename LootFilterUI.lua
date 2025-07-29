-- Sicherstellen, dass die SavedVariables-Tabelle existiert
LootFilterSettings = LootFilterSettings or {}
LootFilterSettings.priceThreshold = LootFilterSettings.priceThreshold or 10000  -- Standard: 1 Gold
LootFilterSettings.forceDeleteList = LootFilterSettings.forceDeleteList or {}

local function hooksecurefunc(arg1, arg2, arg3)
	if type(arg1) == "string" then
		arg1, arg2, arg3 = _G, arg1, arg2
	end
	local orig = arg1[arg2]
	arg1[arg2] = function(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20)
		local x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19,x20 = orig(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20)
		
		arg3(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20)
		
		return x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19,x20
	end
end

local data = MyLootFilterData


local function getKeys(t)
    local keys = {}
    if not t then return keys end
    for k,_ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

local function tableLength(t)
    if not t then return 0 end
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

local originalChatFrameEditBox = nil

SLASH_LOOTFILTER1 = "/lfo"

SlashCmdList["LOOTFILTER"] = function()
    if not LootFilterUI then

        local f = CreateFrame("Frame", "LootFilterUI", UIParent)
        f:SetWidth(340)
        f:SetHeight(270)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)

        f:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        f:SetBackdropColor(0, 0, 0, 1)

        local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        titleText:SetPoint("TOP", f, "TOP", 0, -10)
        titleText:SetText("LootFilter Einstellungen")
        f.title = titleText

        -- Schwelle: Gold, Silber, Kupfer
        local goldBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        goldBox:SetWidth(40)
        goldBox:SetHeight(20)
        goldBox:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -40)
        goldBox:SetAutoFocus(false)

        local silverBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        silverBox:SetWidth(40)
        silverBox:SetHeight(20)
        silverBox:SetPoint("LEFT", goldBox, "RIGHT", 10, 0)
        silverBox:SetAutoFocus(false)

        local copperBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        copperBox:SetWidth(40)
        copperBox:SetHeight(20)
        copperBox:SetPoint("LEFT", silverBox, "RIGHT", 10, 0)
        copperBox:SetAutoFocus(false)

        local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", copperBox, "RIGHT", 10, 0)
        label:SetText("Gold / Silver / Copper")

        -- Bestehenden Wert eintragen
        local threshold = LootFilterSettings.priceThreshold or 0
        local gold = math.floor(threshold / 10000)
        local silver = math.floor((threshold - gold * 10000) / 100)
        local copper = threshold - gold * 10000 - silver * 100

        goldBox:SetText(gold)
        silverBox:SetText(silver)
        copperBox:SetText(copper)
		


 -- Scrollbarer Rahmen für die Itemliste
local scrollFrame = CreateFrame("ScrollFrame", nil, f)
scrollFrame:SetWidth(260)
scrollFrame:SetHeight(130)
scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -90)
scrollFrame:EnableMouse(true)
scrollFrame:SetMovable(false)

-- Das eigentliche EditBox-Feld
local listBox = CreateFrame("EditBox", nil, scrollFrame, "InputBoxTemplate")
listBox:SetMultiLine(true)
listBox:SetWidth(240)
listBox:SetHeight(400)  -- bewusst höher als sichtbarer Bereich
listBox:SetAutoFocus(false)
listBox:SetFontObject(GameFontHighlightSmall)
listBox:SetText(table.concat(getKeys(LootFilterSettings.forceDeleteList), "\n"))

scrollFrame:SetScrollChild(listBox)

-- Scrollfunktion oben
local scrollUpBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
scrollUpBtn:SetWidth(20)
scrollUpBtn:SetHeight(20)
scrollUpBtn:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 5, 0)
scrollUpBtn:SetText("▲")
scrollUpBtn:SetScript("OnClick", function()
    local current = scrollFrame:GetVerticalScroll()
    local new = current - 20
    if new < 0 then new = 0 end
    scrollFrame:SetVerticalScroll(new)
end)

-- Scrollfunktion unten
local scrollDownBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
scrollDownBtn:SetWidth(20)
scrollDownBtn:SetHeight(20)
scrollDownBtn:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 5, 0)
scrollDownBtn:SetText("▼")
scrollDownBtn:SetScript("OnClick", function()
    local current = scrollFrame:GetVerticalScroll()
    local maxScroll = scrollFrame:GetVerticalScrollRange()
    local new = current + 20
    if new > maxScroll then new = maxScroll end
    scrollFrame:SetVerticalScroll(new)
end)

-- Wichtig: WoW denkt jetzt, das ist das Chat-Eingabefeld
LootFilterUI.listBox = listBox

-- Automatischer Zeilenumbruch bei Itemlinks (wie bisher)
listBox:SetScript("OnChar", function()
    local text = LootFilterUI.listBox:GetText()
    local _, _, lastLine = string.find(text, "([^\n]*)$")

    if lastLine and string.find(lastLine, "|Hitem:") and not string.find(lastLine, "^%s*$") then
        local newText = string.gsub(text, "([^\n])(|c%x+|Hitem:)", "%1\n%2")
        if newText ~= text then
            LootFilterUI.listBox:SetText(newText)
        end
    end
end)








        -- Speichern
     local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
saveBtn:SetWidth(80)
saveBtn:SetHeight(22)
saveBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -80, 10)  -- rechts neben Schließen-Button, etwas weiter links
saveBtn:SetText("Save")
saveBtn:SetScript("OnClick", function()
    local g = tonumber(goldBox:GetText()) or 0
    local s = tonumber(silverBox:GetText()) or 0
    local c = tonumber(copperBox:GetText()) or 0
    local total = g * 10000 + s * 100 + c
    LootFilterSettings.priceThreshold = total

    -- Itemliste aktualisieren
    local text = listBox:GetText()
    LootFilterSettings.forceDeleteList = {}

    for item in string.gfind(text, "[^\r\n]+") do
        local name = item

        -- Versuche, aus einem ItemLink den reinen Namen herauszuholen (1.12-kompatibel)
        local left1, right1 = string.find(item, "|h%[")
        local left2, right2 = string.find(item, "%]|h|r")

        if left1 and right2 and right2 > left1 then
            name = string.sub(item, right1 + 1, left2 - 1)
        end

        -- Wenn GetItemInfo funktioniert, verwende dessen Namen
        local gi = GetItemInfo(item)
        if gi then
            name = gi
        end

        if name and name ~= "" then
            LootFilterSettings.forceDeleteList[name] = true
        end
    end

    local keys = getKeys(LootFilterSettings.forceDeleteList)
    local count = tableLength(keys)

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00LootFilter:|r Schwelle gesetzt auf " .. g .. "g " .. s .. "s " .. c .. "c")
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00LootFilter:|r Liste gespeichert (" .. count .. " Einträge)")
end)


        -- Schließen
        local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        closeBtn:SetWidth(60)
        closeBtn:SetHeight(22)
        closeBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
        closeBtn:SetText("Exit")
        closeBtn:SetScript("OnClick", function()
			f:Hide()
			if ChatFrameEditBox == listBox then
				ChatFrameEditBox = originalChatFrameEditBox
			end  
		end)

        f:Show()
		LootFilterUI = f

		if not originalChatFrameEditBox then
			originalChatFrameEditBox = ChatFrameEditBox
		end

		ChatFrameEditBox = listBox

    else
        LootFilterUI:Show()
		if not originalChatFrameEditBox then
			originalChatFrameEditBox = ChatFrameEditBox
		end
		ChatFrameEditBox = LootFilterUI.listBox
    end
end

-- Tooltip-Erweiterung: Verkaufspreis und Max Stack anzeigen

-- Hilfsfunktion zum Extrahieren aus der Datenbank
local function GetSellValueAndStack(itemID)
    if not data or not data[itemID] then return nil, nil end

    local entry = data[itemID]
    local comma = string.find(entry, ",")
    if not comma then return tonumber(entry), 1 end

    local priceStr = string.sub(entry, 1, comma - 1)
    local stackStr = string.sub(entry, comma + 1)

    local price = tonumber(priceStr) or 0
    local maxstack = tonumber(stackStr) or 1

    return price, maxstack
end

hooksecurefunc(GameTooltip, "SetBagItem", 
function(tip, bag, slot)
    if not data then return end

    local _, count = GetContainerItemInfo(bag, slot)
    local link = GetContainerItemLink(bag, slot)
    if not link then return end

    local startPos, endPos = string.find(link, "item:(%d+)")
if not startPos then return end
local itemID = string.sub(link, startPos + 5, endPos)  -- +5 wegen "item:"
itemID = tonumber(itemID)
    if not itemID then return end

    local price, maxstack = GetSellValueAndStack(itemID)
    if not price then return end

    if price == 0 then
        tip:AddLine(ITEM_UNSELLABLE, 1, 1, 1)
    else
        SetTooltipMoney(tip, price * (count or 1))
    end
	tip:AddLine("Max Stackgröße: " .. maxstack, 0.8, 0.8, 0.8)

    tip:Show()
end)

