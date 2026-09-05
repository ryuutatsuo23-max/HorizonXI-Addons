local checklist_ui = {};

local state_colors = {
    manual_complete = { 0.30, 0.90, 0.45, 1.00 },
    manual_open = { 1.00, 0.72, 0.28, 1.00 },
    complete = { 0.30, 0.90, 0.45, 1.00 },
    missing = { 1.00, 0.72, 0.28, 1.00 },
    auto_complete = { 0.30, 0.90, 0.45, 1.00 },
    auto_current = { 0.35, 0.72, 1.00, 1.00 },
    auto_not_logged = { 1.00, 0.72, 0.28, 1.00 },
    mission_current = { 0.35, 0.72, 1.00, 1.00 },
    mission_repeat = { 0.35, 0.72, 1.00, 1.00 },
    mission_not_current = { 1.00, 0.72, 0.28, 1.00 },
    unknown = { 1.00, 0.30, 0.30, 1.00 },
    unavailable = { 0.55, 0.58, 0.62, 1.00 },
};

local state_badges = {
    manual_complete = 'Manual done',
    manual_open = 'Manual',
    complete = 'Checked',
    missing = 'Missing',
    auto_complete = 'Completed',
    auto_current = 'Accepted',
    auto_not_logged = 'Not Accepted',
    mission_current = 'Current',
    mission_repeat = 'Current / Done',
    mission_not_current = 'Not current',
    unknown = 'UNKNOWN',
    unavailable = 'UNAVAILABLE',
};

local quest_nation_names = {
    bastok_quests = 'Bastok',
    sandoria_quests = "San d'Oria",
    windurst_quests = 'Windurst',
    jeuno_quests = 'Jeuno',
    other_quests = 'Other Areas',
    outlands_quests = 'Outlands',
    ahturhgan_quests = 'Aht Urhgan',
    custom_quests = 'Horizon Custom',
};

local availability_labels = {
    reported_active = 'Reported active',
    wiki_listed = 'Wiki-listed',
    unknown = 'Unknown',
    reported_inactive = 'Reported inactive',
};

local function lowercase(value)
    return type(value) == 'string' and value:lower() or '';
end

local function matches_filter(item, filter)
    filter = lowercase(filter);
    if filter == '' then
        return true;
    end
    return lowercase(item.name):find(filter, 1, true) ~= nil
        or lowercase(item.npc):find(filter, 1, true) ~= nil
        or lowercase(item.description):find(filter, 1, true) ~= nil;
end

local function should_show(item, settings, filter)
    if (item.state == 'complete'
        or item.state == 'auto_complete'
        or item.state == 'manual_complete')
        and not settings.show_completed then
        return false;
    end
    if item.state == 'unknown' and not settings.show_unknown then
        return false;
    end
    if item.state == 'unavailable' and not settings.show_unavailable then
        return false;
    end
    return matches_filter(item, filter);
end

local function render_tooltip(item, imgui)
    if not imgui.IsItemHovered() then
        return;
    end

    imgui.BeginTooltip();
    imgui.PushTextWrapPos(imgui.GetFontSize() * 34);
    imgui.TextColored({ 0.35, 0.72, 1.00, 1.00 }, item.name);
    imgui.Text(('Tracking: %s'):fmt(item.state_label));
    imgui.Text(('Availability: %s'):fmt(
        availability_labels[item.availability] or item.availability));
    if item.npc and item.npc ~= '' then
        imgui.Text(('NPC: %s'):fmt(item.npc));
    end
    if item.npc_coordinates and item.npc_coordinates ~= '' then
        imgui.Text(('Coordinates: %s'):fmt(item.npc_coordinates));
    end
    if item.quest_location and item.quest_location ~= '' then
        imgui.Text(('Starts in: %s'):fmt(item.quest_location));
    end
    if item.quest_type and item.quest_type ~= '' then
        imgui.Text(('Quest type: %s'):fmt(item.quest_type));
    end
    if item.description and item.description ~= '' then
        imgui.Separator();
        imgui.TextWrapped(item.description);
    end
    if item.availability_note and item.availability_note ~= '' then
        imgui.Separator();
        imgui.TextWrapped(item.availability_note);
    end
    if item.state_note and item.state_note ~= '' then
        imgui.Separator();
        imgui.TextWrapped(item.state_note);
    end
    imgui.PopTextWrapPos();
    imgui.EndTooltip();
