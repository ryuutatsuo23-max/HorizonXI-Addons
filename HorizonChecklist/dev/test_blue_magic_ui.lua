string.fmt = string.format;
bit = { bor = function() return 0 end };

local ui = dofile('HXIChecklist/checklist_ui.lua');
local summary = { complete = 1, known_total = 2, unknown = 0, unavailable = 0 };
local blue = {
    id = 'blue_magic', name = 'Blue Magic', description = 'Synthetic Blue Magic.',
    summary = summary,
    views = {
        { id = 'all', name = 'All Levels' },
        { id = 'levels_1_20', name = 'Levels 1-20', blue_level_band = 'levels_1_20' },
        { id = 'levels_61_75', name = 'Levels 61-75', blue_level_band = 'levels_61_75' },
    },
    entries = {
        { id = 'blue_magic.577', kind = 'spell', blue_magic = true,
            state = 'complete', state_label = 'Learned', name = 'Foot Kick',
            learn_level = 1, blue_level_band = 'levels_1_20',
            spell_type = 'Slashing', set_trait = 'Lizard Killer',
            availability = 'wiki_listed', source_url = 'https://example.test/foot-kick' },
        { id = 'blue_magic.617', kind = 'spell', blue_magic = true,
            state = 'missing', state_label = 'Not learned', name = 'Vertical Cleave',
            learn_level = 75, blue_level_band = 'levels_61_75',
            spell_type = 'Slashing', set_trait = 'Defense Bonus',
            availability = 'wiki_listed', source_url = 'https://example.test/vertical-cleave' },
    },
};
local magic = { id = 'magic_skills', name = 'Magic Skills',
    description = 'Synthetic magic.', summary = summary, views = {}, entries = {} };
local snapshot = { categories = { magic, blue }, summary = summary };
local settings = { scale_percent = 100, show_completed = true, show_active = true,
    show_open = true, show_unknown = true, show_unavailable = true };
local state = { window_open = { true }, search = { '' }, selected_views = {},
    active_tab = 'blue_magic' };
local seen = { tabs = {}, tables = {}, columns = {}, texts = {}, sources = {} };
local current_id;
local imgui = setmetatable({
    Begin = function() return true end,
    BeginTabBar = function() return true end,
    BeginTabItem = function(name)
        seen.tabs[#seen.tabs + 1] = name;
        return name == 'Magic Skills' or name == 'Blue Magic';
    end,
    BeginCombo = function() return false end,
    BeginTable = function(id) seen.tables[id] = true; return true end,
    TableSetupColumn = function(name) seen.columns[name] = true end,
    PushID = function(id) current_id = id end,
    SmallButton = function(label)
        if label == 'Source' then seen.sources[current_id] = true end;
        return false;
    end,
    Text = function(value) seen.texts[value] = true end,
    TextWrapped = function(value) seen.texts[value] = true end,
    TextColored = function(_, value) seen.texts[value] = true end,
    GetWindowWidth = function() return 760 end,
    CalcTextSize = function(value) return #value * 7 end,
    GetFontSize = function() return 12 end,
    IsItemHovered = function() return false end,
}, { __index = function() return function() return false end end });
local actions = setmetatable({}, { __index = function()
    return function() error('Blue Magic rendering must not change character state.') end;
end });

ui.render({ version = 'test', scope_note = 'test' }, snapshot, { entries = {} },
    settings, state, actions, imgui);
assert(table.concat(seen.tabs, '|') ==
    'Quests|Missions|Magic Skills|Spells|Blue Magic|Crafting|Others/Key Items');
assert(seen.tables['##BlueMagicRows']);
assert(seen.columns['Blue Magic'] and seen.columns.Source
    and seen.columns['Level / Type / Trait']);
assert(seen.texts['[Learned]'] and seen.texts['[Not learned]']);
assert(seen.texts['Level 1 / Slashing / Lizard Killer']);
assert(seen.texts['Level 75 / Slashing / Defense Bonus']);
assert(seen.sources['blue_magic.577'] and seen.sources['blue_magic.617']);

local exported = ui.build_export(snapshot, { entries = {} }, settings, state);
assert(exported.label == 'Blue Magic' and exported.file_label == 'blue-magic-all');
assert(#exported.rows == 2 and #exported.headers == 6);
assert(exported.rows[1][1] == 'Learned' and exported.rows[1][3] == 1);
state.selected_views.blue_magic = 3;
exported = ui.build_export(snapshot, { entries = {} }, settings, state);
assert(#exported.rows == 1 and exported.rows[1][2] == 'Vertical Cleave');
settings.show_open = false;
exported = ui.build_export(snapshot, { entries = {} }, settings, state);
assert(#exported.rows == 0);

print('Blue Magic tabs, table, filters, and export passed');
