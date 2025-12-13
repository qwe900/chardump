local private = CHDMP.private

local function SafeGetItemInfo(linkOrId)
    local name, _, quality, _, _, _, _, _, equipSlot = GetItemInfo(linkOrId)
    return name, quality or 0, equipSlot or ""
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

function private.GetIData()
    local ret = {}

    -- Equipped: WotLK Slots (0..19 is safe-ish; keep 0..19 to match your older layout)
    for slot = 0, 19 do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            local _, quality, equipSlot = SafeGetItemInfo(itemLink)
            local count = (equipSlot == "INVTYPE_BAG") and 1 or (GetInventoryItemCount("player", slot) or 1)
            local itemId, enchantId = ExtractItemAndEnchant(itemLink)
            local g1, g2, g3 = ExtractGems(itemLink)

            ret["0000:" .. slot] = {
                I = itemId or 0,
                C = count or 1,
                E = enchantId or 0,
                G1 = g1, G2 = g2, G3 = g3,
                Q = quality or 0,
            }
        end
    end

    -- Bags: WotLK bags are 0..4 (backpack+4). Keep your 0..11 if you want bank bags elsewhere,
    -- but here we dump inventory bags only:
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local _, count = GetContainerItemInfo(bag, slot)
                local _, quality = SafeGetItemInfo(itemLink)
                local itemId, enchantId = ExtractItemAndEnchant(itemLink)
                local g1, g2, g3 = ExtractGems(itemLink)

                local prefix = bag + 1000
                ret[prefix .. ":" .. slot] = {
                    I = itemId or 0,
                    C = count or 1,
                    E = enchantId or 0,
                    G1 = g1, G2 = g2, G3 = g3,
                    Q = quality or 0,
                }
            end
        end
    end

    private.ILog(CHDMP.L("inventory_done", private.CountKeys(ret)))
    return ret
end
