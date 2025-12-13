CHDMP = CHDMP or {}
CHDMP.private = CHDMP.private or {}
local private = CHDMP.private

-- Simple localization with enUS defaults and deDE overrides
local enUS = {
    title_main = "Character Dumper",
    prompt_dump = "Dump this character now?",
    ready = "Ready.",
    open_profession = "Open Profession",
    debug = "Debug",
    yes = "Yes",
    no = "No",
    close = "Close",
    cancel = "Cancel",
    start_dump = "Starting dump...",
    usage = "Usage: /chardump [status|help]",
    cmd_main = "  /chardump         - opens GUI and starts dump after confirmation",
    cmd_status = "  /chardump status  - shows status/info for current/saved dump",
    open_spell_prefix = "Open: %s",

    -- Steps
    step_prepare = "Preparing (Professions / Quests / Playtime)",
    step_prof_scan = "Scanning profession recipes",
    step_player_stats = "Collecting player stats",
    step_client_realm = "Collecting client/realm info",
    step_char_info = "Collecting character info",
    step_position = "Collecting position/bind point",
    step_reputations = "Collecting reputations",
    step_weapon_skills = "Collecting skill names (weapons)",
    step_achievements = "Collecting achievements",
    step_glyphs = "Collecting glyphs",
    step_mounts_pets = "Collecting mounts & companions",
    step_spells = "Reading spellbook",
    step_talents = "Reading talent trees",
    step_skills_profs = "Collecting skills / professions",
    step_inventory = "Collecting inventory & bags",
    step_bank = "Scanning bank contents",
    step_statistics = "Collecting statistics",
    step_currencies = "Collecting currencies",
    step_quests_completed = "Collecting quest completions",
    step_macros = "Collecting macros",
    step_actionbars = "Collecting action bars",
    step_keybindings = "Collecting keybindings diffs",
    step_save = "Building & saving dump",
    step_generic = "Step %d",

    dump_canceled = "Dump canceled.",
    dump_finished = "Dump completed.",

    -- Prepare progress
    prep_open_prof_windows = "Opening profession windows (cache warmup)...",
    prep_wait_server = "Waiting for server data (Quests/Playtime)...",

    -- Professions collector status
    prof_status_next = "Professions: %d/%d scanned – Next: %s",
    prof_status_simple = "Professions: %d/%d scanned",

    -- Mounts & Critters log
    mounts_done = "Mounts & Companions done... (%d Mounts and %d Companions)",

    -- Save final/messages
    save_progress_done = "Done – dump saved.",
    save_dump_saved = "Dump saved. File can be found at:",
    save_path_line = "WTF\\Account\\<Account>\\%s\\%s\\SavedVariables\\chardump.lua",
    save_reload_hint = "To write the file to disk, please /reload or log out.",

    -- Status command
    status_header = "Status for %s-%s (Lv%d %s)",
    session_dump_present = "Session dump in memory: Quests=%d, Inventory entries=%d",
    session_dump_none = "Session dump in memory: none (use /chardump).",
    savedvars_present = "SavedVariables: DATA length=%d, KEY length=%d, VER=%s",
    savedvars_missing = "SavedVariables: no CHDMP_DATA / CHDMP_KEY found.",
    savedvars_path_header = "File path (per character): WTF\\Account\\<Account>\\%s\\%s\\SavedVariables\\chardump.lua",

    -- Bank
    bank_open_prompt = "Open your bank now and then click OK.",
    bank_scan_done = "Bank scan done (%d entries)...",

    -- Collector done messages
    spells_done = "Spells DONE... (%d entries)",
    reputations_done = "Reputations DONE (%d entries)",
    macros_done = "Macros DONE... (%d entries)",
    macros_done_skipped = "Macros DONE... (%d entries, skipped %d unsafe)",
    inventory_done = "Inventory DONE... (%d entries)",
    glyphs_done = "Glyphs DONE... (%d entries)",
    keybindings_done = "Keybindings DONE... (%d entries)",
    actionbars_done = "Action bars DONE... (%d entries)",
    actionbars_both_done = "Action bars (both specializations) DONE... (%d entries)",
}

