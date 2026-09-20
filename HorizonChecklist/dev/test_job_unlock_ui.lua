string.fmt = string.format;
bit = { bor = function() return 0 end };
local ui = dofile('HXIChecklist/checklist_ui.lua');
local summary = { complete = 1, known_total = 2, unknown = 0, unavailable = 0 };
local category = {
    id = 'job_unlocks', name = 'Job Unlocks', description = 'Synthetic job unlocks.',
    summary = summary,
    views = {
        { id = 'all', name = 'All Job Unlocks' },
        { id = 'original', name = 'Original', job_era = 'original' },
    },
    entries = {
        { id = 'job_unlock.pld', kind = 'job_unlock', state = 'complete', state_label = 'Unlocked',
            name = 'Paladin', abbreviation = 'PLD', current_level = 37, job_era = 'original',
            unlock_quest = "A Knight's Test", npc = 'Balasiel', quest_location = "Southern San d'Oria",
            npc_coordinates = 'F-7', rewards = 'Paladin', prerequisites = 'Level 30',
            availability = 'wiki_listed', source_url = 'https://example.test/pld' },
        { id = 'job_unlock.drk', kind = 'job_unlock', state = 'missing', state_label = 'Locked',
            name = 'Dark Knight', abbreviation = 'DRK', current_level = 0, job_era = 'original',
            unlock_quest = 'Blade of Darkness', availability = 'wiki_listed',
            source_url = 'https://example.test/drk' },
    },
};
local snapshot = { categories = { category }, summary = summary };
local settings = { scale_percent = 100, show_completed = true, show_active = true,
    show_open = true, show_unknown = true, show_unavailable = true };
local state = { window_open = { true }, search = { '' }, selected_views = {}, active_tab = 'job_unlocks' };
local seen = { tabs = {}, tables = {}, columns = {}, texts = {} };
local current_id;
local imgui = setmetatable({
    Begin = function() return true end,
    BeginTabBar = function() return true end,
    BeginTabItem = function(name)
        seen.tabs[#seen.tabs + 1] = name;
        return name == 'Others/Key Items' or name == 'Job Unlocks';
    end,
    BeginCombo = function() return false end,
    BeginTable = function(id) seen.tables[id] = true; return true end,
    TableSetupColumn = function(name) seen.columns[name] = true end,
    PushID = function(id) current_id = id end,
    SmallButton = function(label) return current_id == 'job_unlock.pld'
        and label:find('##job_unlock_details', 1, true) ~= nil end,
    Text = function(value) seen.texts[value] = true end,
    TextWrapped = function(value) seen.texts[value] = true end,
    TextColored = function(_, value) seen.texts[value] = true end,
    GetWindowWidth = function() return 760 end,
    CalcTextSize = function(value) return #value * 7 end,
    GetFontSize = function() return 12 end,
    IsItemHovered = function() return false end,
}, { __index = function() return function() return false end end });
local actions = setmetatable({}, { __index = function()
    return function() error('Rendering job unlocks must not change state.') end;
end });
ui.render({ version = 'test', scope_note = 'test' }, snapshot, { entries = {} },
    settings, state, actions, imgui);
assert(table.concat(seen.tabs, '|') ==
    'Quests|Missions|Magic Skills|Crafting|Others/Key Items|Job Unlocks|Skill Levels');
assert(seen.tables['##JobUnlockRows']);
assert(seen.columns.Job and seen.columns.Source and seen.columns['Unlock Quest / Level']);
assert(seen.texts['[Unlocked]'] and seen.texts['[Locked]']);
assert(seen.texts['Paladin (PLD)'] and seen.texts["A Knight's Test / Lv.37"]);
assert(seen.texts['NPC: Balasiel'] and seen.texts["Location: Southern San d'Oria"]);

local exported = ui.build_export(snapshot, { entries = {} }, settings, state);
assert(exported.label == 'Job Unlocks' and exported.file_label == 'job-unlocks-all');
assert(#exported.rows == 2 and #exported.headers == 12);
assert(exported.rows[1][1] == 'Unlocked' and exported.rows[1][4] == 37);
assert(exported.rows[2][1] == 'Locked' and exported.rows[2][4] == 0);
settings.show_completed = false;
exported = ui.build_export(snapshot, { entries = {} }, settings, state);
assert(#exported.rows == 1 and exported.rows[1][2] == 'Dark Knight');
print('job unlock table, expansion, filters, and export passed');
