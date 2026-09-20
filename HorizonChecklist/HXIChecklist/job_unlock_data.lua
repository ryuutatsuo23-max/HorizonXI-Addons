local job_unlock_data = {};

local quest_catalogs = {
    require('bastok_quest_data'),
    require('sandoria_quest_data'),
    require('windurst_quest_data'),
    require('jeuno_quest_data'),
    require('outlands_quest_data'),
    (require('ahturhgan_quest_data')),
};

local quests = {};
for _, catalog in ipairs(quest_catalogs) do
    for _, quest in ipairs(catalog.entries) do
        quests[quest.id] = quest;
    end
end

local specifications = {
    { 'pld', 7, 'PLD', 'Paladin', 'original', 'sandoria.quest.029' },
    { 'drk', 8, 'DRK', 'Dark Knight', 'original', 'bastok.quest.028' },
    { 'bst', 9, 'BST', 'Beastmaster', 'original', 'jeuno.quest.019' },
    { 'brd', 10, 'BRD', 'Bard', 'original', 'jeuno.quest.020' },
    { 'rng', 11, 'RNG', 'Ranger', 'original', 'windurst.quest.031' },
    { 'sam', 12, 'SAM', 'Samurai', 'rise_of_the_zilart', 'outlands.quest.129' },
    { 'nin', 13, 'NIN', 'Ninja', 'rise_of_the_zilart', 'bastok.quest.060' },
    { 'drg', 14, 'DRG', 'Dragoon', 'rise_of_the_zilart', 'sandoria.quest.093' },
    { 'smn', 15, 'SMN', 'Summoner', 'rise_of_the_zilart', 'windurst.quest.075' },
    { 'blu', 16, 'BLU', 'Blue Mage', 'treasures_of_aht_urhgan', 'ahturhgan.quest.005' },
    { 'cor', 17, 'COR', 'Corsair', 'treasures_of_aht_urhgan', 'ahturhgan.quest.006' },
    { 'pup', 18, 'PUP', 'Puppetmaster', 'treasures_of_aht_urhgan', 'ahturhgan.quest.007' },
};

job_unlock_data.views = {
    { id = 'all', name = 'All Job Unlocks' },
    { id = 'original', name = 'Original', job_era = 'original' },
    { id = 'rise_of_the_zilart', name = 'Rise of the Zilart', job_era = 'rise_of_the_zilart' },
    { id = 'treasures_of_aht_urhgan', name = 'Treasures of Aht Urhgan', job_era = 'treasures_of_aht_urhgan' },
};

job_unlock_data.entries = {};
for _, specification in ipairs(specifications) do
    local quest = assert(quests[specification[6]],
        'Missing reviewed unlock quest: ' .. specification[6]);
    job_unlock_data.entries[#job_unlock_data.entries + 1] = {
        id = 'job_unlock.' .. specification[1],
        kind = 'job_unlock',
        job_id = specification[2],
        abbreviation = specification[3],
        name = specification[4],
        job_era = specification[5],
        unlock_quest = quest.name,
        quest_location = quest.quest_location,
        quest_type = quest.quest_type,
        npc = quest.npc,
        npc_coordinates = quest.npc_coordinates,
        rewards = quest.rewards,
        prerequisites = quest.prerequisites,
        source_url = quest.source_url,
        availability = quest.availability,
        availability_note = quest.availability_note,
        description = string.format(
            '%s unlock quest: %s. Unlock state is read directly from the character job level, not inferred from the quest log.',
            specification[4], quest.name),
    };
end

return job_unlock_data;
