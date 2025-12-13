local private = CHDMP.private

function private.GetGlyphData()
    local ret = {}
    if not GetNumTalentGroups or not GetGlyphSocketInfo then return ret end

    local count = 0
    for specIndex = 1, GetNumTalentGroups() do
        ret[specIndex] = {}
        for slotIndex = 1, 6 do
            local enabled, glyphType, glyphSpell = GetGlyphSocketInfo(slotIndex, specIndex)
            local glyphID = 0
            local link = GetGlyphLink and GetGlyphLink(slotIndex, specIndex)
            if link then
                local _, idstr = link:match("Hglyph:(%d+):(%d+)")
                glyphID = idstr and tonumber(idstr) or 0
            end
            ret[specIndex][slotIndex] = { glyphID = glyphID, Type = glyphType, spell = glyphSpell }
            count = count + 1
        end
    end

    private.ILog(CHDMP.L("glyphs_done", count))
    return ret
end
