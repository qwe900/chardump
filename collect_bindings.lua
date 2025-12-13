local private = CHDMP.private

local function CollectBindings()
    local map = {}
    local num = (GetNumBindings and GetNumBindings()) or 0
    for i = 1, num do
        local command = GetBinding(i)
        if type(command) == "string" and #command > 0 then
            local keys = {}
            local k1, k2 = GetBindingKey(command)
            if k1 then table.insert(keys, k1) end
            if k2 then table.insert(keys, k2) end
            map[command] = keys
        end
    end
    return map
end

local function SameKeySets(a, b)
    if #a ~= #b then return false end
    local s = {}
    for _, k in ipairs(b) do s[k] = true end
    for _, k in ipairs(a) do if not s[k] then return false end end
    return true
end

function private.GetChangedBindings()
    local result = { set = 2, changed = {} }

    if _G.GetCurrentBindingSet then
        local ok, set = pcall(GetCurrentBindingSet)
        if ok and (set == 1 or set == 2) then result.set = set end
    end

    local current = CollectBindings()

    local defaults = {}
    local okLoadDefault = pcall(LoadBindings, 0)
    if okLoadDefault then defaults = CollectBindings() end

    pcall(LoadBindings, result.set)

    for cmd, keys in pairs(current) do
        local dkeys = defaults[cmd] or {}
        if not SameKeySets(keys, dkeys) then
            result.changed[cmd] = keys
        end
    end

    local changedCount = private.CountKeys(result.changed)
    private.ILog(CHDMP.L("keybindings_done", changedCount))
    return result
end
