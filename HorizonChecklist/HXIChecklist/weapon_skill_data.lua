local weapon_skill_data = {};

local quest_catalogs = {
    require('bastok_quest_data'),
    require('sandoria_quest_data'),
    require('windurst_quest_data'),
    require('jeuno_quest_data'),
    (require('outlands_quest_data')),
};

local quests = {};
for _, catalog in ipairs(quest_catalogs) do
    for _, quest in ipairs(catalog.entries) do
        quests[quest.id] = quest;
    end
end

-- IDs align with the client weapon-skill command table used by
-- IPlayer:HasWeaponSkill. Completion deliberately comes from the reviewed
-- unlock-quest log instead: HasWeaponSkill describes current-job availability,
-- not permanent ownership across every job.
local specifications = {
    { 'asuran_fists', 9, 'Asuran Fists', 'Hand-to-Hand', 'bastok.quest.069' },
    { 'evisceration', 25, 'Evisceration', 'Dagger', 'outlands.quest.013' },
    { 'savage_blade', 42, 'Savage Blade', 'Sword', 'sandoria.quest.102' },
    { 'ground_strike', 56, 'Ground Strike', 'Great Sword', 'bastok.quest.068' },
    { 'decimation', 72, 'Decimation', 'Axe', 'jeuno.quest.059' },
    { 'steel_cyclone', 88, 'Steel Cyclone', 'Great Axe', 'bastok.quest.066' },
    { 'spiral_hell', 104, 'Spiral Hell', 'Scythe', 'sandoria.quest.099' },
    { 'impulse_drive', 120, 'Impulse Drive', 'Polearm', 'sandoria.quest.098' },
    { 'blade_ku', 136, 'Blade: Ku', 'Katana', 'outlands.quest.147' },
    { 'tachi_kasha', 152, 'Tachi: Kasha', 'Great Katana', 'outlands.quest.146' },
    { 'black_halo', 169, 'Black Halo', 'Club', 'windurst.quest.086' },
    { 'retribution', 184, 'Retribution', 'Staff', 'windurst.quest.087' },
    { 'empyreal_arrow', 199, 'Empyreal Arrow', 'Archery', 'windurst.quest.085' },
    { 'detonator', 215, 'Detonator', 'Marksmanship', 'bastok.quest.067' },
};

weapon_skill_data.views = {
    { id = 'all', name = 'All Weapon Types' },
};

weapon_skill_data.entries = {};
for _, specification in ipairs(specifications) do
    local quest = assert(quests[specification[5]],
        'Missing reviewed weapon-skill quest: ' .. specification[5]);
    weapon_skill_data.views[#weapon_skill_data.views + 1] = {
        id = specification[1],
        name = specification[4],
        weapon_type = specification[4],
    };
    weapon_skill_data.entries[#weapon_skill_data.entries + 1] = {
        id = 'weapon_skill.' .. specification[1],
        kind = 'weapon_skill',
        weapon_skill_id = specification[2],
        name = specification[3],
        weapon_type = specification[4],
        unlock_quest = quest.name,
        quest_area = quest.quest_area,
        quest_index = quest.quest_index,
        quest_location = quest.quest_location,
        npc = quest.npc,
        npc_coordinates = quest.npc_coordinates,
        rewards = quest.rewards,
        prerequisites = quest.prerequisites,
        source_url = quest.source_url,
        availability = quest.availability,
        availability_note = quest.availability_note,
        description = string.format(
            '%s quest unlock for %s. Permanent unlock state is read from the character quest log; current-job command availability is not used as completion evidence.',
            specification[4], specification[3]),
    };
end

return weapon_skill_data;
