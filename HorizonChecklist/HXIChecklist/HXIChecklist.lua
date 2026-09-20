addon.name = 'HXIChecklist';
addon.author = 'DragoHorse';
addon.version = '0.29.1';
addon.desc = 'Read-only, source-backed checklist foundation for Ashita v4 and HorizonXI.';
addon.link = 'https://github.com/HiPotionQ8/XIchecklist';

require('common');

local chat = require('chat');
local imgui = require('imgui');
local settings = require('settings');

local catalog = require('catalog');
local checklist_ui = require('checklist_ui');
local exporter = require('exporter');
local profile = require('horizon_profile');
local key_item_state = require('key_item_state');
local quest_state = require('quest_state');
local mission_state = require('mission_state');
local skill_levels = require('skill_levels');
local crafting = require('crafting');
local outpost_diagnostic = require('outpost_diagnostic');

local default_settings = T{
    visible = false,
    show_completed = false,
    show_active = true,
    show_open = true,
    show_unknown = true,
    show_unavailable = false,
    scale_percent = 100,
    manual_completed = T{},
    cached_state = T{
        version = 1,
        key_items = T{},
        bastok_quests = T{},
        sandoria_quests = T{},
        windurst_quests = T{},
        jeuno_quests = T{},
        other_quests = T{},
        outlands_quests = T{},
        ahturhgan_quests = T{},
        sandoria_missions = T{},
        bastok_missions = T{},
        windurst_missions = T{},
        zilart_missions = T{},
        promathia_missions = T{},
        ahturhgan_missions = T{},
    },
};

local state = {
    settings = settings.load(default_settings),
    snapshot = catalog.empty_snapshot(profile),
    skill_snapshot = skill_levels.empty_snapshot(),
    last_refresh_at = 0,
    refresh_requested = true,
    ui = {
        addon_version = addon.version,
        window_open = { false },
        search = { '' },
        selected_views = {},
        active_tab = 'quests',
    },
};

-- Visibility belongs to this session, not the previous saved character settings.
state.settings.visible = false;

local refresh_interval_seconds = 0.75;

local function tick_seconds()
    local ok, value = pcall(function()
        return ashita.time.tick64() / 1000;
    end);
    return ok and value or os.clock();
end

local function normalize_settings(value)
    value.manual_completed = value.manual_completed or T{};
    value.cached_state = value.cached_state or T{};
    value.cached_state.version = value.cached_state.version or 1;
    value.cached_state.key_items = value.cached_state.key_items or T{};
    value.cached_state.bastok_quests = value.cached_state.bastok_quests or T{};
    value.cached_state.sandoria_quests = value.cached_state.sandoria_quests or T{};
    value.cached_state.windurst_quests = value.cached_state.windurst_quests or T{};
    value.cached_state.jeuno_quests = value.cached_state.jeuno_quests or T{};
    value.cached_state.other_quests = value.cached_state.other_quests or T{};
    value.cached_state.outlands_quests = value.cached_state.outlands_quests or T{};
    value.cached_state.ahturhgan_quests = value.cached_state.ahturhgan_quests or T{};
    value.cached_state.sandoria_missions = value.cached_state.sandoria_missions or T{};
    value.cached_state.bastok_missions = value.cached_state.bastok_missions or T{};
    value.cached_state.windurst_missions = value.cached_state.windurst_missions or T{};
    value.cached_state.zilart_missions = value.cached_state.zilart_missions or T{};
    value.cached_state.promathia_missions = value.cached_state.promathia_missions or T{};
    value.cached_state.ahturhgan_missions = value.cached_state.ahturhgan_missions or T{};
    if value.show_active == nil then value.show_active = true end;
    if value.show_open == nil then value.show_open = true end;
    value.scale_percent = math.max(75, math.min(150, tonumber(value.scale_percent) or 100));
    return value;
end

state.settings = normalize_settings(state.settings);

