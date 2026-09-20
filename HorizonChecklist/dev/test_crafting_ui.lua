package.path = 'HXIChecklist/?.lua;' .. package.path;
string.fmt = string.format;
bit = { bor = function() return 0 end };
local ui = require('checklist_ui');
local snapshot = { summary = { complete = 3, known_total = 5, unknown = 0, unavailable = 0 },
    categories = {}, crafting = { entries = {
        { name = 'Cooking', value = 28, rank_name = 'Initiate', next_rank = 'Novice',
            test_level = 28, test_item = 'Vegetable Gruel', source_url = 'https://example.test/cooking' },
        { name = 'Fishing', value = 100, rank_name = 'Veteran', next_test = 'No further listed test',
            source_url = 'https://example.test/fishing' },
    } } };
local settings = { scale_percent = 100, show_completed = false, show_open = false, show_unknown = false };
local state = { window_open = { true }, active_tab = 'crafting', addon_version = '0.28.0',
    search = { '' }, selected_views = {} };
assert(#ui.build_export(snapshot, {}, settings, state).rows == 2, 'Status filters do not apply to live crafts');
state.search[1] = 'gruel';
local exported = ui.build_export(snapshot, {}, settings, state);
assert(#exported.rows == 1 and exported.rows[1][2] == 28 and exported.rows[1][5] == 28);
local seen, style_depth, hovered = {}, 0, false;
local imgui = setmetatable({
    Begin = function() return true end, BeginTabBar = function() return true end,
    BeginTabItem = function(label) return label == 'Crafting' end,
    BeginTable = function(id) seen[id] = true; return true end,
    GetWindowWidth = function() return 760 end, GetFontSize = function() return 12 end,
    CalcTextSize = function(value) return #value * 7 end,
    PushStyleColor = function() style_depth = style_depth + 1 end,
    PopStyleColor = function(count) style_depth = style_depth - (count or 1) end,
    Text = function(value) seen[value] = true end,
    TextWrapped = function(value) seen[value] = true end,
    TextColored = function(_, value) seen[value] = true end,
    IsItemHovered = function() return hovered end,
}, { __index = function() return function() return false end end });
local profile = { version = 'internal', scope_note = 'Long technical profile explanation.' };
ui.render(profile, snapshot, {}, settings, state, {}, imgui);
assert(seen['HXIChecklist v0.28.0'] and not seen['Horizon profile internal']);
assert(not seen[profile.scope_note] and not seen['Foundation - intentionally incomplete']);
assert(seen['##CraftingRows'] and seen['Vegetable Gruel'] and not seen.Fishing);
assert(seen['28 / Initiate'] and seen['Novice (Lv.28+)']);
assert(style_depth == 0 and snapshot.summary.known_total == 5);
hovered = true;
ui.render(profile, snapshot, {}, settings, state, {}, imgui);
assert(seen[profile.scope_note] and style_depth == 0);
print('Compact header, balanced text style, Crafting table, search, source rows, and export passed');
