local private = CHDMP.private

local dumpFrame = nil

--------------------------------------------------
-- Playtime handling
--------------------------------------------------
local totalTimePlayed      = 0
local timePlayedThisLevel  = 0
local playerInfoReady      = false

local playtimeFrame = CreateFrame("Frame")
playtimeFrame:RegisterEvent("TIME_PLAYED_MSG")
playtimeFrame:SetScript("OnEvent", function(_, _, total, thisLevel)
    totalTimePlayed     = total or 0
    timePlayedThisLevel = thisLevel or 0
    playerInfoReady     = true
end)
-- Forward TradeSkill events to profession scanner
local tsFrame = CreateFrame("Frame")
tsFrame:RegisterEvent("TRADE_SKILL_SHOW")
tsFrame:RegisterEvent("TRADE_SKILL_UPDATE")
tsFrame:RegisterEvent("CRAFT_SHOW")
tsFrame:RegisterEvent("CRAFT_UPDATE")
tsFrame:RegisterEvent("UI_ERROR_MESSAGE")
tsFrame:RegisterEvent("ADDON_ACTION_BLOCKED")
tsFrame:RegisterEvent("MACRO_ACTION_BLOCKED")
tsFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
tsFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
tsFrame:SetScript("OnEvent", function(_, event, ...)
    if private and private.Professions_OnEvent then
        private.Professions_OnEvent(event, ...)
    end
end)

function private.GetPlayTime()
    if playerInfoReady then return totalTimePlayed end
    return 0
end

function private.GetPlayTimeThisLevel()
    if playerInfoReady then return timePlayedThisLevel end
    return 0
end

--------------------------------------------------
-- Save / Build dump
--------------------------------------------------
local function BuildDumpString()
    local json = private.JSONEncode(private.dmp)
    local inner = b64_enc(json)
    return b64_enc(inner) -- wenn du double willst
end

function private.SaveCharData(data, key)
    private.ILog("Chardump DONE: SavedVariables (per character)")
    CHDMP_DATA = data
    CHDMP_KEY  = key
    CHDMP_VER  = GetAddOnMetadata("chardump", "Version")
end

--------------------------------------------------
-- Status-Ausgabe (/chardump status)
--------------------------------------------------
function private.Status()
    local name      = UnitName("player") or "Unknown"
    local realm     = GetRealmName() or "Unknown"
    local _, class  = UnitClass("player")
    local level     = UnitLevel("player") or 0

    private.ILog(private.L("status_header", name, realm, level, class or "?"))

    local hasSessionDump = private.dmp and next(private.dmp) ~= nil
    if hasSessionDump then
        local qCount   = private.CountKeys(private.dmp.questscompleted)
        local invCount = private.dmp.inventory and private.CountKeys(private.dmp.inventory) or 0
        private.Log(private.L("session_dump_present", qCount, invCount))
    else
        private.Log(private.L("session_dump_none"))
    end

    local hasSaved = type(CHDMP_DATA) == "string" and type(CHDMP_KEY) == "string"
    if hasSaved then
        private.Log(private.L("savedvars_present", #CHDMP_DATA, #CHDMP_KEY, tostring(CHDMP_VER)))
    else
        private.Log(private.L("savedvars_missing"))
    end

    private.Log(private.L("savedvars_path_header", realm, name))
end

--------------------------------------------------
-- GUI: Hauptfenster mit Progressbar + Debug-Button
--------------------------------------------------
local function UpdateProgressUI(label)
    if not dumpFrame then return end
    if label then dumpFrame.statusText:SetText(label) end
    if private.totalSteps and private.totalSteps > 0 then
        local value = (private.currentStep / private.totalSteps) * 100
        dumpFrame.progress:SetValue(value)
    else
        dumpFrame.progress:SetValue(0)
    end
end

function private.CreateMainFrame()
    if dumpFrame then return end

    local f = CreateFrame("Frame", "CHDMP_MainFrame", UIParent)
    -- Größeres UI, damit sich Buttons nicht überlappen
    f:SetSize(520, 240)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText(private.L("title_main"))

    local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOP", title, "BOTTOM", 0, -10)
    text:SetText(private.L("prompt_dump"))

    local statusText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("TOP", text, "BOTTOM", 0, -10)
    statusText:SetText(private.L("ready"))

    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetSize(360, 18)
    bar:SetPoint("TOP", statusText, "BOTTOM", 0, -10)
    bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)

    local barBG = bar:CreateTexture(nil, "BACKGROUND")
    barBG:SetAllPoints(true)
    barBG:SetTexture(0, 0, 0, 0.5)

    local profStatus = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    -- Positioniere Status/Button sicher über den Bottom-Buttons
    profStatus:SetText("")
    profStatus:Hide()

    -- Make this a secure button so we can assign spells for profession opening
    local profButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate,SecureActionButtonTemplate")
    profButton:SetSize(260, 24)
    profButton:SetText(private.L("open_profession"))
    profButton:Hide()
    if profButton.RegisterForClicks then
        profButton:RegisterForClicks("AnyUp")
    end
    -- Button sicher nach vorne holen
    pcall(function()
        profButton:SetFrameLevel((f:GetFrameLevel() or 0) + 10)
    end)
    profButton:EnableMouse(true)
    profButton:SetAlpha(1)

    -- Sichere, feste Verankerung: knapp über den unteren Ja/Nein-Buttons
    profButton:ClearAllPoints()
    profButton:SetPoint("BOTTOM", f, "BOTTOM", 0, 48)
    profStatus:ClearAllPoints()
    profStatus:SetPoint("BOTTOM", profButton, "TOP", 0, 6)

    local dbg = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    dbg:SetSize(80, 22)
    dbg:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 15)
    dbg:SetText(private.L("debug"))
    dbg:SetScript("OnClick", function() private.Status() end)

    local yes = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    yes:SetSize(80, 22)
    yes:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -5, 15)
    yes:SetText(private.L("yes"))

    local no = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    no:SetSize(80, 22)
    no:SetPoint("LEFT", yes, "RIGHT", 10, 0)
    no:SetText(private.L("no"))
    no:SetScript("OnClick", function() f:Hide() end)

    f.title        = title
    f.text         = text
    f.statusText   = statusText
    f.progress     = bar
    f.profStatus   = profStatus
    f.profButton   = profButton
    f.yesButton    = yes
    f.noButton     = no
    f.debugButton  = dbg

    dumpFrame = f
