local support_url = 'https://github.com/ryuutatsuo23-max/HXIPresence';

addon.name = 'HXIPresence';
addon.author = 'DragoHorse';
addon.version = '0.4.4';
addon.desc = 'Privacy-controlled Discord Rich Presence for HorizonXI.';
addon.link = support_url;

require('common');

local bit = require('bit');
local chat = require('chat');
local discord_ipc = require('discord_ipc');
local imgui = require('imgui');
local presence_builder = require('presence_builder');
local settings = require('settings');

local shared_application_id = '1543549056184360960';
local fixed_large_image_key = '';
local fixed_large_image_text = 'HorizonXI';
local poll_interval_seconds = 1;
local reconnect_interval_seconds = 15;
local minimum_publish_interval_seconds = 15;
local acknowledgement_timeout_seconds = 10;
local looking_for_party_flag_mask = 0x00100000;

local default_settings = T{
    enabled = false,
    application_id = shared_application_id,
    show_character_name = false,
    show_job = false,
    show_level = false,
    show_subjob = false,
    show_subjob_level = false,
    show_zone = false,
    show_looking_for_party = false,
    show_party_size = false,
    show_elapsed_time = false,
};

local runtime = T{
    settings = settings.load(default_settings),
    last_poll_at = 0,
    last_connect_attempt_at = -reconnect_interval_seconds,
    last_publish_at = -minimum_publish_interval_seconds,
    last_signature = nil,
    pending_activity = nil,
    pending_signature = nil,
    pending_publish_nonce = nil,
    pending_publish_sent_at = nil,
    session_started_at = nil,
    was_logged_in = false,
    published = false,
    last_notice = '',
};

local settings_ui = T{
    is_open = {false},
    feedback = 'Settings are private until presence is enabled.',
};

local control_ui = T{
    is_open = {false},
};

local function tick_seconds()
    return ashita.time.tick64() / 1000;
end

local function trim(value)
    if value == nil then
        return '';
    end
    return tostring(value):gsub('^%s+', ''):gsub('%s+$', '');
end

local function notify(value)
    print(chat.header(addon.name):append(chat.message(value)));
end

local function notify_once(value)
    if runtime.last_notice == value then
        return;
    end
    runtime.last_notice = value;
    notify(value);
end

local function mark_for_refresh()
    runtime.last_signature = nil;
    runtime.pending_activity = nil;
    runtime.pending_signature = nil;
    runtime.pending_publish_nonce = nil;
    runtime.pending_publish_sent_at = nil;
end

local function save_and_refresh()
    settings.save();
    mark_for_refresh();
end

local function resource_string(table_name, resource_id)
    local ok, value = pcall(function()
        return AshitaCore:GetResourceManager():GetString(table_name, resource_id);
    end);
    if not ok then
        return '';
    end
    return trim(value);
end

local function read_player_snapshot()
    local memory = AshitaCore:GetMemoryManager();
    local player = memory:GetPlayer();
    local party = memory:GetParty();
    local entity = memory:GetEntity();
    local login_status = player ~= nil and (tonumber(player:GetLoginStatus()) or 0) or 0;
    if player == nil or party == nil or entity == nil or login_status ~= 2
        or party:GetMemberIsActive(0) == 0
        or party:GetMemberServerId(0) == 0 then
        return nil, login_status;
    end

    local main_job_id = tonumber(party:GetMemberMainJob(0)) or 0;
    local sub_job_id = tonumber(party:GetMemberSubJob(0)) or 0;
    local zone_id = tonumber(party:GetMemberZone(0)) or 0;
    local player_index = tonumber(party:GetMemberTargetIndex(0)) or 0;
    local render_flags_1 = player_index > 0
        and (tonumber(entity:GetRenderFlags1(player_index)) or 0)
        or 0;
    local party_size = tonumber(party:GetAlliancePartyMemberCount1()) or 0;
    if party_size < 1 or party_size > 6 then
        party_size = 0;
        for member_index = 0, 5 do
            if party:GetMemberIsActive(member_index) ~= 0 then
                party_size = party_size + 1;
            end
        end
    end
    party_size = math.max(1, math.min(6, party_size));

    local character_name = '';
    if runtime.settings.show_character_name == true then
        character_name = trim(party:GetMemberName(0));
    end

    return {
        character_name = character_name,
        main_job = resource_string('jobs.names_abbr', main_job_id),
        main_level = tonumber(party:GetMemberMainJobLevel(0)),
        sub_job = resource_string('jobs.names_abbr', sub_job_id),
        sub_level = tonumber(party:GetMemberSubJobLevel(0)),
        zone = resource_string('zones.names', zone_id),
        looking_for_party = bit.band(render_flags_1, looking_for_party_flag_mask) ~= 0,
        party_size = party_size,
    }, login_status;