local function load_cached_state()
    if tonumber(state.settings.cached_state.version) ~= 1 then
        key_item_state.load_cache(nil);
        quest_state.clear();
        mission_state.clear();
        return;
    end
    key_item_state.load_cache(state.settings.cached_state.key_items);
    quest_state.load_area_cache('bastok', state.settings.cached_state.bastok_quests);
    quest_state.load_area_cache('sandoria', state.settings.cached_state.sandoria_quests);
    quest_state.load_area_cache('windurst', state.settings.cached_state.windurst_quests);
    quest_state.load_area_cache('jeuno', state.settings.cached_state.jeuno_quests);
    quest_state.load_area_cache('other', state.settings.cached_state.other_quests);
    quest_state.load_area_cache('outlands', state.settings.cached_state.outlands_quests);
    quest_state.load_area_cache('ahturhgan', state.settings.cached_state.ahturhgan_quests);
    mission_state.load_area_cache('sandoria', state.settings.cached_state.sandoria_missions);
    mission_state.load_area_cache('bastok', state.settings.cached_state.bastok_missions);
    mission_state.load_area_cache('windurst', state.settings.cached_state.windurst_missions);
    mission_state.load_area_cache('zilart', state.settings.cached_state.zilart_missions);
    mission_state.load_area_cache('promathia', state.settings.cached_state.promathia_missions);
    mission_state.load_area_cache('ahturhgan', state.settings.cached_state.ahturhgan_missions);
end

local function save_cached_state(key, value)
    if value == nil or tonumber(state.settings.cached_state.version) ~= 1 then
        return;
    end
    state.settings.cached_state[key] = value;
    settings.save();
end

load_cached_state();

local function request_refresh()
    state.refresh_requested = true;
end

local function refresh(force)
    local now = tick_seconds();
    if not force
        and not state.refresh_requested
        and (now - state.last_refresh_at) < refresh_interval_seconds then
        return;
    end

    state.snapshot = catalog.build_snapshot(profile, state.settings.manual_completed);
    state.snapshot.crafting = crafting.build_snapshot();
    state.skill_snapshot = skill_levels.build_snapshot();
    state.last_refresh_at = now;
    state.refresh_requested = false;
end

local function header_message(message)
    print(chat.header(addon.name):append(chat.message(message)));
end

local function status_message()
    refresh(true);
    local summary = state.snapshot.summary;
    header_message(('Profile %s: %d/%d known goals complete; %d unknown; %d unavailable.')
        :fmt(profile.version, summary.complete, summary.known_total,
            summary.unknown, summary.unavailable));
end

local actions = {};

function actions.set_visible(value)
    state.settings.visible = value == true;
    state.ui.window_open[1] = state.settings.visible;
    settings.save();
end

function actions.set_setting(key, value)
    if key ~= 'show_completed'
        and key ~= 'show_active'
        and key ~= 'show_open'
        and key ~= 'show_unknown'
        and key ~= 'show_unavailable'
        and key ~= 'scale_percent' then
        return;
    end

    state.settings[key] = value;
    state.settings = normalize_settings(state.settings);
    settings.save();
end

function actions.open_source(url)
    if type(url) ~= 'string' or not url:match('^https://') then
        return;
    end
    ashita.misc.open_url(url);
end

function actions.set_manual_completed(id, completed)
    if catalog.set_manual_completed(profile, state.settings.manual_completed, id, completed) then
        settings.save();
        request_refresh();
    end
end

function actions.refresh()
    catalog.invalidate();
    request_refresh();
    refresh(true);
end

function actions.export_visible()
    refresh(true);
    local data, reason = checklist_ui.build_export(
        state.snapshot, state.skill_snapshot, state.settings, state.ui);
    if not data then
        header_message('Export failed: ' .. tostring(reason));
        return;
    end
    local path, count, write_reason = exporter.write(addon.path, data);
    if not path then
        header_message('Export failed: ' .. tostring(write_reason));
        return;
    end
    header_message(('Exported %d visible %s row(s) to %s'):fmt(
        count, data.label, path));
end

