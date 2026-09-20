-- HorizonXI craft-category Guild Test Items tables, reviewed 2026-09-08.
-- Index and rank numbering follow the Ashita v4 SDK, not combat-skill IDs.
local data = {};
data.ranks = { [0] = 'Amateur', 'Recruit', 'Initiate', 'Novice', 'Apprentice',
    'Journeyman', 'Craftsman', 'Artisan', 'Adept', 'Veteran' };
data.crafts = {
    { index = 0, name = 'Fishing', items = {
        'Moat Carp', 'Cheval Salmon', 'Giant Catfish', 'Gugru Tuna', 'Monke-Onke',
        'Bhefhel Marlin', 'Bladefish', 'Three-eyed Fish', 'Gigant Squid' } },
    { index = 1, name = 'Woodworking', items = {
        'Workbench', 'Maple Table', 'Harp', 'Traversiere', 'Rose Wand',
        'Kaman', 'Ebony Wand', 'Commode', 'Mythic Pole' } },
    { index = 2, name = 'Smithing', items = {
        'Xiphos', 'Aspis', 'Bilbo', 'War Pick', 'Mythril Pick',
        'Darksteel Falchion', 'Bascinet', 'Bastard Sword', 'Celata' } },
    { index = 3, name = 'Goldsmithing', items = {
        'Copper Hairpin', 'Brass Hairpin', 'Silver Hairpin', 'Chain Gorget', 'Mythril Ring',
        'Mythril Gorget', 'Mythril Breastplate', 'Torque', 'Colichemarde' } },
    { index = 4, name = 'Clothcraft', items = {
        'Cape', 'Cotton Cape', 'Heko Obi', 'Feather Collar', 'Wool Bracers',
        'Red Cape', 'Wool Doublet', 'Silk Cloak', "Arhat's Hakama" } },
    { index = 5, name = 'Leathercraft', items = {
        'Rabbit Mantle', 'Lizard Cesti', 'Dhalmel Mantle', 'Magic Belt', 'Cuir Bouilli',
        'Raptor Jerkin', 'Battle Boots', 'Tiger Gloves', 'Coeurl Mask' } },
    { index = 6, name = 'Bonecraft', items = {
        'Shell Ring', 'Bone Ring', 'Beetle Earring', 'Horn Ring', 'Carapace Gorget',
        'Astragalos', 'Bone Patas', 'Coral Hairpin', 'Coral Bangles' } },
    { index = 7, name = 'Alchemy', items = {
        'Animal Glue', 'Poison Potion', 'Blinding Potion', 'Firesand', 'Fire Sword',
        'Hi-Potion', 'Acid Kukri', 'X-Potion', 'Bloody Sword' } },
    { index = 8, name = 'Cooking', items = {
        'Salmon Sub Sandwich', 'Pea Soup', 'Vegetable Gruel', 'Meat Mithkabob', 'Apple Pie',
        'Yagudo Drink', 'Raisin Bread', 'Whitefish Stew', 'Seafood Stew' } },
};
for _, craft in ipairs(data.crafts) do
    craft.id = 'craft.' .. craft.name:lower();
    craft.source_url = 'https://horizonffxi.wiki/Category:' .. craft.name .. '#Guild_Test_Items';
end
return data;
