local checklist_ui = {};

local state_colors = {
    complete = { 0.30, 0.90, 0.45, 1.00 },
    missing = { 1.00, 0.72, 0.28, 1.00 },
    auto_complete = { 0.30, 0.90, 0.45, 1.00 },
    auto_current = { 0.35, 0.72, 1.00, 1.00 },
    auto_not_logged = { 1.00, 0.72, 0.28, 1.00 },
    unknown = { 1.00, 0.30, 0.30, 1.00 },
    unavailable = { 0.55, 0.58, 0.62, 1.00 },
};

local state_badges = {
    complete = 'Checked',
    missing = 'Missing',
    auto_complete = 'Completed',
    auto_current = 'Accepted',
    auto_not_logged = 'Not Accepted',
    unknown = 'UNKNOWN',
    unavailable = 'UNAVAILABLE',
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
        or item.state == 'auto_complete')
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

local function matches_view(item, view)
    return view.magic_skill == nil or item.magic_skill == view.magic_skill;
end

local function render_entries(category, view, settings, ui_state, actions, imgui)
    local shown = 0;
    for _, item in ipairs(category.entries) do
        if matches_view(item, view)
            and should_show(item, settings, ui_state.search[1]) then
            render_entry(item, settings, actions, imgui);
            shown = shown + 1;
        end
    end

    if shown == 0 then
        imgui.TextColored({ 0.68, 0.72, 0.78, 1.00 }, 'No entries match the current filters.');
    end
end

local function render_category(category, settings, ui_state, actions, imgui)
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

        imgui.SetNextItemWidth(220);
        if imgui.BeginCombo(('Category##%s'):fmt(category.id), view.name) then
            for index, candidate in ipairs(category.views) do
                if imgui.Selectable(
                    ('%s##%s'):fmt(candidate.name, candidate.id),
                    index == selected) then
                    selected = index;
                    view = candidate;
                    ui_state.selected_views[category.id] = index;
                end
            end
            imgui.EndCombo();
        end
        render_entries(category, view, settings, ui_state, actions, imgui);
        return;
    end

    render_entries(category, {}, settings, ui_state, actions, imgui);
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

function checklist_ui.render(profile, snapshot, settings, ui_state, actions, imgui)
    local was_open = ui_state.window_open[1];
    imgui.SetNextWindowSize({ 760, 560 }, ImGuiCond_FirstUseEver);

    if imgui.Begin('HXIChecklist##main', ui_state.window_open, ImGuiWindowFlags_None) then
        if imgui.SetWindowFontScale then
            imgui.SetWindowFontScale(settings.scale_percent / 100);
        end

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
                if imgui.BeginTabItem(category.name, nil) then
                    render_category(category, settings, ui_state, actions, imgui);
                    imgui.EndTabItem();
                end
            end
            imgui.EndTabBar();
        end
    end
    imgui.End();

    if was_open and not ui_state.window_open[1] then
        actions.set_visible(false);
    end
end

return checklist_ui;
