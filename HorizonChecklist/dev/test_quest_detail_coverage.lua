package.path = 'HXIChecklist/?.lua;' .. package.path;
local expected = {
    sandoria = {82, 78, 79, 76}, windurst = {90, 84, 87, 85},
    jeuno = {146, 79, 78, 72}, other = {91, 57, 60, 55},
    outlands = {57, 47, 46, 47}, ahturhgan = {72, 41, 41, 40},
};
local all = {};
for area, counts in pairs(expected) do
    local entries = require(area .. '_quest_data').entries;
    assert(#entries == counts[1]);
    local actual = {0, 0, 0};
    for _, row in ipairs(entries) do
        all[row.id] = row;
        for index, field in ipairs({'npc_coordinates', 'rewards', 'prerequisites'}) do
            local value = row[field];
            if value then
                actual[index] = actual[index] + 1;
                assert(type(value) == 'string' and #value > 0);
                for _, markup in ipairs({'{{', '}}', '[[', ']]', '<br', '<span', 'http'}) do
                    assert(not value:find(markup, 1, true), row.id .. ': unparsed markup');
                end
            end
        end
        if row.prerequisites then
            assert(row.prerequisites:find('Source summary only', 1, true));
        end
    end
    for index = 1, 3 do assert(actual[index] == counts[index + 1], area .. ' detail coverage'); end
end
assert(all['sandoria.quest.070'].prerequisites:find('Fame conflicts', 1, true));
assert(all['sandoria.quest.117'].rewards:find('conflicting sources', 1, true));
assert(all['windurst.quest.050'].rewards:find('first time', 1, true));
assert(all['jeuno.quest.044'].prerequisites:find('Must have started', 1, true));
assert(all['jeuno.quest.044'].rewards:find('Optional coffer rewards', 1, true));
assert(all['other.quest.025'].prerequisites:find('unknown factors', 1, true));
assert(all['outlands.quest.163'].rewards:find('One of the following', 1, true));
assert(all['ahturhgan.quest.023'].prerequisites:find('unless another form of access', 1, true));
-- Unresolved client rows remain un-enriched, not falsely assigned None.
local unknown_without_details = 0;
for _, row in pairs(all) do
    if row.availability == 'unknown' and not row.rewards and not row.prerequisites then
        unknown_without_details = unknown_without_details + 1;
    end
end
assert(unknown_without_details > 90);
print('quest detail coverage fixture: passed');
