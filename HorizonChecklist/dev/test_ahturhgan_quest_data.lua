package.path = 'HXIChecklist/?.lua;' .. package.path;
local data = require('ahturhgan_quest_data');
assert(#data.entries == 72 and #data.views == 8);
local rows, locations, views = {}, {}, {};
for _, view in ipairs(data.views) do
    if view.quest_location then views[view.quest_location] = true end;
end
for _, entry in ipairs(data.entries) do
    assert(entry.kind == 'manual' and entry.quest_area == 'ahturhgan');
    assert(entry.quest_index >= 0 and entry.quest_index < 128 and not rows[entry.quest_index]);
    assert(entry.id == string.format('ahturhgan.quest.%03d', entry.quest_index));
    assert(entry.reference_id == entry.id and views[entry.quest_location]);
    assert(entry.fame_label == 'N/A' and entry.fame_level == nil);
    assert(entry.fame_note:find('other prerequisites may still apply', 1, true));
    assert(entry.availability == 'wiki_listed');
    assert(entry.source_url:find('^https://horizonffxi%.wiki/'));
    assert(not entry.source_url:find('action=edit', 1, true));
    rows[entry.quest_index] = entry;
    locations[entry.quest_location] = (locations[entry.quest_location] or 0) + 1;
end
assert(locations['Aht Urhgan Whitegate'] == 53 and locations['Al Zahbi'] == 3);
assert(locations.Nashmau == 9 and locations['Bastok Markets'] == 1);
assert(locations['Wajaom Woodlands'] == 2 and locations['Arrapago Reef'] == 3);
assert(locations['Mount Zhayolm'] == 1);
assert(rows[0].name == 'Keeping Notes');
assert(rows[7].name == 'No Strings Attached' and rows[7].quest_location == 'Bastok Markets');
assert(rows[15].name == 'Cook-a-roon?');
assert(rows[18].name == "Totoroon's Treasure Hunt");
assert(rows[68].name == 'VW Op. #050: Aht Urhgan Assault');
assert(rows[69].name == 'VW Op. #068: Subterranean Skirmish');
assert(rows[71].name == 'Duties, Tasks, and Deeds');
assert(rows[99].name == 'Promotion: Captain' and rows[99].source_url == data.source_url);
assert(rows[103].name == 'Targeting the Captain');
for _, index in ipairs({11, 33, 42, 89, 100, 104, 128}) do assert(rows[index] == nil) end;
print('ahturhgan_quest_data fixture passed');
