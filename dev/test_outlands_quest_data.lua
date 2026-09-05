package.path = 'HXIChecklist/?.lua;' .. package.path;
local data = require('outlands_quest_data');
assert(#data.entries == 57 and #data.views == 9);
local rows, locations, view_locations = {}, {}, {};
local numeric, unlisted, unknown = 0, 0, 0;
for _, view in ipairs(data.views) do
    if view.quest_location then view_locations[view.quest_location] = true end;
end
for _, entry in ipairs(data.entries) do
    assert(entry.quest_area == 'outlands' and entry.kind == 'manual');
    assert(entry.quest_index < 256 and not rows[entry.quest_index]);
    assert(entry.id == string.format('outlands.quest.%03d', entry.quest_index));
    assert(entry.reference_id == entry.id);
    assert(entry.source_url:find('^https://horizonffxi%.wiki/'));
    assert(not entry.source_url:find('action=edit', 1, true));
    assert(view_locations[entry.quest_location]);
    rows[entry.quest_index] = entry;
    locations[entry.quest_location] = (locations[entry.quest_location] or 0) + 1;
    if entry.fame_level then
        numeric = numeric + 1;
        assert(entry.fame_region == entry.quest_location);
        assert(entry.fame_level >= 1 and entry.fame_level <= 7 and entry.fame_note);
    elseif entry.fame_label == 'Not listed' then unlisted = unlisted + 1;
    elseif entry.fame_label == 'Unknown' then unknown = unknown + 1;
    else error('Unexpected fame label') end;
    if entry.quest_location == 'Unresolved' then
        assert(entry.availability == 'unknown' and entry.fame_label == 'Unknown');
    else assert(entry.availability == 'wiki_listed') end;
end
assert(numeric == 23 and unlisted == 28 and unknown == 6);
assert(locations.Kazham == 14 and locations.Norg == 21 and locations.Rabao == 11);
assert(locations.Unresolved == 6 and locations["The Shrine of Ru'Avitau"] == 2);
assert(rows[163].name == 'Divine Might');
assert(rows[164].name == 'Divine Might (Repeat)');
assert(rows[164].source_url:find('Divine_Might_(Repeat)', 1, true));
for _, element in ipairs({ {15, 'Fire'}, {148, 'Water'}, {197, 'Wind'} }) do
    assert(rows[element[1]].name == 'Trial-Size Trial by ' .. element[2]);
    assert(rows[element[1]].source_url:find('Trial_Size_Trial_by_' .. element[2], 1, true));
end
assert(rows[193].name == 'The Missing Piece' and rows[193].fame_level == 4);
assert(rows[193].fame_note:find('individual HorizonXI quest page', 1, true));
assert(rows[136].fame_level == 4 and rows[136].fame_region == 'Norg');
assert(rows[1].source_url == data.source_url, 'Red links use their actual category evidence.');
for _, index in ipairs({100, 101, 102, 103, 104, 165}) do
    assert(rows[index].availability == 'unknown');
end
assert(rows[0] == nil and rows[5] == nil and rows[128] == nil and rows[198] == nil);
print('outlands_quest_data fixture passed');
