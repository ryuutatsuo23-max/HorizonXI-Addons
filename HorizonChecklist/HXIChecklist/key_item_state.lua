require('common');

local bit = require('bit');
local struct = require('struct');

local key_item_state = {};
local live_available_by_group = {};
local cached_available_by_group = {};

local key_items_per_group = 0x200;
local available_offset = 0x04;
local available_length = 0x40;
local type_offset = 0x84;

local function clear_live()
    live_available_by_group = {};
end

local function clear_cached()
    cached_available_by_group = {};
end

local function encode_hex(value)
    return (value:gsub('.', function(character)
        return string.format('%02X', character:byte());
    end));
end

local function decode_hex(value)
    if type(value) ~= 'string'
        or #value ~= available_length * 2
        or value:find('[^0-9A-Fa-f]') ~= nil then
        return nil;
    end

    return (value:gsub('..', function(byte)
        return string.char(tonumber(byte, 16));
    end));
end

function key_item_state.handle_packet(e)
    if e.id == 0x00A then
        clear_live();
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

    live_available_by_group[group] = available;
    cached_available_by_group[group] = available;
    return true;
end

function key_item_state.has_key_item(identifier)
    if type(identifier) ~= 'number' or identifier < 0 then
        return nil, 'Invalid key-item identifier.';
    end

    identifier = math.floor(identifier);
    local group = math.floor(identifier / key_items_per_group);
    local available = live_available_by_group[group];
    local source_note = nil;
    if available == nil then
        available = cached_available_by_group[group];
        if available ~= nil then
            source_note = 'Using saved key-item state for this character; it refreshes when the next key-item log arrives.';
        end
    end
    if available == nil then
        return nil, 'No saved key-item state exists for this character yet. Zone once to receive it; future reloads can use the character cache.';
    end

    local group_index = identifier % key_items_per_group;
    local byte_index = math.floor(group_index / 8) + 1;
    local mask = bit.lshift(1, group_index % 8);
    local value = available:byte(byte_index);
    if value == nil then
        return nil, 'The key-item log did not contain the expected byte.';
    end

    return bit.band(value, mask) ~= 0, source_note;
end

function key_item_state.load_cache(cache)
    clear_live();
    clear_cached();
    if type(cache) ~= 'table'
        or tonumber(cache.version) ~= 1
        or type(cache.groups) ~= 'table' then
        return false;
    end

    local loaded = false;
    for group, encoded in pairs(cache.groups) do
        local identifier = tonumber(group);
        local available = decode_hex(encoded);
        if identifier ~= nil
            and identifier >= 0
            and identifier <= 7
            and identifier == math.floor(identifier)
            and available ~= nil then
            cached_available_by_group[identifier] = available;
            loaded = true;
        end
    end
    return loaded;
end

function key_item_state.export_cache()
    local groups = {};
    local count = 0;
    for group, available in pairs(cached_available_by_group) do
        groups[group] = encode_hex(available);
        count = count + 1;
    end
    if count == 0 then
        return nil;
    end

    return {
        version = 1,
        groups = groups,
    };
end

function key_item_state.clear()
    clear_live();
    clear_cached();
end

return key_item_state;
