-- Initiale SavedVariables
if not LootFilterSettings then
    LootFilterSettings = {
        priceThreshold = 10000,
        forceDeleteList = {},
        debugEnabled = false,  -- <--- NEW
		showReason = false,  -- NEW: Show reasons on/off
		unknownItems = {}
    }
else
    LootFilterSettings.unknownItems = LootFilterSettings.unknownItems or {}
end

local data = MyLootFilterData

local function LF_Debug(msg)
    if LootFilterSettings and LootFilterSettings.debugEnabled then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00LootFilter Debug:|r " .. msg)
    end
end


-- Helper function: Read vendor price from ShaguValue data
local function GetVendorPrice(itemID)
    if not data then
        LF_Debug("No 'data' table found!")
        return 0
    end
    local entry = data[itemID]
    if not entry then
        LF_Debug("No entry for ItemID " .. tostring(itemID))
		local itemName = GetItemInfo(itemID)
		if itemName and itemName ~= "" then
			if not LootFilterSettings then
    LF_Debug("LootFilterSettings is nil!")
    return
end
if not LootFilterSettings.unknownItems then
    LF_Debug("LootFilterSettings.unknownItems is nil!")
    LootFilterSettings.unknownItems = {}
end
			if not LootFilterSettings.unknownItems[itemID] then
				LootFilterSettings.unknownItems[itemID] = itemName
				LF_Debug("Unknown item saved: [" .. itemID .. "] " .. itemName)
			end
		end
        return 0
    end

    local commaStart, commaEnd = string.find(entry, ",")

    if not commaStart then
        LF_Debug("Invalid format for ItemID " .. itemID)
        return 0
    end

    local sellStr = string.sub(entry, 1, commaStart - 1)
    local maxstackStr = string.sub(entry, commaEnd + 1)

    local sellPrice = tonumber(sellStr) or 0
    local maxstack = tonumber(maxstackStr) or 1

    local totalPrice = sellPrice * maxstack

    LF_Debug("ItemID " .. itemID .. " Vendor price per unit: " .. sellPrice .. ", MaxStack: " .. maxstack .. ", Total price: " .. totalPrice)

    return totalPrice
end

local function GetDeleteReason(name, quality, itemID)
    local price = GetVendorPrice(itemID) or 0
    local onList = LootFilterSettings.forceDeleteList[name] == true

    if not onList and quality ~= 0 then
        return "Quality"
    end
	
	if (quality == 0 or onList) and price >= LootFilterSettings.priceThreshold then
        return "Price"
    end

    if price < LootFilterSettings.priceThreshold then
		if quality == 0 then
			return "Quality"
		elseif onList then
			return "List"
		end	
    end

    return "Unknown"
end

local function GetQualityFromLinkColor(link)
    if not link then return nil end
    local colorCode = string.sub(link, 1, 10)
    local qualityMap = {
        ["|cff9d9d9d"] = 0,
        ["|cffffffff"] = 1,
        ["|cff1eff00"] = 2,
        ["|cff0070dd"] = 3,
        ["|cffa335ee"] = 4,
        ["|cffff8000"] = 5,
    }
    return qualityMap[colorCode]
end

function ShouldDeleteItem(name, quality, itemID)
    local price = GetVendorPrice(itemID) or 0

    LF_Debug("Checking item '" .. tostring(name) .. "' (Quality: " .. tostring(quality) .. ", Price: " .. tostring(price) .. ")")

    if LootFilterSettings.forceDeleteList[name] then
        LF_Debug("Item is on ForceDeleteList.")
        if price < LootFilterSettings.priceThreshold then
            LF_Debug("Deleting due to ForceDeleteList and price < threshold")
            return true
        else
            LF_Debug("Not deleting, price >= threshold")
            return false
        end
    end

    if quality == 0 then
        LF_Debug("Item is grey.")
        if price < LootFilterSettings.priceThreshold then
            LF_Debug("Deleting grey item, price < threshold")
            return true
        else
            LF_Debug("Grey item but price >= threshold, not deleting")
            return false
        end
    end

    LF_Debug("Item will not be deleted.")
    return false
end

local recentlyLootedItemIDs = {}

local function CheckLootedItems()
    LF_Debug("CheckLootedItems started")

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local _, _, itemIDStr = string.find(link, "item:(%d+)")
                local itemID = tonumber(itemIDStr)

                if itemID and recentlyLootedItemIDs[itemID] then
                    local name, _, quality = GetItemInfo(link)

                    if not name then
                        local left1, right1 = string.find(link, "|h%[")
                        local left2, right2 = string.find(link, "%]|h|r")
                        if left1 and right2 and right2 > left1 then
                            name = string.sub(link, right1 + 1, left2 - 1)
                        end
                    end

                    if not quality then
                        quality = GetQualityFromLinkColor(link)
                    end

                    if name and quality then
                        local reason = GetDeleteReason(name, quality, itemID)
						if LootFilterSettings.showReason then
							if ShouldDeleteItem(name, quality, itemID) then
								PickupContainerItem(bag, slot)
								DeleteCursorItem()
								DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Deleted:|r " .. link .. " (" .. reason .. ")")
							else
								DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Kept:|r " .. link .. " (" .. reason .. ")")
							end
						else
							if ShouldDeleteItem(name, quality, itemID) then
								PickupContainerItem(bag, slot)
								DeleteCursorItem()
							end
						end
                    end
                end
            end
        end
    end

    LF_Debug("CheckLootedItems finished")
