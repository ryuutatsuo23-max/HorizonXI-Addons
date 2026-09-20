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
    category('other_quests', 'Other Quests', 'Selbina'),
    category('outlands_quests', 'Outlands Quests', 'Norg'),
    category('ahturhgan_quests', 'Aht Urhgan Quests', 'Aht Urhgan Whitegate'),
    category('custom_quests', 'Horizon Custom Quests', 'Windurst Woods'),
    { id = 'blue_magic', name = 'Blue Magic', summary = summary, entries = {},
        views = { { id = 'all', name = 'All Levels' } } },
};
categories[7].entries[1].fame_region = 'Selbina';
categories[8].entries[1].fame_region = 'Norg';
categories[9].entries[1].fame_level = nil;
categories[9].entries[1].fame_label = 'N/A';
categories[9].entries[1].fame_note = 'Synthetic Aht Urhgan no-fame explanation.';
categories[10].entries[1].state = 'manual_open';
categories[10].entries[1].fame_level = nil;
categories[10].entries[1].fame_label = 'None';
categories[7].entries[1].fame_note = 'Synthetic Selbina fame note.';
categories[7].entries[2] = { id = 'other.mhaura', name = 'Mhaura row', state = 'auto_current',
    quest_location = 'Mhaura', fame_level = 4, fame_region = 'Mhaura', fame_note = 'Synthetic Mhaura fame note.' };
categories[7].entries[3] = { id = 'other.mog', name = 'Mog House row', state = 'auto_current',
    quest_location = 'Mog House', fame_level = 3, fame_note = 'Synthetic unspecified fame-region note.' };
