local addonName, NS = ...
local tt = CreateFrame("GameTooltip", "QuickSimTT", UIParent, "GameTooltipTemplate")
    tt:SetOwner(UIParent, "ANCHOR_PRESERVE")
    tt:SetPoint("CENTER", "UIParent")
    tt:Hide()
local PLAIN_LETTER = 8383 -- Plain Letter stationery item id, "always" cached (for enchants)
local slots = {"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", 
"WristSlot", "WaistSlot", "LegsSlot", "FeetSlot", "HandsSlot", "Finger0Slot",
 "Finger1Slot", "Trinket0Slot", "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot"}
local slotMap = {}
slotMap["HeadSlot"] = "HEAD";
slotMap["NeckSlot"] = "NECK";
slotMap["ShoulderSlot"] = "SHOULDERS";
slotMap["BackSlot"] = "BACK";
slotMap["ChestSlot"] = "CHEST";
slotMap["WristSlot"] = "WRISTS";
slotMap["WaistSlot"] = "WAIST";
slotMap["LegsSlot"] = "LEGS";
slotMap["FeetSlot"] = "FEET";
slotMap["HandsSlot"] = "HANDS";
slotMap["Finger0Slot"] = "FINGER_1";
slotMap["Finger1Slot"] = "FINGER_2";
slotMap["Trinket0Slot"] = "TRINKET_1";
slotMap["Trinket1Slot"] = "TRINKET_2";
slotMap["MainHandSlot"] = "MAIN_HAND";
slotMap["SecondaryHandSlot"] = "OFF_HAND";
slotMap["RangedSlot"] = "RANGED";

local xformSlot = {}
xformSlot["HeadSlot"] = "Head";
xformSlot["NeckSlot"] = "Neck";
xformSlot["ShoulderSlot"] = "Shoulders";
xformSlot["BackSlot"] = "Cloak";
xformSlot["ChestSlot"] = "Chest";
xformSlot["WristSlot"] = "Bracers";
xformSlot["WaistSlot"] = "Waist";
xformSlot["LegsSlot"] = "Legs";
xformSlot["FeetSlot"] = "Boots";
xformSlot["HandsSlot"] = "Gloves";
xformSlot["Finger0Slot"] = "Ring";
xformSlot["Finger1Slot"] = "Ring";
xformSlot["MainHandSlot"] = "Weapon";
xformSlot["SecondaryHandSlot"] = "Shield";

local QuickSimFrame = nil
local fullData = {}
fullData["stats"] = {}
fullData["items"] = {}

local function GetCharacterInfo()
    local info = {}
    info["name"] = GetUnitName("player")
    info["level"] = UnitLevel("player")
    info["gameClass"] = UnitClass("player")
    info["race"] = UnitRace("player")
    info["faction"],_ = UnitFactionGroup("player")
    return info
end

local function GetStats()
    local stats = {}
    _, stats["strength"], _, _ = UnitStat("player", 1)
    _, stats["agility"], _, _ = UnitStat("player", 2)
    _, stats["stamina"], _, _ = UnitStat("player", 3)
    _, stats["intellect"], _, _ = UnitStat("player", 4)
    _, stats["spirit"], _, _ = UnitStat("player", 5)
    stats["arcaneDamage"] = GetSpellBonusDamage(7)
    stats["fireDamage"] = GetSpellBonusDamage(3)
    stats["frostDamage"] = GetSpellBonusDamage(5)
    stats["crit"] = GetCritChance()
    local statList = { "agility",  "arcaneDamage",  "armor",  "attackPower",  "crit",  "critRating",  "defense",  "dodge",  "feralAttackPower",  "fireDamage",  "frostDamage",  "haste",  "hasteRating",  "healing",  "health",  "hit",  "holyDamage",  "intellect",  "mainHandSpeed",  "mana",  "mp5",  "natureDamage",  "parry",  "shadowDamage",  "shadowResist",  "spellCrit",  "spellDamage",  "spellHaste",  "spellHit",  "spirit",  "stamina",  "strength" }
    return stats
end

