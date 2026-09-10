-- HorizonScout manual camp timers. Independently implemented; MIT licensed.
-- Timers remain estimates; explicit optional death observations live in camp_observer.lua.
local M = {};
local maximum_minutes = 10080; -- Seven days; real-world minutes, not game time.
local maximum_camps = 50;
local input_name = {''};
local input_min = {5};
local input_max = {5};
local feedback = '';
local pending_audio = nil;
local last_audio_at = nil;
local audio_config = nil;

local function finite(value)
    return type(value) == 'number' and value == value
        and value ~= math.huge and value ~= -math.huge;
end

local function minutes(value)
    if not finite(value) then return 5; end
    return math.max(1, math.min(maximum_minutes, math.floor(value)));
end

local function name_of(value)
    if type(value) ~= 'string' then return ''; end
    return value:gsub('%c', ''):gsub('^%s+', ''):gsub('%s+$', ''):sub(1, 64);
end

function M.binding(value)
    if type(value) ~= 'table' then return nil; end
    for _, field in ipairs({'zone', 'index', 'id'}) do
        if not finite(value[field]) or value[field] <= 0 or value[field] % 1 ~= 0 then return nil; end
    end
    if value.zone > 65535 or value.index > 2303 or value.id > 4294967295
        or name_of(value.name) == '' then return nil; end
    return {zone = value.zone, index = value.index, id = value.id,
        name = name_of(value.name), placeholder = value.placeholder == true};
end

function M.normalize(config)
    config.camps_enabled = config.camps_enabled == true;
    config.camps_notify = config.camps_notify == true;
    config.camps_placeholder_markers = config.camps_placeholder_markers == true;
    config.camps_diagnostics = config.camps_diagnostics == true;
    config.camps_sound_enabled = config.camps_sound_enabled == true;
    local clean = {};
    for _, camp in ipairs(type(config.camps) == 'table' and config.camps or {}) do
        if type(camp) == 'table' and name_of(camp.name) ~= '' and #clean < maximum_camps then
            local lower = minutes(camp.min_minutes);
            clean[#clean + 1] = {
                name = name_of(camp.name),
                min_minutes = lower,
                max_minutes = math.max(lower, minutes(camp.max_minutes)),
                death_at = finite(camp.death_at) and camp.death_at > 0
                    and math.floor(camp.death_at) or 0,
                notified = camp.notified == true,
                binding = M.binding(camp.binding),
                auto_death = camp.auto_death == true and M.binding(camp.binding) ~= nil,
                auto_start_on_bind = camp.auto_start_on_bind == true,
            };
        end
    end
    config.camps = clean;
end

function M.add(config, name, lower, upper)
    name = name_of(name);
    if name == '' then return false, 'Enter a camp name first.'; end
    if #config.camps >= maximum_camps then return false, 'Maximum of 50 camps reached.'; end
    for _, camp in ipairs(config.camps) do
        if camp.name:lower() == name:lower() then
            return false, 'That camp name already exists; use a distinct camp label.';
        end
    end
    lower = minutes(lower);
    config.camps[#config.camps + 1] = {
        name = name, min_minutes = lower,
        max_minutes = math.max(lower, minutes(upper)), death_at = 0, notified = false,
        auto_start_on_bind = true,
    };
    return true, 'Camp added. Bind a living monster to enable automatic death tracking, or record a death manually.';
end

function M.is_placeholder(config, zone, entity)
    if not config.camps_enabled then return false; end
    for _, camp in ipairs(config.camps) do
        local b = camp.binding;
        if b and b.placeholder and b.zone == zone and b.id == entity.id
            and b.index == entity.index and b.name == entity.name then return true; end
    end
    return false;
end

function M.record(camp, now)
    if not finite(now) or now <= 0 then return false; end
    camp.death_at = math.floor(now);
    camp.notified = false;
    return true;
end

function M.status(camp, now)
    if camp.death_at == 0 then return 'Not started', 0; end
    if not finite(now) or now < camp.death_at then return 'Clock changed', 0; end
    local elapsed = now - camp.death_at;
    local lower, upper = camp.min_minutes * 60, camp.max_minutes * 60;
    if elapsed < lower then return 'Waiting', lower - elapsed; end
    -- A fixed estimate has no closing boundary; it stays open until reset.
    if lower == upper or elapsed <= upper then return 'Window open', math.max(0, upper - elapsed); end
    return 'Overdue', elapsed - upper;
