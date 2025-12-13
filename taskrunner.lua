CHDMP = CHDMP or {}
CHDMP.private = CHDMP.private or {}
local private = CHDMP.private

private.TaskRunner = private.TaskRunner or {}
local R = private.TaskRunner

R.queue = {}
R.current = nil

R.frame = R.frame or CreateFrame("Frame")
-- OnUpdate drives the active task's update loop
R.frame:SetScript("OnUpdate", function(_, elapsed)
    if not R.current then
        R.current = table.remove(R.queue, 1)
        if R.current and R.current.start then
            R.current.start()
        end
        if not R.current then return end
    end

    if R.current.update then
        local done, err = R.current.update(elapsed)
        if done then
            if R.current.finish then R.current.finish(err) end
            R.current = nil
        end
    else
        if R.current.finish then R.current.finish() end
        R.current = nil
    end
end)

function R:Push(task)
    self.queue[#self.queue + 1] = task
end

function R:OnEvent(event, ...)
    if self.current and self.current.onEvent then
        self.current.onEvent(event, ...)
    end
    -- Forward to professions scanner if present (central event hub)
    if CHDMP and CHDMP.private and CHDMP.private.Professions_OnEvent then
        CHDMP.private.Professions_OnEvent(event, ...)
    end
end

-- Register relevant events and forward them through OnEvent
R.frame:RegisterEvent("TRADE_SKILL_SHOW")
R.frame:RegisterEvent("TRADE_SKILL_UPDATE")
R.frame:RegisterEvent("CRAFT_SHOW")
R.frame:RegisterEvent("CRAFT_UPDATE")
R.frame:RegisterEvent("UI_ERROR_MESSAGE")
R.frame:RegisterEvent("ADDON_ACTION_BLOCKED")
R.frame:RegisterEvent("MACRO_ACTION_BLOCKED")
R.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
R.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
R.frame:SetScript("OnEvent", function(_, event, ...)
    R:OnEvent(event, ...)
end)
