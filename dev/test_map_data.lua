package.path = './HXIChecklist/?.lua;' .. package.path;

getmetatable('').__index.fmt = string.format;

local map_data = require('map_data');

local expected_counts = {
    original_areas = 28,
    rise_of_the_zilart = 16,
    chains_of_promathia = 17,
    treasures_of_aht_urhgan = 11,
};

assert(#map_data.views == 5, 'expected All Maps plus four catalog views');
assert(map_data.views[1].name == 'All Maps', 'All Maps must be the first view');
assert(#map_data.entries == 72, 'expected 72 Horizon-listed map entries');

local seen_ids = {};
local seen_resource_ids = {};
local observed_counts = {};
local vendor_count = 0;
for index, entry in ipairs(map_data.entries) do
    assert(entry.kind == 'key_item', 'map row is not a key item');
    assert(not seen_ids[entry.id], 'duplicate map id: ' .. entry.id);
    assert(not seen_resource_ids[entry.resource_id],
        'duplicate client key-item id: ' .. entry.resource_id);
    assert(entry.source_url:match('^https://horizonffxi%.wiki/'),
        'missing map source');
    assert(entry.availability == 'wiki_listed',
        'unexpected availability label');
    if index > 1 then
        assert(map_data.entries[index - 1].name:lower() <= entry.name:lower(),
            'All Maps is not alphabetically sorted');
    end
    seen_ids[entry.id] = entry.resource_id;
    seen_resource_ids[entry.resource_id] = true;
    observed_counts[entry.map_catalog] =
        (observed_counts[entry.map_catalog] or 0) + 1;
    if entry.vendor_cost ~= nil then
        vendor_count = vendor_count + 1;
        assert(entry.vendor_source_url == 'https://horizonffxi.wiki/Map_Guide',
            'priced map is missing its vendor source');
    else
        assert(entry.vendor_source_url == nil,
            'unpriced map unexpectedly has a vendor source');
    end
end

assert(vendor_count == 30, 'expected 30 sourced vendor prices');

for catalog, count in pairs(expected_counts) do
    assert(observed_counts[catalog] == count,
        'wrong entry count for ' .. catalog);
    assert(map_data.counts[catalog] == count,
        'wrong declared count for ' .. catalog);
end

assert(seen_ids['map.san_doria'] == 385,
    'existing San d\'Oria map id changed');
assert(seen_ids['map.ghelsba'] == 404,
    'existing Ghelsba map id changed');
assert(seen_ids['map.giddeus'] == 408,
    'existing Giddeus map id changed');
assert(seen_ids['map.al_zahbi'] == 1856,
    'Al Zahbi client key-item id is wrong');
assert(seen_ids['map.bhaflau_thickets'] == 1874,
    'Bhaflau Thickets client key-item id is wrong');
assert(not seen_ids['map.uleguerand_range'],
    'client-only Uleguerand map was imported outside the Horizon table');
assert(not seen_ids['map.leujaoam_sanctum'],
    'temporary Assault map was imported outside the Horizon table');

local entries_by_id = {};
for _, entry in ipairs(map_data.entries) do
    entries_by_id[entry.id] = entry;
end
assert(entries_by_id['map.san_doria'].vendor_cost == '200 gil');
assert(entries_by_id['map.jeuno'].vendor_cost == '600 gil');
assert(entries_by_id['map.qufim_island'].vendor_cost == '3,000 gil');
assert(entries_by_id['map.mamook'].vendor_cost == '2,000 Imperial Standing');
assert(entries_by_id['map.arrapago_reef'].vendor_cost == '2,000 Imperial Standing');
assert(entries_by_id['map.halvung'].vendor_cost == '2,000 Imperial Standing');
assert(entries_by_id['map.dangruf_wadi'].vendor_cost == nil);

print('map_data fixture: passed');
