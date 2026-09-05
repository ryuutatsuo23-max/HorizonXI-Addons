package.path = 'HXIChecklist/?.lua;' .. package.path;
package.preload.common = function() return {} end;
local quest_reads = 0;
package.preload.quest_state = function() return {
    get_area = function() quest_reads = quest_reads + 1; return nil, 'Synthetic missing log' end,
    load_area_cache = function() end, clear = function() end,
} end;
package.preload.key_item_state = function() return { load_cache = function() end } end;
package.preload.job_levels = function() return {} end;
local catalog = require('catalog');
local data = require('custom_quest_data');
assert(#data.entries == 4 and #data.views == 4);
local ids, views = {}, {};
for _, view in ipairs(data.views) do if view.quest_location then views[view.quest_location] = true end end;
for _, entry in ipairs(data.entries) do
    assert(type(entry.npc_coordinates) == 'string' and entry.npc_coordinates ~= '');
    assert(type(entry.rewards) == 'string' and entry.rewards ~= '');
    assert(type(entry.prerequisites) == 'string' and entry.prerequisites ~= '');
    assert(not ids[entry.id] and entry.id == entry.reference_id);
    assert(entry.id:find('^horizon%.custom%.'));
    assert(entry.kind == 'manual' and entry.tracking == 'manual');
    assert(entry.quest_area == 'horizon_custom' and entry.quest_index == nil);
    assert(entry.availability == 'wiki_listed' and views[entry.quest_location]);
    assert(entry.source_url:find('^https://horizonffxi%.wiki/'));
    ids[entry.id] = true;
end
assert(data.entries[1].name == 'Omni Aketon' and data.entries[1].fame_label == 'None');
assert(data.entries[2].description:find('at least once', 1, true));
assert(data.entries[3].fame_label == 'Unknown' and data.entries[4].fame_label == 'Unknown');
assert(data.entries[4].description:find('unconfirmed', 1, true));
local profile = { version = 'synthetic', categories = { { id = 'custom_quests', entries = data.entries } } };
local legacy = { ['HXQ-0001'] = true };
local snapshot = catalog.build_snapshot(profile, legacy);
assert(snapshot.summary.known_total == 4 and snapshot.summary.complete == 0 and snapshot.summary.unknown == 0);
assert(snapshot.categories[1].entries[1].state == 'manual_open');
local id = data.entries[1].id;
assert(catalog.set_manual_completed(profile, legacy, id, true));
assert(not catalog.set_manual_completed(profile, legacy, id, true), 'Unchanged values must not trigger saves.');
assert(legacy['HXQ-0001'] == true);
snapshot = catalog.build_snapshot(profile, legacy);
assert(snapshot.summary.complete == 1 and snapshot.categories[1].entries[1].state == 'manual_complete');
assert(snapshot.categories[1].entries[1].state_label == 'Completed (manual)');
assert(snapshot.categories[1].entries[1].npc_coordinates == data.entries[1].npc_coordinates);
assert(snapshot.categories[1].entries[1].rewards == data.entries[1].rewards);
assert(snapshot.categories[1].entries[1].prerequisites == data.entries[1].prerequisites);
assert(catalog.set_manual_completed(profile, legacy, id, false) and legacy[id] == nil);
for _, bad in ipairs({ 'missing', 'HXQ-0001', 'bastok.quest.090', 'spell.1' }) do
    assert(not catalog.set_manual_completed(profile, legacy, bad, true));
end
assert(not catalog.set_manual_completed(profile, legacy, id, 'true'));
assert(quest_reads == 0, 'Custom rows must not guess packet reads.');
-- Even an explicitly manual-labelled row is ineligible when it has a log index.
local mapped = { version = 'synthetic', categories = { { entries = {
    { id = 'mapped', kind = 'manual', tracking = 'manual', quest_area = 'bastok', quest_index = 0, availability = 'wiki_listed' },
} } } };
assert(not catalog.set_manual_completed(mapped, legacy, 'mapped', true));
assert(catalog.build_snapshot(mapped, { mapped = true }).summary.known_total == 0);

-- Exercise the real addon action, settings callback, reload and character swap
-- using synthetic settings only; never load or write player settings files.
local function copy(value)
    if type(value) ~= 'table' then return value end;
    local result = {}; for key, item in pairs(value) do result[key] = copy(item) end; return result;
end
T = function(value) return value end;
addon = {};
local callbacks, settings_callback, actions, shown_settings, shown_snapshot;
local saves, character = 0, 'one';
local stored = {
    one = { visible = true, manual_completed = { ['HXQ-0001'] = true }, cached_state = { version = 1, bastok_quests = { sentinel = true } } },
    two = { visible = true, manual_completed = {}, cached_state = { version = 1 } },
};
local active;
package.loaded.horizon_profile = profile;
package.loaded.chat = {};
package.loaded.imgui = {};
package.loaded.skill_levels = { empty_snapshot = function() return {} end, build_snapshot = function() return {} end };
package.loaded.checklist_ui = { render = function(_, snapshot_value, _, settings_value, _, action_value)
    actions, shown_settings, shown_snapshot = action_value, settings_value, snapshot_value;
end };
package.loaded.settings = {
    load = function() active = copy(stored[character]); return active end,
    save = function() saves = saves + 1; stored[character] = copy(active) end,
    register = function(_, _, callback) settings_callback = callback end,
};
ashita = { time = { tick64 = function() return 1000 end }, events = {
    register = function(event, _, callback) callbacks[event] = callback end,
} };
local function reload()
    callbacks = {};
    dofile('HXIChecklist/HXIChecklist.lua');
    callbacks.d3d_present();
end
reload();
local prior = saves;
actions.set_manual_completed('HXQ-0001', false);
assert(saves == prior and shown_settings.manual_completed['HXQ-0001']);
actions.set_manual_completed(id, true);
assert(saves == prior + 1 and stored.one.manual_completed[id]);
assert(stored.one.cached_state.bastok_quests.sentinel);
callbacks.d3d_present();
assert(shown_snapshot.summary.complete == 1);
actions.set_manual_completed(id, true);
assert(saves == prior + 1);
reload();
assert(shown_snapshot.summary.complete == 1 and shown_settings.manual_completed[id]);
character = 'two'; active = copy(stored.two); settings_callback(active); callbacks.d3d_present();
assert(shown_snapshot.summary.complete == 0 and not shown_settings.manual_completed[id]);
actions.set_manual_completed(data.entries[2].id, true);
assert(stored.two.manual_completed[data.entries[2].id] and not stored.one.manual_completed[data.entries[2].id]);
character = 'one'; active = copy(stored.one); settings_callback(active); callbacks.d3d_present();
assert(shown_settings.manual_completed[id] and not shown_settings.manual_completed[data.entries[2].id]);
actions.set_manual_completed(id, false); reload();
assert(shown_snapshot.summary.complete == 0 and stored.one.manual_completed['HXQ-0001']);
print('custom quest data, guarded marks, and synthetic character persistence passed');
