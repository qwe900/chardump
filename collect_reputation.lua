local private = CHDMP.private

local REPUTATION_IDS = {
    21, 47, 54, 59, 67, 68, 69, 70, 72, 76, 81,
    87, 92, 93, 169, 270, 349, 369, 469, 470,
    509, 510, 529, 530, 576, 577, 589, 609,
    729, 730, 749, 809, 889, 890, 909, 910,
    911, 922, 930, 932, 933, 934, 935, 941,
    942, 946, 947, 967, 970, 978,
    989, 990, 1011, 1012, 1015, 1031, 1038,
    1050, 1052, 1064, 1067, 1068, 1073, 1077,
    1082, 1085, 1090, 1091, 1094, 1098, 1104,
    1105, 1106, 1119, 1124, 1156
}

function private.GetRepData()
    local ret = {}

    if type(GetFactionInfoByID) ~= "function" then
        private.ErrLog("GetFactionInfoByID not available on WotLK client -> reputation empty")
        return ret
    end

    for _, factionID in ipairs(REPUTATION_IDS) do
        local name, _, _, bottomValue, topValue, earnedValue, atWarWith, canToggleAtWar, isHeader =
        GetFactionInfoByID(factionID)

        if name and not isHeader and earnedValue and earnedValue ~= 0 then
            local flags = 1
            if canToggleAtWar and atWarWith then flags = bit.bor(flags, 2) end
            if not canToggleAtWar then flags = bit.bor(flags, 16) end

            table.insert(ret, { ID = factionID, Flags = flags, Value = earnedValue })
        end
    end

    private.ILog(CHDMP.L("reputations_done", #ret))
    return ret
end
