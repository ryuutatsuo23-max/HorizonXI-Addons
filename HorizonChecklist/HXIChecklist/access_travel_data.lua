local access_travel_data = {};

-- Permanent Horizon-era travel unlocks with explicit client key-item IDs.
-- Temporary mission keys, repeatable permits, and later-era gate crystals are
-- deliberately excluded even when the client resource table contains them.
local specifications = {
    {
        'airship_pass', 8, 'Airship Pass', 'airship pass', 'travel_services',
        'Rank 5 in a home nation, or 500,000 gil from Derrick in Lower Jeuno',
        'Allows travel on the nation-to-Jeuno airship routes.',
        'Airship_Pass',
    },
    {
        'airship_pass_kazham', 9, 'Airship Pass for Kazham',
        'airship pass for Kazham', 'travel_services',
        'Guddal, Port Jeuno I-7: 148,000 gil or three beastmen chest keys',
        'Allows travel on the Jeuno-to-Kazham airship route.',
        'Kazham_Airship_Pass',
    },
    {
        'chocobo_license', 138, 'Chocobo License', 'chocobo license',
        'travel_services', "Quest: Chocobo's Wounds (level 20+)",
        'Allows eligible characters to rent chocobos without the unlicensed restrictions.',
        'Chocobo_License',
    },
    {
        'boarding_permit', 781, 'Boarding Permit', 'boarding permit',
        'travel_services', 'Quest: The Road to Aht Urhgan',
        'Allows passage from Mhaura to Aht Urhgan.',
        'Boarding_Permit',
    },
    {
        'holla_gate_crystal', 352, 'Holla Gate Crystal', 'Holla gate crystal',
        'gate_crystals', 'Check the Telepoint at the Crag of Holla',
        'Required for Teleport-Holla travel to La Theine Plateau.',
        'Holla_Gate_Crystal',
    },
    {
        'dem_gate_crystal', 353, 'Dem Gate Crystal', 'Dem gate crystal',
        'gate_crystals', 'Check the Telepoint at the Crag of Dem',
        'Required for Teleport-Dem travel to Konschtat Highlands.',
        'Dem_Gate_Crystal',
    },
    {
        'mea_gate_crystal', 354, 'Mea Gate Crystal', 'Mea gate crystal',
        'gate_crystals', 'Check the Telepoint at the Crag of Mea',
        'Required for Teleport-Mea travel to Tahrongi Canyon.',
        'Mea_Gate_Crystal',
    },
    {
        'vahzl_gate_crystal', 355, 'Vahzl Gate Crystal', 'Vahzl gate crystal',
        'gate_crystals', 'Check the Glowing Telepoint in Xarcabard at H-8',
        'Required for Teleport-Vahzl travel to Xarcabard.',
        'Vahzl_Gate_Crystal',
    },
    {
        'yhoator_gate_crystal', 356, 'Yhoator Gate Crystal',
        'Yhoator gate crystal', 'gate_crystals',
        'Check the Glowing Telepoint in Yhoator Jungle at F-9',
        'Required for Teleport-Yhoat travel to Yhoator Jungle.',
        'Yhoator_Gate_Crystal',
    },
    {
        'altepa_gate_crystal', 357, 'Altepa Gate Crystal', 'Altepa gate crystal',
        'gate_crystals',
        'Check the Glowing Telepoint in Eastern Altepa Desert at G-7',
        'Required for Teleport-Altep travel to Eastern Altepa Desert.',
        'Altepa_Gate_Crystal',
    },
    {
        'shrouded_sand', 492, 'Vial of Shrouded Sand', 'vial of shrouded sand', 'dynamis',
        'Level 65+, nation mission 5-2 complete: Xarcabard cutscene, then city Trail Markings.',
        'Permanent Dynamis prerequisite; other entry requirements still apply.', 'Vial_of_Shrouded_Sand',
    },
    {
        'hydra_scepter', 486, 'Hydra Corps Command Scepter', 'Hydra Corps Command Scepter', 'dynamis',
        "Defeat Overlord's Tombstone in Dynamis - San d'Oria.",
        'One of four city-clear items required for Dynamis - Beaucedine.', 'Hydra_Corps_Command_Scepter',
    },
    {
        'hydra_eyeglass', 487, 'Hydra Corps Eyeglass', 'Hydra Corps Eyeglass', 'dynamis',
        "Defeat Gu'Dha Effigy in Dynamis - Bastok.",
        'One of four city-clear items required for Dynamis - Beaucedine.', 'Hydra_Corps_Eyeglass',
    },
    {
        'hydra_lantern', 488, 'Hydra Corps Lantern', 'Hydra Corps Lantern', 'dynamis',
        'Defeat Tzee Xicu Idol in Dynamis - Windurst.',
        'One of four city-clear items required for Dynamis - Beaucedine.', 'Hydra_Corps_Lantern',
    },
    {
        'hydra_map', 489, 'Hydra Corps Tactical Map', 'Hydra Corps Tactical Map', 'dynamis',
        'Defeat Goblin Golem in Dynamis - Jeuno.',
        'One of four city-clear items required for Dynamis - Beaucedine.', 'Hydra_Corps_Tactical_Map',
    },
    {
        'hydra_insignia', 490, 'Hydra Corps Insignia', 'Hydra Corps Insignia', 'dynamis',
        'Defeat Angra Mainyu in Dynamis - Beaucedine.',
        'Permanent prerequisite for Dynamis - Xarcabard; other entry requirements still apply.', 'Hydra_Corps_Insignia',
    },
    {
        'moongate_pass', 485, 'Moongate Pass', 'moongate pass', 'dungeon_access',
        'Moongate Pass Quest.',
        'Opens the moongates without waiting for a full moon.', 'Moongate_Pass',
    },
    {
        'portal_charm', 195, 'Portal Charm', 'portal charm', 'dungeon_access',
        'Give Kupipi a Rolanberry after Windurst mission 3-2.',
        'Opens the Three Mage Gate without needing three mages.', 'Portal_Charm',
    },
};

access_travel_data.views = {
    { id = 'all', name = 'All Unlocks' },
    { id = 'travel_services', name = 'Travel Services', access_group = 'travel_services' },
    { id = 'gate_crystals', name = 'Gate Crystals', access_group = 'gate_crystals' },
    { id = 'dynamis', name = 'Dynamis', access_group = 'dynamis' },
    { id = 'dungeon_access', name = 'Dungeon Access', access_group = 'dungeon_access' },
};

access_travel_data.entries = {};
for _, specification in ipairs(specifications) do
    access_travel_data.entries[#access_travel_data.entries + 1] = {
        id = 'access_travel.' .. specification[1],
        kind = 'key_item',
        access_unlock = true,
        resource_id = specification[2],
        name = specification[3],
        resource_name = specification[4],
        access_group = specification[5],
        acquisition_method = specification[6],
        travel_use = specification[7],
        availability = 'wiki_listed',
        description = specification[7]
            .. ' Ownership is read from the character key-item log.',
        source_url = 'https://horizonffxi.wiki/' .. specification[8],
    };
end

return access_travel_data;
