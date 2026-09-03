require('common');

local bit = require('bit');
local struct = require('struct');

local quest_state = {};

local flags_offset = 0x04;
local flags_length = 0x20;
local type_offset = 0x24;
local bastok_current_type = 0x0058;
local bastok_completed_type = 0x0098;

local live_logs = {
    current = nil,
    completed = nil,
};

local cached_logs = {
    current = nil,
    completed = nil,
};

local function clear_live_logs()
    live_logs.current = nil;
    live_logs.completed = nil;
end

local function clear_cached_logs()
    cached_logs.current = nil;
    cached_logs.completed = nil;
end

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

function quest_state.handle_packet(e)
    if e.id == 0x00A then
        clear_live_logs();
        return true;
    end

    if e.id ~= 0x056 or type(e.data) ~= 'string' then
        return false;
    end

    local ok, log_type = pcall(struct.unpack, 'H', e.data, type_offset + 1);
    if not ok then
        return false;
    end

    local log_name = nil;
    if log_type == bastok_current_type then
        log_name = 'current';
    elseif log_type == bastok_completed_type then
        log_name = 'completed';
    else
        return false;
    end

    local flags = e.data:sub(flags_offset + 1, flags_offset + flags_length);
    if #flags ~= flags_length then
        return false;
    end

    live_logs[log_name] = flags;
    if live_logs.current ~= nil and live_logs.completed ~= nil then
        cached_logs.current = live_logs.current;
        cached_logs.completed = live_logs.completed;
    end
    return true;
end

function quest_state.get_bastok(index)
    if type(index) ~= 'number'
        or index < 0
        or index >= flags_length * 8 then
        return nil, 'Invalid Bastok quest index.';
    end

    local selected = nil;
    local source = nil;
    if live_logs.current ~= nil and live_logs.completed ~= nil then
        selected = live_logs;
        source = 'live';
    elseif cached_logs.current ~= nil and cached_logs.completed ~= nil then
        selected = cached_logs;
        source = 'cache';
    else
        return nil, 'No saved Bastok quest state exists for this character yet. Zone once to receive it; future reloads can use the character cache.';
    end

    return {
        current = has_bit(selected.current, index),
        completed = has_bit(selected.completed, index),
        source = source,
    }, nil;
end

function quest_state.load_cache(cache)
    clear_live_logs();
    clear_cached_logs();
    if type(cache) ~= 'table' or tonumber(cache.version) ~= 1 then
        return false;
    end

    local current = decode_hex(cache.current);
    local completed = decode_hex(cache.completed);
    if current == nil or completed == nil then
        return false;
    end

    cached_logs.current = current;
    cached_logs.completed = completed;
    return true;
end

function quest_state.export_cache()
    if live_logs.current == nil or live_logs.completed == nil then
        return nil;
    end

    return {
        version = 1,
        current = encode_hex(live_logs.current),
        completed = encode_hex(live_logs.completed),
    };
end

function quest_state.clear()
    clear_live_logs();
    clear_cached_logs();
end

return quest_state;