end

function private.UpdateProfessionScanUI(opts)
    if not dumpFrame then
        return
    end

    opts = opts or {}
    if opts.status then
        dumpFrame.profStatus:SetText(opts.status)
        dumpFrame.profStatus:Show()
    else
        dumpFrame.profStatus:SetText("")
        dumpFrame.profStatus:Hide()
    end

    -- Button nur anfassen, wenn explizit Button-Parameter übergeben werden
    local wantsButtonUpdate = (opts.buttonLabel ~= nil) or (opts.secureSpellName ~= nil) or (opts.hideButton == true) or (opts.disabled ~= nil) or (opts.onClick ~= nil)
    if wantsButtonUpdate and opts.hideButton == true then
        dumpFrame.profButton:SetScript("OnClick", nil)
        if not InCombatLockdown or not InCombatLockdown() then
            dumpFrame.profButton:SetAttribute("type", nil)
            dumpFrame.profButton:SetAttribute("spell", nil)
        end
        dumpFrame.profButton:Hide()
        dumpFrame:Show()
        return
    end

    if wantsButtonUpdate and opts.buttonLabel then
        dumpFrame.profButton:SetText(opts.buttonLabel)
        -- Optional normal OnClick handler (rarely needed when we use secure spell casting)
        local clickHandler = opts.onClick
        if not clickHandler and opts.secureSpellName and type(opts.secureSpellName) == "string" and opts.secureSpellName ~= "" then
            clickHandler = function()
                if not InCombatLockdown or not InCombatLockdown() then
                    if CastSpellByName then pcall(CastSpellByName, opts.secureSpellName) end
                end
            end
        end
        dumpFrame.profButton:SetScript("OnClick", clickHandler)

        -- If a secure spell name is provided, arm the button to cast/open that spell
        if opts.secureSpellName and type(opts.secureSpellName) == "string" and opts.secureSpellName ~= "" then
            if not InCombatLockdown or not InCombatLockdown() then
                dumpFrame.profButton:SetAttribute("type", "spell")
                dumpFrame.profButton:SetAttribute("spell", opts.secureSpellName)
            end
        elseif opts.secureSpellName ~= nil then -- explizit leeren, wenn übergeben
            if not InCombatLockdown or not InCombatLockdown() then
                dumpFrame.profButton:SetAttribute("type", nil)
                dumpFrame.profButton:SetAttribute("spell", nil)
            end
        end
        if opts.disabled then
            dumpFrame.profButton:Disable()
        else
            dumpFrame.profButton:Enable()
        end
        dumpFrame.profButton:Show()
        dumpFrame:Show()
    end
end

--------------------------------------------------
-- Step-Logik
--------------------------------------------------
private.steps = {}
private.currentStep = 0
private.totalSteps = 0
private.cancelRequested = false
private.prepareStart = nil