end

local function render_entry(item, settings, actions, imgui)
    imgui.PushID(item.id);

    local color = state_colors[item.state] or { 1, 1, 1, 1 };
    imgui.TextColored(color, ('[%s]'):fmt(state_badges[item.state] or item.state));
    imgui.SameLine();
    imgui.Text(item.name);
    render_tooltip(item, imgui);

    if item.source_url and item.source_url ~= '' then
        imgui.SameLine();
        if imgui.SmallButton('Source') then
            actions.open_source(item.source_url);
        end
    end

    imgui.PopID();
end

local function render_magic_entry(item, actions, imgui)
    imgui.PushID(item.id);
    imgui.TableNextRow();

    imgui.TableSetColumnIndex(0);
    local color = state_colors[item.state] or { 1, 1, 1, 1 };
    imgui.TextColored(color, ('[%s]'):fmt(state_badges[item.state] or item.state));
    imgui.SameLine();
    imgui.Text(item.name);
    render_tooltip(item, imgui);

    imgui.TableSetColumnIndex(1);
    if item.source_url and item.source_url ~= '' then
        if imgui.SmallButton('Source') then
            actions.open_source(item.source_url);
        end
    end

    imgui.TableSetColumnIndex(2);
    if item.job_levels and item.job_levels ~= '' then
        imgui.TextWrapped(item.job_levels);
    else
        imgui.TextColored(
            { 0.55, 0.58, 0.62, 1.00 },
            'Job levels unavailable');
    end

    imgui.PopID();
end

local function render_map_entry(item, actions, imgui)
    imgui.PushID(item.id);
    imgui.TableNextRow();

    imgui.TableSetColumnIndex(0);
    local color = state_colors[item.state] or { 1, 1, 1, 1 };
    imgui.TextColored(color, ('[%s]'):fmt(state_badges[item.state] or item.state));
    imgui.SameLine();
    imgui.Text(item.name);
    render_tooltip(item, imgui);

    imgui.TableSetColumnIndex(1);
    if item.source_url and item.source_url ~= '' then
        if imgui.SmallButton('Source') then
            actions.open_source(item.source_url);
        end
    end

    imgui.TableSetColumnIndex(2);
    if item.vendor_cost and item.vendor_cost ~= '' then
        imgui.TextWrapped(item.vendor_cost);
    elseif item.acquisition_method and item.acquisition_method ~= '' then
        imgui.TextWrapped(item.acquisition_method);
    else
        imgui.TextColored({ 1.00, 0.30, 0.30, 1.00 }, 'Unknown');
    end
    if imgui.IsItemHovered() then
        imgui.BeginTooltip();
        imgui.PushTextWrapPos(imgui.GetFontSize() * 32);
        if item.vendor_cost ~= nil then
            imgui.TextWrapped('Vendor price listed in the HorizonXI Map Guide.');
        elseif item.acquisition_method ~= nil then
            imgui.TextWrapped('Acquisition method listed in the HorizonXI Magical Maps table.');
        else
            imgui.TextWrapped('No sourced acquisition method is available.');
        end
        imgui.PopTextWrapPos();
        imgui.EndTooltip();
    end

    imgui.PopID();
end

local function render_quest_details(item, imgui)
    local function detail(label, value)
        if type(value) ~= 'string' or value == '' then value = 'Not yet verified' end;
        imgui.TextWrapped(label .. ': ' .. value);
    end
    imgui.TableNextRow();
    imgui.TableSetColumnIndex(0);
    detail('NPC', item.npc);
    detail('Location', item.quest_location);
    detail('Coordinates', item.npc_coordinates);
    imgui.TableSetColumnIndex(2);
    detail('Rewards', item.rewards);
    detail('Prerequisites', item.prerequisites);
    imgui.TextWrapped('Reference information only; requirements are not checked against your character.');
