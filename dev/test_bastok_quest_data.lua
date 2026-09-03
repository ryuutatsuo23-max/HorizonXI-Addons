package.path = './HXIChecklist/?.lua;' .. package.path;

local data = require('bastok_quest_data');

assert(#data.views == 8, 'expected All Quests, six sourced locations, and Unresolved');
assert(data.views[1].name == 'All Quests', 'All Quests must be the first view');
assert(#data.entries == 93, 'expected every client Bastok quest index from 0 through 92');

local seen_ids = {};
local numeric_fame = 0;
local not_listed_fame = 0;
local unknown_fame = 0;
for index, entry in ipairs(data.entries) do
    assert(entry.quest_index == index - 1, 'Bastok quest indices must remain contiguous');
    assert(entry.kind == 'manual' and entry.quest_area == 'bastok',
        'quest row is not mapped to the Bastok client log');
    assert(not seen_ids[entry.id], 'duplicate quest id: ' .. entry.id);
    assert(entry.source_url:match('^https://horizonffxi%.wiki/'),
        'missing HorizonXI quest source');
    assert(entry.quest_location ~= nil, 'missing quest location boundary');
    seen_ids[entry.id] = true;

    if type(entry.fame_level) == 'number' then
        numeric_fame = numeric_fame + 1;
        assert(entry.fame_level >= 1 and entry.fame_level <= 9,
            'invalid Bastok fame level');
    elseif entry.fame_label == 'Not listed' then
        not_listed_fame = not_listed_fame + 1;
    else
        assert(entry.fame_label == 'Unknown', 'unexpected fame boundary');
        unknown_fame = unknown_fame + 1;
    end
end

assert(numeric_fame == 67, 'expected 67 numeric Bastok fame requirements');
assert(not_listed_fame == 21, 'expected 21 table rows without a listed fame level');
assert(unknown_fame == 5, 'expected five quests without a sourced fame row');

assert(seen_ids['HXQ-0001'] and seen_ids['HXQ-0019'],
    'existing pilot IDs must remain stable');
assert(data.entries[1].name == 'The Siren\'s Tear');
assert(data.entries[89].name == 'Fully Mental Alchemist');
assert(data.entries[90].name == 'Synergistic Pursuits');
assert(data.entries[93].name == 'Trust: Bastok');
assert(data.entries[88].availability == 'unknown',
    'A Proper Burial must remain explicit unknown');
assert(data.entries[77].availability == 'reported_inactive',
    'All by Myself pilot boundary must remain unavailable');

print('bastok_quest_data fixture: passed');