local function ConfigFrame(text)
    if not QuickSimFrame then
        local f = CreateFrame("Frame", "QuickSimFrame", UIParent, "DialogBoxFrame")
        f:ClearAllPoints()
        f:SetMovable(true)
        -- local frameConfig = { "point": "CENTER", "relativeFrame"= nil, "relativePoint" = "CENTER", "ofsx" = 0, "ofsy" = 0, "width": 750, "height"= 400}
        f:SetPoint(
        "CENTER",
        nil,
        "CENTER",
        0,
        0
        )
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
            edgeSize = 16,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        }
        )
        f:SetSize(750, 400)
        f:SetClampedToScreen(true)
        f:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
            self:StartMoving()
            end
        end
        )
        f:SetScript("OnMouseUp", function(self, button)
            self:StopMovingOrSizing()
        end
        )
        local sf = CreateFrame("ScrollFrame", "QuickSimScrollFrame", f, "UIPanelScrollFrameTemplate")
        sf:SetPoint("LEFT", 16, 0)
        sf:SetPoint("RIGHT", -32, 0)
        sf:SetPoint("TOP", 0, -32)
        
        local eb = CreateFrame("EditBox", "QuickSimEditBox", QuickSimScrollFrame)
        eb:SetSize(sf:GetSize())
        eb:SetMultiLine(true)
        eb:SetAutoFocus(true)
        eb:SetFontObject("ChatFontNormal")
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(eb)
        f:SetResizable(true)
        f:SetMinResize(150, 100)
        local rb = CreateFrame("Button", "QuickSimResizeButton", f)
        rb:SetPoint("BOTTOMRIGHT", -6, 7)
        rb:SetSize(16, 16)

        rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        rb:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                f:StartSizing("BOTTOMRIGHT")
                self:GetHighlightTexture():Hide() -- more noticeable
            end
        end
        )
        rb:SetScript("OnMouseUp", function(self, button)
            f:StopMovingOrSizing()
            self:GetHighlightTexture():Show()
            eb:SetWidth(sf:GetWidth())

            -- save size between sessions
            frameConfig.width = f:GetWidth()
            frameConfig.height = f:GetHeight()
        end
        )
        QuickSimFrame = f
    end
    QuickSimEditBox:SetText(text)
    QuickSimEditBox:HighlightText()
    return QuickSimFrame
end

local function GetEnchant(id)
    local link = ("item:%i:%i"):format(PLAIN_LETTER, id)
    -- tt:Show()
    tt:SetOwner(UIParent, "ANCHOR_PRESERVE")
	tt:SetHyperlink("spell:1:QuickSimTT")
	tt:SetHyperlink(link)
    local text = _G["QuickSimTTText" .. "Left" .. 3]:GetText()
    tt:Hide()
    return text, ("|cffffff00%s|r"):format(text)
    -- return ""
end

local function trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

local function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end
  
local function stringStarts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end
 

local function GenerateJson()
    local items = {}
    for _, slotName in ipairs(slots) do
        local itemDetail = {}
        local slotId = GetInventorySlotInfo(slotName)
        local itemLink = GetInventoryItemLink("player", slotId)
        local itemName, _, _, itemLevel, _, _, _, _, _, _, _ = GetItemInfo(itemLink)
        local _, _, _, _, itemId, enchant, gem1, gem2, gem3, gem4,
        _, _, _, _ = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
        if enchant ~= "" then
            itemDetail["enchant"] = {}
            local enchantDetail = {}
            enchantDetail["id"] = tonumber(enchant)
            print("Getting enchant details from " .. itemName .. " which is a " .. slotName .. " with id " .. enchant)
            local enchantDbEntryToUse = nil
            if qsEnchantDict[enchant] then
                if tablelength(qsEnchantDict[enchant]) > 1 then
                    for _, enchantDbRecord in ipairs(qsEnchantDict[enchant]) do
                        local lookupVal = xformSlot[slotName]
                        if string.find(enchantDbRecord["name"], ".*" .. lookupVal .. ".*") then
                            enchantDbEntryToUse = enchantDbRecord
                        end
                    end
                end
                if enchantDbEntryToUse == nil then
                    local iter = pairs(qsEnchantDict[enchant])
                    _, enchantDbEntryToUse = iter(qsEnchantDict[enchant])
                end
                if stringStarts(enchantDbEntryToUse["name"], "Enchant ") then
                    enchantDetail["spellId"] = tonumber(enchantDbEntryToUse["spell_id"])
                else
                    enchantDetail["itemId"] = tonumber(enchantDbEntryToUse["spell_id"])
                end
                enchantDetail["name"] = enchantDbEntryToUse["name"]
            end
            -- enchantDetail["name"] = GetEnchant(enchant)
            itemDetail["enchant"] = enchantDetail
        end
        itemDetail["name"] = itemName
        itemDetail["id"] = tonumber(itemId)
        itemDetail["gems"] = {}
        -- itemDetail["gems"] = {}
        itemDetail["slot"] = slotMap[slotName]
        -- itemDetail["enchant"] = {}
        
        table.insert(items, itemDetail)
    end
    return items
end

local function CommandHook(msg, editbox)
    fullData["items"] = GenerateJson()
    fullData["stats"] = GetStats()
    fullData["name"] = GetUnitName("player") .. " QuickSimExport"
    fullData["character"] = GetCharacterInfo()
    local f = ConfigFrame(NS.json.encode(fullData))
    f:Show()
end
qsEnchantDict = NS.json.decode(NS.enchantDict)
SLASH_QUICKSIM1 = "/quicksim"
SlashCmdList["QUICKSIM"] = CommandHook