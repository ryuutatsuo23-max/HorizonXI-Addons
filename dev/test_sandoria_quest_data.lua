package.path = 'HXIChecklist/?.lua;' .. package.path;

local data = require('sandoria_quest_data');

assert(#data.views == 8, 'Expected eight San d\'Oria location views.');
assert(#data.entries == 82, 'Expected 82 named client-log entries.');

local numeric_fame = 0;
local not_listed = 0;
local unknown_fame = 0;
local unknown_availability = 0;
local by_index = {};

for _, entry in ipairs(data.entries) do
    assert(entry.kind == 'manual' and entry.quest_area == 'sandoria');
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
    end
end

assert(numeric_fame == 60 and not_listed == 19 and unknown_fame == 3);
assert(unknown_availability == 2);
assert(by_index[0].name == "A Sentry's Peril");
assert(by_index[58].name == 'Growing Flowers');
assert(by_index[113].name == "Lure of the Wildcat (San d'Oria)");
assert(by_index[113].availability == 'wiki_listed');
assert(by_index[114].name == "Atelloune's Lament" and by_index[114].availability == 'unknown');
assert(by_index[117].name == 'Thick Shells');
assert(by_index[118].name == 'Forest for the Trees');
assert(by_index[119].name == "Trust: San d'Oria" and by_index[119].availability == 'unknown');

print("sandoria_quest_data fixture passed");
