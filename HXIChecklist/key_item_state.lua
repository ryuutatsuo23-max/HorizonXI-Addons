require('common');

local bit = require('bit');
local struct = require('struct');

local key_item_state = {};
local available_by_group = {};

local key_items_per_group = 0x200;
local available_offset = 0x04;
local available_length = 0x40;
local type_offset = 0x84;

local function clear()
    available_by_group = {};
end

function key_item_state.handle_packet(e)
    if e.id == 0x00A then
        clear();
        return true;
    end

    if e.id ~= 0x055 or type(e.data) ~= 'string' then
        return false;
    end

    local ok, group = pcall(struct.unpack, 'L', e.data, type_offset + 1);
    if not ok or type(group) ~= 'number' or group < 0 or group > 7 then
        return false;
    end

    local first = available_offset + 1;
    local last = available_offset + available_length;
    local available = e.data:sub(first, last);
    if #available ~= available_length then
        return false;
    end

    available_by_group[group] = available;
    return true;
end

function key_item_state.has_key_item(identifier)
    if type(identifier) ~= 'number' or identifier < 0 then
        return nil, 'Invalid key-item identifier.';
    end

    identifier = math.floor(identifier);
    local group = math.floor(identifier / key_items_per_group);
    local available = available_by_group[group];
    if available == nil then
        return nil, 'Waiting for the key-item log. Zone once after loading HXIChecklist.';
    end

    local group_index = identifier % key_items_per_group;
    local byte_index = math.floor(group_index / 8) + 1;
    local mask = bit.lshift(1, group_index % 8);
    local value = available:byte(byte_index);
    if value == nil then
        return nil, 'The key-item log did not contain the expected byte.';
    end

    return bit.band(value, mask) ~= 0, nil;
end

function key_item_state.clear()
    clear();
end

return key_item_state;
