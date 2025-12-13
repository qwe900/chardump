-- collect_professions.lua (WotLK 3.3.5) - SECURE Wizard Scanner
CHDMP = CHDMP or {}
CHDMP.private = CHDMP.private or {}
local private = CHDMP.private

--------------------------------------------------
-- Profession SpellIDs (WotLK)
-- (ordered array of SpellIDs; resolve names at runtime via GetSpellInfo)
--------------------------------------------------
private.professionSpellIdsList = private.professionSpellIdsList or {
	51304,
	51300,
	51296,
	51313,
	51306,
	45542,
	51302,
	32606,
	51309,
	51311,
	45363,

}

--------------------------------------------------
-- Helpers: learned? list recipes
--------------------------------------------------
local function IsKnownSpell(spellId)
    -- WotLK fallback: IsSpellKnown may not exist on some cores/clients
    if IsSpellKnown then
        return IsSpellKnown(spellId)
    end
    local name = GetSpellInfo(spellId)
    if not name or name == "" then return false end
    local i = 1
    while true do
        local spellName = GetSpellName(i, BOOKTYPE_SPELL)
        if not spellName then break end
        if spellName == name then return true end
        i = i + 1
    end
    return false
end

local function CollectCurrentTradeSkillRecipes()
    local recipes = {}
    if not GetNumTradeSkills or not GetTradeSkillRecipeLink then
        return recipes
    end

    local num = GetNumTradeSkills() or 0
    for i = 1, num do
        local link = GetTradeSkillRecipeLink(i)
        if link then
            local sid = tonumber(link:match("enchant:(%d+)"))
            if sid then
                recipes[sid] = 1
            end
        end
    end
    return recipes
end

local function CollectCurrentCraftRecipes()
    local recipes = {}
    if not GetNumCrafts then return recipes end

    local num = GetNumCrafts() or 0
    for i = 1, num do
        local link
        if GetCraftRecipeLink then link = GetCraftRecipeLink(i) end
        if not link and GetCraftItemLink then link = GetCraftItemLink(i) end
        if type(link) == "string" then
            local sid = tonumber(link:match("enchant:(%d+)"))
            if sid then
                recipes[sid] = 1
            end
        end
    end
    return recipes
end

--------------------------------------------------
-- Spezialisierungen ermitteln (z. B. Gnom/Goblin‑Ing.)
--------------------------------------------------
local function CollectKnownSpecializations()
    -- Mapping: Basis‑Beruf (WotLK 513xx) -> Liste möglicher Spezialisierungs‑SpellIDs
    -- Hinweis: Wir prüfen per IsKnownSpell(sid) und speichern genau EINE gefundene Spezialisierung (SpellID) pro Basis‑Beruf.
    local SPEC_BY_PROF = {
        [51304] = { -- Alchemy (Grand Master)
            28674, -- Alchemy: Elixir Master
            28678, -- Alchemy: Transmutation Master
            28676, -- Alchemy: Potion Master
        },
        [51300] = { -- Blacksmithing (Grand Master)
            9788,  -- Armorsmith
            17041, -- Master Axesmith
            17040, -- Master Hammersmith
            17039, -- Master Swordsmith
            9787,  -- Weaponsmith
        },
        [51306] = { -- Engineering (Grand Master)
            20219, -- Gnomish Engineering
            20222, -- Goblin Engineering
        },
        [51302] = { -- Leatherworking (Grand Master)
            10657, -- Dragonscale Leatherworking
            10659, -- Elemental Leatherworking
            10661, -- Tribal Leatherworking
        },
        [51309] = { -- Tailoring (Grand Master)
            26797, -- Spellfire Tailoring
            26801, -- Shadoweave Tailoring
            26798, -- Mooncloth Tailoring
        },
    }

    local known = {}
    for baseProfId, specList in pairs(SPEC_BY_PROF) do
        for _, sid in ipairs(specList) do
            if IsKnownSpell(sid) then
                known[baseProfId] = sid
                break
            end
        end
    end

    return known
end

--------------------------------------------------
-- UI-Integration: nutzt das Hauptfenster in core.lua
--------------------------------------------------
-- Platzhalter: keine eigenes Fenster mehr, nur Status/Button im Main-UI
local function EnsureProfessionScanUI()
    -- Sorge dafür, dass das Hauptfenster existiert
    if CHDMP and CHDMP.private and CHDMP.private.CreateMainFrame then
        pcall(CHDMP.private.CreateMainFrame)
    end
end

