local private = CHDMP.private

function private.GetGlobalInfo()
    local ret = {}
    ret.locale     = GetLocale()
    ret.realm      = GetRealmName()
    ret.realmlist  = GetCVar("realmList")
    local _, build = GetBuildInfo()
    ret.clientbuild = build
    return ret
end

function private.GetPositionInfo()
    local ret = {}

    if _G.GetBindLocation then
        local ok, bind = pcall(GetBindLocation)
        if ok then ret.bindlocation = bind end
    end

    if _G.GetZoneText then ret.zone = GetZoneText() end
    if _G.GetSubZoneText then ret.subzone = GetSubZoneText() end

    local x, y = 0, 0
    if _G.SetMapToCurrentZone then pcall(SetMapToCurrentZone) end
    if _G.GetPlayerMapPosition then
        local px, py = GetPlayerMapPosition("player")
        if px and py then x, y = px, py end
    end

    ret.mapId = 0
    ret.x = x or 0
    ret.y = y or 0
    return ret
end

function private.GetPlayerStats()
    local stats = {}
    stats.health = UnitHealthMax("player") or 0

    stats.strength  = select(1, UnitStat("player", 1)) or 0
    stats.agility   = select(1, UnitStat("player", 2)) or 0
    stats.stamina   = select(1, UnitStat("player", 3)) or 0
    stats.intellect = select(1, UnitStat("player", 4)) or 0
    stats.spirit    = select(1, UnitStat("player", 5)) or 0
    return stats
end

function private.GetUnitInfo()
    local ret = {}
    ret.name = UnitName("player")
    local _, class = UnitClass("player")
    ret.class = class
    ret.level = UnitLevel("player") or 0
    local _, race = UnitRace("player")
    ret.race = race
    ret.gender = UnitSex("player") or 0

    local honorableKills = GetPVPLifetimeStats()
    ret.kills = honorableKills or 0

    ret.honor      = (GetHonorCurrency and GetHonorCurrency()) or 0
    ret.arenapoints = (GetArenaCurrency and GetArenaCurrency()) or 0
    ret.money      = GetMoney() or 0

    ret.specs      = (GetNumTalentGroups and GetNumTalentGroups()) or 1
    ret.playtime   = private.GetPlayTime()
    ret.playtimeonlevel = private.GetPlayTimeThisLevel()

    return ret
end