end

function M.advance(config, now)
    local messages, changed = {}, false;
    local due = {};
    if not config.camps_enabled then return messages, changed, due; end
    for _, camp in ipairs(config.camps) do
        local status = M.status(camp, now);
        if not camp.notified and (status == 'Window open' or status == 'Overdue') then
            -- Consume even with notifications disabled, so enabling later does not spam.
            camp.notified = true;
            changed = true;
            due[#due + 1] = {camp = camp, death_at = camp.death_at};
            if config.camps_notify then
                messages[#messages + 1] = camp.name .. (status == 'Overdue'
                    and ' (estimated window already passed)' or ' (estimated window open)');
            end
        end
    end
    return messages, changed, due;
end

-- One coalesced window sound, independent of chat. Never interrupt other audio.
function M.queue_sound(config, due, now)
    if audio_config ~= config then
        pending_audio = nil; last_audio_at = nil; audio_config = config;
    end
    if config.camps_enabled and config.camps_sound_enabled and #due > 0
        and (last_audio_at == nil or now - last_audio_at >= 10) then
        pending_audio = {due = due, expires_at = now + 10};
    end
end

function M.play_pending(config, now, busy, play)
    if audio_config ~= config or not config.camps_enabled or not config.camps_sound_enabled
        or (pending_audio and now > pending_audio.expires_at) then pending_audio = nil; end
    if not pending_audio then return false; end
    local valid = false;
    for _, event in ipairs(pending_audio.due) do
        for _, camp in ipairs(config.camps) do
            if camp == event.camp and camp.death_at == event.death_at and camp.notified then valid = true; end
        end
    end
    if not valid then pending_audio = nil; return false; end
    if busy then return false; end
    pending_audio = nil;
    local played = play();
    if played then last_audio_at = now; end
    return played;
end

local function duration(seconds)
    seconds = math.max(0, math.floor(seconds));
    return string.format('%02d:%02d:%02d', math.floor(seconds / 3600),
        math.floor(seconds / 60) % 60, seconds % 60);
end

function M.draw(config, save, now, bind_target, describe_observer, test_sound)
    local imgui = require('imgui');
    local enabled = {config.camps_enabled};
    if imgui.Checkbox('Enable camp timers', enabled) then
        config.camps_enabled = enabled[1];
        save();
    end
    imgui.TextDisabled('Respawn estimates only; automatic death tracking is optional per camp.');
    if not config.camps_enabled then
        imgui.TextDisabled('Saved timers are retained; elapsed real-world time still counts.');
        return;
    end
    local notify = {config.camps_notify};
    if imgui.Checkbox('Notify once in chat when a window opens', notify) then
        config.camps_notify = notify[1];
        save();
    end
    local sound = {config.camps_sound_enabled};
    if imgui.Checkbox('Play sound when a window opens', sound) then
        config.camps_sound_enabled = sound[1]; save();
    end
    if test_sound then
        imgui.SameLine();
        if imgui.SmallButton('Test##ScoutCampSound') then feedback = test_sound(); end
    end
    imgui.TextDisabled('Camps.wav uses alert volume; grouped alerts, 10-second sound cooldown.');
    local markers = {config.camps_placeholder_markers};
    if imgui.Checkbox('Show NM placeholder markers on radar (P)', markers) then
        config.camps_placeholder_markers = markers[1]; save();
    end
    local debug = {config.camps_diagnostics};
    if imgui.Checkbox('Show camp diagnostics', debug) then config.camps_diagnostics = debug[1]; save(); end
    imgui.Separator();
    if imgui.CollapsingHeader('Create camp') then
    imgui.InputText('Name##ScoutCampName', input_name, 65);
    imgui.SetNextItemWidth(130);
    if imgui.InputInt('Earliest (minutes)##ScoutCampNewMin', input_min) then
        input_min[1] = minutes(input_min[1]);
        input_max[1] = math.max(input_min[1], input_max[1]);
    end
    imgui.SetNextItemWidth(130);
    if imgui.InputInt('Latest (minutes)##ScoutCampNewMax', input_max) then
        input_max[1] = math.max(input_min[1], minutes(input_max[1]));
    end
    imgui.TextDisabled('Real-world minutes (1-10080). Use equal values for a fixed estimate.');
    if imgui.Button('Add camp') then
        local ok;
        ok, feedback = M.add(config, input_name[1], input_min[1], input_max[1]);
        if ok then input_name[1] = ''; save(); end
    end
    end
    if feedback ~= '' then imgui.TextWrapped(feedback); end
    imgui.Separator();
    if #config.camps == 0 then imgui.TextDisabled('No camps configured.'); end
    -- Keep many camps from growing the settings window beyond the screen.
    imgui.BeginChild('##ScoutCampList', {0, 270}, 0);
    local remove_index;
    for index, camp in ipairs(config.camps) do
        imgui.PushID('ScoutCamp' .. camp.name);
        local expanded = imgui.CollapsingHeader(camp.name);
        if not expanded then
            local status, remaining = M.status(camp, now);
            local alive = false;
            if describe_observer and camp.binding then
                local _, ignored;
                _, ignored, alive = describe_observer(camp);
            end
            imgui.Text(alive and 'Alive - bound spawn detected'
                or (status .. (remaining > 0 and ((status == 'Waiting' and ' - opens in '
                    or status == 'Overdue' and ' by ' or ' - ends in ') .. duration(remaining)) or '')));
        else
        local alive = false;
        if camp.binding then
            imgui.TextWrapped((camp.binding.placeholder and 'NM placeholder: ' or 'Monster: ')
                .. camp.binding.name);
            local automatic = {camp.auto_death == true};
            if imgui.Checkbox('Start on observed death (experimental)', automatic) then
                camp.auto_death = automatic[1]; save();
            end
            if describe_observer then
                local status, last;
                status, last, alive = describe_observer(camp);
                if config.camps_diagnostics then
                    imgui.TextWrapped('Zone ' .. camp.binding.zone .. ' | ID ' .. camp.binding.id);
                    imgui.TextWrapped('Observer: ' .. status);
                    imgui.TextWrapped('Last defeat check: ' .. last);
                end
            end
            if imgui.SmallButton('Unbind') then
                camp.binding = nil; camp.auto_death = false; camp.auto_start_on_bind = false; save();
            end
        end
        if bind_target then
            if imgui.SmallButton('Bind selected monster') then
                feedback = bind_target(camp, false); save();
            end
            imgui.SameLine();
            if imgui.SmallButton('Bind selected NM placeholder') then
                feedback = bind_target(camp, true); save();
            end
        end
        local status, remaining = M.status(camp, now);
        if camp.binding then
            imgui.Text(alive and 'Alive - bound spawn detected' or 'Bound spawn not currently observed alive');
        end
        local estimate = status .. (status == 'Waiting' and (' - opens in ' .. duration(remaining))
            or status == 'Overdue' and (' by ' .. duration(remaining))
            or status == 'Window open' and camp.max_minutes > camp.min_minutes
                and (' - ends in ' .. duration(remaining)) or '');
        if alive then imgui.TextDisabled('Previous estimate: ' .. estimate);
        else imgui.Text('Respawn estimate: ' .. estimate); end
        if camp.death_at > 0 then
            local ok, recorded = pcall(os.date, '%Y-%m-%d %H:%M:%S', camp.death_at);
            imgui.TextDisabled('Recorded death: ' .. (ok and recorded or 'Invalid clock date'));
        end
        local lower, upper = {camp.min_minutes}, {camp.max_minutes};
        imgui.SetNextItemWidth(130);
        if imgui.InputInt('Earliest (minutes)', lower) then
            camp.min_minutes = minutes(lower[1]);
            camp.max_minutes = math.max(camp.min_minutes, camp.max_minutes);
            save();
        end
        imgui.SetNextItemWidth(130);
        if imgui.InputInt('Latest (minutes)', upper) then
            camp.max_minutes = math.max(camp.min_minutes, minutes(upper[1]));
            save();
        end
        if imgui.Button('Record death now') then M.record(camp, now); save(); end
        imgui.SameLine();
        if imgui.SmallButton('Stop') then
            camp.death_at = 0; camp.notified = false; camp.auto_death = false;
            camp.auto_start_on_bind = false; save();
        end
        imgui.SameLine();
        if imgui.SmallButton('X') then remove_index = index; end
        end
        imgui.Separator();
        imgui.PopID();
    end
    imgui.EndChild();
    if remove_index then table.remove(config.camps, remove_index); save(); end
    imgui.TextDisabled('An open or overdue window does not mean the monster has spawned.');
    imgui.TextDisabled('NM placeholder assignments and respawn timings are supplied by you, not verified by a database.');
end

return M;