settings.register('settings', 'HXIChecklist_SettingsUpdate', function(updated)
    outpost_diagnostic.clear();
    state.settings = normalize_settings(updated);
    state.settings.visible = state.ui.window_open[1] == true;
    load_cached_state();
    request_refresh();
end);

ashita.events.register('load', 'HXIChecklist_Load', function()
    actions.refresh();
    header_message('Loaded source-only foundation. Reads character state and incoming logs; sends no packets or gameplay input.');
end);

ashita.events.register('packet_in', 'HXIChecklist_PacketIn', function(e)
    if outpost_diagnostic.handle_packet(e) then
        header_message('Menu captured; diagnostic switched off. Use /hc outpostdiag show.');
    end
    local key_items_changed = key_item_state.handle_packet(e);
    local quests_changed, quest_area = quest_state.handle_packet(e);
    local missions_changed, mission_areas = mission_state.handle_packet(e);

    if key_items_changed and e.id == 0x055 then
        save_cached_state('key_items', key_item_state.export_cache());
    end
    if quests_changed and e.id == 0x056 and quest_area ~= nil then
        save_cached_state(
            quest_area .. '_quests',
            quest_state.export_area_cache(quest_area));
    end

    if missions_changed and e.id == 0x056 then
        local save_missions = false;
        for _, area in ipairs(mission_areas or {}) do
            local value = mission_state.export_area_cache(area);
            if value ~= nil then
                state.settings.cached_state[area .. '_missions'] = value;
                save_missions = true;
            end
        end
        if save_missions then settings.save() end;
    end

    local changed = key_items_changed or missions_changed;
    if quests_changed then
        changed = true;
    end
    if changed then
        request_refresh();
    end
end);

ashita.events.register('command', 'HXIChecklist_Command', function(e)
    local args = e.command:args();
    if #args == 0
        or not args[1]:any('/hxichecklist', '/horizonchecklist', '/hcheck', '/hc') then
        return;
    end

    e.blocked = true;
    local command = #args >= 2 and args[2]:lower() or '';

    if command == 'outpostdiag' then
        local operation = #args >= 3 and args[3]:lower() or 'status';
        if operation == 'arm' then
            outpost_diagnostic.arm();
            header_message('Diagnostic armed for 60 seconds. Manually open one Outpost warp NPC menu; any first 0x034 menu is captured, then observation stops.');
        elseif operation == 'off' then
            outpost_diagnostic.clear();
            header_message('Diagnostic off; captured data cleared.');
        elseif operation == 'show' then
            for _, line in ipairs(outpost_diagnostic.lines()) do header_message(line) end;
        elseif operation == 'status' then
            header_message('Outpost diagnostic: ' .. outpost_diagnostic.status());
        else
            header_message('Usage: /hc outpostdiag arm|show|status|off');
        end
        return;
    end

    if command == '' or command == 'toggle' then
        actions.set_visible(not state.settings.visible);
        return;
    end

    if command == 'show' then
        actions.set_visible(true);
        return;
    end

    if command == 'hide' then
        actions.set_visible(false);
        return;
    end

    if command == 'refresh' then
        actions.refresh();
        header_message('Checklist state and resource lookups refreshed.');
        return;
    end

    if command == 'status' then
        status_message();
        return;
    end

    if command == 'export' then
        actions.export_visible();
        return;
    end

    if command == 'scale' then
        local value = tonumber(args[3]);
        if value == nil or value < 75 or value > 150 then
            header_message('Usage: /hc scale <75-150>');
            return;
        end
        actions.set_setting('scale_percent', math.floor(value));
        return;
    end

    header_message('Commands: /hc, /hc show, /hc hide, /hc refresh, /hc status, /hc export, /hc scale <75-150>.');
end);

ashita.events.register('d3d_present', 'HXIChecklist_Present', function()
    if not state.settings.visible then
        return;
    end

    refresh(false);
    checklist_ui.render(
        profile, state.snapshot, state.skill_snapshot,
        state.settings, state.ui, actions, imgui);
end);

ashita.events.register('unload', 'HXIChecklist_Unload', function()
    settings.save();
end);