end

local function clear_and_disconnect()
    if discord_ipc.is_connected() then
        if runtime.published or runtime.pending_publish_nonce ~= nil then
            discord_ipc.clear_activity();
        end
        discord_ipc.disconnect();
    end
    runtime.published = false;
    runtime.last_signature = nil;
    runtime.pending_activity = nil;
    runtime.pending_signature = nil;
    runtime.pending_publish_nonce = nil;
    runtime.pending_publish_sent_at = nil;
end

local function apply_updated_settings(updated)
    if updated == nil then
        return;
    end

    runtime.settings = updated;
    mark_for_refresh();
    runtime.last_connect_attempt_at = -reconnect_interval_seconds;
    if runtime.settings.enabled == true then
        settings_ui.feedback = 'Saved settings restored; waiting for the local Discord client.';
    else
        clear_and_disconnect();
        settings_ui.feedback = 'Presence is disabled for this character.';
    end
end

settings.register('settings', 'HXIPresence_SettingsUpdate', apply_updated_settings);

local function ensure_connected(now)
    if discord_ipc.is_connected() then
        return discord_ipc.is_ready();
    end
    if (now - runtime.last_connect_attempt_at) < reconnect_interval_seconds then
        return false;
    end

    runtime.last_connect_attempt_at = now;
    local ok = discord_ipc.connect(runtime.settings.application_id);
    if not ok then
        notify_once('Discord is not available; retrying every 15 seconds.');
        return false;
    end

    runtime.last_notice = '';
    runtime.last_publish_at = -minimum_publish_interval_seconds;
    runtime.last_signature = nil;
    notify('Connected to the local Discord desktop client; waiting for READY.');
    return false;
end

local function update_login_state(snapshot, login_status)
    local logged_in = snapshot ~= nil;
    if logged_in then
        if not runtime.was_logged_in then
            if runtime.session_started_at == nil then
                runtime.session_started_at = os.time();
            end
            mark_for_refresh();
        end
        runtime.was_logged_in = true;
        return;
    end

    -- Keep the last activity visible while Ashita temporarily reports zoning.
    if login_status ~= 0 then
        return;
    end

    runtime.session_started_at = nil;
    if discord_ipc.is_connected()
        and (runtime.published or runtime.pending_publish_nonce ~= nil) then
        discord_ipc.clear_activity();
    end
    runtime.published = false;
    runtime.last_signature = nil;
    runtime.pending_activity = nil;
    runtime.pending_signature = nil;
    runtime.pending_publish_nonce = nil;
    runtime.pending_publish_sent_at = nil;
    runtime.was_logged_in = false;
end

local function apply_ipc_result(now)
    if runtime.pending_publish_nonce == nil then
        return;
    end

    local acknowledged_nonce = discord_ipc.get_last_activity_ack_nonce();
    if acknowledged_nonce == runtime.pending_publish_nonce then
        runtime.last_signature = runtime.pending_signature;
        runtime.pending_publish_nonce = nil;
        runtime.pending_publish_sent_at = nil;
        runtime.published = true;
        runtime.last_notice = '';
        settings_ui.feedback = 'Discord acknowledged the active presence.';
        return;
    end

    local error_nonce, error_message = discord_ipc.get_last_activity_error();
    if error_nonce == runtime.pending_publish_nonce then
        runtime.pending_publish_nonce = nil;
        runtime.pending_publish_sent_at = nil;
        runtime.published = false;
        settings_ui.feedback = 'Discord rejected the presence: ' .. error_message;
        notify_once(settings_ui.feedback);
        return;
    end

    if runtime.pending_publish_sent_at ~= nil
        and (now - runtime.pending_publish_sent_at) >= acknowledgement_timeout_seconds then
        discord_ipc.disconnect();
        runtime.pending_publish_nonce = nil;
        runtime.pending_publish_sent_at = nil;
        runtime.published = false;
        runtime.last_connect_attempt_at = now;
        settings_ui.feedback = 'Discord acknowledgement timed out; reconnecting.';
        notify_once(settings_ui.feedback);
    end
