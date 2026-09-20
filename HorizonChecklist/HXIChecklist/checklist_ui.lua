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
        or lowercase(item.weapon_type):find(filter, 1, true) ~= nil
        or lowercase(item.unlock_quest):find(filter, 1, true) ~= nil
        or lowercase(item.acquisition_method):find(filter, 1, true) ~= nil
        or lowercase(item.travel_use):find(filter, 1, true) ~= nil
        or lowercase(item.spell_type):find(filter, 1, true) ~= nil
        or lowercase(item.set_trait):find(filter, 1, true) ~= nil
        or tostring(item.learn_level or ''):find(filter, 1, true) ~= nil
        or lowercase(item.description):find(filter, 1, true) ~= nil;
end

local function should_show(item, settings, filter)
    local completed = item.state == 'complete'
        or item.state == 'auto_complete'
        or item.state == 'manual_complete';
    local active = item.state == 'auto_current'
        or item.state == 'mission_current'
        or item.state == 'mission_repeat';
    local other_open = item.state == 'missing'
        or item.state == 'auto_not_logged'
        or item.state == 'mission_not_current'
        or item.state == 'manual_open';
    if completed and not settings.show_completed then
        return false;
    end
    if item.state == 'mission_repeat' then
        if settings.show_active == false and not settings.show_completed then return false end;
    elseif active and settings.show_active == false then
        return false;
    end
    if other_open and settings.show_open == false then return false end;
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
    if item.unlock_quest and item.unlock_quest ~= '' then
        imgui.Text(('Unlock quest: %s'):fmt(item.unlock_quest));
    end
    if type(item.current_level) == 'number' then
        imgui.Text(('Current job level: %d'):fmt(item.current_level));
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
    if item.capacity_mirror_id then
        imgui.TextWrapped('Quest-log mirror: excluded from overall progress. The capacity milestone is counted in Inventory Expansions.');
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

local function render_blue_magic_entry(item, actions, imgui)
    imgui.PushID(item.id);
    imgui.TableNextRow();

    imgui.TableSetColumnIndex(0);
    local color = state_colors[item.state] or { 1, 1, 1, 1 };
    imgui.TextColored(color, ('[%s]'):fmt(item.state_label or item.state));
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
    local trait = item.set_trait == 'None' and 'No set trait' or item.set_trait;
    imgui.TextWrapped(('Level %d / %s / %s'):fmt(
        item.learn_level, item.spell_type, trait));

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

local function render_access_travel_entry(item, actions, imgui)
    imgui.PushID(item.id);
    imgui.TableNextRow();

    imgui.TableSetColumnIndex(0);
    local color = state_colors[item.state] or { 1, 1, 1, 1 };
    imgui.TextColored(color, ('[%s]'):fmt(item.state_label
        or state_badges[item.state] or item.state));
    imgui.SameLine();
    imgui.Text(item.name);
    render_tooltip(item, imgui);

    imgui.TableSetColumnIndex(1);
    if item.source_url and item.source_url ~= '' then
        if imgui.SmallButton('Source') then actions.open_source(item.source_url) end;
    end

    imgui.TableSetColumnIndex(2);
    imgui.TextWrapped(item.acquisition_method or 'Unknown');
    if item.travel_use and item.travel_use ~= '' and imgui.IsItemHovered() then
        imgui.BeginTooltip();
        imgui.PushTextWrapPos(imgui.GetFontSize() * 32);
        imgui.TextWrapped(item.travel_use);
        imgui.PopTextWrapPos();
        imgui.EndTooltip();
    end

    imgui.PopID();
end

local render_quest_details;

local function render_job_unlock_entry(item, ui_state, actions, imgui)
    imgui.PushID(item.id);
    imgui.TableNextRow();

    imgui.TableSetColumnIndex(0);
    ui_state.expanded_job_unlocks = ui_state.expanded_job_unlocks or {};
    local expanded = ui_state.expanded_job_unlocks[item.id] == true;
    if imgui.SmallButton((expanded and '-' or '+') .. '##job_unlock_details') then
        expanded = not expanded;
        ui_state.expanded_job_unlocks[item.id] = expanded or nil;
    end
    imgui.SameLine();
    local color = state_colors[item.state] or { 1, 1, 1, 1 };
    local badge = item.state == 'complete' and 'Unlocked'
        or item.state == 'missing' and 'Locked'
        or state_badges[item.state] or item.state;
    imgui.TextColored(color, ('[%s]'):fmt(badge));
    imgui.SameLine();
    imgui.Text(('%s (%s)'):fmt(item.name, item.abbreviation));
    render_tooltip(item, imgui);

    imgui.TableSetColumnIndex(1);
    if item.source_url and item.source_url ~= '' then
        if imgui.SmallButton('Source') then actions.open_source(item.source_url) end;
    end

    imgui.TableSetColumnIndex(2);
    local label = item.unlock_quest or 'Not listed';
    if type(item.current_level) == 'number' and item.current_level >= 1 then
        label = ('%s / Lv.%d'):fmt(label, item.current_level);
    end
    imgui.TextWrapped(label);

    if expanded then render_quest_details(item, imgui) end;
    imgui.PopID();
