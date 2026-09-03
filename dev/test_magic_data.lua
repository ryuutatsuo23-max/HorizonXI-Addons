package.path = './HXIChecklist/?.lua;' .. package.path;

getmetatable('').__index.fmt = string.format;

local magic_data = require('magic_data');

local expected_counts = {
    dark_magic = 15,
    divine_magic = 8,
    elemental_magic = 60,
    enfeebling_magic = 19,
    enhancing_magic = 76,
    healing_magic = 22,
};

assert(#magic_data.views == 7, 'expected All Magic plus six skill views');
assert(magic_data.views[1].name == 'All Magic', 'All Magic must be the first view');
assert(#magic_data.entries == 200, 'expected 200 magic entries');

local seen_ids = {};
local seen_names = {};
local observed_counts = {};
for index, entry in ipairs(magic_data.entries) do
    assert(entry.id == ('spell.%d'):format(entry.resource_id), 'unstable spell id');
    assert(not seen_ids[entry.id], 'duplicate spell id: ' .. entry.id);
    assert(not seen_names[entry.name], 'duplicate spell name: ' .. entry.name);
    assert(type(entry.skill_id) == 'number', 'missing client skill id');
    assert(entry.source_url:match('^https://horizonffxi%.wiki/'), 'missing spell source');
    assert(entry.availability == 'wiki_listed', 'unexpected availability label');
    if index > 1 then
        assert(magic_data.entries[index - 1].name:lower() <= entry.name:lower(),
            'All Magic is not alphabetically sorted');
    end
    seen_ids[entry.id] = true;
    seen_names[entry.name] = true;
    observed_counts[entry.magic_skill] = (observed_counts[entry.magic_skill] or 0) + 1;
end

for skill, count in pairs(expected_counts) do
    assert(observed_counts[skill] == count, 'wrong entry count for ' .. skill);
    assert(magic_data.counts[skill] == count, 'wrong declared count for ' .. skill);
end

assert(seen_ids['spell.273'], 'learnable Sleepga id is missing');
assert(seen_ids['spell.274'], 'learnable Sleepga II id is missing');
assert(not seen_ids['spell.363'], 'unlearnable Sleepga id was imported');
assert(not seen_names.Enlight, 'level-85 Enlight was imported');

print('magic_data fixture: passed');