end

local function publish_pending(now)
    if runtime.pending_activity == nil
        or runtime.pending_publish_nonce ~= nil
        or runtime.pending_signature == runtime.last_signature
        or (now - runtime.last_publish_at) < minimum_publish_interval_seconds then
        return;
    end

    local ok, nonce_or_reason = discord_ipc.set_activity(runtime.pending_activity);
    if not ok then
        if discord_ipc.is_connected() then
            settings_ui.feedback = 'Discord is not ready to publish yet.';
        else
            runtime.published = false;
            runtime.last_connect_attempt_at = now;
            notify_once('Lost the local Discord connection; retrying.');
        end
        return;
    end

    runtime.last_publish_at = now;
    runtime.pending_publish_nonce = nonce_or_reason;
    runtime.pending_publish_sent_at = now;
    settings_ui.feedback = 'Presence sent; waiting for Discord acknowledgement.';
end

local function update_presence(now)
    discord_ipc.tick();
    apply_ipc_result(now);

    if runtime.settings.enabled ~= true then
        clear_and_disconnect();
        return;
    end
    if trim(runtime.settings.application_id) == '' then
        clear_and_disconnect();
        notify_once('The configured Discord application ID is missing.');
        return;
    end

    local snapshot, login_status = read_player_snapshot();
    update_login_state(snapshot, login_status);
    if snapshot == nil then
        return;
    end
    if not ensure_connected(now) then
        return;
    end

    local activity, signature = presence_builder.build(
        snapshot,
        runtime.settings,
        runtime.session_started_at,
        fixed_large_image_key,
        fixed_large_image_text
    );
    runtime.pending_activity = activity;
    runtime.pending_signature = signature;
    publish_pending(now);
end

local function set_presence_enabled(value)
    runtime.settings.enabled = value == true;
    settings.save();
    if runtime.settings.enabled then
        mark_for_refresh();
        runtime.last_connect_attempt_at = -reconnect_interval_seconds;
        settings_ui.feedback = 'Presence enabled; waiting for the local Discord client.';
    else
        clear_and_disconnect();
        settings_ui.feedback = 'Presence disabled and cleared from Discord.';
    end
end

local function connection_status()
    if runtime.settings.enabled ~= true then
        return 'Off';
    end
    if discord_ipc.is_connected() then
        if discord_ipc.is_ready() ~= true then
            return 'Connected; handshaking';
        end
        if runtime.pending_publish_nonce ~= nil then
            return 'Publishing; awaiting acknowledgement';
        end
        return runtime.published and 'Discord acknowledged active' or 'Ready';
    end
    if runtime.was_logged_in ~= true then
        return 'Waiting for character login';
    end
    return 'Waiting for Discord';
end

local function draw_boolean_setting(label, field)
    local value = {runtime.settings[field] == true};
    if imgui.Checkbox(label, value) then
        runtime.settings[field] = value[1];
        save_and_refresh();
        settings_ui.feedback = label .. (value[1] and ' enabled.' or ' disabled.');
    end
end

local function draw_control_ui()
    if not control_ui.is_open[1] then
        return;
    end

    imgui.SetNextWindowPos({20, 220}, ImGuiCond_FirstUseEver);
    local flags = bit.bor(
        ImGuiWindowFlags_AlwaysAutoResize,
        ImGuiWindowFlags_NoCollapse,
        ImGuiWindowFlags_NoFocusOnAppearing
    );
    if imgui.Begin('HXIPresence##HXIPresenceControl', control_ui.is_open, flags) then
        local enabled = {runtime.settings.enabled == true};
        if imgui.Checkbox('Discord presence##HXIPresenceControlEnabled', enabled) then
            set_presence_enabled(enabled[1]);
        end
        imgui.SameLine();
        if imgui.SmallButton('Settings##HXIPresenceOpenSettings') then
            settings_ui.is_open[1] = true;
        end
        imgui.TextDisabled(connection_status());
    end
    imgui.End();
end