end

local function render_weapon_skill_entry(item, ui_state, actions, imgui)
    imgui.PushID(item.id);
    imgui.TableNextRow();

    imgui.TableSetColumnIndex(0);
    ui_state.expanded_weapon_skills = ui_state.expanded_weapon_skills or {};
    local expanded = ui_state.expanded_weapon_skills[item.id] == true;
    if imgui.SmallButton((expanded and '-' or '+') .. '##weapon_skill_details') then
        expanded = not expanded;
        ui_state.expanded_weapon_skills[item.id] = expanded or nil;
    end
    imgui.SameLine();
    local color = state_colors[item.state] or { 1, 1, 1, 1 };
    imgui.TextColored(color, ('[%s]'):fmt(item.state_label
        or state_badges[item.state] or item.state));
    imgui.SameLine();
    imgui.Text(item.name);
    render_tooltip(item, imgui);

    imgui.TableSetColumnIndex(1);
    if item.source_url and item.source_url ~= '' then
        if imgui.SmallButton('Source') then actions.open_source(item.source_url) end;
    end

    imgui.TableSetColumnIndex(2);
    imgui.TextWrapped(('%s / %s'):fmt(
        item.weapon_type or 'Unknown weapon', item.unlock_quest or 'Quest not listed'));

    if expanded then render_quest_details(item, imgui) end;
    imgui.PopID();
end

render_quest_details = function(item, imgui)
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
    local group = item.mission_rank and ('Rank %d'):fmt(item.mission_rank)
        or (item.mission_group ~= 'Story' and item.mission_group or nil);
    imgui.TextWrapped(group and ('%s / %s'):fmt(group, item.mission_type or 'Not listed')
        or (item.mission_type or 'Not listed'));
    if expanded then render_quest_details(item, imgui) end;
    imgui.PopID();
end

local function matches_view(item, view)
    if view.inventory_container ~= nil and item.inventory_container ~= view.inventory_container then
        return false;
    end
    if view.mission_rank ~= nil and item.mission_rank ~= view.mission_rank then
        return false;
    end
    if view.mission_group ~= nil and item.mission_group ~= view.mission_group then
        return false;
    end
    if view.magic_skill ~= nil and item.magic_skill ~= view.magic_skill then
        return false;
    end
    if view.level_min ~= nil and (item.minimum_level == nil
        or item.minimum_level < view.level_min or item.minimum_level > view.level_max) then
        return false;
    end
    if view.song_min ~= nil and (item.song_level == nil
        or item.song_level < view.song_min or item.song_level > view.song_max) then
        return false;
    end
    if view.blue_level_band ~= nil
        and item.blue_level_band ~= view.blue_level_band then
        return false;
    end
    if view.map_catalog ~= nil and item.map_catalog ~= view.map_catalog then
        return false;
    end
    if view.access_group ~= nil and item.access_group ~= view.access_group then
        return false;
    end
    if view.job_era ~= nil and item.job_era ~= view.job_era then
        return false;
    end
    if view.weapon_type ~= nil and item.weapon_type ~= view.weapon_type then
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

