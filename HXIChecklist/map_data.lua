local map_data = {};

local category_source_url = 'https://horizonffxi.wiki/Category:Magical_Maps';
local vendor_source_url = 'https://horizonffxi.wiki/Map_Guide';

-- Vendor prices are a separate sourced data set from the Map Guide's
-- Purchased tables. An absent key means the guide does not list a vendor sale;
-- it never means that the map costs zero.
local vendor_costs = {
    ['map.san_doria'] = '200 gil',
    ['map.bastok'] = '200 gil',
    ['map.windurst'] = '200 gil',
    ['map.jeuno'] = '600 gil',
    ['map.qufim_island'] = '3,000 gil',
    ['map.zeruhn'] = '200 gil',
    ['map.ordelles_caves'] = '600 gil',
    ['map.maze_of_shakhrami'] = '600 gil',
    ['map.eldieme_necropolis'] = '3,000 gil',
    ['map.garlaige_citadel'] = '3,000 gil',
    ['map.ghelsba'] = '600 gil',
    ['map.davoi'] = '3,000 gil',
    ['map.palborough'] = '600 gil',
    ['map.beadeaux'] = '3,000 gil',
    ['map.giddeus'] = '600 gil',
    ['map.castle_oztroja'] = '3,000 gil',
    ['map.elshimo_regions'] = '3,000 gil',
    ['map.kuzotz_region'] = '3,000 gil',
    ['map.litelor_region'] = '3,000 gil',
    ['map.korroloka_tunnel'] = '3,000 gil',
    ['map.vollbow_region'] = '3,000 gil',
    ['map.carpenters_landing'] = '3,000 gil',
    ['map.bibiki_bay'] = '3,000 gil',
    ['map.al_zahbi'] = '600 gil',
    ['map.nashmau'] = '3,000 gil',
    ['map.bhaflau_thickets'] = '3,000 gil',
    ['map.wajaom_woodlands'] = '3,000 gil',
    ['map.mamook'] = '2,000 Imperial Standing',
    ['map.arrapago_reef'] = '2,000 Imperial Standing',
    ['map.halvung'] = '2,000 Imperial Standing',
};

