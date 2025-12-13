local private = CHDMP.private

local function IsJsonSafeString(s)
    if type(s) ~= "string" then return true end
    for i = 1, #s do
        local b = string.byte(s, i)
        if b < 32 and b ~= 8 and b ~= 9 and b ~= 10 and b ~= 12 and b ~= 13 then
            return false, b
        end
    end
    return true
end

function private.GetMacroData()
    local ret = { account = {}, character = {} }

    local maxAccount = _G.MAX_ACCOUNT_MACROS or 36
    local maxChar    = _G.MAX_CHARACTER_MACROS or 18
    local total      = maxAccount + maxChar

    local skipped = 0

    for i = 1, total do
        local name, icon, body = GetMacroInfo(i)
        if name then
            body = tostring(body or "")
            local ok = IsJsonSafeString(body)
            if ok then
                local entry = { id = i, name = name, icon = icon, body = body }
                if i <= maxAccount then
                    table.insert(ret.account, entry)
                else
                    table.insert(ret.character, entry)
                end
            else
                skipped = skipped + 1
            end
        end
    end

    local exported = (#ret.account) + (#ret.character)
    if skipped > 0 then
        private.ILog(CHDMP.L("macros_done_skipped", exported, skipped))
    else
        private.ILog(CHDMP.L("macros_done", exported))
    end

    return ret
end
