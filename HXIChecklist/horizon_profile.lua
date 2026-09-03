local magic_data = require('magic_data');
local map_data = require('map_data');

local profile = {
    id = 'horizon-foundation',
    version = '2026-09-03-foundation.7',
    incomplete = true,
    scope_note = 'This profile is intentionally incomplete: nine sourced magic catalogs, the HorizonXI Magical Maps catalog, and the Bastok Markets pilot. Its totals are not whole-server completion.',
    categories = {
        {
            id = 'magic_skills',
            name = 'Magic Skills',
            description = 'Three hundred sixteen sourced level-75-cap spells, summons, ninjutsu, and songs across nine Horizon catalogs. Ownership is read live from Ashita; a wiki listing is not a guarantee of current server availability.',
            views = magic_data.views,
            entries = magic_data.entries,
        },
        {
            id = 'maps',
            name = 'Maps',
            description = 'Seventy-two map key items from the sourced HorizonXI Magical Maps table, with documented vendor prices from the Map Guide. Ownership is read from incoming key-item log 0x055 and cached by Ashita character; a first-time character must zone once.',
            views = map_data.views,
            entries = map_data.entries,
        },
        {
            id = 'bastok_markets_pilot',
            name = 'Bastok Markets Pilot',
            description = 'Nineteen sourced Bastok quest rows. Current/completed state is read from incoming quest logs and cached by Ashita character; no manual completion fallback is shown.',
            entries = {
                { id = 'HXQ-0001', reference_id = 'HXQ-0001', kind = 'manual', quest_area = 'bastok', quest_index = 38, name = 'The Bare Bones', npc = 'Degenhard', availability = 'wiki_listed', description = 'Trade 1 Bone Chip.', source_url = 'https://horizonffxi.wiki/The_Bare_Bones' },
                { id = 'HXQ-0002', reference_id = 'HXQ-0002', kind = 'manual', quest_area = 'bastok', quest_index = 14, name = 'A Flash in the Pan', npc = 'Aquillina', availability = 'wiki_listed', description = 'Trade 4 Flint Stones.', source_url = 'https://horizonffxi.wiki/A_Flash_in_the_Pan' },
                { id = 'HXQ-0003', reference_id = 'HXQ-0003', kind = 'manual', quest_area = 'bastok', quest_index = 87, name = 'A Proper Burial', availability = 'unknown', availability_note = 'No matching individual Horizon source was found. Unknown does not mean unavailable.', description = 'Unknown — no matching Horizon source found.', source_url = 'https://horizonffxi.wiki/Category:Bastok_Quests' },
                { id = 'HXQ-0004', reference_id = 'HXQ-0004', kind = 'manual', quest_area = 'bastok', quest_index = 44, name = 'Brygid the Stylist', npc = 'Brygid', availability = 'wiki_listed', description = 'Equip 1 Bronze Subligar and 1 Robe; speak to Brygid while wearing both.', source_url = 'https://horizonffxi.wiki/Brygid_the_Stylist' },
                { id = 'HXQ-0005', reference_id = 'HXQ-0005', kind = 'manual', quest_area = 'bastok', quest_index = 74, name = 'Brygid the Stylist Returns', npc = 'Brygid', availability = 'wiki_listed', description = 'Level 52+; wear an Artifact Armor piece. Wear the requested body/legs, then trade the subligar for your chosen reward.', source_url = 'https://horizonffxi.wiki/Brygid_the_Stylist_Returns' },
                { id = 'HXQ-0006', reference_id = 'HXQ-0006', kind = 'manual', quest_area = 'bastok', quest_index = 41, name = 'Buckets of Gold', npc = 'Foss', availability = 'wiki_listed', description = 'Trade 5 Rusty Buckets.', source_url = 'https://horizonffxi.wiki/Buckets_of_Gold' },
                { id = 'HXQ-0007', reference_id = 'HXQ-0007', kind = 'manual', quest_area = 'bastok', quest_index = 12, name = 'Gourmet', npc = 'Salimah', availability = 'wiki_listed', description = 'Trade a Sleepshroom, Treant Bulb, or Wild Onion. Reward depends on item and game time.', source_url = 'https://horizonffxi.wiki/Gourmet' },
                { id = 'HXQ-0008', reference_id = 'HXQ-0008', kind = 'manual', quest_area = 'bastok', quest_index = 21, name = 'Mom, the Adventurer?', npc = 'Nbu Latteh', availability = 'wiki_listed', description = 'Trade a Copper Ring (not +1) to Roh Latteh in Bastok Mines H-7; return with her letter.', source_url = 'https://horizonffxi.wiki/Mom,_the_Adventurer%3F' },
                { id = 'HXQ-0009', reference_id = 'HXQ-0009', kind = 'manual', quest_area = 'bastok', quest_index = 16, name = 'Stamp Hunt', npc = 'Arawn', availability = 'wiki_listed', description = 'Receive the Stamp Sheet, speak to all 7 guards listed in the source, then return to Arawn.', source_url = 'https://horizonffxi.wiki/Stamp_Hunt' },
                { id = 'HXQ-0010', reference_id = 'HXQ-0010', kind = 'manual', quest_area = 'bastok', quest_index = 11, name = 'The Cold Light of Day', npc = 'Malene', availability = 'wiki_listed', description = 'Trade a Quus at South Gustaberg M-10; defeat Bubbly Bernie; trade its Steam Clock to Malene.', source_url = 'https://horizonffxi.wiki/The_Cold_Light_of_Day' },
                { id = 'HXQ-0011', reference_id = 'HXQ-0011', kind = 'manual', quest_area = 'bastok', quest_index = 13, name = 'The Elvaan Goldsmith', npc = 'Michea', availability = 'wiki_listed', description = 'Trade 1 Copper Ingot.', source_url = 'https://horizonffxi.wiki/The_Elvaan_Goldsmith' },
                { id = 'HXQ-0012', reference_id = 'HXQ-0012', kind = 'manual', quest_area = 'bastok', quest_index = 76, name = 'All by Myself', npc = 'Marin', availability = 'reported_inactive', availability_note = 'The sourced pilot reports this quest inactive. It is excluded from progress totals.', description = 'Described escort of Ken in Dangruf Wadi; event level cap 10. Do not rely on this as currently playable.', source_url = 'https://horizonffxi.wiki/All_by_Myself' },
                { id = 'HXQ-0013', reference_id = 'HXQ-0013', kind = 'manual', quest_area = 'bastok', quest_index = 10, name = 'Breaking Stones', npc = 'Horatius', availability = 'wiki_listed', description = 'Accept the quest; obtain a Dangruf Stone at Dangruf Wadi I-5/J-5 in sunny/no-weather conditions; trade it to Horatius.', source_url = 'https://horizonffxi.wiki/Breaking_Stones' },
                { id = 'HXQ-0014', reference_id = 'HXQ-0014', kind = 'manual', quest_area = 'bastok', quest_index = 22, name = 'The Signpost Marks the Spot', npc = 'Nbu Latteh', availability = 'wiki_listed', description = 'Check Konschtat Highlands G-5 for Painting of a Windmill; finish with Roh Latteh in Bastok Mines.', source_url = 'https://horizonffxi.wiki/The_Signpost_Marks_the_Spot' },
                { id = 'HXQ-0015', reference_id = 'HXQ-0015', kind = 'manual', quest_area = 'bastok', quest_index = 29, name = 'Father Figure', npc = 'Michea', availability = 'reported_active', availability_note = 'The sourced pilot records this as reported active; private-server behavior still needs testing.', description = 'Trade a Silver Ingot.', source_url = 'https://horizonffxi.wiki/Father_Figure' },
                { id = 'HXQ-0016', reference_id = 'HXQ-0016', kind = 'manual', quest_area = 'bastok', quest_index = 30, name = 'The Return of the Adventurer', npc = 'Gwill', availability = 'wiki_listed', description = "Trade 1 Cinnamon to Gwill, above Mjoll's General Goods.", source_url = 'https://horizonffxi.wiki/The_Return_of_the_Adventurer' },
                { id = 'HXQ-0017', reference_id = 'HXQ-0017', kind = 'manual', quest_area = 'bastok', quest_index = 34, name = 'The Curse Collector', npc = 'Zon-Fobun', availability = 'wiki_listed', description = 'Receive Cursepaper. In Beadeaux, get Cursed by an Afflictor first, then Silenced by a Mute; return to Zon-Fobun.', source_url = 'https://horizonffxi.wiki/The_Curse_Collector' },
                { id = 'HXQ-0018', reference_id = 'HXQ-0018', kind = 'manual', quest_area = 'bastok', quest_index = 64, name = 'Wish Upon a Star', npc = 'Zacc', availability = 'wiki_listed', description = 'Speak to Zacc, Malene, then Enu. Use a Hatchet at a Yuhtunga/Yhoator logging point for Fallen Star; trade to Enu on a clear night, 20:00–04:00 game time.', source_url = 'https://horizonffxi.wiki/Wish_Upon_a_Star' },
                { id = 'HXQ-0019', reference_id = 'HXQ-0019', kind = 'manual', quest_area = 'bastok', quest_index = 85, name = 'Achieving True Power', npc = 'Shamarhaan', availability = 'wiki_listed', availability_note = 'The pilot lists the quest, but an individual source page was not resolved; the category page is linked.', description = 'Unknown — no matching Horizon source found.', source_url = 'https://horizonffxi.wiki/Category:Bastok_Quests' },
            },
        },
    },
};

return profile;