local snapshot = { categories = categories, summary = summary };
local function frame(area_choice, location_choice, active_tab, hover_fame, toggle_manual, type_choice, window_width, interaction)
    local seen = { tabs = {}, combos = {}, texts = {}, tables = {}, columns = {}, checkboxes = {}, writes = {} };
    local current_combo;
    local current_column;
    local inline_after_location = false;
    local current_id;
    local imgui = setmetatable({
        Begin = function() return true end,
        BeginTabBar = function() return true end,
        BeginTabItem = function(name)
            seen.tabs[#seen.tabs + 1] = name;
            if name == 'Spells' then
                return active_tab == 'Magic Skills';
            end
            if name == 'Blue Magic' then return false end;
            return name == (active_tab or 'Quests');
        end,
        BeginCombo = function(label, preview)
            if label:find('Type##', 1, true) == 1 then
                seen.type_inline = inline_after_location;
            end
            current_combo = label;
            seen.combos[label] = preview;
            return true;
        end,
        Selectable = function(label)
            if current_combo == 'Area##QuestArea' then
                return area_choice ~= nil and label:find('##' .. area_choice, 1, true) ~= nil;
            end
            if current_combo:find('Type##', 1, true) == 1 then
                return label == type_choice;
            end
            return location_choice ~= nil and label:find('##' .. location_choice, 1, true) ~= nil;
        end,
        Text = function(value) seen.texts[value] = true end,
        PushID = function(id) current_id = id end,
        SmallButton = function(label)
            return interaction and interaction.expand == current_id
                and label:find('##quest_details', 1, true) ~= nil;
        end,
        Checkbox = function(label, value)
            if label == 'Accepted only' and interaction and interaction.toggle_accepted then
                value[1] = not value[1];
                return true;
            end
            if label:find('##custom_completion_', 1, true) then
                seen.checkboxes[#seen.checkboxes + 1] = label;
                if toggle_manual then value[1] = not value[1]; return true end;
            end
            return false;
        end,
        TextWrapped = function(value) seen.texts[value] = true end,
        TextColored = function(_, value) seen.texts[value] = true end,
        SameLine = function()
            if current_combo and current_combo:find('Location##', 1, true) == 1 then
                inline_after_location = true;
            end
        end,
        GetWindowWidth = function() return window_width or 760 end,
        CalcTextSize = function(value) return #value * 7 * settings.scale_percent / 100 end,
        GetFontSize = function() return 12 end,
        TableSetColumnIndex = function(index) current_column = index end,
        IsItemHovered = function() return hover_fame and current_column == 2 end,
        BeginTable = function(id) seen.tables[id] = true; return true end,
        TableSetupColumn = function(name) seen.columns[name] = true end,
    }, { __index = function() return function() return false end end });
    local actions = setmetatable({ set_manual_completed = function(id, value)
        assert(toggle_manual, 'Navigation alone must not write manual state');
        seen.writes[#seen.writes + 1] = { id, value };
    end }, { __index = function()
        return function() error('Navigation must not save or refresh character state') end;
    end });
    ui.render({ version = 'test', scope_note = 'test' }, snapshot, { entries = {} },
        settings, state, actions, imgui);
    local expected_tabs = active_tab == 'Magic Skills'
        and 'Quests|Missions|Magic Skills|Spells|All##spell-all|Blue Magic|Crafting|Others/Key Items'
        or 'Quests|Missions|Magic Skills|Crafting|Others/Key Items';
    assert(table.concat(seen.tabs, '|') == expected_tabs);
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
assert(windurst.texts['Windurst Quests (?)']);
assert(not windurst.texts['Windurst Quests description']);
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
local other = frame('other_quests', nil, nil, true);
assert(other.columns['Required Fame'] and not other.columns['Other Areas Fame']);
assert(other.tables['##other_questsRows']);
assert(other.texts['Selbina Fame 2'] and other.texts['Mhaura Fame 4']);
assert(other.texts['Fame 3 (see source)']);
assert(other.texts['Synthetic unspecified fame-region note.']);
local selbina = frame(nil, 'local');
assert(selbina.texts['Selbina Fame 2'] and not selbina.texts['Mhaura Fame 4']);
frame('bastok_quests');
assert(frame('other_quests').combos['Location##other_quests'] == 'Selbina');
assert(frame('bastok_quests').texts['Fame 2'], 'Existing nation formatting stays unchanged.');
state.selected_quest_area = 'removed_area';
local outlands = frame('outlands_quests', 'local');
assert(outlands.columns['Required Fame'] and not outlands.columns['Outlands Fame']);
assert(outlands.tables['##outlands_questsRows']);
assert(outlands.texts['Norg Fame 2']);
frame('other_quests');
assert(frame('outlands_quests').combos['Location##outlands_quests'] == 'Norg');
assert(frame('other_quests').combos['Location##other_quests'] == 'Selbina');
state.selected_quest_area = 'removed_area';
frame();
assert(state.selected_quest_area == 'bastok_quests');
local magic = frame(nil, nil, 'Magic Skills');
local aht = frame('ahturhgan_quests', 'local', nil, true);
assert(aht.columns['Required Fame'] and not aht.columns['Aht Urhgan Fame']);
assert(aht.texts['N/A'] and not aht.texts['Unknown'] and not aht.texts['Fame 2']);
assert(aht.texts['Synthetic Aht Urhgan no-fame explanation.']);
assert(aht.tables['##ahturhgan_questsRows']);
assert(frame('outlands_quests').combos['Location##outlands_quests'] == 'Norg');
assert(frame('ahturhgan_quests').combos['Location##ahturhgan_quests'] == 'Aht Urhgan Whitegate');
assert(frame('bastok_quests').texts['Fame 2'], 'Numeric fame remains unchanged.');
assert(magic.combos['Category##magic_skills'] == nil);
assert(categories[3].views[1].name == 'All Quests');
assert(snapshot.summary == summary and summary.known_total == 2);
print('quest navigation fixture passed');
settings.show_unknown = false;
local custom = frame('custom_quests');
assert(custom.columns['Required Fame'] and custom.tables['##custom_questsRows']);
assert(custom.texts['None'] and custom.texts['[Manual]']);
assert(#custom.checkboxes == 1 and #custom.writes == 0);
local changed = frame(nil, nil, nil, nil, true);
assert(#changed.writes == 1 and changed.writes[1][1] == 'custom_quests.one' and changed.writes[1][2] == true);
categories[10].entries[1].state = 'manual_complete';
assert(frame().texts['[Manual done]']);
settings.show_completed = false;
assert(#frame().checkboxes == 0);
settings.show_completed = true;
local unchecked = frame(nil, nil, nil, nil, true);
assert(unchecked.writes[1][2] == false);
assert(#frame('bastok_quests').checkboxes == 0, 'Mapped quests must never have manual checkboxes.');
print('custom quest UI fixture passed');

-- Type is a view-only, per-area intersection with existing filters.
local function typed_row(name, quest_type, location, row_state)
    return { id = name, name = name, quest_type = quest_type,
        quest_location = location or 'Bastok Markets', state = row_state or 'auto_current',
        fame_level = 1 };
end
categories[3].entries = {
    typed_row('First artifact', 'DRK AF1'), typed_row('Second artifact', 'WAR AF'),
    typed_row('Outside artifact', 'MNK AF3', 'Metalworks'),
    typed_row('Unlock', 'DRK Flag'), typed_row('Map row', 'Map'),
    typed_row('Known untyped', nil), typed_row('Unknown untyped', 'Unknown', nil, 'unknown'),
    typed_row('Completed artifact', 'WAR AF2', nil, 'auto_complete'),
};
local filtered = frame('bastok_quests', 'all', nil, nil, nil, 'Artifact');
assert(filtered.texts['First artifact'] and filtered.texts['Second artifact']);
assert(filtered.texts['Outside artifact'] and not filtered.texts['Unlock']);
assert(filtered.texts['Completed artifact']);
assert(filtered.texts['1/2 complete | 0 unknown | 0 unavailable']);
assert(state.selected_quest_types.bastok_quests == 'Artifact');
local local_only = frame(nil, 'local');
assert(local_only.texts['First artifact'] and not local_only.texts['Outside artifact']);
settings.show_completed = false;
assert(not frame().texts['Completed artifact']);
settings.show_completed = true;
state.search[1] = 'Second';
assert(frame().texts['Second artifact'] and not frame().texts['First artifact']);
state.search[1] = 'nothing matches';
assert(frame().texts['No entries match the current filters.']);
state.search[1] = '';
assert(frame('windurst_quests').combos['Type##windurst_quests'] == 'All Types');
assert(frame('bastok_quests').combos['Type##bastok_quests'] == 'Artifact');
local untyped = frame(nil, nil, nil, nil, nil, 'Unknown Type');
assert(untyped.texts['Known untyped'] and not untyped.texts['Unknown untyped']);
settings.show_unknown = true;
assert(frame().texts['Unknown untyped']);
assert(frame(nil, nil, nil, nil, nil, 'All Types').texts['Map row']);
assert(frame(nil, nil, nil, nil, nil, 'Job Unlock').texts['Unlock']);
state.selected_quest_types.bastok_quests = 'Removed type';
assert(frame().combos['Type##bastok_quests'] == 'All Types');
assert(frame(nil, nil, 'Magic Skills').combos['Type##magic_skills'] == nil);
assert(frame(nil, nil, 'Maps').combos['Type##maps'] == nil);
for raw, label in pairs({ WS = 'Weapon Skill', LB = 'Limit Break', SJ = 'Subjob Unlock',
    RSE = 'Race-specific Equipment', ['Custom quest'] = 'Custom',
    ['Custom repeatable quest'] = 'Custom Repeatable',
    ['Custom quest (provisional title)'] = 'Custom', ['Future tag'] = 'Future tag' }) do
    categories[10].entries[1].quest_type = raw;
    local result = frame('custom_quests', nil, nil, nil, nil, label);
    assert(#result.checkboxes == 1 and #result.writes == 0);
    assert(state.selected_quest_types.custom_quests == label);
end
assert(snapshot.summary == summary and summary.known_total == 2 and summary.complete == 1);
print('quest type filter fixture passed');
for _, scale in ipairs({ 75, 100, 150 }) do
    settings.scale_percent = scale;
    assert(frame('bastok_quests', nil, nil, nil, nil, nil, 650).type_inline == true);
    assert(frame(nil, nil, nil, nil, nil, nil, 480).type_inline == false);
end
settings.scale_percent = 100;
print('responsive quest filter layout fixture passed');

categories[3].entries = {
    typed_row('Current', 'General'),
    typed_row('Not accepted', 'General', nil, 'auto_not_logged'),
    typed_row('Completed', 'General', nil, 'auto_complete'),
    typed_row('Unknown status', 'General', nil, 'unknown'),
    typed_row('Unavailable', 'General', nil, 'unavailable'),
};
settings.show_unavailable = true;
local accepted = frame('bastok_quests', 'all', nil, nil, nil, 'All Types', nil, { toggle_accepted = true });
assert(state.accepted_only and accepted.texts['Current']);
for _, name in ipairs({ 'Not accepted', 'Completed', 'Unknown status', 'Unavailable' }) do
    assert(not accepted.texts[name]);
end
assert(#frame('custom_quests').checkboxes == 0, 'Manual quests have no Accepted state');
assert(frame().texts['Manual custom quests have no confirmed Accepted state. Turn off Accepted only to view them.']);
frame('bastok_quests');
local entry = categories[3].entries[1];
entry.npc = 'Synthetic NPC'; entry.npc_coordinates = 'H-8';
entry.rewards = 'Synthetic reward'; entry.prerequisites = 'Synthetic prerequisite';
local details = frame(nil, nil, nil, nil, nil, nil, nil, { expand = 'Current' });
assert(details.texts['NPC: Synthetic NPC'] and details.texts['Coordinates: H-8']);
assert(details.texts['Rewards: Synthetic reward'] and details.texts['Prerequisites: Synthetic prerequisite']);
assert(state.expanded_quests.Current and entry.state == 'auto_current' and #details.writes == 0);
assert(frame().texts['Rewards: Synthetic reward'], 'Expansion remains open between frames');
assert(not frame(nil, nil, nil, nil, nil, nil, nil, { expand = 'Current' }).texts['Rewards: Synthetic reward']);
local restored = frame(nil, nil, nil, nil, nil, nil, nil, { toggle_accepted = true, expand = 'Not accepted' });
assert(not state.accepted_only and restored.texts['Completed']);
assert(restored.texts['NPC: Not yet verified'] and restored.texts['Prerequisites: Not yet verified']);
assert(snapshot.summary == summary and summary.known_total == 2 and summary.complete == 1);
print('accepted-only and expandable quest detail fixtures passed');
