package.path = 'HXIChecklist/?.lua;' .. package.path;
string.fmt = string.format;
bit = { bor = function() return 0 end };
package.preload.common = function() return {} end;
package.preload.key_item_state = function() return {} end;
package.preload.mission_state = function() return {} end;
package.preload.quest_state = function() return {
    get_area = function() return { completed = true } end,
} end;
local data = require('inventory_expansion_data');
assert(#data.entries == 17 and #data.views == 4);
local profile = require('horizon_profile');
local ids, mirrors, mirror_entries, total = {}, 0, {}, 0;
for _, category in ipairs(profile.categories) do
    for _, entry in ipairs(category.entries) do
        assert(not ids[entry.id], 'Duplicate ownership ID'); ids[entry.id] = true;
        if category.counts_toward_profile ~= false and entry.counts_toward_profile ~= false then total = total + 1 end;
        if entry.capacity_mirror_id then
            assert(data.mirror_ids[entry.id] == entry.capacity_mirror_id);
            assert(entry.counts_toward_profile == false and entry.kind == 'manual');
            mirrors = mirrors + 1;
            mirror_entries[#mirror_entries + 1] = entry;
        end
    end
end
assert(mirrors == 11 and total == 1325);
local sizes, logged, throwing = { [0] = 60, [1] = 70, [4] = 0 }, true, false;
local inventory = { GetContainerCountMax = function(_, id)
    if throwing then error('Synthetic unavailable reader') end;
    return sizes[id];
end };
AshitaCore = { GetMemoryManager = function() return {
    GetInventory = function() return inventory end,
    GetPlayer = function() return { GetLoginStatus = function() return logged and 2 or 1 end } end,
} end };
local catalog = require('catalog');
local mini = { categories = {
    { id = 'inventory_expansions', name = 'Inventory Expansions', views = data.views, entries = data.entries },
    { id = 'quest_mirrors', entries = mirror_entries },
} };
local function snapshot() return catalog.build_snapshot(mini, {}) end;
local result = snapshot();
assert(result.summary.entries == 17 and result.summary.complete == 8
    and result.summary.open == 3 and result.summary.unknown == 6);
assert(result.categories[2].summary.complete == 11, 'Quest-local totals must keep mirrors');
assert(result.categories[1].entries[6].current_capacity == 60);
assert(result.categories[1].entries[6].current_level == nil);
assert(result.categories[1].entries[6].state_label == 'Reached');
assert(result.categories[1].entries[7].state_label == 'Not reached');
sizes[0], sizes[1], sizes[4] = 70, 80, 80;
assert(snapshot().summary.complete == 17);
sizes[0], sizes[1], sizes[4] = 30, 50, 30;
assert(snapshot().summary.complete == 1 and snapshot().summary.open == 16);
for _, value in ipairs({ 0, -1, 31, 30.5, 81, 0/0 }) do
    sizes[0] = value;
    assert(snapshot().summary.unknown == 17, 'Invalid base capacity must fail closed');
end
sizes[0], sizes[1], sizes[4] = 60, 0, 40;
assert(snapshot().categories[1].entries[9].state == 'unknown');
sizes[1] = 70;
throwing = true; assert(snapshot().summary.unknown == 17); throwing = false;
logged = false; assert(snapshot().summary.unknown == 17); logged = true;
local ui = require('checklist_ui');
local settings = { scale_percent = 100, show_completed = true, show_open = true,
    show_unknown = true, show_unavailable = true };
local state = { window_open = { true }, active_tab = 'inventory_expansions',
    search = { '' }, selected_views = { inventory_expansions = 2 } };
result = snapshot();
local exported = ui.build_export(result, { entries = {} }, settings, state);
assert(exported.label == 'Inventory Expansions' and #exported.rows == 8);
assert(exported.rows[1][4] == 60 and exported.rows[1][5] == 35);
settings.show_completed = false;
assert(#ui.build_export(result, { entries = {} }, settings, state).rows == 2);
state.search[1] = '70 slots';
assert(#ui.build_export(result, { entries = {} }, settings, state).rows == 1);
state.search[1] = '';
local seen = {};
local imgui = setmetatable({
    Begin = function() return true end, BeginTabBar = function() return true end,
    BeginTabItem = function(label) return label == 'Others/Key Items' or label == 'Inventory Expansions' end,
    BeginTable = function(label) seen[label] = true; return true end,
    BeginCombo = function(label) seen[label] = true; return false end,
    TextWrapped = function(value) if value then seen[value] = true end end,
    GetWindowWidth = function() return 760 end, GetFontSize = function() return 12 end,
    CalcTextSize = function(value) return #value * 7 end,
}, { __index = function() return function() return false end end });
ui.render({ version = 'test' }, result, { entries = {} }, settings, state, {}, imgui);
assert(seen['##InventoryExpansionRows'] and seen['Category##inventory_expansions']);
assert(seen['Current capacity: 60 | Target: 70']);
print('Inventory capacities, unknown guards, 11 quest mirrors, profile totals, UI, and export passed');
