local private = CHDMP.private

function private.GetTalentTree()
    local talentData = {}
    if not GetNumTalentGroups or not GetNumTalentTabs then return talentData end

    for specIndex = 1, GetNumTalentGroups() do
        talentData[specIndex] = {}

        for tabIndex = 1, GetNumTalentTabs() do
            local tabName, tabTexture = GetTalentTabInfo(tabIndex, false, false, specIndex)

            local tabEntry = {
                name = tabName,
                icon = tabTexture and tabTexture:match("Interface\\Icons\\(.+)"),
                talents = {},
            }

            for talentIndex = 1, GetNumTalents(tabIndex) do
                local name, icon, _, _, currentRank, maxRank =
                GetTalentInfo(tabIndex, talentIndex, false, false, specIndex)

                local talentLink = GetTalentLink(tabIndex, talentIndex)
                local talentID = talentLink and tonumber(talentLink:match("talent:(%d+)"))

                tabEntry.talents[talentIndex] = {
                    name = name,
                    icon = icon and icon:match("Interface\\Icons\\(.+)"),
                    currentRank = currentRank or 0,
                    maxRank = maxRank or 0,
                    tab = tabIndex,
                    talent = talentIndex,
                    talentID = talentID or 0,
                }
            end

            talentData[specIndex][tabIndex] = tabEntry
        end
    end

    return talentData
end