-- Each row is:
-- stable addon ID, client key-item ID, display name, client resource name,
-- individual HorizonXI Wiki slug when a usable page exists.
-- A nil slug deliberately links the row to the sourced category table instead
-- of pretending that a red-link page is an individual source.
local catalogs = {
    {
        id = 'original_areas',
        name = 'Original Areas',
        maps = {
            { 'map.san_doria', 385, "Map of the San d'Oria Area", "map of the San d'Oria area", 'Map_of_the_San_d%27Oria_Area' },
            { 'map.bastok', 386, 'Map of the Bastok Area', 'map of the Bastok area', 'Map_of_the_Bastok_Area' },
            { 'map.windurst', 387, 'Map of the Windurst Area', 'map of the Windurst area', 'Map_of_the_Windurst_Area' },
            { 'map.jeuno', 388, 'Map of the Jeuno Area', 'map of the Jeuno area' },
            { 'map.qufim_island', 389, 'Map of Qufim Island', 'map of Qufim Island', 'Map_of_Qufim_Island' },
            { 'map.northlands', 390, 'Map of the Northlands Area', 'map of the Northlands area' },
            { 'map.king_ranperres_tomb', 391, "Map of King Ranperre's Tomb", "map of King Ranperre's Tomb" },
            { 'map.dangruf_wadi', 392, 'Map of the Dangruf Wadi', 'map of the Dangruf Wadi', 'Map_of_the_Dangruf_Wadi' },
            { 'map.horutoto_ruins', 393, 'Map of the Horutoto Ruins', 'map of the Horutoto Ruins', 'Map_of_the_Horutoto_Ruins' },
            { 'map.bostaunieux_oubliette', 394, 'Map of Bostaunieux Oubliette', 'map of Bostaunieux Oubliette', 'Map_of_Bostaunieux_Oubliette' },
            { 'map.zeruhn', 395, 'Map of the Zeruhn Mines', 'map of the Zeruhn Mines', 'Map_of_the_Zeruhn_Mines' },
            { 'map.toraimarai_canal', 396, 'Map of the Toraimarai Canal', 'map of the Toraimarai Canal', 'Map_of_the_Toraimarai_Canal' },
            { 'map.ordelles_caves', 397, "Map of Ordelle's Caves", "map of Ordelle's Caves" },
            { 'map.gusgen_mines', 398, 'Map of the Gusgen Mines', 'map of the Gusgen Mines', 'Map_of_the_Gusgen_Mines' },
            { 'map.maze_of_shakhrami', 399, 'Map of the Maze of Shakhrami', 'map of the Maze of Shakhrami' },
            { 'map.eldieme_necropolis', 400, 'Map of the Eldieme Necropolis', 'map of the Eldieme Necropolis', 'Map_of_the_Eldieme_Necropolis' },
            { 'map.crawlers_nest', 401, "Map of the Crawlers' Nest", "map of the Crawlers' Nest", 'Map_of_the_Crawlers%27_Nest' },
            { 'map.garlaige_citadel', 402, 'Map of the Garlaige Citadel', 'map of the Garlaige Citadel', 'Map_of_the_Garlaige_Citadel' },
            { 'map.ranguemont_pass', 403, 'Map of the Ranguemont Pass', 'map of the Ranguemont Pass', 'Map_of_the_Ranguemont_Pass' },
            { 'map.ghelsba', 404, 'Map of Ghelsba', 'map of Ghelsba' },
            { 'map.davoi', 405, 'Map of Davoi', 'map of Davoi' },
            { 'map.palborough', 406, 'Map of the Palborough Mines', 'map of the Palborough Mines', 'Map_of_the_Palborough_Mines' },
            { 'map.beadeaux', 407, 'Map of Beadeaux', 'map of Beadeaux' },
            { 'map.giddeus', 408, 'Map of Giddeus', 'map of Giddeus', 'Map_of_Giddeus' },
            { 'map.castle_oztroja', 409, 'Map of Castle Oztroja', 'map of Castle Oztroja', 'Map_of_Castle_Oztroja' },
            { 'map.delkfutts_tower', 410, "Map of Delkfutt's Tower", "map of Delkfutt's Tower" },
            { 'map.feiyin', 411, "Map of Fei'Yin", "map of Fei'Yin", 'Map_of_Fei%27Yin' },
            { 'map.castle_zvahl', 412, 'Map of Castle Zvahl', 'map of Castle Zvahl', 'Map_of_Castle_Zvahl' },
        },
    },
    {
        id = 'rise_of_the_zilart',
        name = 'Rise of the Zilart',
        maps = {
            { 'map.elshimo_regions', 413, 'Map of the Elshimo Regions', 'map of the Elshimo regions', 'Map_of_the_Elshimo_Regions' },
            { 'map.kuzotz_region', 414, 'Map of the Kuzotz Region', 'map of the Kuzotz region', 'Map_of_the_Kuzotz_Region' },
            { 'map.litelor_region', 415, "Map of the Li'Telor Region", "map of the Li'Telor region" },
            { 'map.ruaun_gardens', 416, "Map of the Ru'Aun Gardens", "map of the Ru'Aun Gardens", 'Map_of_the_Ru%27Aun_Gardens' },
            { 'map.norg', 417, 'Map of Norg', 'map of Norg', 'Map_of_Norg' },
            { 'map.temple_of_uggalepih', 418, 'Map of the Temple of Uggalepih', 'map of Temple of Uggalepih' },
            { 'map.den_of_rancor', 419, 'Map of the Den of Rancor', 'map of the Den of Rancor', 'Map_of_the_Den_of_Rancor' },
            { 'map.korroloka_tunnel', 420, 'Map of the Korroloka Tunnel', 'map of the Korroloka Tunnel' },
            { 'map.kuftal_tunnel', 421, 'Map of the Kuftal Tunnel', 'map of the Kuftal Tunnel', 'Map_of_the_Kuftal_Tunnel' },
            { 'map.boyahda_tree', 422, 'Map of the Boyahda Tree', 'map of the Boyahda Tree', 'Map_of_the_Boyahda_Tree' },
            { 'map.velugannon_palace', 423, "Map of the Ve'Lugannon Palace", "map of Ve'Lugannon Palace", 'Map_of_the_Ve%27Lugannon_Palace' },
            { 'map.ifrits_cauldron', 424, "Map of Ifrit's Cauldron", "map of Ifrit's Cauldron", 'Map_of_Ifrit%27s_Cauldron' },
            { 'map.quicksand_caves', 425, 'Map of the Quicksand Caves', 'map of the Quicksand Caves', 'Map_of_the_Quicksand_Caves' },
            { 'map.sea_serpent_grotto', 426, 'Map of Sea Serpent Grotto', 'map of Sea Serpent Grotto', 'Map_of_Sea_Serpent_Grotto' },
            { 'map.vollbow_region', 427, 'Map of the Vollbow Region', 'map of the Vollbow region', 'Map_of_the_Vollbow_Region' },
            { 'map.labyrinth_of_onzozo', 428, 'Map of the Labyrinth of Onzozo', 'map of Labyrinth of Onzozo', 'Map_of_the_Labyrinth_of_Onzozo' },
        },
    },
    {
        id = 'chains_of_promathia',
        name = 'Chains of Promathia',
        maps = {
            { 'map.carpenters_landing', 429, "Map of Carpenters' Landing", "map of Carpenters' Landing" },
            { 'map.bibiki_bay', 430, 'Map of Bibiki Bay', 'map of Bibiki Bay' },
            { 'map.attohwa_chasm', 432, 'Map of the Attohwa Chasm', 'map of the Attohwa Chasm', 'Map_of_the_Attohwa_Chasm' },
            { 'map.psoxja', 433, "Map of Pso'Xja", "map of Pso'Xja", 'Map_of_Pso%27Xja' },
            { 'map.oldton_movalpolos', 434, 'Map of Oldton Movalpolos', 'map of Oldton Movalpolos', 'Map_of_Oldton_Movalpolos' },
            { 'map.newton_movalpolos', 435, 'Map of Newton Movalpolos', 'map of Newton Movalpolos', 'Map_of_Newton_Movalpolos' },
            { 'map.promyvion_holla', 436, 'Map of Promyvion - Holla', 'map of Promyvion - Holla' },
            { 'map.promyvion_dem', 437, 'Map of Promyvion - Dem', 'map of Promyvion - Dem' },
            { 'map.promyvion_mea', 438, 'Map of Promyvion - Mea', 'map of Promyvion - Mea' },
            { 'map.promyvion_vahzl', 439, 'Map of Promyvion - Vahzl', 'map of Promyvion - Vahzl' },
            { 'map.tavnazia', 440, 'Map of Tavnazia', 'map of Tavnazia', 'Map_of_Tavnazia' },
            { 'map.aqueducts', 441, 'Map of the Aqueducts', 'map of the Aqueducts' },
            { 'map.sacrarium', 442, 'Map of the Sacrarium', 'map of the Sacrarium', 'Map_of_the_Sacrarium' },
            { 'map.cape_riverne', 443, 'Map of Cape Riverne', 'map of Cape Riverne' },
            { 'map.altaieu', 444, "Map of Al'Taieu", "map of Al'Taieu" },
            { 'map.huxzoi', 445, "Map of Hu'Xzoi", "map of Hu'Xzoi" },
            { 'map.ruhmet', 446, "Map of Ru'Hmet", "map of Ru'Hmet", 'Map_of_Ru%27Hmet' },
        },
    },
    {
        id = 'treasures_of_aht_urhgan',
        name = 'Treasures of Aht Urhgan',
        maps = {
            { 'map.al_zahbi', 1856, 'Map of Al Zahbi', 'map of Al Zahbi' },
            { 'map.nashmau', 1857, 'Map of Nashmau', 'map of Nashmau' },
            { 'map.wajaom_woodlands', 1858, 'Map of Wajaom Woodlands', 'map of Wajaom Woodlands' },
            { 'map.caedarva_mire', 1859, 'Map of Caedarva Mire', 'map of Caedarva Mire' },
            { 'map.mount_zhayolm', 1860, 'Map of Mount Zhayolm', 'map of Mount Zhayolm' },
            { 'map.aydeewa_subterrane', 1861, 'Map of Aydeewa Subterrane', 'map of Aydeewa Subterrane' },
            { 'map.mamook', 1862, 'Map of Mamook', 'map of Mamook' },
            { 'map.halvung', 1863, 'Map of Halvung', 'map of Halvung' },
            { 'map.arrapago_reef', 1864, 'Map of Arrapago Reef', 'map of Arrapago Reef' },
            { 'map.alzadaal_ruins', 1865, "Map of Alza'daal Ruins", 'map of Alzadaal Ruins' },
            { 'map.bhaflau_thickets', 1874, 'Map of Bhaflau Thickets', 'map of Bhaflau Thickets' },
        },
    },
};

map_data.views = {
    { id = 'all_maps', name = 'All Maps' },
};
map_data.entries = {};
map_data.counts = {};

for _, catalog in ipairs(catalogs) do
    table.insert(map_data.views, {
        id = catalog.id,
        name = catalog.name,
        map_catalog = catalog.id,
    });
    map_data.counts[catalog.id] = #catalog.maps;

    for _, map in ipairs(catalog.maps) do
        table.insert(map_data.entries, {
            id = map[1],
            kind = 'key_item',
            name = map[3],
            resource_name = map[4],
            resource_id = map[2],
            map_catalog = catalog.id,
            availability = 'wiki_listed',
            description = ('Map key item listed in the HorizonXI Magical Maps table (%s).'):fmt(catalog.name),
            source_url = map[5] ~= nil
                and ('https://horizonffxi.wiki/' .. map[5])
                or category_source_url,
            category_source_url = category_source_url,
            vendor_cost = vendor_costs[map[1]],
            vendor_source_url = vendor_costs[map[1]] ~= nil
                and vendor_source_url or nil,
        });
    end
end

table.sort(map_data.entries, function(left, right)
    return left.name:lower() < right.name:lower();
end);

return map_data;
