require('common');

local bit = require('bit');
local struct = require('struct');

local quest_state = {};

local flags_offset = 0x04;
local flags_length = 0x20;
local type_offset = 0x24;
local area_configs = {
    sandoria = { label = "San d'Oria", current_type = 0x0050, completed_type = 0x0090 },
    bastok = { label = 'Bastok', current_type = 0x0058, completed_type = 0x0098 },
    windurst = { label = 'Windurst', current_type = 0x0060, completed_type = 0x00A0 },
    jeuno = { label = 'Jeuno', current_type = 0x0068, completed_type = 0x00A8 },
};

local live_logs = {};
local cached_logs = {};

local function empty_logs()
    return { current = nil, completed = nil };
end

local function clear_live_logs()
    for area in pairs(area_configs) do
        live_logs[area] = empty_logs();
    end
end

local function clear_cached_logs()
    for area in pairs(area_configs) do
        cached_logs[area] = empty_logs();
    end
end

clear_live_logs();
clear_cached_logs();

local function encode_hex(value)
    return (value:gsub('.', function(character)
        return string.format('%02X', character:byte());
    end));
end

local function decode_hex(value)
    if type(value) ~= 'string'
        or #value ~= flags_length * 2
        or value:find('[^0-9A-Fa-f]') ~= nil then
        return nil;
    end
    return (value:gsub('..', function(byte)
        return string.char(tonumber(byte, 16));
    end));
end

local function has_bit(flags, index)
    local byte_index = math.floor(index / 8) + 1;
    local value = flags:byte(byte_index);
    if value == nil then
        return nil;
    end
    local mask = bit.lshift(1, index % 8);
    return bit.band(value, mask) ~= 0;
end

local function identify_log(log_type)
    for area, config in pairs(area_configs) do
        if log_type == config.current_type then
            return area, 'current';
        elseif log_type == config.completed_type then
            return area, 'completed';
        end
    end
    return nil, nil;
end

function quest_state.handle_packet(e)
    if e.id == 0x00A then
        clear_live_logs();
        return true, nil;
    end
    if e.id ~= 0x056 or type(e.data) ~= 'string' then
        return false, nil;
    end

    local ok, log_type = pcall(struct.unpack, 'H', e.data, type_offset + 1);
    if not ok then
        return false, nil;
    end
    local area, log_name = identify_log(log_type);
    if area == nil then
        return false, nil;
    end

    local flags = e.data:sub(flags_offset + 1, flags_offset + flags_length);
    if #flags ~= flags_length then
        return false, nil;
    end
    live_logs[area][log_name] = flags;
    if live_logs[area].current ~= nil and live_logs[area].completed ~= nil then
        cached_logs[area].current = live_logs[area].current;
        cached_logs[area].completed = live_logs[area].completed;
    end
    return true, area;
end

function quest_state.get_area(area, index)
    local config = area_configs[area];
    if config == nil then
        return nil, 'Unknown quest area.';
    end
    if type(index) ~= 'number' or index < 0 or index >= flags_length * 8 then
        return nil, string.format('Invalid %s quest index.', config.label);
    end

    local selected = nil;
    local source = nil;
    if live_logs[area].current ~= nil and live_logs[area].completed ~= nil then
        selected = live_logs[area];
        source = 'live';
    elseif cached_logs[area].current ~= nil and cached_logs[area].completed ~= nil then
        selected = cached_logs[area];
        source = 'cache';
    else
        return nil, string.format(
            'No saved %s quest state exists for this character yet. Zone once to receive it; future reloads can use the character cache.',
            config.label);
    end

    return {
        current = has_bit(selected.current, index),
        completed = has_bit(selected.completed, index),
        source = source,
    }, nil;
end

function quest_state.get_bastok(index)
    return quest_state.get_area('bastok', index);
end

function quest_state.get_sandoria(index)
    return quest_state.get_area('sandoria', index);
end

function quest_state.get_windurst(index)
    return quest_state.get_area('windurst', index);
end

function quest_state.load_area_cache(area, cache)
    if area_configs[area] == nil then
        return false;
    end
    live_logs[area] = empty_logs();
    cached_logs[area] = empty_logs();
    if type(cache) ~= 'table' or tonumber(cache.version) ~= 1 then
        return false;
    end

    local current = decode_hex(cache.current);
    local completed = decode_hex(cache.completed);
    if current == nil or completed == nil then
        return false;
    end
    cached_logs[area].current = current;
    cached_logs[area].completed = completed;
    return true;
end

function quest_state.export_area_cache(area)
    if area_configs[area] == nil
        or live_logs[area].current == nil
        or live_logs[area].completed == nil then
        return nil;
    end
    return {
        version = 1,
        current = encode_hex(live_logs[area].current),
        completed = encode_hex(live_logs[area].completed),
    };
end

-- Preserve the established Bastok-only API for existing callers and caches.
function quest_state.load_cache(cache)
    return quest_state.load_area_cache('bastok', cache);
end

function quest_state.export_cache()
    return quest_state.export_area_cache('bastok');
end

function quest_state.clear()
    clear_live_logs();
    clear_cached_logs();
end

return quest_state;