local professionSpellIdsList = {
    2259,  -- Alchemy
    2018,  -- Blacksmithing
    7411,  -- Enchanting
    4036,  -- Engineering
    2366,  -- Herbalism
    45357, -- Inscription
    25229, -- Jewelcrafting
    2108,  -- Leatherworking
    8613,  -- Skinning
    3908,  -- Tailoring
    45542, -- First Aid

}

-- State for profession warmup
private._prepState = private._prepState or nil

local function Step_Prepare()
    local now = GetTime() or 0

    -- Init once
    if not private._prepState then
        private._prepState = {
            phase = "prof",      -- "prof" -> "waitserver"
            idx = 1,
            waitUntil = 0,
        }

        if QueryQuestsCompleted then pcall(QueryQuestsCompleted) end
        if not playerInfoReady then pcall(RequestTimePlayed) end

        private.prepareStart = now
        UpdateProgressUI(private.L("prep_open_prof_windows"))
        return false
    end

    local S = private._prepState

    -- Phase 1: open profession windows one by one
    if S.phase == "prof" then
        -- still waiting between casts
        if now < (S.waitUntil or 0) then
            return false
        end

        -- finished all spells -> go to server wait phase
        local profList = private.professionSpellIdsList or {}
        if S.idx > #profList then
            S.phase = "waitserver"
            private.prepareStart = now
            UpdateProgressUI(private.L("prep_wait_server"))
            return false
        end

        -- Intentionally do not check or open profession spells here.
        -- All profession opening is handled exclusively by the scanner in collect_professions.lua.
        -- Just advance through the list immediately.
        S.idx = S.idx + 1

        return false
    end

    -- Phase 2: keep your old "wait on server data" logic
    if S.phase == "waitserver" then
        local elapsed = now - (private.prepareStart or now)
        if elapsed > 3 and (playerInfoReady or elapsed > 5) then
            private._prepState = nil
            return true
        end
        return false
    end

    -- fallback
    private._prepState = nil
    return true
end


-- Step: Profession scan using state-machine from collect_professions.lua
local _profScanStarted = false
local function Step_ProfessionsScan()
    if not _profScanStarted then
        _profScanStarted = true
        if private.Professions_BeginScan then
            private.Professions_BeginScan({ timeout = 6.0, settle = 0.25 })
        end
        return false
    end

    if private.Professions_Tick then
        local done = private.Professions_Tick()
        return done == true
    end

    -- If functions are missing, consider it done to not block the dump
    return true
end


local function safeCallStore(field, func)
    if type(func) ~= "function" then
        private.ErrLog("Missing step function for field '" .. tostring(field) .. "'")
        private.dmp[field] = {}
        return true
    end
    private.dmp[field] = private.trycall(func, private.ErrLog) or {}
    return true
end

local function Step_SaveFinal()
    local fullDump = BuildDumpString()

    local data = string.sub(fullDump, 1, -65)
    local key  = string.sub(fullDump, -64)

    private.SaveCharData(data, key)
    UpdateProgressUI(private.L("save_progress_done"))

    local name  = UnitName("player") or "<Char>"
    local realm = GetRealmName() or "<Realm>"
    private.Log(private.L("save_dump_saved"))
    private.Log(private.L("save_path_line", realm, name))
    private.Log(private.L("save_reload_hint"))

    if dumpFrame then
        dumpFrame.yesButton:Hide()
        dumpFrame.noButton:SetText(private.L("close"))
        dumpFrame.noButton:SetScript("OnClick", function() dumpFrame:Hide() end)
    end
    return true
end