end

local function render_nation_quest_entry(item, nation_name, ui_state, actions, imgui)
    imgui.PushID(item.id);
    imgui.TableNextRow();

    imgui.TableSetColumnIndex(0);
    ui_state.expanded_quests = ui_state.expanded_quests or {};
    local expanded = ui_state.expanded_quests[item.id] == true;
    if imgui.SmallButton((expanded and '-' or '+') .. '##quest_details') then
        expanded = not expanded;
        ui_state.expanded_quests[item.id] = expanded or nil;
    end
    imgui.SameLine();
    local color = state_colors[item.state] or { 1, 1, 1, 1 };
    if item.state == 'manual_open' or item.state == 'manual_complete' then
        local checked = { item.state == 'manual_complete' };
        if imgui.Checkbox(('##custom_completion_%s'):fmt(item.id), checked) then
            actions.set_manual_completed(item.id, checked[1]);
        end
        imgui.SameLine();
    end
    imgui.TextColored(color, ('[%s]'):fmt(state_badges[item.state] or item.state));
    imgui.SameLine();
    imgui.Text(item.name);
    render_tooltip(item, imgui);

    imgui.TableSetColumnIndex(1);
    if item.source_url and item.source_url ~= '' then
        if imgui.SmallButton('Source') then
            actions.open_source(item.source_url);
        end
    end

    imgui.TableSetColumnIndex(2);
    if type(item.fame_level) == 'number' then
        if item.fame_region then
            imgui.TextWrapped(('%s Fame %d'):fmt(item.fame_region, item.fame_level));
        elseif item.fame_note then
            imgui.TextWrapped(('Fame %d (see source)'):fmt(item.fame_level));
        else
            imgui.Text(('Fame %d'):fmt(item.fame_level));
        end
    elseif item.fame_label == 'Not listed' then
        imgui.TextColored({ 0.68, 0.72, 0.78, 1.00 }, 'Not listed');
    elseif item.fame_label == 'N/A' then
        imgui.TextColored({ 0.68, 0.72, 0.78, 1.00 }, 'N/A');
    elseif item.fame_label == 'None' then
        imgui.TextColored({ 0.68, 0.72, 0.78, 1.00 }, 'None');
    else
        imgui.TextColored({ 1.00, 0.30, 0.30, 1.00 }, 'Unknown');
    end
    if imgui.IsItemHovered() then
        imgui.BeginTooltip();
        imgui.PushTextWrapPos(imgui.GetFontSize() * 32);
        if item.fame_note then
            imgui.TextWrapped(item.fame_note);
        elseif type(item.fame_level) == 'number' then
            imgui.TextWrapped(
                ('HorizonXI lists %s fame %d as required.'):fmt(
                    nation_name, item.fame_level));
        elseif item.fame_label == 'Not listed' then
            imgui.TextWrapped(
                ('The HorizonXI %s quest table does not list a fame value for this quest.'):fmt(
                    nation_name));
        else
            imgui.TextWrapped(
                ('No sourced %s fame value was available; this is not a guessed requirement.'):fmt(
                    nation_name));
        end
        imgui.PopTextWrapPos();
        imgui.EndTooltip();
    end

    if expanded then render_quest_details(item, imgui) end;
    imgui.PopID();
end

local function render_mission_entry(item, ui_state, actions, imgui)
    imgui.PushID(item.id);
    imgui.TableNextRow();
    imgui.TableSetColumnIndex(0);
    ui_state.expanded_missions = ui_state.expanded_missions or {};
    local expanded = ui_state.expanded_missions[item.id] == true;
    if imgui.SmallButton((expanded and '-' or '+') .. '##mission_details') then
        expanded = not expanded;
        ui_state.expanded_missions[item.id] = expanded or nil;
    end
    imgui.SameLine();
    imgui.TextColored(state_colors[item.state] or {1, 1, 1, 1},
        ('[%s]'):fmt(state_badges[item.state] or item.state));
    imgui.SameLine();
    imgui.Text(('%s %s'):fmt(item.mission_number, item.name));
    render_tooltip(item, imgui);
    imgui.TableSetColumnIndex(1);
    if item.source_url and imgui.SmallButton('Source') then actions.open_source(item.source_url) end;
    imgui.TableSetColumnIndex(2);
    imgui.TextWrapped(('Rank %d / %s'):fmt(item.mission_rank, item.mission_type or 'Not listed'));
    if expanded then render_quest_details(item, imgui) end;
    imgui.PopID();
