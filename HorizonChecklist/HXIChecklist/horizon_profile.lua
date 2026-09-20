local magic_data = require('magic_data');
local inventory_expansion_data = require('inventory_expansion_data');
local blue_magic_data = require('blue_magic_data');
local map_data = require('map_data');
local access_travel_data = require('access_travel_data');
local job_unlock_data = require('job_unlock_data');
local weapon_skill_data = require('weapon_skill_data');
local bastok_quest_data = require('bastok_quest_data');
local sandoria_quest_data = require('sandoria_quest_data');
local windurst_quest_data = require('windurst_quest_data');
local jeuno_quest_data = require('jeuno_quest_data');
local other_quest_data = require('other_quest_data');
local outlands_quest_data = require('outlands_quest_data');
local ahturhgan_quest_data = require('ahturhgan_quest_data');
local custom_quest_data = require('custom_quest_data');
local sandoria_mission_data = require('sandoria_mission_data');
local bastok_mission_data = require('bastok_mission_data');
local windurst_mission_data = require('windurst_mission_data');
local zilart_mission_data = require('zilart_mission_data');
local promathia_mission_data = require('promathia_mission_data');
local ahturhgan_mission_data = require('ahturhgan_mission_data');

local profile = {
    id = 'horizon-foundation',
    version = '2026-09-08-foundation.29',
    incomplete = true,
    scope_note = "This profile is intentionally incomplete: magic, maps, inventory expansions, access and travel, job unlocks, weapon skills, seven client quest logs, four Horizon custom quests, and six Horizon-era mission storylines. Weapon-skill mirrors and 11 inventory-upgrade quest mirrors are excluded from the overall total. Quest mirrors retain their own quest-log state.",
    categories = {
        {
            id = 'magic_skills',
            name = 'Spells',
            description = '200 sourced level-75-cap spells across six Horizon catalogs. Ownership is read live from Ashita. Level ranges use the lowest listed job requirement; unavailable levels appear under All Levels. A wiki listing does not guarantee current server availability.',
            views = magic_data.spell_views,
            entries = magic_data.spell_entries,
        },
        {
            id = 'songs',
            name = 'Songs',
            description = '76 sourced Bard songs. Ownership and required BRD levels are read from Ashita. Songs with unavailable level data appear under All Levels only. A wiki listing does not guarantee current server availability.',
            views = magic_data.song_views,
            entries = magic_data.song_entries,
        },
        {
            id = 'summoning', name = 'Summoning',
            description = '17 sourced summons. Ownership is read live from Ashita. Level ranges use the lowest listed job requirement; unavailable levels appear under All Levels.',
            views = magic_data.song_views, entries = magic_data.summoning_entries,
        },
        {
            id = 'ninjutsu', name = 'Ninjutsu',
            description = '23 sourced ninjutsu spells. Ownership is read live from Ashita. Level ranges use the lowest listed job requirement; unavailable levels appear under All Levels.',
            views = magic_data.song_views, entries = magic_data.ninjutsu_entries,
        },
        {
            id = 'blue_magic',
            name = 'Blue Magic',
            description = 'One hundred six level-1-to-75 Blue Magic spells from the current HorizonXI category table. Learned state is read live from Ashita spell ownership. Horizon learn levels, spell types, and set traits follow the table; exact learning monsters and zones remain excluded until Horizon-specific sources are verified.',
            views = blue_magic_data.views,
            entries = blue_magic_data.entries,
        },
        {
            id = 'inventory_expansions', name = 'Inventory Expansions',
            description = '17 capacity milestones: Gobbiebag 35-70, Mog Safe 60-80, and Mog Locker 30-80. Maximum capacity is read live from Ashita; zero or unreadable values stay Unknown. Linked quest rows remain tracked in Quests but are excluded from the overall total. Locker capacity does not establish lease access. Furniture Storage and mirrored bags are excluded.',
            views = inventory_expansion_data.views, entries = inventory_expansion_data.entries,
        },
        {
            id = 'maps',
            name = 'Maps',
            description = 'Seventy-two map key items with sourced vendor prices or acquisition methods. Ownership is read from incoming key-item log 0x055 and cached by Ashita character; a first-time character must zone once.',
            views = map_data.views,
            entries = map_data.entries,
        },
        {
            id = 'access_travel',
            name = 'Access & Travel',
            description = '18 permanent travel, Dynamis, and dungeon key items. Ownership is read from the character key-item log. Individual items do not establish full entry eligibility. Sea is mission-based; temporary Limbus entry items are excluded.',
            views = access_travel_data.views,
            entries = access_travel_data.entries,
        },
        {
            id = 'job_unlocks',
            name = 'Job Unlocks',
            description = 'Twelve Horizon-era advanced jobs through Treasures of Aht Urhgan. Unlock state is read live from the character job levels exposed by Ashita; quest completion is not inferred. Starting jobs and later-era jobs are excluded.',
            views = job_unlock_data.views,
            entries = job_unlock_data.entries,
        },
        {
            id = 'weapon_skills',
            name = 'Weapon Skills',
            description = 'Fourteen level-75-era quest-unlocked weapon skills, one per weapon type. Permanent unlock state is read from the same validated client quest logs as Quests. Current-job HasWeaponSkill availability is deliberately not treated as ownership. These mirror rows do not count twice in the overall progress total.',
            counts_toward_profile = false,
            views = weapon_skill_data.views,
            entries = weapon_skill_data.entries,
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
            mission_view_label = 'Rank', mission_column_label = 'Rank / Type',
            views = bastok_mission_data.views, entries = bastok_mission_data.entries,
        },
        {
            id = 'sandoria_missions', name = "San d'Oria Missions", mission_area = 'sandoria',
            description = "Twenty main San d'Oria missions in rank order. Current state is nation-gated and completion uses only explicit incoming mission bits. Journey Abroad travel stages share one row; rank/order never imply completion.",
            mission_view_label = 'Rank', mission_column_label = 'Rank / Type',
            views = sandoria_mission_data.views, entries = sandoria_mission_data.entries,
        },
        {
            id = 'windurst_missions', name = 'Windurst Missions', mission_area = 'windurst',
            description = 'Twenty main Windurst missions in rank order. Current state is nation-gated and completion uses only explicit incoming mission bits. Three Kingdoms travel stages share one row; rank/order never imply completion.',
            mission_view_label = 'Rank', mission_column_label = 'Rank / Type',
            views = windurst_mission_data.views, entries = windurst_mission_data.entries,
        },
        {
            id = 'zilart_missions', name = 'Rise of the Zilart Missions', mission_area = 'zilart',
            description = 'Eighteen HorizonXI-listed Zilart missions. Current state and explicit completion bits are read from incoming mission logs. Packet gaps remain unknown; story order is never used to infer completion.',
            mission_view_label = 'Mission', mission_column_label = 'Type',
            views = zilart_mission_data.views, entries = zilart_mission_data.entries,
        },
        {
            id = 'promathia_missions', name = 'Chains of Promathia Missions', mission_area = 'promathia',
            description = 'Thirty-four numbered Promathia missions across eight chapters. Incoming logs identify the current mission and reviewed multi-part stages, but no completion bitfield is used; every non-current row therefore remains Unknown.',
            mission_view_label = 'Chapter', mission_column_label = 'Chapter / Type',
            views = promathia_mission_data.views, entries = promathia_mission_data.entries,
        },
        {
            id = 'ahturhgan_missions', name = 'Treasures of Aht Urhgan Missions', mission_area = 'ahturhgan',
            description = 'Forty-eight Aht Urhgan missions from the HorizonXI category, which currently labels the list as planned content. Current state and explicit completion bits are read when supplied; the listing itself does not prove server availability.',
            mission_view_label = 'Mission', mission_column_label = 'Type',
            views = ahturhgan_mission_data.views, entries = ahturhgan_mission_data.entries,
        },
    },
};

-- Exclude only the explicitly linked quest mirrors, retaining their real log state
-- and their contribution to the local Quests progress summary.
for _, category in ipairs(profile.categories) do
    for index, entry in ipairs(category.entries) do
        local mirror = inventory_expansion_data.mirror_ids[entry.id];
        if mirror then
            local copy = {};
            for key, value in pairs(entry) do copy[key] = value end;
            copy.counts_toward_profile = false;
            copy.capacity_mirror_id = mirror;
            category.entries[index] = copy;
        end
    end
end
return profile;
