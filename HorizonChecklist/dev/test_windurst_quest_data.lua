package.path = 'HXIChecklist/?.lua;' .. package.path;

local data = require('windurst_quest_data');

assert(#data.views == 8, 'Expected eight Windurst location views.');
assert(#data.entries == 90, 'Expected 90 named client-log entries.');

local numeric_fame = 0;
local not_listed = 0;
local unknown_fame = 0;
local unknown_availability = 0;
local unavailable = 0;
local by_index = {};

for _, entry in ipairs(data.entries) do
    assert(entry.kind == 'manual' and entry.quest_area == 'windurst');
    assert(type(entry.quest_index) == 'number' and by_index[entry.quest_index] == nil);
    assert(type(entry.source_url) == 'string' and entry.source_url:find('^https://'));
    by_index[entry.quest_index] = entry;
    if type(entry.fame_level) == 'number' then
        numeric_fame = numeric_fame + 1;
    elseif entry.fame_label == 'Not listed' then
        not_listed = not_listed + 1;
    elseif entry.fame_label == 'Unknown' then
        unknown_fame = unknown_fame + 1;
    else
        error('Unexpected fame representation for ' .. entry.name);
    end
    if entry.availability == 'unknown' then
        unknown_availability = unknown_availability + 1;
    elseif entry.availability == 'reported_inactive' then
        unavailable = unavailable + 1;
    end
end

assert(numeric_fame == 65 and not_listed == 22 and unknown_fame == 3);
assert(unknown_availability == 1);
assert(unavailable == 4);
assert(by_index[0].name == 'Hat in Hand');
assert(by_index[16].name == 'Water Way to Go!');
assert(by_index[19].name == "The Postman Always K.O.'s Twice");
assert(by_index[60].name == 'Paying Lip Service');
assert(by_index[94].name == 'Lure of the Wildcat (Windurst)');
assert(by_index[94].availability == 'wiki_listed');
assert(by_index[95].name == 'Babban Ny Mheillea');
assert(by_index[95].availability == 'wiki_listed');
assert(by_index[96].name == 'Trust: Windurst');
assert(by_index[96].availability == 'unknown');
assert(by_index[46].availability == 'reported_inactive');
assert(by_index[79].availability == 'reported_inactive');
assert(by_index[88].availability == 'reported_inactive');
assert(by_index[89].availability == 'reported_inactive');

print('windurst_quest_data fixture passed');