local function draw_presence_preview()
    imgui.Text('Preview');
    imgui.Separator();
    imgui.Text('Playing HorizonXI');

    local snapshot = read_player_snapshot();
    if snapshot == nil then
        imgui.TextDisabled('Log in to preview the selected character details.');
        return;
    end

    local activity = presence_builder.build(
        snapshot,
        runtime.settings,
        runtime.session_started_at,
        fixed_large_image_key,
        fixed_large_image_text
    );
    if activity.details ~= nil then
        imgui.Text(activity.details);
    else
        imgui.TextDisabled('No job details selected.');
    end
    if activity.state ~= nil then
        if activity.party ~= nil and activity.party.size ~= nil then
            imgui.Text(('%s (%d of %d)'):fmt(
                activity.state,
                activity.party.size[1],
                activity.party.size[2]
            ));
        else
            imgui.Text(activity.state);
        end
    else
        imgui.TextDisabled('No secondary details selected.');
    end
    if activity.timestamps ~= nil then
        imgui.TextDisabled('Elapsed session time shown by Discord.');
    end
end

local function draw_settings_ui()
    if not settings_ui.is_open[1] then
        return;
    end

    imgui.SetNextWindowSize({430, 0}, ImGuiCond_FirstUseEver);
    if imgui.Begin(
        'HXIPresence Settings##HXIPresenceSettings',
        settings_ui.is_open,
        ImGuiWindowFlags_AlwaysAutoResize
    ) then
        imgui.Text('Discord Rich Presence');
        imgui.Separator();
        imgui.Text('Status: ' .. connection_status());
        imgui.TextDisabled(
            'Application: HorizonXI (' .. tostring(runtime.settings.application_id or '') .. ')'
        );

        imgui.Spacing();
        imgui.Text('Optional details');
        imgui.Separator();
        imgui.TextWrapped(
            'Discord has two activity lines below the game title. Job information uses '
            .. 'the first line; zone, Looking for Party, and party status share the second line.'
        );
        imgui.Spacing();
        draw_boolean_setting('Show character name', 'show_character_name');
        draw_boolean_setting('Show main job', 'show_job');
        draw_boolean_setting('Show main-job level', 'show_level');
        draw_boolean_setting('Show subjob', 'show_subjob');
        draw_boolean_setting('Show subjob level', 'show_subjob_level');
        draw_boolean_setting('Show current zone', 'show_zone');
        draw_boolean_setting('Show Looking for Party status', 'show_looking_for_party');
        draw_boolean_setting('Show party size', 'show_party_size');
        draw_boolean_setting('Use full session elapsed time', 'show_elapsed_time');
        imgui.TextDisabled('Discord adds party fill to the second line, for example (3 of 6).');
        imgui.TextDisabled('When off, Discord may still show time since the last presence update.');
        imgui.TextDisabled('Character name is read and published only when its option is enabled.');

        imgui.Spacing();
        draw_presence_preview();

        imgui.Spacing();
        imgui.Separator();
        if support_url:match('^https://') ~= nil then
            if imgui.SmallButton('Repository / support##HXIPresenceSupport') then
                ashita.misc.open_url(support_url);
            end
        else
            imgui.TextDisabled('Repository and support link will be added before publication.');
        end
        imgui.TextDisabled(settings_ui.feedback);
        imgui.TextWrapped('Approved by HorizonXI staff on September 4, 2026.');
    end
    imgui.End();
end

ashita.events.register('load', 'HXIPresence_Load', function()
    notify('Loaded. Use /hxipresence to open or close the control window.');
end);

ashita.events.register('command', 'HXIPresence_Command', function(e)
    local args = e.command:args();
    if #args == 0 or trim(args[1]):lower() ~= '/hxipresence' then
        return;
    end

    e.blocked = true;
    if #args ~= 1 then
        notify('Usage: /hxipresence');
        return;
    end
    control_ui.is_open[1] = not control_ui.is_open[1];
end);

ashita.events.register('d3d_present', 'HXIPresence_Present', function()
    local now = tick_seconds();
    if runtime.last_poll_at == 0 or (now - runtime.last_poll_at) >= poll_interval_seconds then
        runtime.last_poll_at = now;
        update_presence(now);
    end
    draw_control_ui();
    draw_settings_ui();
end);

ashita.events.register('unload', 'HXIPresence_Unload', function()
    clear_and_disconnect();
    settings.save();
end);
