package.path = 'HXIChecklist/?.lua;' .. package.path;
string.fmt = string.format;
bit = { bor = function() return 0 end };
package.preload.common = function() return {} end;
for _, module in ipairs({ 'key_item_state', 'quest_state', 'mission_state' }) do
    package.preload[module] = function() return {} end;
end
local magic = require('magic_data');
assert(#magic.entries == 316 and #magic.spell_entries == 200 and #magic.song_entries == 76);
assert(#magic.summoning_entries == 17 and #magic.ninjutsu_entries == 23);
assert(#magic.spell_views == 7 and #magic.song_views == 5);
local ids = {};
for _, group in ipairs({ magic.spell_entries, magic.song_entries, magic.summoning_entries, magic.ninjutsu_entries }) do
    for _, entry in ipairs(group) do assert(not ids[entry.id]); ids[entry.id] = true end;
end
for _, view in ipairs(magic.spell_views) do
    assert(view.magic_skill ~= 'songs' and view.magic_skill ~= 'summoning' and view.magic_skill ~= 'ninjutsu');
end
local resources = {};
local levels = { 1, 20, 21, 40, 41, 60, 61, 75 };
for index, entry in ipairs(magic.song_entries) do
    resources[entry.resource_id] = { Name = { [1] = entry.resource_name }, Skill = 40,
        Index = entry.resource_id, LevelRequired = { [11] = levels[index] or 0 } };
end
local player = { GetLoginStatus = function() return 2 end,
    HasSpellData = function() return true end, HasSpell = function() return true end };
AshitaCore = {
    GetMemoryManager = function() return { GetPlayer = function() return player end } end,
    GetResourceManager = function() return { GetSpellById = function(_, id) return resources[id] end } end,
};
local catalog = require('catalog');
local snapshot = catalog.build_snapshot({ categories = {
    { id = 'songs', name = 'Songs', views = magic.song_views, entries = magic.song_entries },
} }, {});
assert(snapshot.summary.complete == 76);
assert(snapshot.categories[1].entries[9].song_level == nil);
local ui = require('checklist_ui');
local settings = { scale_percent = 100, show_completed = true, show_open = true,
    show_unknown = true, show_unavailable = true };
local state = { active_tab = 'songs', search = { '' }, selected_views = {} };
for band = 1, 5 do
    state.selected_views.songs = band;
    local exported = ui.build_export(snapshot, { entries = {} }, settings, state);
    assert(exported.label == 'Songs');
    assert(#exported.rows == (band == 1 and 76 or 2));
    for _, row in ipairs(exported.rows) do assert(row[3] == 'Songs') end;
end
settings.show_completed = false;
assert(#ui.build_export(snapshot, { entries = {} }, settings, state).rows == 0);
settings.show_completed = true;
local spells = { id = 'magic_skills', summary = snapshot.summary,
    views = magic.spell_views, entries = {
        { id = 'spell.synthetic', name = 'Synthetic spell', state = 'complete',
            magic_skill = 'dark_magic', job_levels = 'DRK Lv.1', minimum_level = 1 },
    } };
table.insert(snapshot.categories, 1, spells);
local active = 'Spells';
local seen = {};
state.window_open = { true };
local imgui = setmetatable({
    Begin = function() return true end,
    BeginTabBar = function() return true end,
    BeginTabItem = function(label)
        seen[label] = true;
        return label == 'Magic Skills' or label == active or label == 'Dark##spell-dark_magic';
    end,
    BeginCombo = function(label) seen[label] = true; return false end,
    BeginTable = function(label) seen[label] = true; return true end,
    GetWindowWidth = function() return 760 end,
    CalcTextSize = function(value) return #value * 7 end,
    GetFontSize = function() return 12 end,
}, { __index = function() return function() return false end end });
ui.render({ version = 'test' }, snapshot, { entries = {} }, settings, state, {}, imgui);
assert(seen.Spells and seen.Songs and seen['Dark##spell-dark_magic']);
assert(not seen['Category##magic_skills'] and seen['##MagicRows']);
assert(state.active_tab == 'magic_skills' and state.selected_views.magic_skills == 2);
assert(seen['Level Range##spell-dark_magic']);
state.spell_level_ranges.dark_magic = 3;
assert(#ui.build_export(snapshot, { entries = {} }, settings, state).rows == 0);
state.spell_level_ranges.dark_magic = 2;
assert(#ui.build_export(snapshot, { entries = {} }, settings, state).rows == 1);
active = 'Songs';
ui.render({ version = 'test' }, snapshot, { entries = {} }, settings, state, {}, imgui);
assert(state.active_tab == 'songs' and seen['Level Range##songs'] and seen['##SongRows']);
print('Song partition, ownership, level boundaries, unavailable levels, and filtered export passed');
