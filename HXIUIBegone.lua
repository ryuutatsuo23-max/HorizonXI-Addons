-- SPDX-License-Identifier: GPL-3.0-or-later
addon.name = 'HXIUIBegone';
addon.author = 'DragoHorse';
addon.version = '0.2.4';
addon.desc = 'Choose which parts of the FFXI interface to hide.';

require('common');
local imgui = require('imgui');
local settings = require('settings');
local native = require('native_ui');
local io_adapter = require('memory_io');

local defaults = T{enabled = true, party = false, alliance1 = false,
    alliance2 = false, target = false, castbar = false, compass = false,
    clock = false, connection = false};
local config = settings.load(defaults);
local opened = {false};
local feedback = nil;
local stopped = false;

local function notify(message)
    feedback = message;
    print('[HXIUIBegone] ' .. message);
end

local controller = native.new(io_adapter, notify);

local function normalize()
    config.enabled = config.enabled == true;
    for _, control in ipairs(native.controls) do
        config[control.key] = config[control.key] == true;
    end
end
normalize();

local function apply()
    if stopped then return; end
    local ok = pcall(function() controller:tick(config); end);
    if not ok then
        stopped = true;
        controller:restore();
        notify('Error: Hiding paused. Click Reset choices, then Retry.');
    end
end

local function save()
    local ok = pcall(settings.save);
    if not ok then notify('Error: Could not save your choices.'); end
end

local function restore_everything()
    config.enabled = false;
    for _, control in ipairs(native.controls) do config[control.key] = false; end
    local ok = controller:restore();
    save();
    if ok then notify('Choices cleared. Hiding is off.'); end
end

local function recheck()
    local ok, restored = pcall(function() return controller:recheck(); end);
    if ok and restored then
        stopped = false;
        notify('Options checked again.');
        apply();
    else
        notify('Could not restore the UI. Stop other UI-hiding addons, then Retry.');
    end
end

settings.register('settings', 'HXIUIBegone_settings', function(updated)
    controller:restore();
    if updated ~= nil then config = updated; end
    normalize();
end);

local function hint(text)
    if imgui.IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled) then
        imgui.SetTooltip(text);
    end
end

local function draw()
    if not opened[1] then return; end
    imgui.SetNextWindowSize({440, 420}, ImGuiCond_FirstUseEver);
    if imgui.Begin('HXIUIBegone', opened, ImGuiWindowFlags_NoSavedSettings) then
        local enabled = {config.enabled};
        if imgui.Checkbox('Enable hiding', enabled) then
            config.enabled = enabled[1];
            save();
            apply();
        end
        hint('Pause or resume hiding without clearing your choices.');
        imgui.Separator();
        imgui.TextWrapped('Check what you want to hide. Hover for details.');
        local needs_retry = stopped;
        for _, control in ipairs(native.controls) do
            local row = controller.rows[control.key];
            local selected = {config[control.key]};
            local unavailable = not row.available or row.fault or row.status:match('^Blocked');
            -- A selected unavailable control may always be cleared.
            imgui.BeginDisabled(unavailable and not selected[1] or false);
            if imgui.Checkbox(control.label, selected) then
                config[control.key] = selected[1];
                save();
                apply();
            end
            imgui.EndDisabled();
            hint(control.hint);
            -- Keep routine status out of the way, but never hide problems.
            if row.fault or row.status:match('^Blocked') then
                imgui.TextWrapped(row.status);
                needs_retry = true;
            elseif not row.available then
                imgui.TextWrapped(row.status:match('^Waiting') and 'Log in to use this option.'
                    or 'Unavailable on this game version.');
                needs_retry = needs_retry or not row.status:match('^Waiting');
            elseif selected[1] and row.status:match('^Waiting') then
                imgui.TextDisabled('Waiting for this panel to appear.');
            end
        end
        imgui.Separator();
        if imgui.Button('Reset choices') then imgui.OpenPopup('Confirm reset choices'); end
        if imgui.BeginPopupModal('Confirm reset choices', nil,
            ImGuiWindowFlags_AlwaysAutoResize) then
            imgui.TextWrapped('Show all native UI and clear every saved choice?');
            if imgui.Button('Reset') then
                restore_everything();
                imgui.CloseCurrentPopup();
            end
            imgui.SameLine();
            if imgui.Button('Cancel') then imgui.CloseCurrentPopup(); end
            imgui.EndPopup();
        end
        if needs_retry then
            imgui.SameLine();
            if imgui.Button('Retry') then recheck(); end
        end
        if feedback then imgui.TextWrapped(feedback); end
        imgui.TextDisabled('Your choices save automatically.');
        imgui.TextDisabled('v' .. addon.version .. ' | ' .. addon.author);
    end
    imgui.End();
end

ashita.events.register('load', 'HXIUIBegone_load', function()
    print('[HXIUIBegone] Loaded. Type /hxiuibegone for settings.');
end);

ashita.events.register('d3d_present', 'HXIUIBegone_present', function()
    apply();
    draw();
end);

ashita.events.register('command', 'HXIUIBegone_command', function(event)
    local args = {};
    for token in event.command:gmatch('%S+') do args[#args + 1] = token:lower(); end
    if args[1] ~= '/hxiui' and args[1] ~= '/hxiuibegone' then return; end
    event.blocked = true;
    if #args == 1 or (#args == 2 and args[2] == 'config') then
        opened[1] = true;
    elseif #args == 2 and args[2] == 'restore' then
        restore_everything();
    elseif #args == 2 and args[2] == 'recheck' then
        recheck();
    elseif #args == 2 and (args[2] == 'on' or args[2] == 'off' or args[2] == 'toggle') then
        if args[2] == 'toggle' then
            config.enabled = not config.enabled;
        else
            config.enabled = args[2] == 'on';
        end
        save();
        apply();
        notify(config.enabled and 'Hiding enabled.' or 'Hiding paused. Your choices are kept.');
    elseif #args == 4 and args[2] == 'hide' and controller.rows[args[3]]
        and (args[4] == 'on' or args[4] == 'off') then
        config[args[3]] = args[4] == 'on';
        save();
        apply();
        notify(args[3] .. ': ' .. controller.rows[args[3]].status);
    else
        notify('Use /hxiuibegone for settings, /hxiuibegone toggle to pause/resume, or /hxiuibegone restore to reset.');
    end
end);

ashita.events.register('unload', 'HXIUIBegone_unload', function()
    controller:restore();
    save(); -- retain selections for next load, after releasing our runtime changes
end);
