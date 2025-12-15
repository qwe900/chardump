local private = CHDMP.private

local function SafeGetItemInfo(linkOrId)
    local name, _, quality = GetItemInfo(linkOrId)
    return name, quality or 0
end

local function ExtractItemAndEnchant(itemLink)
    if not itemLink then return nil, nil end
    local itemId, enchantId = itemLink:match("item:(%d+):(%d+)")
    return tonumber(itemId), tonumber(enchantId)
end

local function ExtractGems(itemLink)
    if not itemLink or not GetItemGem then return 0,0,0 end
    local g1, g2, g3 = 0, 0, 0
    local _, l1 = GetItemGem(itemLink, 1); if l1 then g1 = tonumber(l1:match("item:(%d+)")) or 0 end
    local _, l2 = GetItemGem(itemLink, 2); if l2 then g2 = tonumber(l2:match("item:(%d+)")) or 0 end
    local _, l3 = GetItemGem(itemLink, 3); if l3 then g3 = tonumber(l3:match("item:(%d+)")) or 0 end
    return g1, g2, g3
end

-- ---------- helpers ----------
local function StoreItemContainer(ret, bag, slot, link)
    if not link then return end

    local _, count = GetContainerItemInfo(bag, slot)
    local _, quality = SafeGetItemInfo(link)
    local itemId, enchantId = ExtractItemAndEnchant(link)
    local g1, g2, g3 = ExtractGems(link)

    ret[tostring(bag) .. ":" .. tostring(slot)] = {
        I  = itemId or 0,
        C  = count or 1,
        E  = enchantId or 0,
        G1 = g1, G2 = g2, G3 = g3,
        Q  = quality or 0,
    }
end

local function StoreItemInventory(ret, key, unit, invSlot, link)
    if not link then return end

    local count = GetInventoryItemCount(unit, invSlot) or 1
    local _, quality = SafeGetItemInfo(link)
    local itemId, enchantId = ExtractItemAndEnchant(link)
    local g1, g2, g3 = ExtractGems(link)

    ret[key] = {
        I  = itemId or 0,
        C  = count or 1,
        E  = enchantId or 0,
        G1 = g1, G2 = g2, G3 = g3,
        Q  = quality or 0,
    }
end

-- ---------- data collection ----------
local function GetBankData()
    local ret = {}

    -- 1) Main bank slots: InventorySlot 39..66 (28 slots)
    ret["main"] = {}
    for invSlot = 39, 66 do
        local link = GetInventoryItemLink("player", invSlot)
        if link then
            StoreItemInventory(ret["main"], "inv:" .. invSlot, "player", invSlot, link)
        end
    end

    -- 2) Bank bag ITEMS equipped: InventorySlot 67..73 (7 bag slots)
    -- (these are the bags themselves, not their contents)
    ret["bankbags"] = {}
    for i = 1, 7 do
        local invSlot = 66 + i -- 67..73
        local link = GetInventoryItemLink("player", invSlot)
        if link then
            -- keep same shape (I,C,E,G*,Q) even though gems don’t matter for bags
            StoreItemInventory(ret["bankbags"], "inv:" .. invSlot, "player", invSlot, link)
        else
            ret["bankbags"]["inv:" .. invSlot] = { I = 0, C = 0, E = 0, G1 = 0, G2 = 0, G3 = 0, Q = 0 }
        end
    end

    -- 3) Contents of bank bags: ContainerIDs 5..11 (best effort)
    ret["bags"] = {}
    for bag = 5, 11 do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                StoreItemContainer(ret["bags"], bag, slot, link)
            end
        end
    end

    return ret
end

-- ---------- step workflow ----------
private._bankStep = private._bankStep or nil

local function BankIsOpen()
    -- most reliable in 3.3.5: BankFrame visible
    if _G.BankFrame and BankFrame:IsShown() then
        return true
    end
    -- fallback: try if at least one bank slot is readable
    for invSlot = 39, 66 do
        if GetInventoryItemLink("player", invSlot) then
            return true
        end
    end
    return false
end

local function ShowOpenBankPopup()
    if not StaticPopupDialogs then return end
    if not StaticPopupDialogs["CHDMP_OPEN_BANK"] then
        StaticPopupDialogs["CHDMP_OPEN_BANK"] = {
            text = (CHDMP and CHDMP.L and CHDMP.L("bank_open_prompt")) or "Open your bank now and then click OK.",
            button1 = OKAY,
            button2 = CANCEL,
            OnAccept = function()
                if private._bankStep then private._bankStep.ack = true end
            end,
            OnCancel = function()
                if private._bankStep then private._bankStep.cancel = true end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    StaticPopup_Show("CHDMP_OPEN_BANK")
end

function private.Step_BankScan()
    if not private._bankStep then
        private._bankStep = { phase = "init", t0 = GetTime() or 0 }
    end

    local S = private._bankStep

    if S.phase == "init" then
        ShowOpenBankPopup()
        S.phase = "wait"
        return false
    end

    if S.phase == "wait" then
        local now = GetTime() or 0

        if BankIsOpen() and S.ack then
            if StaticPopup_Hide then StaticPopup_Hide("CHDMP_OPEN_BANK") end
            S.phase = "collect"
            return false
        end

        if S.cancel or (now - (S.t0 or now) > 45) then
            if StaticPopup_Hide then StaticPopup_Hide("CHDMP_OPEN_BANK") end
            private.dmp["bank"] = {}
            private._bankStep = nil
            return true
        end

        return false
    end

    if S.phase == "collect" then
        private.dmp["bank"] = GetBankData() or {}

        local cntMain = private.dmp["bank"].main and private.CountKeys(private.dmp["bank"].main) or 0
        local cntBags = private.dmp["bank"].bags and private.CountKeys(private.dmp["bank"].bags) or 0
        local cntBankBags = private.dmp["bank"].bankbags and private.CountKeys(private.dmp["bank"].bankbags) or 0

        if CHDMP and CHDMP.L then
            private.ILog(CHDMP.L("bank_scan_done", (cntMain + cntBags + cntBankBags) or 0))
        else
            private.ILog("Bank scan DONE (main=" .. cntMain .. ", bankbags=" .. cntBankBags .. ", bags=" .. cntBags .. ")")
        end

        if StaticPopup_Hide then StaticPopup_Hide("CHDMP_OPEN_BANK") end
        private._bankStep = nil
        return true
    end

    private.dmp["bank"] = {}
    private._bankStep = nil
    return true
end
