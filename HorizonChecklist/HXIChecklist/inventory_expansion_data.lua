-- HorizonXI capacity milestones reviewed 2026-09-08. Capacity is not quest completion.
local data = { entries = {}, mirror_ids = {}, views = {
    { id = 'all', name = 'All Containers' },
    { id = 'inventory', name = 'Gobbiebag', inventory_container = 0 },
    { id = 'safe', name = 'Mog Safe', inventory_container = 1 },
    { id = 'locker', name = 'Mog Locker', inventory_container = 4 },
} };
local function add(container, label, target, source, method, mirror_id)
    local entry = {
        id = ('inventory_expansion.%d.%d'):fmt(container, target),
        kind = 'inventory_expansion', inventory_container = container,
        container_name = label, target_capacity = target,
        name = ('%s: %d slots'):fmt(label, target), availability = 'wiki_listed',
        source_url = 'https://horizonffxi.wiki/' .. source,
        acquisition_method = method, mirror_quest_id = mirror_id,
        description = 'Tracks current maximum capacity, independently of quest-log state. Zero or unreadable capacity remains Unknown. Source listings do not guarantee server availability.',
    };
    data.entries[#data.entries + 1] = entry;
    if mirror_id then data.mirror_ids[mirror_id] = entry.id end;
end
local roman = { 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII' };
local quest_indices = { 27, 28, 29, 30, 74, 75, 93, 94 };
for index, part in ipairs(roman) do
    add(0, 'Gobbiebag', 30 + index * 5, 'Inventory',
        'The Gobbiebag Part ' .. part .. ' - Bluffnix, Lower Jeuno H-9. See Source for materials and prerequisites.',
        ('jeuno.quest.%03d'):fmt(quest_indices[index]));
end
local safe_quests = { 'Give a Moogle a Break', "The Moogle's Picnic!", 'Moogles in the Wild' };
for index, quest in ipairs(safe_quests) do
    add(1, 'Mog Safe', 50 + index * 10, 'Mog_Safe',
        quest .. ' - Moogle in your home Mog House. See Source for furniture, items, and fame requirements.',
        ('other.quest.%03d'):fmt(99 + index));
end
local locker_costs = {
    'Speak to Fubruhn after Immortal Sentries; lease payments are separate.',
    'Trade 4 Imperial Mythril Pieces to Fubruhn.',
    'Trade 3 Imperial Gold Pieces to Fubruhn.',
    'Trade 4 Imperial Gold Pieces to Fubruhn.',
    'Trade 5 Imperial Gold Pieces to Fubruhn.',
    'Trade 10 Imperial Gold Pieces to Fubruhn.',
};
for index, method in ipairs(locker_costs) do
    add(4, 'Mog Locker', 20 + index * 10, 'Mog_Locker',
        method .. ' Capacity does not establish an active lease or current access.');
end
return data;
