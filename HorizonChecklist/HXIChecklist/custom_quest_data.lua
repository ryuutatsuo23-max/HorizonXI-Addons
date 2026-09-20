local custom_quest_data = {};

custom_quest_data.source_url = 'https://horizonffxi.wiki/Category:HorizonXI_Custom_Content/Quests';
custom_quest_data.views = {
    { id = 'all', name = 'All Quests' },
    { id = 'rulude_gardens', name = 'Ru\'Lude Gardens', quest_location = 'Ru\'Lude Gardens' },
    { id = 'windurst_woods', name = 'Windurst Woods', quest_location = 'Windurst Woods' },
    { id = 'mount_zhayolm', name = 'Mount Zhayolm', quest_location = 'Mount Zhayolm' },
};

-- Reviewed custom-category pages, 2026-09-03. No client-log indices are assigned.
-- Stable namespaced IDs address self-reported character marks, not packet bits.
custom_quest_data.entries = {
    {
        id = 'horizon.custom.omni_aketon', reference_id = 'horizon.custom.omni_aketon',
        kind = 'manual', tracking = 'manual', quest_area = 'horizon_custom',
        name = 'Omni Aketon', quest_location = 'Ru\'Lude Gardens', npc = 'Milia',
        quest_type = 'Custom quest', availability = 'wiki_listed',
        fame_label = 'None', fame_note = 'The source explicitly lists no required fame. Rank 10 in all three nations and the three nation aketons are separate requirements.',
        description = 'Hidden custom quest rewarding the Ducal Aketon. The source says it does not appear in the quest log. Completion is a manual character mark, not inferred from rank or reward ownership.',
        source_url = 'https://horizonffxi.wiki/Omni_Aketon',
        npc_coordinates = 'H-6', rewards = 'Ducal Aketon',
        prerequisites = 'Rank 10 in Bastok, San d\'Oria, and Windurst; provide the Republic, Kingdom, and Federation Aketons. No fame required. Reward pickup follows the weekly reset; see Source.',
    },
    {
        id = 'horizon.custom.dyers_woad', reference_id = 'horizon.custom.dyers_woad',
        kind = 'manual', tracking = 'manual', quest_area = 'horizon_custom',
        name = 'Dyer\'s Woad Quest', quest_location = 'Windurst Woods', npc = 'Sorutoto',
        quest_type = 'Custom repeatable quest', availability = 'wiki_listed',
        fame_label = 'None', fame_note = 'The source explicitly lists no required fame and says this quest awards no fame.',
        description = 'Trade two Dyer\'s Woad for 800 gil. Repeatable: a checked box means you report completing it at least once; it is not a repeat counter or cooldown tracker.',
        source_url = 'https://horizonffxi.wiki/Dyer%27s_Woad_Quest',
        npc_coordinates = 'G-12 (Weavers\' Guild)', rewards = '800 gil; no fame awarded',
        prerequisites = 'Trade two Dyer\'s Woad. No fame required. Repeatable.',
    },
    {
        id = 'horizon.custom.fill_in', reference_id = 'horizon.custom.fill_in',
        kind = 'manual', tracking = 'manual', quest_area = 'horizon_custom',
        name = 'Fill In', quest_location = 'Windurst Woods', npc = 'Nanaa Mihgo',
        quest_type = 'Custom quest', availability = 'wiki_listed',
        fame_label = 'Unknown', fame_note = 'The source names Windurst fame but marks the requirement as Information Needed. No numeric requirement is inferred.',
        description = 'Custom quest rewarding Nanaa\'s Charm, begun by trading a Broken Charm Bracelet. No confirmed client-log mapping is assigned; completion is self-reported.',
        source_url = 'https://horizonffxi.wiki/Fill_In',
        npc_coordinates = 'J-3', rewards = 'Nanaa\'s Charm',
        prerequisites = 'Trade a Broken Charm Bracelet to begin. Then provide a Four-Leaf Mandragora Bud, Lucky Egg, Sand Charm, and Wild Rabbit Tail. Required Windurst fame is unconfirmed.',
    },
    {
        id = 'horizon.custom.a_mind_unbound', reference_id = 'horizon.custom.a_mind_unbound',
        kind = 'manual', tracking = 'manual', quest_area = 'horizon_custom',
        name = 'A Mind Unbound', quest_location = 'Mount Zhayolm', npc = 'Zonono',
        quest_type = 'Custom quest (provisional title)', availability = 'wiki_listed',
        fame_label = 'Unknown', fame_note = 'The source lists None with an Information Needed marker; the fame requirement is not treated as confirmed.',
        description = 'Wiki working title for a Puppetmaster quest rewarding a Black Puppet Turban. The source says the official quest title and quest-log description are unconfirmed, and additional prerequisites remain uncertain. Requires Puppetmaster as main job to begin according to the source.',
        source_url = 'https://horizonffxi.wiki/A_Mind_Unbound',
        npc_coordinates = 'K-6, Map 1 (Halvung Staging Point)', rewards = 'Black Puppet Turban',
        prerequisites = 'Puppetmaster as main job to begin. The source describes a solo level-40-capped battlefield; other prerequisites and fame remain unconfirmed.',
    },
};

return custom_quest_data;
