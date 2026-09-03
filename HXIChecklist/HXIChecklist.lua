addon.name = 'HXIChecklist';
addon.author = 'HXIChecklist contributors';
addon.version = '0.12.1';
addon.desc = 'Read-only, source-backed checklist foundation for Ashita v4 and HorizonXI.';
addon.link = 'https://github.com/HiPotionQ8/XIchecklist';

require('common');

local chat = require('chat');
local imgui = require('imgui');
local settings = require('settings');

local catalog = require('catalog');
local checklist_ui = require('checklist_ui');
local profile = require('horizon_profile');
local key_item_state = require('key_item_state');
local quest_state = require('quest_state');
local skill_levels = require('skill_levels');

local default_settings = T{
    visible = true,
    show_completed = false,
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
    },
};

local state = {
    settings = settings.load(default_settings),
    snapshot = catalog.empty_snapshot(profile),
    skill_snapshot = skill_levels.empty_snapshot(),
    last_refresh_at = 0,
    refresh_requested = true,
    ui = {
        window_open = { true },
        search = { '' },
        selected_views = {},
    },
};

state.ui.window_open[1] = state.settings.visible ~= false;

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
    value.scale_percent = math.max(75, math.min(150, tonumber(value.scale_percent) or 100));
    return value;
end

state.settings = normalize_settings(state.settings);

local function load_cached_state()
    if tonumber(state.settings.cached_state.version) ~= 1 then
        key_item_state.load_cache(nil);
        quest_state.clear();
        return;
    end
    key_item_state.load_cache(state.settings.cached_state.key_items);
    quest_state.load_area_cache('bastok', state.settings.cached_state.bastok_quests);
    quest_state.load_area_cache('sandoria', state.settings.cached_state.sandoria_quests);
    quest_state.load_area_cache('windurst', state.settings.cached_state.windurst_quests);
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

function actions.refresh()
    catalog.invalidate();
    request_refresh();
    refresh(true);
end

settings.register('settings', 'HXIChecklist_SettingsUpdate', function(updated)
    state.settings = normalize_settings(updated);
    load_cached_state();
    state.ui.window_open[1] = state.settings.visible ~= false;
    request_refresh();
end);

ashita.events.register('load', 'HXIChecklist_Load', function()
    actions.refresh();
    header_message('Loaded source-only foundation. Reads character state and incoming logs; sends no packets or gameplay input.');
end);

ashita.events.register('packet_in', 'HXIChecklist_PacketIn', function(e)
    local key_items_changed = key_item_state.handle_packet(e);
    local quests_changed, quest_area = quest_state.handle_packet(e);

    if key_items_changed and e.id == 0x055 then
        save_cached_state('key_items', key_item_state.export_cache());
    end
    if quests_changed and e.id == 0x056 and quest_area ~= nil then
        save_cached_state(
            quest_area .. '_quests',
            quest_state.export_area_cache(quest_area));
    end

    local changed = key_items_changed;
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

    if command == 'scale' then
        local value = tonumber(args[3]);
        if value == nil or value < 75 or value > 150 then
            header_message('Usage: /hc scale <75-150>');
            return;
        end
        actions.set_setting('scale_percent', math.floor(value));
        return;
    end

    header_message('Commands: /hc, /hc show, /hc hide, /hc refresh, /hc status, /hc scale <75-150>.');
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
