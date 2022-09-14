local addonName, NS = ...

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

local function GenerateJson()
    local items = {}
    for _, slotName in ipairs(slots) do
        local slotId = GetInventorySlotInfo(slotName)
        local itemLink = GetInventoryItemLink("player", slotId)
        local itemName, _, _, itemLevel, _, _, _, _, _, _, _ = GetItemInfo(itemLink)
        local itemId = select(3, strfind(itemLink, "item:(%d+)"))
        local itemDetail = {}
        itemDetail["name"] = itemName
        itemDetail["id"] = tonumber(itemId)
        -- itemDetail["gems"] = {}
        itemDetail["slot"] = slotMap[slotName]
        -- itemDetail["enchant"] = {}
        table.insert(items, itemDetail)
    end
    return items
end

local function CommandHook(msg, editbox)
    fullData["items"] = GenerateJson()
    -- fullData["stats"] = GetStats()
    fullData["name"] = GetUnitName("player") .. "-QuickSimExport"
    fullData["character"] = GetCharacterInfo()
    local f = ConfigFrame(NS.json.encode(fullData))
    f:Show()
end

SLASH_QUICKSIM1 = "/quicksim"
SlashCmdList["QUICKSIM"] = CommandHook