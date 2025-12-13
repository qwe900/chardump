local private = CHDMP.private

function private.GetQuestCompletedData()
    local completedQuests = {}
    if not GetQuestsCompleted then return completedQuests end

    local t = {}
    GetQuestsCompleted(t)
    for questID, isCompleted in pairs(t) do
        if isCompleted then
            table.insert(completedQuests, questID)
        end
    end
    return completedQuests
end
