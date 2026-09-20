package.path = 'HXIChecklist/?.lua;' .. package.path;
local data = require('other_quest_data');
assert(#data.views == 15 and #data.entries == 91);
local by_index, by_location, view_locations = {}, {}, {};
local counts = { numeric = 0, not_listed = 0, unknown_fame = 0, listed = 0, unknown = 0, unavailable = 0 };
for _, view in ipairs(data.views) do
    if view.quest_location then view_locations[view.quest_location] = true end;
end
for _, entry in ipairs(data.entries) do
    assert(entry.quest_area == 'other' and entry.kind == 'manual');
    assert(entry.quest_index < 256 and not by_index[entry.quest_index]);
    assert(entry.id == string.format('other.quest.%03d', entry.quest_index));
    assert(entry.reference_id == entry.id);
    assert(entry.source_url:find('^https://horizonffxi%.wiki/'));
    assert(view_locations[entry.quest_location]);
    by_index[entry.quest_index] = entry;
    by_location[entry.quest_location] = (by_location[entry.quest_location] or 0) + 1;
    if entry.fame_level then
        counts.numeric = counts.numeric + 1;
        assert(entry.fame_level >= 1 and entry.fame_level <= 7);
        assert(entry.fame_note);
        if entry.quest_location == 'Mog House' then
            assert(entry.fame_region == nil);
            assert(entry.fame_note:find('does not identify the fame region', 1, true));
        elseif entry.fame_note:find('linked Quest Header', 1, true) then
            assert(type(entry.fame_region) == 'string' and entry.fame_region ~= '');
        else
            assert(entry.fame_region == entry.quest_location);
        end
    elseif entry.fame_label == 'Not listed' then counts.not_listed = counts.not_listed + 1;
    elseif entry.fame_label == 'Unknown' then counts.unknown_fame = counts.unknown_fame + 1;
    else error('Unexpected fame label') end;
    if entry.availability == 'wiki_listed' then counts.listed = counts.listed + 1;
    elseif entry.availability == 'unknown' then counts.unknown = counts.unknown + 1;
    elseif entry.availability == 'reported_inactive' then counts.unavailable = counts.unavailable + 1;
    else error('Unexpected availability') end;
end
assert(counts.numeric == 21 and counts.not_listed == 39 and counts.unknown_fame == 31);
assert(counts.listed == 56 and counts.unknown == 34 and counts.unavailable == 1);
assert(by_location.Selbina == 11 and by_location.Mhaura == 16);
assert(by_location['Tavnazian Safehold Main Level'] == 6);
assert(by_location['Tavnazian Safehold Upper Level'] == 13);
assert(by_location.Unresolved == 31);
assert(by_index[8].name == 'The Sand Charm' and by_index[8].fame_level == 4);
assert(by_index[19].name == "An Explorer's Footsteps" and by_index[19].fame_region == 'Selbina');
assert(by_index[28].name == 'Trial-Size Trial by Lightning');
assert(by_index[28].source_url:find('Trial_Size_Trial_by_Lightning', 1, true));
assert(by_index[11].fame_level == 2 and by_index[11].fame_region == 'Windurst');
assert(by_index[108].npc_coordinates == 'N/A');
assert(by_index[70].name == 'The Big One' and by_index[70].availability == 'reported_inactive');
for _, index in ipairs({ 106, 107, 109 }) do
    assert(by_index[index].availability == 'unknown');
    assert(by_index[index].availability_note:find('Verification Needed', 1, true));
end
assert(by_index[209].name == 'Sally Forth!' and by_index[209].availability == 'unknown');
assert(by_index[12] == nil and by_index[49] == nil and by_index[1039] == nil);
print('other_quest_data fixture passed');
