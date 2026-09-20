string.fmt = string.format;
bit = { bor = function() return 0 end };
local ui = dofile('HXIChecklist/checklist_ui.lua');
local summary = { complete = 1, known_total = 2, unknown = 0, unavailable = 0 };
local category = {
    id = 'access_travel', name = 'Access & Travel',
    description = 'Synthetic permanent travel unlocks.', summary = summary,
    views = {
        { id = 'all', name = 'All Unlocks' },
        { id = 'travel_services', name = 'Travel Services', access_group = 'travel_services' },
        { id = 'gate_crystals', name = 'Gate Crystals', access_group = 'gate_crystals' },
    },
    entries = {
        { id = 'access_travel.airship_pass', kind = 'key_item', access_unlock = true,
            state = 'complete', state_label = 'Unlocked', name = 'Airship Pass',
            access_group = 'travel_services',
            acquisition_method = 'Rank 5 or 500,000 gil',
            travel_use = 'Nation-to-Jeuno airships', availability = 'wiki_listed',
            source_url = 'https://example.test/airship' },
        { id = 'access_travel.holla_gate_crystal', kind = 'key_item', access_unlock = true,
            state = 'missing', state_label = 'Locked', name = 'Holla Gate Crystal',
            access_group = 'gate_crystals', acquisition_method = 'Check the Telepoint',
            travel_use = 'Teleport-Holla', availability = 'wiki_listed',
            source_url = 'https://example.test/holla' },
    },
};
local function stub(id, name)
    return { id = id, name = name, description = 'Synthetic.', summary = summary,
        views = {}, entries = {} };
end
local snapshot = { categories = {
    stub('maps', 'Maps'), category, stub('job_unlocks', 'Job Unlocks'),
    stub('weapon_skills', 'Weapon Skills'),
}, summary = summary };
local settings = { scale_percent = 100, show_completed = true, show_active = true,
    show_open = true, show_unknown = true, show_unavailable = true };
local state = { window_open = { true }, search = { '' }, selected_views = {},
    active_tab = 'access_travel' };
local seen = { tabs = {}, tables = {}, columns = {}, texts = {} };
local imgui = setmetatable({
    Begin = function() return true end,
    BeginTabBar = function() return true end,
    BeginTabItem = function(name)
        seen.tabs[#seen.tabs + 1] = name;
        return name == 'Others/Key Items' or name == 'Access & Travel';
    end,
    BeginCombo = function() return false end,
    BeginTable = function(id) seen.tables[id] = true; return true end,
    TableSetupColumn = function(name) seen.columns[name] = true end,
    Text = function(value) seen.texts[value] = true end,
    TextWrapped = function(value) seen.texts[value] = true end,
    TextColored = function(_, value) seen.texts[value] = true end,
    GetWindowWidth = function() return 760 end,
    CalcTextSize = function(value) return #value * 7 end,
    GetFontSize = function() return 12 end,
    IsItemHovered = function() return false end,
}, { __index = function() return function() return false end end });
local actions = setmetatable({}, { __index = function()
    return function() error('Rendering Access & Travel must not change state.') end;
end });

ui.render({ version = 'test', scope_note = 'test' }, snapshot, { entries = {} },
    settings, state, actions, imgui);
assert(table.concat(seen.tabs, '|') ==
    'Quests|Missions|Magic Skills|Crafting|Others/Key Items|Maps|Access & Travel|Job Unlocks|Weapon Skills|Skill Levels');
assert(seen.tables['##AccessTravelRows']);
assert(seen.columns.Unlock and seen.columns.Source and seen.columns.Obtained);
assert(seen.texts['[Unlocked]'] and seen.texts['[Locked]']);
assert(seen.texts['Airship Pass'] and seen.texts['Rank 5 or 500,000 gil']);

local exported = ui.build_export(snapshot, { entries = {} }, settings, state);
assert(exported.label == 'Access & Travel');
assert(exported.file_label == 'access-travel-all');
assert(#exported.rows == 2 and #exported.headers == 6);
assert(exported.rows[1][1] == 'Unlocked' and exported.rows[1][3] == 'Travel Services');
state.selected_views.access_travel = 3;
exported = ui.build_export(snapshot, { entries = {} }, settings, state);
assert(#exported.rows == 1 and exported.rows[1][2] == 'Holla Gate Crystal');
settings.show_open = false;
exported = ui.build_export(snapshot, { entries = {} }, settings, state);
assert(#exported.rows == 0);

print('access and travel table, views, filters, and export passed');