local function selected_view(category, ui_state)
    if not category.views or #category.views == 0 then return {} end;
    local selected = tonumber(ui_state.selected_views[category.id]) or 1;
    selected = math.max(1, math.min(#category.views, math.floor(selected)));
    return category.views[selected];
end

local spell_level_ranges = {
    { name = 'All Levels' },
    { name = 'Levels 1-20', level_min = 1, level_max = 20 },
    { name = 'Levels 21-40', level_min = 21, level_max = 40 },
    { name = 'Levels 41-60', level_min = 41, level_max = 60 },
    { name = 'Levels 61-75', level_min = 61, level_max = 75 },
};

local function selected_spell_range(view, ui_state)
    local index = ui_state.spell_level_ranges and ui_state.spell_level_ranges[view.id];
    return spell_level_ranges[index or 1] or spell_level_ranges[1];
end

local function collect_visible_entries(category, view, settings, ui_state)
    local selected_type = quest_nation_names[category.id]
        and ui_state.selected_quest_types and ui_state.selected_quest_types[category.id];
    local visible = {};
    for _, item in ipairs(category.entries) do
        if matches_view(item, view)
            and (category.id ~= 'magic_skills'
                or matches_view(item, selected_spell_range(view, ui_state)))
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
    return visible;
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
    local visible = collect_visible_entries(category, view, settings, ui_state);

    if #visible == 0 then
        imgui.TextColored({ 0.68, 0.72, 0.78, 1.00 }, 'No entries match the current filters.');
        return;
    end

    if category.id == 'inventory_expansions' then
        imgui.TextWrapped('Drag dividers to resize Upgrade, Source, and Capacity / Obtained columns.');
        local flags = bit.bor(ImGuiTableFlags_Resizable, ImGuiTableFlags_BordersInnerV,
            ImGuiTableFlags_SizingStretchProp);
        if imgui.BeginTable('##InventoryExpansionRows', 3, flags) then
            imgui.TableSetupColumn('Upgrade', ImGuiTableColumnFlags_WidthFixed, 280 * settings.scale_percent / 100, 0);
            imgui.TableSetupColumn('Source', ImGuiTableColumnFlags_WidthFixed, imgui.CalcTextSize('Source') + 24, 0);
            imgui.TableSetupColumn('Capacity / Obtained', ImGuiTableColumnFlags_WidthStretch, 1, 0);
            for _, item in ipairs(visible) do
                imgui.PushID(item.id);
                imgui.TableNextRow();
                imgui.TableSetColumnIndex(0);
                imgui.TextColored(state_colors[item.state] or { 1, 1, 1, 1 },
                    ('[%s]'):fmt(item.state_label or item.state));
                imgui.SameLine();
                imgui.Text(item.name);
                render_tooltip(item, imgui);
                imgui.TableSetColumnIndex(1);
                if imgui.SmallButton('Source') then actions.open_source(item.source_url) end;
                imgui.TableSetColumnIndex(2);
                imgui.TextWrapped(('Current capacity: %s | Target: %d'):fmt(
                    item.current_capacity and tostring(item.current_capacity) or 'Unknown', item.target_capacity));
                imgui.TextWrapped(item.acquisition_method);
                imgui.PopID();
            end
            imgui.EndTable();
        end
        return;
    end

    if category.mission_area then
        local scale = settings.scale_percent / 100;
        local width = math.max(250 * scale, math.min(imgui.GetWindowWidth() * 0.45, 360 * scale));
        local mission_heading = category.mission_column_label or 'Rank / Type';
        imgui.TextColored({ 0.68, 0.72, 0.78, 1.00 },
            ('Click + for details. Drag dividers to resize Mission, Source, and %s columns.'):fmt(mission_heading));
        imgui.PushStyleColor(ImGuiCol_TableBorderStrong, { 0.78, 0.82, 0.88, 1.00 });
        imgui.PushStyleColor(ImGuiCol_TableBorderLight, { 0.58, 0.64, 0.72, 1.00 });
        local flags = bit.bor(ImGuiTableFlags_Resizable, ImGuiTableFlags_BordersInnerV, ImGuiTableFlags_SizingStretchProp);
        if imgui.BeginTable('##MissionRows_' .. category.id, 3, flags) then
            imgui.TableSetupColumn('Mission', ImGuiTableColumnFlags_WidthFixed, width, 0);
            imgui.TableSetupColumn('Source', ImGuiTableColumnFlags_WidthFixed, imgui.CalcTextSize('Source') + 24, 0);
            imgui.TableSetupColumn(mission_heading, ImGuiTableColumnFlags_WidthStretch, 1.0, 0);
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

    if category.id == 'access_travel' then
        local scale = settings.scale_percent / 100;
        local unlock_width = math.max(
            230 * scale,
            math.min(imgui.GetWindowWidth() * 0.42, 340 * scale));
        local source_width = imgui.CalcTextSize('Source') + 24;
        local table_flags = bit.bor(
            ImGuiTableFlags_Resizable,
            ImGuiTableFlags_BordersInnerV,
            ImGuiTableFlags_SizingStretchProp);
        imgui.TextColored(
            { 0.68, 0.72, 0.78, 1.00 },
            'Drag the vertical dividers to resize Unlock, Source, and Obtained columns.');
        imgui.PushStyleColor(
            ImGuiCol_TableBorderStrong,
            { 0.78, 0.82, 0.88, 1.00 });
        imgui.PushStyleColor(
            ImGuiCol_TableBorderLight,
            { 0.58, 0.64, 0.72, 1.00 });
        if imgui.BeginTable('##AccessTravelRows', 3, table_flags) then
            imgui.TableSetupColumn(
                'Unlock', ImGuiTableColumnFlags_WidthFixed, unlock_width, 0);
            imgui.TableSetupColumn(
                'Source', ImGuiTableColumnFlags_WidthFixed, source_width, 0);
            imgui.TableSetupColumn(
                'Obtained', ImGuiTableColumnFlags_WidthStretch, 1.0, 0);
            for _, item in ipairs(visible) do
                render_access_travel_entry(item, actions, imgui);
            end
            imgui.EndTable();
        end
        imgui.PopStyleColor(2);
        return;
    end

    if category.id == 'job_unlocks' then
        local scale = settings.scale_percent / 100;
        local job_width = math.max(
            220 * scale,
            math.min(imgui.GetWindowWidth() * 0.40, 330 * scale));
        local source_width = imgui.CalcTextSize('Source') + 24;
        local table_flags = bit.bor(
            ImGuiTableFlags_Resizable,
            ImGuiTableFlags_BordersInnerV,
            ImGuiTableFlags_SizingStretchProp);
        imgui.TextColored(
            { 0.68, 0.72, 0.78, 1.00 },
            'Click + for quest details. Drag dividers to resize Job, Source, and Unlock Quest / Level columns.');
        imgui.PushStyleColor(
            ImGuiCol_TableBorderStrong,
            { 0.78, 0.82, 0.88, 1.00 });
        imgui.PushStyleColor(
            ImGuiCol_TableBorderLight,
            { 0.58, 0.64, 0.72, 1.00 });
        if imgui.BeginTable('##JobUnlockRows', 3, table_flags) then
            imgui.TableSetupColumn(
                'Job', ImGuiTableColumnFlags_WidthFixed, job_width, 0);
            imgui.TableSetupColumn(
                'Source', ImGuiTableColumnFlags_WidthFixed, source_width, 0);
            imgui.TableSetupColumn(
                'Unlock Quest / Level', ImGuiTableColumnFlags_WidthStretch, 1.0, 0);
            for _, item in ipairs(visible) do
                render_job_unlock_entry(item, ui_state, actions, imgui);
            end
            imgui.EndTable();
        end
        imgui.PopStyleColor(2);
        return;
    end

    if category.id == 'weapon_skills' then
        local scale = settings.scale_percent / 100;
        local skill_width = math.max(
            220 * scale,
            math.min(imgui.GetWindowWidth() * 0.40, 330 * scale));
        local source_width = imgui.CalcTextSize('Source') + 24;
        local table_flags = bit.bor(
            ImGuiTableFlags_Resizable,
            ImGuiTableFlags_BordersInnerV,
            ImGuiTableFlags_SizingStretchProp);
        imgui.TextColored(
            { 0.68, 0.72, 0.78, 1.00 },
            'Click + for quest details. Drag dividers to resize Weapon Skill, Source, and Weapon / Unlock Quest columns.');
        imgui.PushStyleColor(
            ImGuiCol_TableBorderStrong,
            { 0.78, 0.82, 0.88, 1.00 });
        imgui.PushStyleColor(
            ImGuiCol_TableBorderLight,
            { 0.58, 0.64, 0.72, 1.00 });
        if imgui.BeginTable('##WeaponSkillRows', 3, table_flags) then
            imgui.TableSetupColumn(
                'Weapon Skill', ImGuiTableColumnFlags_WidthFixed, skill_width, 0);
            imgui.TableSetupColumn(
                'Source', ImGuiTableColumnFlags_WidthFixed, source_width, 0);
            imgui.TableSetupColumn(
                'Weapon / Unlock Quest', ImGuiTableColumnFlags_WidthStretch, 1.0, 0);
            for _, item in ipairs(visible) do
                render_weapon_skill_entry(item, ui_state, actions, imgui);
            end
            imgui.EndTable();
        end
        imgui.PopStyleColor(2);
        return;
    end

    if category.id == 'blue_magic' then
        local scale = settings.scale_percent / 100;
        local spell_width = math.max(
            220 * scale,
            math.min(imgui.GetWindowWidth() * 0.38, 330 * scale));
        local source_width = imgui.CalcTextSize('Source') + 24;
        local table_flags = bit.bor(
            ImGuiTableFlags_Resizable,
            ImGuiTableFlags_BordersInnerV,
            ImGuiTableFlags_SizingStretchProp);
        imgui.TextColored(
            { 0.68, 0.72, 0.78, 1.00 },
            'Drag the vertical dividers to resize Spell, Source, and Level / Type / Trait columns.');
        imgui.PushStyleColor(
            ImGuiCol_TableBorderStrong,
            { 0.78, 0.82, 0.88, 1.00 });
        imgui.PushStyleColor(
            ImGuiCol_TableBorderLight,
            { 0.58, 0.64, 0.72, 1.00 });
        if imgui.BeginTable('##BlueMagicRows', 3, table_flags) then
            imgui.TableSetupColumn(
                'Blue Magic', ImGuiTableColumnFlags_WidthFixed, spell_width, 0);
            imgui.TableSetupColumn(
                'Source', ImGuiTableColumnFlags_WidthFixed, source_width, 0);
            imgui.TableSetupColumn(
                'Level / Type / Trait', ImGuiTableColumnFlags_WidthStretch, 1.0, 0);
            for _, item in ipairs(visible) do
                render_blue_magic_entry(item, actions, imgui);
            end
            imgui.EndTable();
        end
        imgui.PopStyleColor(2);
        return;
    end

    if category.id == 'magic_skills' or category.id == 'songs'
        or category.id == 'summoning' or category.id == 'ninjutsu' then
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
        local table_id = category.id == 'songs' and '##SongRows' or '##MagicRows';
        if category.id == 'summoning' or category.id == 'ninjutsu' then table_id = '##' .. category.id .. 'Rows' end;
        if imgui.BeginTable(table_id, 3, table_flags) then
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

local function hover_help(text, imgui)
    if imgui.IsItemHovered() then
        imgui.BeginTooltip();
        imgui.PushTextWrapPos(imgui.GetFontSize() * 32);
        imgui.TextWrapped(text or '');
        imgui.PopTextWrapPos();
        imgui.EndTooltip();
    end
end

local function render_category(category, settings, ui_state, actions, imgui, selector_label)
    imgui.TextColored({ 0.68, 0.72, 0.78, 1.00 }, (category.name or '') .. ' (?)');
    hover_help(category.description, imgui);
    imgui.TextColored(
        { 0.68, 0.72, 0.78, 1.00 },
        ('%d/%d complete | %d unknown | %d unavailable')
            :fmt(category.summary.complete, category.summary.known_total,
                category.summary.unknown, category.summary.unavailable)
    );
    imgui.Separator();

    if category.id == 'magic_skills' and category.views and #category.views > 0 then
        if imgui.BeginTabBar('##SpellCategories', ImGuiTabBarFlags_FittingPolicyScroll or 0) then
            for index, candidate in ipairs(category.views) do
                local label = candidate.magic_skill and candidate.name:gsub(' Magic$', '') or 'All';
                if imgui.BeginTabItem(label .. '##spell-' .. candidate.id, nil) then
                    ui_state.selected_views[category.id] = index;
                    ui_state.spell_level_ranges = ui_state.spell_level_ranges or {};
                    imgui.SetNextItemWidth(220);
                    if imgui.BeginCombo('Level Range##spell-' .. candidate.id,
                        selected_spell_range(candidate, ui_state).name) then
                        for range_index, range in ipairs(spell_level_ranges) do
                            if imgui.Selectable(range.name, selected_spell_range(candidate, ui_state) == range) then
                                ui_state.spell_level_ranges[candidate.id] = range_index;
                            end
                        end
                        imgui.EndCombo();
                    end
                    render_entries(category, candidate, settings, ui_state, actions, imgui);
                    imgui.EndTabItem();
                end
            end
            imgui.EndTabBar();
        end
        return;
    end

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
    render_category(selected, settings, ui_state, actions, imgui,
        selected.mission_view_label or 'Mission');
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

local function find_category(categories, wanted, predicate)
    local first = nil;
    for _, category in ipairs(categories) do
        if predicate(category) then
            first = first or category;
            if category.id == wanted then return category end;
        end
    end
    return first;
end

local function category_value_label(category, field, value)
    for _, view in ipairs(category.views or {}) do
        if view[field] == value then return view.name end;
    end
    return value or '';
end

local function fame_label(item)
    if type(item.fame_level) == 'number' then
        if item.fame_region then
            return ('%s Fame %d'):fmt(item.fame_region, item.fame_level);
        end
        return ('Fame %d'):fmt(item.fame_level);
    end
    return item.fame_label or 'Unknown';
end

local function mission_group_label(item)
    if item.mission_rank then return ('Rank %d'):fmt(item.mission_rank) end;
    if item.mission_group and item.mission_group ~= 'Story' then return item.mission_group end;
    return '';
end

local function row_status(item)
    if item.kind == 'inventory_expansion' then return item.state_label or item.state end;
    if item.blue_magic == true then
        return item.state_label or item.state or '';
    end
    if item.kind == 'job_unlock' then
        if item.state == 'complete' then return 'Unlocked' end;
        if item.state == 'missing' then return 'Locked' end;
    end
    if item.kind == 'weapon_skill' then
        return item.state_label or state_badges[item.state] or item.state or '';
    end
    if item.access_unlock == true then
        return item.state_label or state_badges[item.state] or item.state or '';
    end
    return state_badges[item.state] or item.state_label or item.state or '';
end

local function category_export(category, settings, ui_state)
    local view = selected_view(category, ui_state);
    local visible = collect_visible_entries(category, view, settings, ui_state);
    local data = { rows = {} };

    if quest_nation_names[category.id] then
        local area = quest_nation_names[category.id];
        data.label = 'Quests - ' .. area;
        data.file_label = 'quests-' .. category.id:gsub('_quests$', '');
        data.headers = { 'Status', 'Quest', 'Area', 'Location', 'Type', 'Required Fame',
            'NPC', 'Coordinates', 'Rewards', 'Prerequisites', 'Source' };
        for _, item in ipairs(visible) do
            data.rows[#data.rows + 1] = { row_status(item), item.name or '', area,
                item.quest_location or '', quest_type_label(item), fame_label(item),
                item.npc or '', item.npc_coordinates or '', item.rewards or '',
                item.prerequisites or '', item.source_url or '' };
        end
        return data;
    end

    if category.mission_area then
        local storyline = category.name:gsub(' Missions$', '');
        data.label = 'Missions - ' .. storyline;
        data.file_label = 'missions-' .. category.mission_area;
        data.headers = { 'Status', 'Mission Number', 'Mission', 'Storyline',
            'Rank or Chapter', 'Type', 'NPC', 'Location', 'Coordinates', 'Rewards',
            'Prerequisites', 'Source' };
        for _, item in ipairs(visible) do
            data.rows[#data.rows + 1] = { row_status(item), item.mission_number or '',
                item.name or '', storyline, mission_group_label(item), item.mission_type or '',
                item.npc or '', item.quest_location or '', item.npc_coordinates or '',
                item.rewards or '', item.prerequisites or '', item.source_url or '' };
        end
        return data;
    end

    if category.id == 'inventory_expansions' then
        data.label = 'Inventory Expansions';
        data.file_label = 'inventory-expansions-' .. (view.id or 'all');
        data.headers = { 'Status', 'Upgrade', 'Container', 'Current Capacity', 'Target Capacity', 'Obtained', 'Source' };
        for _, item in ipairs(visible) do
            data.rows[#data.rows + 1] = { row_status(item), item.name, item.container_name,
                item.current_capacity or 'Unknown', item.target_capacity, item.acquisition_method, item.source_url };
        end
        return data;
    end

    if category.id == 'magic_skills' or category.id == 'songs'
        or category.id == 'summoning' or category.id == 'ninjutsu' then
        data.label = category.name or 'Spells';
        data.file_label = (category.id == 'magic_skills' and 'magic-skills' or category.id) .. '-' .. (view.id or 'all');
        data.headers = { 'Status', 'Magic Skill', 'Category', 'Required Job Levels', 'Source' };
        for _, item in ipairs(visible) do
            data.rows[#data.rows + 1] = { row_status(item), item.name or '',
                category.id ~= 'magic_skills' and category.name or category_value_label(category, 'magic_skill', item.magic_skill),
                item.job_levels or 'Unavailable', item.source_url or '' };
        end
        return data;
    end

    if category.id == 'blue_magic' then
        data.label = 'Blue Magic';
        data.file_label = 'blue-magic-' .. (view.id or 'all');
        data.headers = { 'Status', 'Spell', 'Learn Level', 'Type', 'Set Trait', 'Source' };
        for _, item in ipairs(visible) do
            data.rows[#data.rows + 1] = { row_status(item), item.name or '',
                item.learn_level or '', item.spell_type or '', item.set_trait or '',
                item.source_url or '' };
        end
        return data;
    end

    if category.id == 'maps' then
        data.label = 'Maps';
        data.file_label = 'maps-' .. (view.id or 'all');
        data.headers = { 'Status', 'Map', 'Category', 'Obtained', 'Source' };
        for _, item in ipairs(visible) do
            data.rows[#data.rows + 1] = { row_status(item), item.name or '',
                category_value_label(category, 'map_catalog', item.map_catalog),
                item.vendor_cost or item.acquisition_method or 'Unknown', item.source_url or '' };
        end
        return data;
    end

    if category.id == 'access_travel' then
        data.label = 'Access & Travel';
        data.file_label = 'access-travel-' .. (view.id or 'all');
        data.headers = { 'Status', 'Unlock', 'Category', 'Obtained', 'Travel Use', 'Source' };
        for _, item in ipairs(visible) do
            data.rows[#data.rows + 1] = { row_status(item), item.name or '',
                category_value_label(category, 'access_group', item.access_group),
                item.acquisition_method or '', item.travel_use or '', item.source_url or '' };
        end
        return data;
    end

    if category.id == 'job_unlocks' then
        data.label = 'Job Unlocks';
        data.file_label = 'job-unlocks-' .. (view.id or 'all');
        data.headers = { 'Status', 'Job', 'Abbreviation', 'Current Level', 'Era',
            'Unlock Quest', 'NPC', 'Location', 'Coordinates', 'Rewards',
            'Prerequisites', 'Source' };
        for _, item in ipairs(visible) do
            data.rows[#data.rows + 1] = { row_status(item), item.name or '',
                item.abbreviation or '', item.current_level or '',
                category_value_label(category, 'job_era', item.job_era),
                item.unlock_quest or '', item.npc or '', item.quest_location or '',
                item.npc_coordinates or '', item.rewards or '',
                item.prerequisites or '', item.source_url or '' };
        end
        return data;
    end

    if category.id == 'weapon_skills' then
        data.label = 'Weapon Skills';
        data.file_label = 'weapon-skills-' .. (view.id or 'all');
        data.headers = { 'Status', 'Weapon Skill', 'Weapon Type', 'Unlock Quest',
            'NPC', 'Location', 'Coordinates', 'Rewards', 'Prerequisites', 'Source' };
        for _, item in ipairs(visible) do
            data.rows[#data.rows + 1] = { row_status(item), item.name or '',
                item.weapon_type or '', item.unlock_quest or '', item.npc or '',
                item.quest_location or '', item.npc_coordinates or '',
                item.rewards or '', item.prerequisites or '', item.source_url or '' };
        end
        return data;
    end

    data.label = category.name;
    data.file_label = category.id;
    data.headers = { 'Status', 'Name', 'Source' };
    for _, item in ipairs(visible) do
        data.rows[#data.rows + 1] = { row_status(item), item.name or '', item.source_url or '' };
    end
    return data;
end

function checklist_ui.build_export(snapshot, skill_snapshot, settings, ui_state)
    local active = ui_state.active_tab or 'quests';
    local categories = snapshot.categories or {};
    if active == 'crafting' then
        local data = { label = 'Crafting', file_label = 'crafting',
            headers = { 'Craft', 'Skill', 'Rank', 'Next Rank', 'Test Level', 'Required Item', 'Source' }, rows = {} };
        for _, item in ipairs(snapshot.crafting and snapshot.crafting.entries or {}) do
            local searchable = { name = item.name, description = (item.rank_name or '') .. ' ' .. (item.test_item or '') };
            if matches_filter(searchable, ui_state.search[1]) then
                data.rows[#data.rows + 1] = { item.name, item.value or 'Unknown', item.rank_name,
                    item.next_rank or item.next_test, item.test_level or '', item.test_item or '', item.source_url };
            end
        end
        return data;
    end
    if active == 'quests' then
        local category = find_category(categories, ui_state.selected_quest_area,
            function(candidate) return quest_nation_names[candidate.id] ~= nil end);
        return category and category_export(category, settings, ui_state)
            or nil, 'No quest area is available.';
    end
    if active == 'missions' then
        local category = find_category(categories, ui_state.selected_mission_story,
            function(candidate) return candidate.mission_area ~= nil end);
        return category and category_export(category, settings, ui_state)
            or nil, 'No mission storyline is available.';
    end
    if active == 'skill_levels' then
        local data = {
            label = 'Skill Levels', file_label = 'skill-levels',
            headers = { 'Skill', 'Value', 'Status' }, rows = {},
        };
        for _, item in ipairs(skill_snapshot.entries or {}) do
            local status = item.value == nil and 'Unavailable'
                or item.capped == true and 'Capped'
                or item.capped == false and 'Training' or '';
            data.rows[#data.rows + 1] = { item.name or '', item.value or '', status };
        end
        return data, nil;
    end
    local category = find_category(categories, active, function(candidate)
        return quest_nation_names[candidate.id] == nil and not candidate.mission_area;
    end);
    return category and category_export(category, settings, ui_state)
        or nil, 'The active tab is unavailable.';
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

    local show_active = { settings.show_active ~= false };
    if imgui.Checkbox('Show accepted/current', show_active) then
        actions.set_setting('show_active', show_active[1]);
    end
    if imgui.GetWindowWidth() >= imgui.CalcTextSize(
        'Show accepted/current Show missing/not accepted/not current') + 84 then
        imgui.SameLine();
    end
    local show_open = { settings.show_open ~= false };
    if imgui.Checkbox('Show missing/not accepted/not current', show_open) then
        actions.set_setting('show_open', show_open[1]);
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
    imgui.SameLine();
    if imgui.Button('Export visible') then
        actions.export_visible();
    end
    if imgui.IsItemHovered() then
        imgui.BeginTooltip();
        imgui.PushTextWrapPos(imgui.GetFontSize() * 32);
        imgui.TextWrapped('Writes the rows currently shown on the active tab to a tab-separated file for spreadsheets.');
        imgui.PopTextWrapPos();
        imgui.EndTooltip();
    end
end

local function render_skill_levels(snapshot, imgui)
    imgui.TextColored({ 0.68, 0.72, 0.78, 1.00 }, 'Live skills (?)');
    hover_help('Informational only; excluded from checklist totals and status filters.', imgui);
    if snapshot.note and snapshot.note ~= '' then
        imgui.TextColored({ 1.00, 0.72, 0.28, 1.00 }, snapshot.note);
    end
    imgui.Separator();

    local flags = bit.bor(ImGuiTableFlags_Resizable, ImGuiTableFlags_BordersInnerV,
        ImGuiTableFlags_SizingStretchProp);
    if not imgui.BeginTable('##SkillLevelRows', 3, flags) then return end;
    imgui.TableSetupColumn('Skill', ImGuiTableColumnFlags_WidthStretch, 2, 0);
    imgui.TableSetupColumn('Level', ImGuiTableColumnFlags_WidthStretch, 1, 0);
    imgui.TableSetupColumn('Status', ImGuiTableColumnFlags_WidthStretch, 1, 0);
    imgui.TableHeadersRow();
    for _, entry in ipairs(snapshot.entries) do
        imgui.TableNextRow();
        imgui.TableSetColumnIndex(0);
        imgui.Text(entry.name);
        imgui.TableSetColumnIndex(1);
        if entry.value == nil then
            imgui.Text('--');
            imgui.TableSetColumnIndex(2);
            imgui.TextColored({ 0.55, 0.58, 0.62, 1.00 }, 'Unavailable');
        else
            imgui.TextColored({ 0.35, 0.72, 1.00, 1.00 }, tostring(entry.value));
            imgui.TableSetColumnIndex(2);
            if entry.capped ~= nil then
                imgui.TextColored(
                    entry.capped
                        and { 0.30, 0.90, 0.45, 1.00 }
                        or { 1.00, 0.72, 0.28, 1.00 },
                    entry.capped and 'Capped' or 'Training');
            else
                imgui.Text('Unknown');
            end
        end
    end
    imgui.EndTable();
end

local function render_crafting(snapshot, settings, ui_state, actions, imgui)
    imgui.TextColored({ 0.68, 0.72, 0.78, 1.00 }, 'Live skills and next guild tests (?)');
    hover_help('Uses search only. Excluded from checklist totals and status filters. Rank is read directly; test items are reference information. Recipes and guild key items are not tracked.', imgui);
    local rows = checklist_ui.build_export(snapshot, { entries = {} }, settings, ui_state).rows;
    if #rows == 0 then
        imgui.Text('No crafts to show.');
        return;
    end
    local flags = bit.bor(ImGuiTableFlags_Resizable, ImGuiTableFlags_BordersInnerV,
        ImGuiTableFlags_SizingStretchProp);
    if imgui.BeginTable('##CraftingRows', 4, flags) then
        local scale = settings.scale_percent / 100;
        imgui.TableSetupColumn('Craft', ImGuiTableColumnFlags_WidthFixed, 110 * scale, 0);
        imgui.TableSetupColumn('Skill / Rank', ImGuiTableColumnFlags_WidthFixed, 150 * scale, 0);
        imgui.TableSetupColumn('Next test / Item', ImGuiTableColumnFlags_WidthStretch, 1, 0);
        imgui.TableSetupColumn('Source', ImGuiTableColumnFlags_WidthFixed, imgui.CalcTextSize('Source') + 24, 0);
        imgui.TableHeadersRow();
        for _, row in ipairs(rows) do
            imgui.PushID(row[1]);
            imgui.TableNextRow();
            imgui.TableSetColumnIndex(0); imgui.Text(row[1]);
            imgui.TableSetColumnIndex(1); imgui.TextWrapped(tostring(row[2]) .. ' / ' .. row[3]);
            imgui.TableSetColumnIndex(2);
            imgui.TextWrapped(row[4] .. (row[5] ~= '' and (' (Lv.%d+)'):fmt(row[5]) or ''));
            if row[6] ~= '' then imgui.TextWrapped(row[6]) end;
            imgui.TableSetColumnIndex(3);
            if imgui.SmallButton('Source') then actions.open_source(row[7]) end;
            imgui.PopID();
        end
        imgui.EndTable();
    end
end

local magic_category_order = {
    { id = 'magic_skills', label = 'Spells' },
    { id = 'songs', label = 'Songs' },
    { id = 'summoning', label = 'Summoning' },
    { id = 'ninjutsu', label = 'Ninjutsu' },
    { id = 'blue_magic', label = 'Blue Magic' },
};

local function render_magic_categories(
    categories, settings, ui_state, actions, imgui)
    if not imgui.BeginTabBar(
        '##HXIChecklistMagicTabs', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton) then
        return;
    end
    for _, definition in ipairs(magic_category_order) do
        local category = find_category(categories, definition.id,
            function(candidate) return candidate.id == definition.id end);
        if category ~= nil and imgui.BeginTabItem(definition.label, nil) then
            ui_state.active_tab = category.id;
            render_category(category, settings, ui_state, actions, imgui,
                category.id ~= 'magic_skills' and 'Level Range' or 'Category');
            imgui.EndTabItem();
        end
    end
    imgui.EndTabBar();
end

local other_category_order = {
    'maps',
    'access_travel',
    'inventory_expansions',
    'job_unlocks',
    'weapon_skills',
};

local function render_other_key_items(
    categories, skill_snapshot, settings, ui_state, actions, imgui)
    if not imgui.BeginTabBar(
        '##HXIChecklistOtherTabs', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton) then
        return;
    end

    for _, category_id in ipairs(other_category_order) do
        local category = find_category(categories, category_id,
            function(candidate) return candidate.id == category_id end);
        if category ~= nil and imgui.BeginTabItem(category.name, nil) then
            ui_state.active_tab = category.id;
            render_category(category, settings, ui_state, actions, imgui);
            imgui.EndTabItem();
        end
    end

    if imgui.BeginTabItem('Skill Levels', nil) then
        ui_state.active_tab = 'skill_levels';
        render_skill_levels(skill_snapshot, imgui);
        imgui.EndTabItem();
    end
    imgui.EndTabBar();
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
        imgui.PushStyleColor(ImGuiCol_Text, { 0.78, 0.81, 0.85, 1.00 });
        -- Apply the same visible dividers to every table, including newer views.
        imgui.PushStyleColor(ImGuiCol_TableBorderStrong, { 0.78, 0.82, 0.88, 1.00 });
        imgui.PushStyleColor(ImGuiCol_TableBorderLight, { 0.58, 0.64, 0.72, 1.00 });

        imgui.TextColored({ 0.35, 0.72, 1.00, 1.00 },
            ('HXIChecklist v%s'):fmt(ui_state.addon_version or '?'));
        hover_help(profile.scope_note, imgui);

        local summary = snapshot.summary;
        imgui.Text(('Progress: %d/%d complete'):fmt(
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
            if imgui.BeginTabItem('Quests', nil) then
                ui_state.active_tab = 'quests';
                render_quests(snapshot.categories, settings, ui_state, actions, imgui);
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Missions', nil) then
                ui_state.active_tab = 'missions';
                render_missions(snapshot.categories, settings, ui_state, actions, imgui);
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Magic Skills', nil) then
                render_magic_categories(
                    snapshot.categories, settings, ui_state, actions, imgui);
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Crafting', nil) then
                ui_state.active_tab = 'crafting';
                render_crafting(snapshot, settings, ui_state, actions, imgui);
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Others/Key Items', nil) then
                render_other_key_items(
                    snapshot.categories, skill_snapshot, settings,
                    ui_state, actions, imgui);
                imgui.EndTabItem();
            end
            imgui.EndTabBar();
        end
        imgui.PopStyleColor(3);
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
