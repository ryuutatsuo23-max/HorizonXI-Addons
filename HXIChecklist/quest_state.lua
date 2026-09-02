require('common');

local bit = require('bit');
local struct = require('struct');

local quest_state = {};

local flags_offset = 0x04;
local flags_length = 0x20;
local type_offset = 0x24;
local bastok_current_type = 0x0058;
local bastok_completed_type = 0x0098;

local logs = {
    current = nil,
    completed = nil,
};

local function clear_logs()
    logs.current = nil;
    logs.completed = nil;
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
        clear_logs();
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

    logs[log_name] = flags;
    return true;
end

function quest_state.get_bastok(index)
    if type(index) ~= 'number'
        or index < 0
        or index >= flags_length * 8 then
        return nil, 'Invalid Bastok quest index.';
    end

    if logs.current == nil or logs.completed == nil then
        return nil, 'Waiting for both Bastok quest logs. Zone once after loading HXIChecklist; saved manual marks remain the fallback.';
    end

    return {
        current = has_bit(logs.current, index),
        completed = has_bit(logs.completed, index),
    }, nil;
end

function quest_state.clear()
    clear_logs();
end

return quest_state;
