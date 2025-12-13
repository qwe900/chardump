local private = CHDMP.private

function private.GetAchievementCategoryData()
    local achievements = {}
    if not GetCategoryNumAchievements or not GetAchievementInfo then return achievements end

    local num = GetCategoryNumAchievements(-1) or 0
    for index = 1, num do
        local achievementID, _, points, completed, month, day, year, _, _, _, _, isGuildAch =
        GetAchievementInfo(-1, index)

        if completed then
            local categoryID = (GetAchievementCategory and GetAchievementCategory(achievementID)) or 0
            local timeStamp = 0
            if year and month and day and year > 0 then
                timeStamp = time({ year = 2000 + year, month = month, day = day }) or 0
            end
            table.insert(achievements, {
                id = achievementID,
                points = points or 0,
                completed = 1,
                time = timeStamp,
                isGuildAchievement = isGuildAch,
                category = categoryID,
            })
        end
    end
    return achievements
end
