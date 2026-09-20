package.path = 'HXIChecklist/?.lua;' .. package.path;
string.fmt = string.format;
package.preload.common = function() return {} end;

local owned = { [8] = true, [138] = true, [352] = true, [781] = true };
package.preload.key_item_state = function() return {
    has_key_item = function(identifier)
        if owned[identifier] == true then
            return true, 'Synthetic incoming key-item log.';
        end
        return false, 'Synthetic incoming key-item log.';
    end,
} end;
package.preload.quest_state = function() return {
    get_area = function() error('Access & Travel must not infer from quest logs.') end,
} end;
package.preload.mission_state = function() return {
    get_area = function() error('Access & Travel must not infer from mission state.') end,
} end;
package.preload.job_levels = function() return { format = function() return nil end } end;

local names = {
    [492] = 'vial of shrouded sand',
    [486] = 'Hydra Corps Command Scepter',
    [487] = 'Hydra Corps Eyeglass',
    [488] = 'Hydra Corps Lantern',
    [489] = 'Hydra Corps Tactical Map',
    [490] = 'Hydra Corps Insignia',
    [485] = 'moongate pass',
    [195] = 'portal charm',
    [8] = 'airship pass',
    [9] = 'airship pass for Kazham',
    [138] = 'chocobo license',
    [352] = 'Holla gate crystal',
    [353] = 'Dem gate crystal',
    [354] = 'Mea gate crystal',
    [355] = 'Vahzl gate crystal',
    [356] = 'Yhoator gate crystal',
    [357] = 'Altepa gate crystal',
    [781] = 'boarding permit',
};
local player = {
    GetLoginStatus = function() return 2 end,
    HasKeyItem = function() error('Packet state should answer this fixture.') end,
};
AshitaCore = {
    GetMemoryManager = function() return { GetPlayer = function() return player end } end,
    GetResourceManager = function() return {
        GetString = function(_, table_name, identifier)
            assert(table_name == 'keyitems.names');
            return names[identifier];
        end,
    } end,
};

local data = require('access_travel_data');
local catalog = require('catalog');
assert(#data.views == 5 and data.views[1].name == 'All Unlocks');
assert(#data.entries == 18);

local ids, resource_ids = {}, {};
local group_counts = { travel_services = 0, gate_crystals = 0, dynamis = 0, dungeon_access = 0 };
for _, entry in ipairs(data.entries) do
    assert(entry.id:find('^access_travel%.'));
    assert(entry.kind == 'key_item' and entry.access_unlock == true);
    assert(not ids[entry.id] and not resource_ids[entry.resource_id]);
    assert(names[entry.resource_id] == entry.resource_name);
    assert(entry.availability == 'wiki_listed');
    assert(entry.source_url:find('^https://horizonffxi%.wiki/'));
    assert(type(entry.acquisition_method) == 'string' and entry.acquisition_method ~= '');
    assert(type(entry.travel_use) == 'string' and entry.travel_use ~= '');
    ids[entry.id], resource_ids[entry.resource_id] = true, true;
    group_counts[entry.access_group] = group_counts[entry.access_group] + 1;
end
assert(group_counts.travel_services == 4 and group_counts.gate_crystals == 6);
assert(group_counts.dynamis == 6 and group_counts.dungeon_access == 2);
assert(not resource_ids[734] and not resource_ids[491] and not resource_ids[347]);
assert(ids['access_travel.airship_pass'] and resource_ids[8]);
assert(ids['access_travel.boarding_permit'] and resource_ids[781]);
assert(ids['access_travel.altepa_gate_crystal'] and resource_ids[357]);

local profile = { version = 'synthetic', categories = { {
    id = 'access_travel', name = 'Access & Travel',
    views = data.views, entries = data.entries,
} } };
local snapshot = catalog.build_snapshot(profile, {});
assert(snapshot.summary.complete == 4 and snapshot.summary.open == 14);
assert(snapshot.summary.known_total == 18 and snapshot.summary.unknown == 0);
assert(snapshot.categories[1].entries[1].state_label == 'Unlocked');
assert(snapshot.categories[1].entries[2].state_label == 'Locked');
local ui = require('checklist_ui');
local state = { active_tab = 'access_travel', search = { '' }, selected_views = { access_travel = 4 } };
local settings = { show_completed = true, show_open = true, show_unknown = true };
assert(#ui.build_export(snapshot, {}, settings, state).rows == 6);
state.selected_views.access_travel = 5;
assert(#ui.build_export(snapshot, {}, settings, state).rows == 2);
owned[492] = true;
snapshot = catalog.build_snapshot(profile, {});
assert(snapshot.summary.complete == 5);
names[486] = 'wrong key item';
catalog.invalidate();
snapshot = catalog.build_snapshot(profile, {});
assert(snapshot.categories[1].entries[12].state == 'unknown');
names[486] = 'Hydra Corps Command Scepter';

names[8] = 'unexpected resource';
catalog.invalidate();
snapshot = catalog.build_snapshot(profile, {});
assert(snapshot.categories[1].entries[1].state == 'unknown');
assert(snapshot.categories[1].entries[1].state_note:find('could not be resolved', 1, true));

print('access and travel catalog, explicit key-item IDs, and fail-closed tracking passed');