end

local function matches_view(item, view)
    if view.mission_rank ~= nil and item.mission_rank ~= view.mission_rank then
        return false;
    end
    if view.magic_skill ~= nil and item.magic_skill ~= view.magic_skill then
        return false;
    end
    if view.map_catalog ~= nil and item.map_catalog ~= view.map_catalog then
        return false;
    end
    if view.quest_location ~= nil
        and item.quest_location ~= view.quest_location then
        return false;
    end
    return true;
end

local function quest_type_label(item)
    local value = item.quest_type;
    if type(value) ~= 'string' or value == '' or value == 'Unknown' then
        return 'Unknown Type';
    end
    if value:match('^%u%u%u AF[123]?$') then return 'Artifact' end;
    if value:match('^%u%u%u Flag$') then return 'Job Unlock' end;
    local labels = {
        WS = 'Weapon Skill', LB = 'Limit Break', SJ = 'Subjob Unlock',
        RSE = 'Race-specific Equipment',
        ['Custom quest'] = 'Custom',
        ['Custom quest (provisional title)'] = 'Custom',
        ['Custom repeatable quest'] = 'Custom Repeatable',
    };
    return labels[value] or value;
end

local function render_quest_type_filter(category, ui_state, imgui)
    if quest_nation_names[category.id] == nil then return end;
    ui_state.selected_quest_types = ui_state.selected_quest_types or {};
    local present, options = {}, {};
    for _, item in ipairs(category.entries) do
        local label = quest_type_label(item);
        if not present[label] then
            present[label] = true;
            options[#options + 1] = label;
        end
    end
    table.sort(options);
    table.insert(options, 1, 'All Types');
    local selected = ui_state.selected_quest_types[category.id];
    if not present[selected] then selected = 'All Types' end;
    imgui.SetNextItemWidth(220);
    if imgui.BeginCombo(('Type##%s'):fmt(category.id), selected) then
        for _, label in ipairs(options) do
            if imgui.Selectable(label, label == selected) then selected = label end;
        end
        imgui.EndCombo();
    end
    ui_state.selected_quest_types[category.id] = selected;
    if imgui.IsItemHovered() then
        imgui.BeginTooltip();
        imgui.PushTextWrapPos(imgui.GetFontSize() * 32);
        imgui.TextWrapped('Uses catalog type tags, not quest status. Unknown Type means no sourced type. Area progress totals stay unchanged.');
        imgui.PopTextWrapPos();
        imgui.EndTooltip();
    end
end

local function render_entries(category, view, settings, ui_state, actions, imgui)
    local selected_type = quest_nation_names[category.id]
        and ui_state.selected_quest_types and ui_state.selected_quest_types[category.id];
    local visible = {};
    for _, item in ipairs(category.entries) do
        if matches_view(item, view)
            and (not category.mission_area or not ui_state.mission_current_only
                or item.state == 'mission_current' or item.state == 'mission_repeat')
            and (not quest_nation_names[category.id] or not ui_state.accepted_only
                or item.state == 'auto_current')
            and (not selected_type or selected_type == 'All Types'
                or quest_type_label(item) == selected_type)
            and should_show(item, settings, ui_state.search[1]) then
            visible[#visible + 1] = item;
        end
    end

    if #visible == 0 then
        imgui.TextColored({ 0.68, 0.72, 0.78, 1.00 }, 'No entries match the current filters.');
        return;
    end

    if category.mission_area then
        local scale = settings.scale_percent / 100;
        local width = math.max(250 * scale, math.min(imgui.GetWindowWidth() * 0.45, 360 * scale));
        imgui.TextColored({ 0.68, 0.72, 0.78, 1.00 },
            'Click + for details. Drag dividers to resize Mission, Source, and Rank / Type columns.');
        imgui.PushStyleColor(ImGuiCol_TableBorderStrong, { 0.78, 0.82, 0.88, 1.00 });
        imgui.PushStyleColor(ImGuiCol_TableBorderLight, { 0.58, 0.64, 0.72, 1.00 });
        local flags = bit.bor(ImGuiTableFlags_Resizable, ImGuiTableFlags_BordersInnerV, ImGuiTableFlags_SizingStretchProp);
        if imgui.BeginTable('##MissionRows_' .. category.id, 3, flags) then
            imgui.TableSetupColumn('Mission', ImGuiTableColumnFlags_WidthFixed, width, 0);
            imgui.TableSetupColumn('Source', ImGuiTableColumnFlags_WidthFixed, imgui.CalcTextSize('Source') + 24, 0);
            imgui.TableSetupColumn('Rank / Type', ImGuiTableColumnFlags_WidthStretch, 1.0, 0);
            for _, item in ipairs(visible) do render_mission_entry(item, ui_state, actions, imgui) end;
            imgui.EndTable();
        end
        imgui.PopStyleColor(2);
        return;
    end

    if category.id == 'maps' then
        local scale = settings.scale_percent / 100;
        local map_width = math.max(
            240 * scale,
            math.min(imgui.GetWindowWidth() * 0.45, 360 * scale));
        local source_width = imgui.CalcTextSize('Source') + 24;
        local table_flags = bit.bor(
            ImGuiTableFlags_Resizable,
            ImGuiTableFlags_BordersInnerV,
            ImGuiTableFlags_SizingStretchProp);
        imgui.TextColored(
            { 0.68, 0.72, 0.78, 1.00 },
            'Drag the vertical dividers to resize Map, Source, and Obtained columns.');
        imgui.PushStyleColor(
            ImGuiCol_TableBorderStrong,
            { 0.78, 0.82, 0.88, 1.00 });
        imgui.PushStyleColor(
            ImGuiCol_TableBorderLight,
            { 0.58, 0.64, 0.72, 1.00 });
        if imgui.BeginTable('##MapRows', 3, table_flags) then
            imgui.TableSetupColumn(
                'Map', ImGuiTableColumnFlags_WidthFixed, map_width, 0);
            imgui.TableSetupColumn(
                'Source', ImGuiTableColumnFlags_WidthFixed, source_width, 0);
            imgui.TableSetupColumn(
                'Obtained', ImGuiTableColumnFlags_WidthStretch, 1.0, 0);
            for _, item in ipairs(visible) do
                render_map_entry(item, actions, imgui);
            end
            imgui.EndTable();
        end
        imgui.PopStyleColor(2);
        return;
    end

    if category.id == 'magic_skills' then
        local scale = settings.scale_percent / 100;
        local magic_width = math.max(
            220 * scale,
            math.min(imgui.GetWindowWidth() * 0.35, 320 * scale));
        local source_width = imgui.CalcTextSize('Source') + 24;
        local table_flags = bit.bor(
            ImGuiTableFlags_Resizable,
            ImGuiTableFlags_BordersInnerV,
            ImGuiTableFlags_SizingStretchProp);
        imgui.TextColored(
            { 0.68, 0.72, 0.78, 1.00 },
            'Drag the vertical dividers to resize columns.');
        imgui.PushStyleColor(
            ImGuiCol_TableBorderStrong,
            { 0.78, 0.82, 0.88, 1.00 });
        imgui.PushStyleColor(
            ImGuiCol_TableBorderLight,
            { 0.58, 0.64, 0.72, 1.00 });
        if imgui.BeginTable('##MagicRows', 3, table_flags) then
            imgui.TableSetupColumn(
                'Magic', ImGuiTableColumnFlags_WidthFixed, magic_width, 0);
            imgui.TableSetupColumn(
                'Source', ImGuiTableColumnFlags_WidthFixed, source_width, 0);
            imgui.TableSetupColumn(
                'Job levels', ImGuiTableColumnFlags_WidthStretch, 1.0, 0);
            for _, item in ipairs(visible) do
                render_magic_entry(item, actions, imgui);
            end
            imgui.EndTable();
        end
        imgui.PopStyleColor(2);
        return;
    end

    local nation_name = quest_nation_names[category.id];
    if nation_name ~= nil then
        local fame_heading = (category.id == 'other_quests' or category.id == 'outlands_quests'
            or category.id == 'ahturhgan_quests' or category.id == 'custom_quests')
            and 'Required Fame' or nation_name .. ' Fame';
        local scale = settings.scale_percent / 100;
        local quest_width = math.max(
            250 * scale,
            math.min(imgui.GetWindowWidth() * 0.45, 360 * scale));
        local source_width = imgui.CalcTextSize('Source') + 24;
        local table_flags = bit.bor(
            ImGuiTableFlags_Resizable,
            ImGuiTableFlags_BordersInnerV,
            ImGuiTableFlags_SizingStretchProp);
        imgui.TextColored(
            { 0.68, 0.72, 0.78, 1.00 },
            ('Click + for details. Drag dividers to resize Quest, Source, and %s columns.')
                :fmt(fame_heading));
        imgui.PushStyleColor(
            ImGuiCol_TableBorderStrong,
            { 0.78, 0.82, 0.88, 1.00 });
        imgui.PushStyleColor(
            ImGuiCol_TableBorderLight,
            { 0.58, 0.64, 0.72, 1.00 });
        if imgui.BeginTable(('##%sRows'):fmt(category.id), 3, table_flags) then
            imgui.TableSetupColumn(
                'Quest', ImGuiTableColumnFlags_WidthFixed, quest_width, 0);
            imgui.TableSetupColumn(
                'Source', ImGuiTableColumnFlags_WidthFixed, source_width, 0);
            imgui.TableSetupColumn(
                fame_heading, ImGuiTableColumnFlags_WidthStretch, 1.0, 0);
            for _, item in ipairs(visible) do
                render_nation_quest_entry(item, nation_name, ui_state, actions, imgui);
            end
            imgui.EndTable();
        end
        imgui.PopStyleColor(2);
        return;
    end

    for _, item in ipairs(visible) do
        render_entry(item, settings, actions, imgui);
    end
end

local function render_category(category, settings, ui_state, actions, imgui, selector_label)
    imgui.TextWrapped(category.description or '');
    imgui.TextColored(
        { 0.68, 0.72, 0.78, 1.00 },
        ('%d/%d known goals complete | %d unknown | %d unavailable')
            :fmt(category.summary.complete, category.summary.known_total,
                category.summary.unknown, category.summary.unavailable)
    );
    imgui.Separator();

    if category.views and #category.views > 0 then
        local selected = tonumber(ui_state.selected_views[category.id]) or 1;
        selected = math.max(1, math.min(#category.views, math.floor(selected)));
        local view = category.views[selected];
        local function view_name(candidate)
            if selector_label == 'Location' and candidate.id == 'all' then
                return 'All Locations';
            end
            return candidate.name;
        end

        imgui.SetNextItemWidth(220);
        if imgui.BeginCombo(('%s##%s'):fmt(selector_label or 'Category', category.id), view_name(view)) then
            for index, candidate in ipairs(category.views) do
                if imgui.Selectable(
                    ('%s##%s'):fmt(view_name(candidate), candidate.id),
                    index == selected) then
                    selected = index;
                    view = candidate;
                    ui_state.selected_views[category.id] = index;
                end
            end
            imgui.EndCombo();
        end
        -- Allow room for both 220px fields, scaled labels, spacing, and window chrome.
        if quest_nation_names[category.id] ~= nil
            and imgui.GetWindowWidth() >= 440
                + imgui.CalcTextSize('Location') + imgui.CalcTextSize('Type') + 64 then
            imgui.SameLine();
        end
        render_quest_type_filter(category, ui_state, imgui);
        imgui.Separator();
        render_entries(category, view, settings, ui_state, actions, imgui);
        return;
    end

    render_quest_type_filter(category, ui_state, imgui);
    render_entries(category, {}, settings, ui_state, actions, imgui);
end

local function render_missions(categories, settings, ui_state, actions, imgui)
    local stories, selected = {}, nil;
    for _, category in ipairs(categories) do
        if category.mission_area then
            stories[#stories + 1] = category;
            if category.id == ui_state.selected_mission_story then selected = category end;
        end
    end
    selected = selected or stories[1];
    if not selected then imgui.Text('No mission storylines are available.'); return end;
    ui_state.selected_mission_story = selected.id;
    imgui.SetNextItemWidth(220);
    if imgui.BeginCombo('Storyline##MissionStory', (selected.name:gsub(' Missions$', ''))) then
        for _, story in ipairs(stories) do
            if imgui.Selectable(story.name .. '##' .. story.id, story.id == selected.id) then
                selected = story;
                ui_state.selected_mission_story = story.id;
            end
        end
        imgui.EndCombo();
    end
    if imgui.GetWindowWidth() >= 220 + imgui.CalcTextSize('Storyline Current only') + 88 then imgui.SameLine() end;
    local current = { ui_state.mission_current_only == true };
    if imgui.Checkbox('Current only', current) then ui_state.mission_current_only = current[1] end;
    imgui.Separator();
    render_category(selected, settings, ui_state, actions, imgui, 'Rank');
end

local function render_quests(categories, settings, ui_state, actions, imgui)
    local areas = {};
    local selected = nil;
    for _, category in ipairs(categories) do
        if quest_nation_names[category.id] ~= nil then
            areas[#areas + 1] = category;
            if category.id == ui_state.selected_quest_area then
                selected = category;
            end
        end
    end
    selected = selected or areas[1];
    if selected == nil then
        imgui.Text('No quest areas are available.');
        return;
    end
    ui_state.selected_quest_area = selected.id;

    imgui.SetNextItemWidth(220);
    if imgui.BeginCombo('Area##QuestArea', quest_nation_names[selected.id]) then
        for _, category in ipairs(areas) do
            if imgui.Selectable(
                ('%s##%s'):fmt(quest_nation_names[category.id], category.id),
                selected.id == category.id) then
                selected = category;
                ui_state.selected_quest_area = category.id;
            end
        end
        imgui.EndCombo();
    end
    if imgui.GetWindowWidth() >= 220 + imgui.CalcTextSize('Area Accepted only') + 88 then
        imgui.SameLine();
    end
    local accepted_only = { ui_state.accepted_only == true };
    if imgui.Checkbox('Accepted only', accepted_only) then
        ui_state.accepted_only = accepted_only[1];
    end
    if ui_state.accepted_only and selected.id == 'custom_quests' then
        imgui.TextWrapped('Manual custom quests have no confirmed Accepted state. Turn off Accepted only to view them.');
    end
    imgui.Separator();
    render_category(selected, settings, ui_state, actions, imgui, 'Location');
end

local function render_filters(settings, ui_state, actions, imgui)
    imgui.SetNextItemWidth(220);
    imgui.InputText('Search', ui_state.search, 128);

    local show_completed = { settings.show_completed == true };
    if imgui.Checkbox('Show completed', show_completed) then
        actions.set_setting('show_completed', show_completed[1]);
    end
    imgui.SameLine();

    local show_unknown = { settings.show_unknown == true };
    if imgui.Checkbox('Show unknown', show_unknown) then
        actions.set_setting('show_unknown', show_unknown[1]);
    end
    imgui.SameLine();

    local show_unavailable = { settings.show_unavailable == true };
    if imgui.Checkbox('Show unavailable', show_unavailable) then
        actions.set_setting('show_unavailable', show_unavailable[1]);
    end

    imgui.SetNextItemWidth(160);
    local scale = { settings.scale_percent };
    if imgui.SliderInt('Scale', scale, 75, 150, '%d%%') then
        actions.set_setting('scale_percent', scale[1]);
    end
    imgui.SameLine();
    if imgui.Button('Refresh live state') then
        actions.refresh();
    end
end

local function render_skill_levels(snapshot, imgui)
    imgui.TextWrapped(
        'Live numeric character skills read from Ashita. This informational view is excluded from checklist progress, filters, and saved ownership state.');
    if snapshot.note and snapshot.note ~= '' then
        imgui.TextColored({ 1.00, 0.72, 0.28, 1.00 }, snapshot.note);
    end
    imgui.Separator();

    for _, entry in ipairs(snapshot.entries) do
        if entry.value == nil then
            imgui.TextColored({ 0.55, 0.58, 0.62, 1.00 }, '[Unavailable]');
            imgui.SameLine();
            imgui.Text(entry.name);
        else
            imgui.Text(('%s:'):fmt(entry.name));
            imgui.SameLine();
            imgui.TextColored({ 0.35, 0.72, 1.00, 1.00 }, tostring(entry.value));
            if entry.capped ~= nil then
                imgui.SameLine();
                imgui.TextColored(
                    entry.capped
                        and { 0.30, 0.90, 0.45, 1.00 }
                        or { 1.00, 0.72, 0.28, 1.00 },
                    entry.capped and '[Capped]' or '[Training]');
            end
        end
    end
end

local function apply_font_scale(settings, imgui)
    local scale = settings.scale_percent / 100;
    if imgui.SetWindowFontScale then
        imgui.SetWindowFontScale(scale);
        return false;
    end

    imgui.PushFont(nil, imgui.GetFontSize() * scale);
    return true;
end

function checklist_ui.render(
    profile, snapshot, skill_snapshot, settings, ui_state, actions, imgui)
    local was_open = ui_state.window_open[1];
    imgui.SetNextWindowSize({ 760, 560 }, ImGuiCond_FirstUseEver);

    if imgui.Begin('HXIChecklist##main', ui_state.window_open, ImGuiWindowFlags_None) then
        local used_push_font = apply_font_scale(settings, imgui);

        imgui.TextColored({ 0.35, 0.72, 1.00, 1.00 },
            ('Horizon profile %s'):fmt(profile.version));
        imgui.SameLine();
        imgui.TextColored({ 1.00, 0.86, 0.35, 1.00 }, 'Foundation - intentionally incomplete');
        imgui.TextWrapped(profile.scope_note);

        local summary = snapshot.summary;
        imgui.Text(('Progress: %d/%d known goals complete'):fmt(
            summary.complete, summary.known_total));
        imgui.SameLine();
        imgui.TextColored({ 1.00, 0.86, 0.35, 1.00 },
            ('Unknown: %d'):fmt(summary.unknown));
        imgui.SameLine();
        imgui.TextColored({ 0.55, 0.58, 0.62, 1.00 },
            ('Unavailable: %d'):fmt(summary.unavailable));

        imgui.Separator();
        render_filters(settings, ui_state, actions, imgui);
        imgui.Separator();

        if imgui.BeginTabBar('##HXIChecklistTabs', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton) then
            for _, category in ipairs(snapshot.categories) do
                if quest_nation_names[category.id] == nil
                    and not category.mission_area
                    and imgui.BeginTabItem(category.name, nil) then
                    render_category(category, settings, ui_state, actions, imgui);
                    imgui.EndTabItem();
                end
            end
            if imgui.BeginTabItem('Quests', nil) then
                render_quests(snapshot.categories, settings, ui_state, actions, imgui);
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Missions', nil) then
                render_missions(snapshot.categories, settings, ui_state, actions, imgui);
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Skill Levels', nil) then
                render_skill_levels(skill_snapshot, imgui);
                imgui.EndTabItem();
            end
            imgui.EndTabBar();
        end
        if used_push_font then
            imgui.PopFont();
        end
    end
    imgui.End();

    if was_open and not ui_state.window_open[1] then
        actions.set_visible(false);
    end
end

return checklist_ui;
