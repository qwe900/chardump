local private = CHDMP.private

local professionSpellIdsList = {
    2259, 2018, 7411, 4036, 2366, 45357, 25229, 2108, 8613, 3908, 45542, 65293, 51296, 762,
}

function private.GetWeaponSkillNames()
    local out = {}
    if not GetAchievementNumCriteria or not GetAchievementCriteriaInfo then return out end

    local numCriteria = GetAchievementNumCriteria(705) or 0
    for i = 1, numCriteria do
        local criteriaString, _, completed, quantity, requiredQuantity, characterName, flags, assetID,
        quantityString, criteriaID, eligible =
        GetAchievementCriteriaInfo(705, i)

        out[i] = {
            criteriaString = criteriaString,
            completed = completed,
            quantity = quantity,
            requiredQuantity = requiredQuantity,
            characterName = characterName,
            flags = flags,
            assetID = assetID,
            quantityString = quantityString,
            criteriaID = criteriaID,
            eligible = eligible,
        }
    end
    return out
end

function private.GetSkillData()
    local ret = {}
    if not GetNumSkillLines or not GetSkillLineInfo then return ret end

    local weapon = private.GetWeaponSkillNames()

    local professionSpellIds = {}
    for _, spellId in ipairs(professionSpellIdsList) do
        professionSpellIds[spellId] = GetSpellInfo(spellId)
    end
    if GetLocale() == "deDE" then
        professionSpellIds[356] = GetSpellInfo(7620) -- german fishing oddity, optional
    end

    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, _, skillRank, _, _, skillMaxRank = GetSkillLineInfo(i)
        if skillName and not isHeader then
            ret[i] = { N = skillName, C = skillRank or 0, M = skillMaxRank or 0 }

            for _, a in pairs(weapon) do
                if a.criteriaString == skillName then
                    ret[i]["Skill"] = a.assetID
                    break
                end
            end

            for spellId, pname in pairs(professionSpellIds) do
                if pname and pname == skillName then
                    ret[i]["S"] = spellId
                    break
                end
            end
        end
    end

    return ret
end
