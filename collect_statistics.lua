local private = CHDMP.private

function private.DumpPlayerStatistic()
    local playerStatistics = {}
    if not GetStatisticsCategoryList then return playerStatistics end

    local categoryList = GetStatisticsCategoryList() or {}
    for _, categoryId in pairs(categoryList) do
        local numStats = (GetCategoryNumAchievements and GetCategoryNumAchievements(categoryId)) or 0

        for i = 1, numStats do
            local statId = select(1, GetAchievementInfo(categoryId, i))
            if statId and GetStatistic then
                local ok, quantity = pcall(GetStatistic, statId)
                if ok and quantity ~= nil then
                    local stat = { id = statId, quantity = tonumber(quantity) or 0, criteria = {} }

                    local numCriteria = (GetAchievementNumCriteria and GetAchievementNumCriteria(statId)) or 0
                    for j = 1, numCriteria do
                        local _, _, completed, cQuantity, _, _, _, _, _, criteriaID =
                        GetAchievementCriteriaInfo(statId, j)

                        table.insert(stat.criteria, {
                            id = criteriaID or 0,
                            quantity = tonumber(cQuantity) or 0,
                            completed = completed and 1 or 0,
                        })
                    end

                    table.insert(playerStatistics, stat)
                end
            end
        end
    end

    return playerStatistics
end
