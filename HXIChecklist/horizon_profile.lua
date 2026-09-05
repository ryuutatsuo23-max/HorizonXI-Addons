local magic_data = require('magic_data');
local map_data = require('map_data');
local bastok_quest_data = require('bastok_quest_data');
local sandoria_quest_data = require('sandoria_quest_data');
local windurst_quest_data = require('windurst_quest_data');
local jeuno_quest_data = require('jeuno_quest_data');
local other_quest_data = require('other_quest_data');
local outlands_quest_data = require('outlands_quest_data');
local ahturhgan_quest_data = require('ahturhgan_quest_data');
local custom_quest_data = require('custom_quest_data');
local bastok_mission_data = require('bastok_mission_data');

local profile = {
    id = 'horizon-foundation',
    version = '2026-09-04-foundation.19',
    incomplete = true,
    scope_note = "This profile is intentionally incomplete: magic, maps, seven client quest logs, four Horizon custom quests, and Bastok missions. Totals include self-reported custom completion and are not whole-server completion.",
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
        {
            id = 'sandoria_quests',
            name = "San d'Oria Quests",
            description = "Eighty-two named San d'Oria client quest-log entries mapped from XIchecklist. Eighty have HorizonXI evidence; two remain explicit unknown. Required San d'Oria fame is shown exactly as numeric, Not listed, or Unknown. Current/completed state is read from incoming quest logs and cached by Ashita character.",
            views = sandoria_quest_data.views,
            entries = sandoria_quest_data.entries,
        },
        {
            id = 'windurst_quests',
            name = 'Windurst Quests',
            description = 'Ninety named Windurst client quest-log entries mapped from XIchecklist. Eighty-nine have current HorizonXI evidence, four are source-reported unavailable, and one remains explicit unknown. Required Windurst fame is shown exactly as numeric, Not listed, or Unknown. Current/completed state is read from incoming quest logs and cached by Ashita character.',
            views = windurst_quest_data.views,
            entries = windurst_quest_data.entries,
        },
        {
            id = 'jeuno_quests',
            name = 'Jeuno Quests',
            description = 'One hundred forty-six named Jeuno client quest-log entries mapped from XIchecklist. Eighty-three have current HorizonXI category evidence; sixty-three remain explicit unknown. Required Jeuno fame is shown exactly as numeric, Not listed, or Unknown. Current/completed state is read from incoming quest logs and cached by Ashita character.',
            views = jeuno_quest_data.views,
            entries = jeuno_quest_data.entries,
        },
        {
            id = 'other_quests',
            name = 'Other Quests',
            description = 'Ninety-one named Other-area client quests, including Selbina, Mhaura, and Tavnazian Safehold. Sixty have HorizonXI table evidence: one is marked unavailable and three need verification. Thirty-one have no matching category evidence. Fame labels follow the source location; state is read from incoming logs and cached by character.',
            views = other_quest_data.views,
            entries = other_quest_data.entries,
        },
        {
            id = 'outlands_quests',
            name = 'Outlands Quests',
            description = 'Fifty-seven named Outlands client quests, including Kazham, Norg, and Rabao. Fifty-one have HorizonXI table evidence; six remain unknown. Fame labels follow the source location. A listing is not a guarantee of current server availability; state is read from incoming logs and cached by character.',
            views = outlands_quest_data.views,
            entries = outlands_quest_data.entries,
        },
        {
            id = 'ahturhgan_quests',
            name = 'Aht Urhgan Quests',
            description = 'Seventy-two named Aht Urhgan client quests with HorizonXI table evidence. Fame is N/A according to the source; other prerequisites may apply. Listings do not guarantee current server availability. Quest state is read from incoming logs and cached by character; Assault and mission data are excluded.',
            views = ahturhgan_quest_data.views,
            entries = ahturhgan_quest_data.entries,
        },
        {
            id = 'custom_quests',
            name = 'Horizon Custom Quests',
            description = 'Four sourced custom quests with no confirmed automatic reader. Checkboxes save self-reported completion per character and count toward progress. Unchecked means not marked, not Not Accepted. Repeatable quests are marked for completion at least once; source uncertainties remain in tooltips.',
            views = custom_quest_data.views,
            entries = custom_quest_data.entries,
        },
        {
            id = 'bastok_missions', name = 'Bastok Missions', mission_area = 'bastok',
            description = 'Twenty main Bastok missions in rank order. Current state and explicit completion bits are read from incoming mission logs and cached per character. Emissary travel stages share one row. Not current does not mean available to start; completion is never inferred from rank or mission order.',
            views = bastok_mission_data.views, entries = bastok_mission_data.entries,
        },
    },
};

return profile;
