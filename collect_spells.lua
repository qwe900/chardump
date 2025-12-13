local private = CHDMP.private

function private.GetSpellData()
    local ret = {}
    for i = 1, MAX_SKILLLINE_TABS do
        local name, _, _, offset, numSpells = GetSpellTabInfo(i)
        if not name then break end

        for s = offset + 1, offset + numSpells do
            local link = GetSpellLink(s, BOOKTYPE_SPELL)
            if link then
                local spellid = link:match("Hspell:(%d+)")
                if spellid then ret[spellid] = i end
            end
        end
    end
    private.ILog(CHDMP.L("spells_done", private.CountKeys(ret)))
    return ret
end