function private.BuildSteps()
    private.steps = {
        { label = private.L("step_prepare"),          func = Step_Prepare },
        { label = private.L("step_prof_scan"),        func = Step_ProfessionsScan },
        { label = private.L("step_player_stats"),     func = function() return safeCallStore("unitstats",   private.GetPlayerStats) end },
        { label = private.L("step_client_realm"),     func = function() return safeCallStore("globalinfo",  private.GetGlobalInfo) end },
        { label = private.L("step_char_info"),        func = function() return safeCallStore("unitinfo",    private.GetUnitInfo) end },
        { label = private.L("step_position"),         func = function() return safeCallStore("position",    private.GetPositionInfo) end },
        { label = private.L("step_reputations"),      func = function() return safeCallStore("reputation",  private.GetRepData) end },
        { label = private.L("step_weapon_skills"),    func = function() return safeCallStore("skillnames",  private.GetWeaponSkillNames) end },
        { label = private.L("step_achievements"),     func = function() return safeCallStore("achiev",      private.GetAchievementCategoryData) end },
        { label = private.L("step_glyphs"),           func = function() return safeCallStore("glyphs",      private.GetGlyphData) end },
        { label = private.L("step_mounts_pets"),      func = function() return safeCallStore("creature",    private.GetMountsAndCritters) end },
        { label = private.L("step_spells"),           func = function() return safeCallStore("spells",      private.GetSpellData) end },
        { label = private.L("step_talents"),          func = function() return safeCallStore("talents",     private.GetTalentTree) end },
        { label = private.L("step_skills_profs"),     func = function() return safeCallStore("skills",      private.GetSkillData) end },
        { label = private.L("step_inventory"),        func = function() return safeCallStore("inventory",   private.GetIData) end },
        { label = private.L("step_bank"),             func = function() return private.Step_BankScan() end },
        { label = private.L("step_statistics"),       func = function() return safeCallStore("statistic",   private.DumpPlayerStatistic) end },
        { label = private.L("step_currencies"),       func = function() return safeCallStore("currency",    private.GetCurrencyData) end },
        { label = private.L("step_quests_completed"), func = function() return safeCallStore("questscompleted", private.GetQuestCompletedData) end },
        { label = private.L("step_macros"),           func = function() return safeCallStore("macros",      private.GetMacroData) end },
        { label = private.L("step_actionbars"),       func = function() return private.Step_ActionBars() end },
        { label = private.L("step_keybindings"),      func = function() return safeCallStore("keybindings", private.GetChangedBindings) end },
        { label = private.L("step_save"),             func = Step_SaveFinal },
    }

    private.currentStep     = 0
    private.totalSteps      = #private.steps
    private.cancelRequested = false
    private.prepareStart    = nil
end

function private.OnUpdateDump(self, elapsed)
    if private.cancelRequested then
        UpdateProgressUI(private.L("dump_canceled"))
        self:SetScript("OnUpdate", nil)
        if dumpFrame then
            dumpFrame.yesButton:Enable()
            dumpFrame.noButton:SetText(private.L("close"))
            dumpFrame.noButton:SetScript("OnClick", function() dumpFrame:Hide() end)
        end
        return
    end

    local stepInfo = private.steps[private.currentStep + 1]
    if not stepInfo then
        self:SetScript("OnUpdate", nil)
        return
    end

    local label = stepInfo.label or (private.L("step_generic", (private.currentStep + 1)))
    local done = stepInfo.func()

    UpdateProgressUI(label)

    if done then
        private.currentStep = private.currentStep + 1
        if private.currentStep >= private.totalSteps then
            UpdateProgressUI(private.L("dump_finished"))
            self:SetScript("OnUpdate", nil)
        end
    end
end

function private.StartDumpProcess()
    private.dmp = {}
    private.BuildSteps()

    if not dumpFrame then private.CreateMainFrame() end

    dumpFrame.yesButton:Disable()
    dumpFrame.noButton:SetText(private.L("cancel"))
    dumpFrame.noButton:SetScript("OnClick", function()
        private.cancelRequested = true
    end)

    dumpFrame.progress:SetValue(0)
    dumpFrame.statusText:SetText(private.L("start_dump"))
    if dumpFrame.profStatus then dumpFrame.profStatus:Hide() end
    if dumpFrame.profButton then dumpFrame.profButton:Hide() end
    dumpFrame:Show()

    dumpFrame:SetScript("OnUpdate", private.OnUpdateDump)
end

--------------------------------------------------
-- Slash command /chardump
--------------------------------------------------
SLASH_CHDMP1 = "/chardump"
SlashCmdList["CHDMP"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$") or ""

    if msg == "done" then
        private.done = true
        return
    elseif msg == "help" then
        private.Log(private.L("usage"))
        private.Log(private.L("cmd_main"))
        private.Log(private.L("cmd_status"))
        return
    elseif msg == "status" then
        private.Status()
        return
    end

    private.CreateMainFrame()
    dumpFrame.yesButton:Enable()
    dumpFrame.noButton:SetText(private.L("no"))
    dumpFrame.noButton:SetScript("OnClick", function() dumpFrame:Hide() end)
    dumpFrame.progress:SetValue(0)
    dumpFrame.statusText:SetText(private.L("ready"))
    if dumpFrame.profStatus then dumpFrame.profStatus:Hide() end
    if dumpFrame.profButton then dumpFrame.profButton:Hide() end
    dumpFrame:Show()

    dumpFrame.yesButton:SetScript("OnClick", function()
        private.StartDumpProcess()
    end)
end