end

local function CheckAllInventoryItems()
    LF_Debug("CheckAllInventoryItems started")

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local name, _, quality = GetItemInfo(link)

                if not name then
                    local left1, right1 = string.find(link, "|h%[")
                    local left2, right2 = string.find(link, "%]|h|r")
                    if left1 and right2 and right2 > left1 then
                        name = string.sub(link, right1 + 1, left2 - 1)
                    end
                end

                if not quality then
                    quality = GetQualityFromLinkColor(link)
                end

                local _, _, itemIDStr = string.find(link, "item:(%d+)")
                local itemID = tonumber(itemIDStr)

                if name and quality and itemID then
                    local reason = GetDeleteReason(name, quality, itemID)
                    if LootFilterSettings.showReason then
                        if ShouldDeleteItem(name, quality, itemID) then
                            PickupContainerItem(bag, slot)
                            DeleteCursorItem()
                            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Deleted:|r " .. link .. " (" .. reason .. ")")
                        else
                            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Kept:|r " .. link .. " (" .. reason .. ")")
                        end
                    else
                        if ShouldDeleteItem(name, quality, itemID) then
                            PickupContainerItem(bag, slot)
                            DeleteCursorItem()
                        end
                    end
                end
            end
        end
    end

    LF_Debug("CheckAllInventoryItems finished")
end

local function SellItems()
    local soldAny = false

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local name = GetItemInfo(link)
                if not name then
                    local left1, right1 = string.find(link, "|h%[")
                    local left2, right2 = string.find(link, "%]|h|r")
                    if left1 and right2 and right2 > left1 then
                        name = string.sub(link, right1 + 1, left2 - 1)
                    end
                end
                local quality = GetQualityFromLinkColor(link)
                local _, _, itemIDStr = string.find(link, "item:(%d+):")
                local itemID = tonumber(itemIDStr)

                local shouldSell = false
                if LootFilterSettings.forceDeleteList[name] then
                    shouldSell = true
                elseif quality == 0 then
                    shouldSell = true
                end

                if shouldSell then
                    UseContainerItem(bag, slot)
                    DEFAULT_CHAT_FRAME:AddMessage("|cffaaaaaaSold:|r " .. link)
                    soldAny = true
                end
            end
        end
    end

    if not soldAny then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LootFilter]|r No items found to sell.")
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LootFilter]|r Selling complete.")
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("MERCHANT_SHOW")
frame:SetScript("OnEvent", function()
    if event == "MERCHANT_SHOW" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LootFilter]|r Vendor detected – selling items …")
        SellItems()
    end
end)

local lootFrameChecker = CreateFrame("Frame")
local lastLootVisible = false
local checkScheduled = false
local checkRunAt = 0
local delay = 0.5

local function PreloadLootItemInfos()
    recentlyLootedItemIDs = {}

    if LootFrame and LootFrame:IsShown() then
        for slot = 1, GetNumLootItems() do
            local link = GetLootSlotLink(slot)
            if link then
                local _, _, itemIDStr = string.find(link, "item:(%d+)")
                local itemID = tonumber(itemIDStr)
                if itemID then
                    recentlyLootedItemIDs[itemID] = true
                    GetItemInfo(link)
                end
            end
        end
    end
end

lootFrameChecker:SetScript("OnUpdate", function(self)
    local nowLootVisible = LootFrame and LootFrame:IsShown()
    local currentTime = GetTime()

    if nowLootVisible then
        PreloadLootItemInfos()
    end

    if lastLootVisible and not nowLootVisible and not checkScheduled then
        checkScheduled = true
        checkRunAt = currentTime + delay
    end

    if checkScheduled and currentTime >= checkRunAt then
        checkScheduled = false
        CheckLootedItems()
    end

    lastLootVisible = nowLootVisible
end)

SLASH_LF1 = "/lf"
SlashCmdList["LF"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "debug" then
        LootFilterSettings.debugEnabled = not LootFilterSettings.debugEnabled
        local status = LootFilterSettings.debugEnabled and "enabled" or "disabled"
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LootFilter]|r Debugging is now " .. status .. ".")
    elseif msg == "notify" then
        LootFilterSettings.showReason = not LootFilterSettings.showReason
        local status = LootFilterSettings.showReason and "enabled" or "disabled"
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LootFilter]|r Notifications are now " .. status .. ".")
    elseif msg == "all" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LootFilter]|r Starting full inventory scan...")
        CheckAllInventoryItems()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LootFilter]|r Inventory scan complete.")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[LootFilter]|r Available commands:")
		DEFAULT_CHAT_FRAME:AddMessage("|cffaaaaaa/lfo|r – Toggle LootFilter UI")
        DEFAULT_CHAT_FRAME:AddMessage("|cffaaaaaa/lf debug|r – Toggle debug output")
        DEFAULT_CHAT_FRAME:AddMessage("|cffaaaaaa/lf notify|r – Toggle kept/deleted notifications")
        DEFAULT_CHAT_FRAME:AddMessage("|cffaaaaaa/lf all|r – Check full inventory and delete items by filter")
    end
end
