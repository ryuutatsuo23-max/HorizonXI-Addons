string.fmt = string.format;
bit = { bor = function() return 0 end };
local ui = dofile('HXIChecklist/checklist_ui.lua');
local summary = { complete = 1, known_total = 3, unknown = 0, unavailable = 0 };
local category = {
    id = 'weapon_skills', name = 'Weapon Skills', description = 'Synthetic weapon skills.',
    summary = summary, counts_toward_profile = false,
    views = {
        { id = 'all', name = 'All Weapon Types' },
        { id = 'hand_to_hand', name = 'Hand-to-Hand', weapon_type = 'Hand-to-Hand' },
    },
    entries = {
        { id = 'weapon_skill.asuran_fists', kind = 'weapon_skill', state = 'auto_complete',
            state_label = 'Unlocked', name = 'Asuran Fists', weapon_type = 'Hand-to-Hand',
            unlock_quest = 'The Walls of Your Mind', npc = 'Oggbi',
            quest_location = 'Port Bastok', npc_coordinates = 'E-6',
            rewards = 'Asuran Fists', prerequisites = 'Monk level 71',
            availability = 'wiki_listed', source_url = 'https://example.test/asuran' },
        { id = 'weapon_skill.evisceration', kind = 'weapon_skill', state = 'auto_current',
            state_label = 'In progress', name = 'Evisceration', weapon_type = 'Dagger',
            unlock_quest = 'Cloak and Dagger', availability = 'wiki_listed',
            source_url = 'https://example.test/evisceration' },
        { id = 'weapon_skill.savage_blade', kind = 'weapon_skill', state = 'auto_not_logged',
            state_label = 'Locked', name = 'Savage Blade', weapon_type = 'Sword',
            unlock_quest = 'Old Wounds', availability = 'wiki_listed',
            source_url = 'https://example.test/savage' },
    },
};
local snapshot = { categories = { category }, summary = summary };
local settings = { scale_percent = 100, show_completed = true, show_active = true,
    show_open = true, show_unknown = true, show_unavailable = true };
local state = { window_open = { true }, search = { '' }, selected_views = {},
    active_tab = 'weapon_skills' };
local seen = { tabs = {}, tables = {}, columns = {}, texts = {} };
local current_id;
local imgui = setmetatable({
    Begin = function() return true end,
    BeginTabBar = function() return true end,
    BeginTabItem = function(name)
        seen.tabs[#seen.tabs + 1] = name;
        return name == 'Others/Key Items' or name == 'Weapon Skills';
    end,
    BeginCombo = function() return false end,
    BeginTable = function(id) seen.tables[id] = true; return true end,
    TableSetupColumn = function(name) seen.columns[name] = true end,
    PushID = function(id) current_id = id end,
    SmallButton = function(label) return current_id == 'weapon_skill.asuran_fists'
        and label:find('##weapon_skill_details', 1, true) ~= nil end,
    Text = function(value) seen.texts[value] = true end,
    TextWrapped = function(value) seen.texts[value] = true end,
    TextColored = function(_, value) seen.texts[value] = true end,
    GetWindowWidth = function() return 760 end,
    CalcTextSize = function(value) return #value * 7 end,
    GetFontSize = function() return 12 end,
    IsItemHovered = function() return false end,
}, { __index = function() return function() return false end end });
local actions = setmetatable({}, { __index = function()
    return function() error('Rendering weapon skills must not change state.') end;
end });
ui.render({ version = 'test', scope_note = 'test' }, snapshot, { entries = {} },
    settings, state, actions, imgui);
assert(table.concat(seen.tabs, '|') ==
    'Quests|Missions|Magic Skills|Crafting|Others/Key Items|Weapon Skills|Skill Levels');
assert(seen.tables['##WeaponSkillRows']);
assert(seen.columns['Weapon Skill'] and seen.columns.Source
    and seen.columns['Weapon / Unlock Quest']);
assert(seen.texts['[Unlocked]'] and seen.texts['[In progress]'] and seen.texts['[Locked]']);
assert(seen.texts['Asuran Fists'] and seen.texts['Hand-to-Hand / The Walls of Your Mind']);
assert(seen.texts['NPC: Oggbi'] and seen.texts['Location: Port Bastok']);

local exported = ui.build_export(snapshot, { entries = {} }, settings, state);
assert(exported.label == 'Weapon Skills' and exported.file_label == 'weapon-skills-all');
assert(#exported.rows == 3 and #exported.headers == 10);
assert(exported.rows[1][1] == 'Unlocked' and exported.rows[1][3] == 'Hand-to-Hand');
settings.show_completed = false;
exported = ui.build_export(snapshot, { entries = {} }, settings, state);
assert(#exported.rows == 2 and exported.rows[1][1] == 'In progress');
print('weapon-skill table, expansion, filters, and export passed');
