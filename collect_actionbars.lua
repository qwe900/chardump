local private = CHDMP.private

-- Event listener once
private._abEvent = private._abEvent or CreateFrame("Frame")
private._abEvent:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
private._abEvent:SetScript("OnEvent", function()
    if private._abStep then private._abStep.changed = true end
end)

local function MapActionTypeToCode(kind)
    if kind == "spell" then return 0 end
    if kind == "click" then return 1 end
    if kind == "equipmentset" then return 32 end
    if kind == "macro" then return 64 end
    if kind == "item" then return 128 end
    return nil
end

local function ResolveEquipmentSetId(name)
    if type(name) ~= "string" or name == "" then return 0 end
    if _G.GetEquipmentSetInfoByName then
        local _, _, setId = GetEquipmentSetInfoByName(name)
        if type(setId) == "number" then return setId end
    end
    return 0
end

function private.GetActionBarData()
    local entries = {}

    local specIndex = 0
    if _G.GetActiveTalentGroup then
        local ok, grp = pcall(GetActiveTalentGroup)
        if ok and type(grp) == "number" then specIndex = math.max(0, grp - 1) end
    end

    for slot = 1, 120 do
        local kind, id = GetActionInfo(slot)
        if kind then
            local tcode = MapActionTypeToCode(kind)
            local actionId = 0

            if tcode == 32 then
                actionId = ResolveEquipmentSetId(id)
            elseif tcode == 64 then
                actionId = tonumber(id) or 0
                if _G.GetMacroInfo and actionId > 0 then
                    local _, _, body = GetMacroInfo(actionId)
                    if type(body) == "string" and body:lower():find("/click", 1, true) then
                        tcode = 65
                    end
                end
            elseif tcode then
                actionId = tonumber(id) or 0
            end

            if tcode and actionId then
                table.insert(entries, { spec = specIndex, button = slot, action = actionId, type = tcode })
            end
        end
    end

    private.ILog(CHDMP.L("actionbars_done", #entries))
    return entries
end

-- popup result
private.actionbarsBothRequested = nil

local function CanDualSpecSwitch()
    if InCombatLockdown and InCombatLockdown() then return false, "Im Kampf" end
    if _G.GetNumTalentGroups and (GetNumTalentGroups() or 0) >= 2 then return true end
    return false, "Keine Dual-Spezialisierung"
end

local function ShowBothSpecPopup()
    if not StaticPopupDialogs then return false end
    if not StaticPopupDialogs["CHDMP_BOTH_SPECS"] then
        StaticPopupDialogs["CHDMP_BOTH_SPECS"] = {
            text = "Um die Actionbars beider Talentbäume zu speichern, muss kurz die zweite Spezialisierung aktiviert werden. Jetzt wechseln?",
            button1 = ACCEPT,
            button2 = CANCEL,
            OnAccept = function() private.actionbarsBothRequested = true end,
            OnCancel = function() private.actionbarsBothRequested = false end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    StaticPopup_Show("CHDMP_BOTH_SPECS")
    return true
end

local function WaitForTalentGroup(targetGroup, startTime, timeout)
    timeout = timeout or 5.0
    local now = GetTime() or 0
    local active = (_G.GetActiveTalentGroup and GetActiveTalentGroup()) or 1

    if active == targetGroup and private._abStep and private._abStep.changed then
        if (now - (startTime or now)) > 0.3 then
            return true
        end
    end

    if (now - (startTime or now)) > timeout then
        return true, "timeout"
    end

    return false
end

private._abStep = nil

function private.Step_ActionBars()
    local hasDual = CanDualSpecSwitch()

    if not private._abStep then private._abStep = { phase = "init" } end
    local S = private._abStep

    if S.phase == "init" then
        if hasDual then
            private.actionbarsBothRequested = nil
            ShowBothSpecPopup()
            S.phase = "ask"
            return false
        else
            private.dmp["actionbars"] = private.GetActionBarData() or {}
            private._abStep = nil
            return true
        end
    end

    if S.phase == "ask" then
        if private.actionbarsBothRequested == nil then return false end
        if private.actionbarsBothRequested ~= true then
            private.dmp["actionbars"] = private.GetActionBarData() or {}
            private._abStep = nil
            return true
        end

        S.collect = {}
        S.orig = (_G.GetActiveTalentGroup and GetActiveTalentGroup()) or 1
        S.other = (S.orig == 1) and 2 or 1
        S.phase = "collect1"
        return false
    end

    if S.phase == "collect1" then
        S.collect["spec" .. tostring(S.orig-1)] = private.GetActionBarData() or {}

        if _G.SetActiveTalentGroup then
            S.changed = false
            pcall(SetActiveTalentGroup, S.other)
            S.switchStart = GetTime() or 0
            S.phase = "waitswitch1"
            return false
        end

        private.dmp["actionbars"] = S.collect["spec" .. tostring(S.orig-1)]
        private._abStep = nil
        return true
    end

    if S.phase == "waitswitch1" then
        local ok, why = WaitForTalentGroup(S.other, S.switchStart, 6.0)
        if ok then
            if why == "timeout" then private.ErrLog("Spec switch timeout (to other). Capturing anyway.") end
            S.phase = "collect2"
        end
        return false
    end

    if S.phase == "collect2" then
        S.collect["spec" .. tostring(S.other-1)] = private.GetActionBarData() or {}

        if _G.SetActiveTalentGroup then
            S.changed = false
            pcall(SetActiveTalentGroup, S.orig)
            S.switchStart = GetTime() or 0
            S.phase = "waitswitchback"
            return false
        end

        S.phase = "finish"
        return false
    end

    if S.phase == "waitswitchback" then
        local ok, why = WaitForTalentGroup(S.orig, S.switchStart, 6.0)
        if ok then
            if why == "timeout" then private.ErrLog("Spec switch timeout (back). Finishing anyway.") end
            S.phase = "finish"
        end
        return false
    end

    if S.phase == "finish" then
        local merged = {}
        local a = S.collect["spec0"] or {}
        local b = S.collect["spec1"] or {}
        for i = 1, #a do merged[#merged+1] = a[i] end
        for i = 1, #b do merged[#merged+1] = b[i] end

        private.dmp["actionbars"] = merged
        private._abStep = nil
        private.ILog(CHDMP.L("actionbars_both_done", #merged))
        return true
    end

    -- fallback
    private.dmp["actionbars"] = private.GetActionBarData() or {}
    private._abStep = nil
    return true
end
