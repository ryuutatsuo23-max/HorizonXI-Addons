local magic_data = require('magic_data');
local map_data = require('map_data');
local bastok_quest_data = require('bastok_quest_data');

local profile = {
    id = 'horizon-foundation',
    version = '2026-09-03-foundation.9',
    incomplete = true,
    scope_note = 'This profile is intentionally incomplete: nine sourced magic catalogs, the HorizonXI Magical Maps catalog, and the Bastok client quest-log catalog. Its totals are not whole-server completion.',
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
            description = 'Seventy-two map key items with sourced vendor prices or acquisition methods. Ownership is read from incoming key-item log 0x055 and cached by Ashita character; a first-time character must zone once.',
            views = map_data.views,
            entries = map_data.entries,
        },
        {
            id = 'bastok_quests',
            name = 'Bastok Quests',
            description = 'Ninety-three Bastok client quest-log slots mapped from XIchecklist. Ninety-two have HorizonXI category evidence; one remains explicit unknown. Required Bastok fame is shown exactly as numeric, Not listed, or Unknown. Current/completed state is read from incoming quest logs and cached by Ashita character.',
            views = bastok_quest_data.views,
            entries = bastok_quest_data.entries,
        },
    },
};

return profile;
