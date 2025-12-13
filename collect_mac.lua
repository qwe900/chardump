local private = CHDMP.private

function private.GetMountsAndCritters()
    local ret = {}

    if type(GetNumCompanions) == "function" and type(GetCompanionInfo) == "function" then
        local nMounts = GetNumCompanions("MOUNT") or 0
        for i = 1, nMounts do
            local _, _, spellId = GetCompanionInfo("MOUNT", i)
            if spellId then
                ret["M:" .. i] = spellId
            end
        end

        local nCrit = GetNumCompanions("CRITTER") or 0
        for i = 1, nCrit do
            local _, _, spellId = GetCompanionInfo("CRITTER", i)
            if spellId then
                ret["C:" .. i] = spellId
            end
        end
    end

    local m = GetNumCompanions and (GetNumCompanions("MOUNT") or 0) or -1
    local c = GetNumCompanions and (GetNumCompanions("CRITTER") or 0) or -1
    if CHDMP and CHDMP.L then
        private.ILog(CHDMP.L("mounts_done", m, c))
    else
        private.ILog(("Mounts & Critters DONE... (%d Mounts and %d Critters)"):format(m, c))
    end

    return ret
end
