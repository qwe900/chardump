local private = CHDMP.private

function private.GetCurrencyData()
    local ret = {}
    if not GetCurrencyListSize or not GetCurrencyListInfo then return ret end

    for i = 1, GetCurrencyListSize() do
        local _, _, _, _, _, count, _, _, itemID = GetCurrencyListInfo(i)
        if count or itemID then
            ret[i] = { C = count or 0, I = itemID or 0 }
        end
    end
    return ret
end
