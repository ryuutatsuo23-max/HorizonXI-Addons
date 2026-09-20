string.fmt = string.format;
package.path = 'HXIChecklist/?.lua;' .. package.path;

local checklist_ui = require('checklist_ui');
local exporter = require('exporter');

local function summary()
    return { complete = 0, known_total = 0, unknown = 0, unavailable = 0 };
end

local snapshot = { categories = {
    {
        id = 'magic_skills', name = 'Magic Skills', summary = summary(),
        views = {
            { id = 'all_magic', name = 'All Magic' },
            { id = 'dark_magic', name = 'Dark Magic', magic_skill = 'dark_magic' },
        },
        entries = {
            { id = 'spell.1', state = 'missing', name = 'Drain', magic_skill = 'dark_magic',
                job_levels = 'DRK Lv.10', source_url = 'https://example.test/drain' },
            { id = 'spell.2', state = 'complete', name = 'Cure', magic_skill = 'healing_magic',
                job_levels = 'WHM Lv.1', source_url = 'https://example.test/cure' },
        },
    },
    {
        id = 'maps', name = 'Maps', summary = summary(),
        views = {
            { id = 'all_maps', name = 'All Maps' },
            { id = 'original', name = 'Original Areas', map_catalog = 'original' },
        },
        entries = {
            { id = 'map.one', state = 'complete', name = 'Map One', map_catalog = 'original',
                vendor_cost = '600 gil', source_url = 'https://example.test/map' },
        },
    },
    {
        id = 'bastok_quests', name = 'Bastok Quests', summary = summary(),
        views = { { id = 'all', name = 'All Locations' } },
        entries = {
            { id = 'q.done', state = 'auto_complete', name = 'Finished Quest',
                quest_location = 'Bastok Mines', quest_type = 'General', fame_level = 2,
                npc = 'Done NPC', npc_coordinates = 'A-1', rewards = 'Reward',
                prerequisites = 'None', source_url = 'https://example.test/done' },
            { id = 'q.current', state = 'auto_current', name = 'Current Quest',
                quest_location = 'Bastok Markets', quest_type = 'Map', fame_level = 3,
                npc = 'Current NPC', npc_coordinates = 'B-2', rewards = 'Map',
                prerequisites = 'Quest', source_url = 'https://example.test/current' },
            { id = 'q.open', state = 'auto_not_logged', name = 'Open Quest',
                quest_location = 'Port Bastok', quest_type = 'General', fame_label = 'Not listed',
                source_url = 'https://example.test/open' },
            { id = 'q.unknown', state = 'unknown', name = 'Unknown Quest',
                quest_location = 'Bastok', quest_type = 'Unknown' },
        },
    },
    {
        id = 'bastok_missions', name = 'Bastok Missions', mission_area = 'bastok',
        summary = summary(), views = { { id = 'all', name = 'All Ranks' } },
        entries = {
            { id = 'm.current', state = 'mission_current', mission_number = '3-1',
                name = 'Current Mission', mission_rank = 3, mission_type = 'Quest',
                source_url = 'https://example.test/mission' },
            { id = 'm.open', state = 'mission_not_current', mission_number = '3-2',
                name = 'Other Mission', mission_rank = 3, mission_type = 'Fight' },
        },
    },
} };

local settings = { show_completed = true, show_active = true, show_open = true,
    show_unknown = false, show_unavailable = false };
local ui_state = {
    active_tab = 'quests', search = { '' }, selected_views = {},
    selected_quest_area = 'bastok_quests', selected_quest_types = {},
};
local skill_snapshot = { entries = {
    { name = 'Dark Magic', value = 42, capped = false },
    { name = 'Singing', value = 0, capped = true },
} };

local data = checklist_ui.build_export(snapshot, skill_snapshot, settings, ui_state);
assert(data.label == 'Quests - Bastok' and #data.rows == 3);
assert(data.headers[1] == 'Status' and data.rows[1][1] == 'Completed');
assert(data.rows[2][1] == 'Accepted' and data.rows[2][6] == 'Fame 3');
ui_state.accepted_only = true;
data = checklist_ui.build_export(snapshot, skill_snapshot, settings, ui_state);
assert(#data.rows == 1 and data.rows[1][2] == 'Current Quest');
ui_state.accepted_only = false;
settings.show_active = false;
data = checklist_ui.build_export(snapshot, skill_snapshot, settings, ui_state);
assert(#data.rows == 2 and data.rows[1][2] == 'Finished Quest'
    and data.rows[2][2] == 'Open Quest');
settings.show_active = true; settings.show_open = false;
data = checklist_ui.build_export(snapshot, skill_snapshot, settings, ui_state);
assert(#data.rows == 2 and data.rows[1][2] == 'Finished Quest'
    and data.rows[2][2] == 'Current Quest');
settings.show_completed = false;
data = checklist_ui.build_export(snapshot, skill_snapshot, settings, ui_state);
assert(#data.rows == 1 and data.rows[1][2] == 'Current Quest');
settings.show_completed = true; settings.show_open = true;

ui_state.active_tab = 'missions'; ui_state.mission_current_only = true;
data = checklist_ui.build_export(snapshot, skill_snapshot, settings, ui_state);
assert(#data.rows == 1 and data.rows[1][2] == '3-1' and data.rows[1][5] == 'Rank 3');

ui_state.active_tab = 'magic_skills'; ui_state.selected_views.magic_skills = 2;
data = checklist_ui.build_export(snapshot, skill_snapshot, settings, ui_state);
assert(#data.rows == 1 and data.rows[1][3] == 'Dark Magic');

ui_state.active_tab = 'maps'; ui_state.selected_views.maps = 2;
data = checklist_ui.build_export(snapshot, skill_snapshot, settings, ui_state);
assert(#data.rows == 1 and data.rows[1][3] == 'Original Areas' and data.rows[1][4] == '600 gil');

ui_state.active_tab = 'skill_levels';
data = checklist_ui.build_export(snapshot, skill_snapshot, settings, ui_state);
assert(#data.rows == 2 and data.rows[1][3] == 'Training' and data.rows[2][3] == 'Capped');

local content = exporter.serialize({ headers = { 'One', 'Two' }, rows = { { 'a\tb', 'line\nbreak' } } });
assert(content == 'One\tTwo\r\na b\tline break\r\n');
assert(exporter.serialize({ headers = {}, rows = {} }) == nil);

print('visible tab exports, active filters, spreadsheet columns, and TSV sanitation passed');
