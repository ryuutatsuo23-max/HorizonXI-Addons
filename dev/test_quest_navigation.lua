string.fmt = string.format;
bit = { bor = function() return 0 end };
local ui = dofile('HXIChecklist/checklist_ui.lua');
local state = { window_open = { true }, search = { '' }, selected_views = {} };
local settings = { scale_percent = 100, show_completed = true, show_unknown = true };
local summary = { complete = 1, known_total = 2, unknown = 0, unavailable = 0 };
local function category(id, name, location)
    return {
        id = id, name = name, description = name .. ' description', summary = summary,
        views = { { id = 'all', name = 'All Quests' },
            { id = 'local', name = location, quest_location = location } },
        entries = { { id = id .. '.one', name = name .. ' row', state = 'auto_current',
            quest_location = location, fame_level = 2, source_url = 'https://example.test' } },
    };
end
local categories = {
    { id = 'magic_skills', name = 'Magic Skills', summary = summary, entries = {},
        views = { { id = 'all', name = 'All Magic' } } },
    { id = 'maps', name = 'Maps', summary = summary, entries = {} },
    category('bastok_quests', 'Bastok Quests', 'Bastok Markets'),
    category('sandoria_quests', "San d'Oria Quests", "Northern San d'Oria"),
    category('windurst_quests', 'Windurst Quests', 'Windurst Woods'),
    category('jeuno_quests', 'Jeuno Quests', 'Lower Jeuno'),
};
local snapshot = { categories = categories, summary = summary };
local function frame(area_choice, location_choice, active_tab)
    local seen = { tabs = {}, combos = {}, texts = {}, tables = {}, columns = {} };
    local current_combo;
    local imgui = setmetatable({
        Begin = function() return true end,
        BeginTabBar = function() return true end,
        BeginTabItem = function(name)
            seen.tabs[#seen.tabs + 1] = name;
            return name == (active_tab or 'Quests');
        end,
        BeginCombo = function(label, preview)
            current_combo = label;
            seen.combos[label] = preview;
            return true;
        end,
        Selectable = function(label)
            if current_combo == 'Area##QuestArea' then
                return area_choice ~= nil and label:find('##' .. area_choice, 1, true) ~= nil;
            end
            return location_choice ~= nil and label:find('##' .. location_choice, 1, true) ~= nil;
        end,
        Text = function(value) seen.texts[value] = true end,
        TextWrapped = function(value) seen.texts[value] = true end,
        TextColored = function(_, value) seen.texts[value] = true end,
        GetWindowWidth = function() return 760 end,
        CalcTextSize = function() return 40 end,
        BeginTable = function(id) seen.tables[id] = true; return true end,
        TableSetupColumn = function(name) seen.columns[name] = true end,
    }, { __index = function() return function() return false end end });
    local actions = setmetatable({}, { __index = function()
        return function() error('Navigation must not save or refresh character state') end;
    end });
    ui.render({ version = 'test', scope_note = 'test' }, snapshot, { entries = {} },
        settings, state, actions, imgui);
    assert(table.concat(seen.tabs, '|') == 'Magic Skills|Maps|Quests|Skill Levels');
    return seen;
end

local first = frame();
assert(state.selected_quest_area == 'bastok_quests');
assert(first.combos['Location##bastok_quests'] == 'All Locations');
assert(first.columns['Bastok Fame']);
frame(nil, 'local');
assert(state.selected_views.bastok_quests == 2);
local windurst = frame('windurst_quests', 'local');
assert(state.selected_quest_area == 'windurst_quests');
assert(state.selected_views.windurst_quests == 2);
assert(windurst.columns['Windurst Fame']);
assert(windurst.texts['Windurst Quests description']);
assert(windurst.tables['##windurst_questsRows']);
local back = frame('bastok_quests');
assert(back.combos['Location##bastok_quests'] == 'Bastok Markets');
assert(state.selected_views.windurst_quests == 2);
local sandoria = frame('sandoria_quests');
assert(sandoria.combos['Location##sandoria_quests'] == 'All Locations');
assert(sandoria.columns["San d'Oria Fame"]);
local jeuno = frame('jeuno_quests', 'local');
assert(state.selected_quest_area == 'jeuno_quests');
assert(jeuno.columns['Jeuno Fame']);
assert(jeuno.tables['##jeuno_questsRows']);
assert(state.selected_views.jeuno_quests == 2);
frame('bastok_quests');
assert(frame('jeuno_quests').combos['Location##jeuno_quests'] == 'Lower Jeuno');
state.selected_quest_area = 'removed_area';
frame();
assert(state.selected_quest_area == 'bastok_quests');
local magic = frame(nil, nil, 'Magic Skills');
assert(magic.combos['Category##magic_skills'] == 'All Magic');
assert(categories[3].views[1].name == 'All Quests');
assert(snapshot.summary == summary and summary.known_total == 2);
print('quest navigation fixture passed');