local deDE = {
    title_main = "Character Dumper",
    prompt_dump = "Diesen Charakter jetzt dumpen?",
    ready = "Bereit.",
    open_profession = "Beruf öffnen",
    debug = "Debug",
    yes = "Ja",
    no = "Nein",
    close = "Schließen",
    cancel = "Abbrechen",
    start_dump = "Starte Dump...",
    usage = "Verwendung: /chardump [status|help]",
    cmd_main = "  /chardump         - öffnet GUI und startet Dump nach Bestätigung",
    cmd_status = "  /chardump status  - zeigt Status/Infos zum aktuellen/saved Dump",
    open_spell_prefix = "Öffne: %s",

    -- Steps
    step_prepare = "Vorbereitung (Berufe / Quests / Spielzeit)",
    step_prof_scan = "Berufsrezepte scannen",
    step_player_stats = "Spieler-Stats sammeln",
    step_client_realm = "Client/Realm-Infos sammeln",
    step_char_info = "Charakter-Infos sammeln",
    step_position = "Position/Bindepunkt sammeln",
    step_reputations = "Reputationen sammeln",
    step_weapon_skills = "Skillnamen (Waffen) sammeln",
    step_achievements = "Erfolge sammeln",
    step_glyphs = "Glyphen sammeln",
    step_mounts_pets = "Mounts & Begleiter sammeln",
    step_spells = "Zauberbuch auslesen",
    step_talents = "Talentbäume auslesen",
    step_skills_profs = "Skills / Berufe sammeln",
    step_inventory = "Inventar & Taschen sammeln",
    step_bank = "Bankinhalt scannen",
    step_statistics = "Statistiken sammeln",
    step_currencies = "Währungen sammeln",
    step_quests_completed = "Quest-Abschlüsse sammeln",
    step_macros = "Makros sammeln",
    step_actionbars = "Actionbars sammeln",
    step_keybindings = "Keybindings-Diffs sammeln",
    step_save = "Dump bauen & speichern",
    step_generic = "Schritt %d",

    dump_canceled = "Dump abgebrochen.",
    dump_finished = "Dump abgeschlossen.",
    
    -- Prepare progress
    prep_open_prof_windows = "Öffne Berufsfenster (Cache-Warmup)...",
    prep_wait_server = "Warte auf Serverdaten (Quests/Spielzeit)...",

    prof_status_next = "Berufe: %d/%d gescannt – Nächster: %s",
    prof_status_simple = "Berufe: %d/%d gescannt",

    mounts_done = "Mounts & Begleiter erledigt... (%d Mounts und %d Begleiter)",

    -- Save final/messages
    save_progress_done = "Fertig – Dump gespeichert.",
    save_dump_saved = "Dump gespeichert. Datei zu finden unter:",
    save_path_line = "WTF\\Account\\<Account>\\%s\\%s\\SavedVariables\\chardump.lua",
    save_reload_hint = "Zum endgültigen Schreiben der Datei bitte /reload ausführen oder ausloggen.",

    -- Status command
    status_header = "Status für %s-%s (Lv%d %s)",
    session_dump_present = "Session-Dump im Speicher: Quests=%d, Inventory-Einträge=%d",
    session_dump_none = "Session-Dump im Speicher: keiner (nutze /chardump).",
    savedvars_present = "SavedVariables: DATA-Länge=%d, KEY-Länge=%d, VER=%s",
    savedvars_missing = "SavedVariables: keine CHDMP_DATA / CHDMP_KEY gefunden.",
    savedvars_path_header = "Dateipfad (per Character): WTF\\Account\\<Account>\\%s\\%s\\SavedVariables\\chardump.lua",

    -- Bank
    bank_open_prompt = "Öffne jetzt deine Bank und klicke anschließend auf OK.",
    bank_scan_done = "Bank-Scan abgeschlossen (%d Einträge)...",

    -- Collector done messages
    spells_done = "Zauber erledigt... (%d Einträge)",
    reputations_done = "Reputationen erledigt (%d Einträge)",
    macros_done = "Makros erledigt... (%d Einträge)",
    macros_done_skipped = "Makros erledigt... (%d Einträge, %d unsichere übersprungen)",
    inventory_done = "Inventar erledigt... (%d Einträge)",
    glyphs_done = "Glyphen erledigt... (%d Einträge)",
    keybindings_done = "Tastenbelegungen erledigt... (%d Einträge)",
    actionbars_done = "Aktionsleisten erledigt... (%d Einträge)",
    actionbars_both_done = "Aktionsleisten (beide Spezialisierungen) erledigt... (%d Einträge)",
}

local function makeLocale()
    local loc = enUS
    local cur = (type(GetLocale) == "function" and GetLocale()) or "enUS"
    if cur == "deDE" then
        setmetatable(deDE, { __index = enUS })
        loc = deDE
    else
        setmetatable(enUS, { __index = enUS })
    end
    return loc
end

CHDMP._L = makeLocale()

function CHDMP.L(key, ...)
    local s = (CHDMP._L and CHDMP._L[key]) or key
    if select('#', ...) > 0 then
        local ok, out = pcall(string.format, s, ...)
        if ok then return out end
    end
    return s
end

function private.L(key, ...)
    return CHDMP.L(key, ...)
end
