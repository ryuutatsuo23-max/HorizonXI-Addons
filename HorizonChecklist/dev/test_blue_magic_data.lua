package.path = './HXIChecklist/?.lua;' .. package.path;

getmetatable('').__index.fmt = string.format;

local data = require('blue_magic_data');

assert(#data.views == 5, 'expected All Levels plus four level bands');
assert(data.views[1].name == 'All Levels', 'All Levels must be first');
assert(#data.entries == 106, 'expected 106 HorizonXI category rows');

local expected_bands = {
    levels_1_20 = 20,
    levels_21_40 = 20,
    levels_41_60 = 28,
    levels_61_75 = 38,
};
local observed_bands = {};
local seen_ids = {};
local seen_names = {};
local by_name = {};

for _, entry in ipairs(data.entries) do
    assert(entry.id == ('blue_magic.%d'):format(entry.resource_id),
        'unstable Blue Magic id');
    assert(not seen_ids[entry.id], 'duplicate Blue Magic id: ' .. entry.id);
    assert(not seen_names[entry.name], 'duplicate Blue Magic name: ' .. entry.name);
    assert(entry.kind == 'spell' and entry.blue_magic == true,
        'Blue Magic must reuse live spell ownership');
    assert(entry.skill_id == 43, 'wrong Blue Magic skill id');
    assert(entry.learn_level >= 1 and entry.learn_level <= 75,
        'learn level outside Horizon cap');
    assert(entry.spell_type ~= '' and entry.set_trait ~= '',
        'missing source metadata');
    assert(entry.source_url == 'https://horizonffxi.wiki/Category:Blue_Magic',
        'unexpected Blue Magic source');
    assert(entry.availability == 'wiki_listed', 'availability was overstated');
    seen_ids[entry.id] = true;
    seen_names[entry.name] = true;
    by_name[entry.name] = entry;
    observed_bands[entry.blue_level_band] =
        (observed_bands[entry.blue_level_band] or 0) + 1;
end

for band, count in pairs(expected_bands) do
    assert(observed_bands[band] == count, 'wrong count for ' .. band);
end

assert(by_name['Foot Kick'].resource_id == 577);
assert(by_name['Vanity Dive'].resource_id == 667
    and by_name['Vanity Dive'].learn_level == 28);
assert(by_name['Quadratic Continuum'].resource_id == 673
    and by_name['Quadratic Continuum'].resource_name == 'Quad. Continuum');
assert(by_name['Winds of Promyvion'].resource_id == 681
    and by_name['Winds of Promyvion'].resource_name == 'Winds of Promy.');

print('Blue Magic data, identifiers, levels, metadata, and views passed');
