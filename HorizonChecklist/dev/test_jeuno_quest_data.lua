package.path = 'HXIChecklist/?.lua;' .. package.path;
local data = require('jeuno_quest_data');

assert(#data.views == 6);
assert(#data.entries == 146);
local by_index = {};
local counts = { numeric = 0, not_listed = 0, unknown_fame = 0, unknown = 0, listed = 0 };
for _, entry in ipairs(data.entries) do
    assert(entry.kind == 'manual' and entry.quest_area == 'jeuno');
    assert(type(entry.quest_index) == 'number' and by_index[entry.quest_index] == nil);
    assert(entry.id == string.format('jeuno.quest.%03d', entry.quest_index));
    assert(entry.source_url:find('^https://horizonffxi%.wiki/'));
    assert(entry.name ~= 'Omni Aketon');
    by_index[entry.quest_index] = entry;
    if type(entry.fame_level) == 'number' then
        counts.numeric = counts.numeric + 1;
    elseif entry.fame_label == 'Not listed' then
        counts.not_listed = counts.not_listed + 1;
    elseif entry.fame_label == 'Unknown' then
        counts.unknown_fame = counts.unknown_fame + 1;
    else
        error('Unexpected fame representation: ' .. entry.name);
    end
    if entry.availability == 'unknown' then
        counts.unknown = counts.unknown + 1;
    elseif entry.availability == 'wiki_listed' then
        counts.listed = counts.listed + 1;
    else
        error('Unexpected availability: ' .. entry.name);
    end
end
assert(counts.numeric == 32 and counts.not_listed == 47 and counts.unknown_fame == 67);
assert(counts.unknown == 63 and counts.listed == 83);
assert(by_index[0].name == 'Crest of Davoi' and by_index[0].fame_level == 2);
assert(by_index[27].name == 'The Gobbiebag Part I' and by_index[27].fame_level == 3);
assert(by_index[68].name == 'Ducal Hospitality');
assert(by_index[84].name == 'Chameleon Capers' and by_index[84].fame_label == 'Unknown');
assert(by_index[128].name == 'In Defiant Challenge');
assert(by_index[132].name == 'Shattering Stars');
assert(by_index[186].name == 'The Flying Machine of Eld' and by_index[186].availability == 'unknown');
assert(by_index[33] == nil and by_index[122] == nil and by_index[165] == nil);
print('jeuno_quest_data fixture passed');