local function UpdateUIState(S)
    EnsureProfessionScanUI()
    local scannedCount = 0
    for _, p in ipairs(S.list) do
        if S.scanned[p.name] then scannedCount = scannedCount + 1 end
    end
    local status
    if S.nextIdx and S.list[S.nextIdx] then
        local nextName = S.list[S.nextIdx].name
        status = (CHDMP and CHDMP.L and CHDMP.L("prof_status_next", scannedCount, #S.list, nextName))
    else
        status = (CHDMP and CHDMP.L and CHDMP.L("prof_status_simple", scannedCount, #S.list))
    end
    if private.UpdateProfessionScanUI then
        private.UpdateProfessionScanUI({ status = status })
    end
end

local function FindNextUnscanned(S, startIdx)
    for i = startIdx or 1, #S.list do
        if not S.scanned[S.list[i].name] then
            return i
        end
    end
    return nil
end

local function SetNextButtonToSpell(spellName)
    EnsureProfessionScanUI()
    if private.UpdateProfessionScanUI then
        if not spellName then
            private.UpdateProfessionScanUI({ buttonLabel = nil, secureSpellName = nil })
            return
        end
        local label = (CHDMP and CHDMP.L and CHDMP.L("open_spell_prefix", spellName)) or ("Open: " .. tostring(spellName))
        private.UpdateProfessionScanUI({ buttonLabel = label, secureSpellName = spellName, disabled = false })
    end
end

--------------------------------------------------
-- Hook ShowUIPanel (fallback detection)
--------------------------------------------------
local function CHDMP_OnShowUIPanel(frame)
    local S = private._profScan
    if not S or not S.waiting then return end
    if not frame or not frame.GetName then return end
    local name = frame:GetName()
    if name == "TradeSkillFrame" or name == "CraftFrame" then
        S.gotTS = true
        S.gotTSAt = GetTime() or 0
        S.lastOpenSource = (name == "CraftFrame") and "CRAFT" or "TRADE"
    end
end

pcall(hooksecurefunc, _G, "ShowUIPanel", CHDMP_OnShowUIPanel)

--------------------------------------------------
-- Public: profession scan state-machine (no while)
--------------------------------------------------
private._profScan = private._profScan or nil

-- Start scan (builds wizard list + shows UI)
function private.Professions_BeginScan(opts)
    opts = opts or {}
    EnsureProfessionScanUI()

    local candidates = {}

    -- like your old code: prefer learned-only if possible
    if IsSpellKnown then
        for _, sid in ipairs(private.professionSpellIdsList) do
            if IsKnownSpell(sid) then
                table.insert(candidates, sid)
            end
        end
    end
    if #candidates == 0 then
        for _, sid in ipairs(private.professionSpellIdsList) do
            table.insert(candidates, sid)
        end
    end

    -- build pretty list entries (unique by name)
    local seen = {}
    local list = {}
    for _, sid in ipairs(candidates) do
        local n = GetSpellInfo(sid)
        if n and n ~= "" and not seen[n] then
            seen[n] = true
            table.insert(list, { spellId = sid, name = n })
        end
    end
    table.sort(list, function(a,b) return a.name < b.name end)

    private._profScan = {
        list = list,
        scanned = {},

        idx = 1,
        nextIdx = 1,

        timeout = tonumber(opts.timeout) or 8.0,
        settle  = tonumber(opts.settle) or 0.25,

        waiting = false,
        gotTS = false,
        gotTSAt = 0,
        lastOpenSource = "TRADE",

        currentSpellId = 0,
        currentName = nil,

        result = {
            professions = {}, -- key by spellId
            order = {},       -- spellIds in scan order
        },

        scannedCount = 0,
        totalRecipes = 0,
    }

    local S = private._profScan
    S.nextIdx = FindNextUnscanned(S, 1)

    UpdateUIState(S)

    if not S.nextIdx then
        SetNextButtonToSpell(nil)
        private.ILog("Berufsscan: keine Berufe gefunden.")
        return
    end

    -- prime button for first profession
    SetNextButtonToSpell(S.list[S.nextIdx].name)
end

-- Feed events here (call from your event hub)
function private.Professions_OnEvent(event, ...)
    local S = private._profScan
    if not S then return end

    if event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE" then
        S.gotTS = true
        S.gotTSAt = GetTime() or 0
        S.lastOpenSource = "TRADE"
        return
    end
    if event == "CRAFT_SHOW" or event == "CRAFT_UPDATE" then
        S.gotTS = true
        S.gotTSAt = GetTime() or 0
        S.lastOpenSource = "CRAFT"
        return
    end
end

-- Tick: call repeatedly until returns true (done)
function private.Professions_Tick()
    local S = private._profScan
    if not S then return true end

    local now = GetTime() or 0

    -- done?
    if not S.nextIdx then
        private.dmp = private.dmp or {}
        -- Spezialisierungen ergänzen (SpellID je Basis‑Beruf 513xx)
        S.result = S.result or {}
        S.result.specialization = CollectKnownSpecializations()
        -- Spezialisierung zusätzlich direkt beim jeweiligen Basis‑Beruf ablegen
        do
            local spec = S.result.specialization or {}
            for baseId, sid in pairs(spec) do
                if S.result.professions and S.result.professions[baseId] then
                    S.result.professions[baseId].specId = sid
                end
            end
        end
        private.dmp.professions = S.result

        private.ILog("Berufsscan fertig: " .. tostring(S.scannedCount or 0) .. " Berufe, " .. tostring(S.totalRecipes or 0) .. " Rezepte gesamt")

        -- Update main UI one last time and hide the spell button
        UpdateUIState(S)
        if private.UpdateProfessionScanUI then
            private.UpdateProfessionScanUI({ buttonLabel = nil, secureSpellName = nil })
        end

        private._profScan = nil
        return true
    end

    -- currently waiting for TS/Craft to actually open
    if S.waiting then
        -- got TS signal?
        if S.gotTS then
            if (now - (S.gotTSAt or now)) < (S.settle or 0) then
                return false
            end

            -- determine opened profession name from trade line if possible
            local tradeName = nil
            if GetTradeSkillLine then
                tradeName = GetTradeSkillLine()
            end
            tradeName = (tradeName and tradeName ~= "" and tradeName ~= "UNKNOWN") and tradeName or S.currentName

            -- collect recipes
            local rec
            if S.lastOpenSource == "CRAFT" then
                rec = CollectCurrentCraftRecipes()
            else
                rec = CollectCurrentTradeSkillRecipes()
            end

            -- store result
            S.result.professions[S.currentSpellId] = {
                name = tradeName or (S.currentName or ""),
                recipes = rec,
            }
            table.insert(S.result.order, S.currentSpellId)

            -- mark scanned by tradeName AND by currentName (covers server-localized strings)
            if tradeName then S.scanned[tradeName] = true end
            if S.currentName then S.scanned[S.currentName] = true end

            -- accounting
            S.scannedCount = (S.scannedCount or 0) + 1
            do
                local c = 0; for _ in pairs(rec) do c = c + 1 end
                S.totalRecipes = (S.totalRecipes or 0) + c
            end

            -- advance to next
            S.waiting = false
            S.gotTS = false
            S.currentSpellId = 0
            S.currentName = nil

            S.nextIdx = FindNextUnscanned(S, (S.nextIdx or 1) + 1)
            -- Hide current button before switching to next
            if private.UpdateProfessionScanUI then
                private.UpdateProfessionScanUI({ buttonLabel = nil, secureSpellName = nil, hideButton = true })
            end
            UpdateUIState(S)

            if S.nextIdx and S.list[S.nextIdx] then
                SetNextButtonToSpell(S.list[S.nextIdx].name)
            else
                SetNextButtonToSpell(nil)
            end

            return false
        end

        -- timeout
        if now >= (S.waitUntil or 0) then
            private.ErrLog("Profession scan timeout (no TS/Craft show)")

            -- store empty mark, still advance
            S.result.professions[S.currentSpellId] = {
                name = S.currentName or (GetSpellInfo(S.currentSpellId) or ""),
                recipes = {},
            }
            table.insert(S.result.order, S.currentSpellId)

            if S.currentName then S.scanned[S.currentName] = true end

            S.waiting = false
            S.gotTS = false
            S.currentSpellId = 0
            S.currentName = nil

            S.scannedCount = (S.scannedCount or 0) + 1

            S.nextIdx = FindNextUnscanned(S, (S.nextIdx or 1) + 1)
            -- Hide current button before switching to next (timeout path)
            if private.UpdateProfessionScanUI then
                private.UpdateProfessionScanUI({ buttonLabel = nil, secureSpellName = nil, hideButton = true })
            end
            UpdateUIState(S)

            if S.nextIdx and S.list[S.nextIdx] then
                SetNextButtonToSpell(S.list[S.nextIdx].name)
            else
                SetNextButtonToSpell(nil)
            end

            return false
        end

        return false
    end

    -- not waiting: we are idle, waiting for user to click the secure button
    -- We detect click indirectly: when click happens, the profession window opens and events/ShowUIPanel set gotTS.
    -- To start waiting for the current "next" profession we just arm the timer once (so timeout works).
    if (InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player")) then
        return false
    end

    -- arm waiting for the currently selected next profession (after button is visible)
    local p = S.list[S.nextIdx]
    if not p then
        S.nextIdx = nil
        SetNextButtonToSpell(nil)
        return false
    end

    -- if user clicked, TS events will come; we start waiting now so we can timeout
    S.currentSpellId = p.spellId
    S.currentName = p.name
    S.waiting = true
    S.gotTS = false
    S.waitUntil = now + (S.timeout or 8.0)

    -- Note: DO NOT advance index here; nextIdx advances after scan completes
    return false
end
