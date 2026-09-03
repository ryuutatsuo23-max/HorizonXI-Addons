package.preload['common'] = function()
    return true;
end;

package.preload['bit'] = function()
    return {
        band = function(left, right)
            return left & right;
        end,
        lshift = function(value, count)
            return value << count;
        end,
    };
end;

package.preload['struct'] = function()
    return {
        unpack = function(format, data, position)
            assert(format == 'L');
            local a, b, c, d = data:byte(position, position + 3);
            assert(d ~= nil);
            return a + (b << 8) + (c << 16) + (d << 24);
        end,
    };
end;

local function key_item_packet(group, owned_ids)
    local bytes = {};
    for index = 1, 0x88 do
        bytes[index] = 0;
    end

    for _, identifier in ipairs(owned_ids) do
        assert(math.floor(identifier / 0x200) == group);
        local group_index = identifier % 0x200;
        local byte_index = math.floor(group_index / 8);
        local position = 0x04 + byte_index + 1;
        bytes[position] = bytes[position] | (1 << (group_index % 8));
    end

    local type_position = 0x84 + 1;
    bytes[type_position] = group & 0xFF;
    bytes[type_position + 1] = (group >> 8) & 0xFF;
    bytes[type_position + 2] = (group >> 16) & 0xFF;
    bytes[type_position + 3] = (group >> 24) & 0xFF;

    local characters = {};
    for index, value in ipairs(bytes) do
        characters[index] = string.char(value);
    end
    return table.concat(characters);
end

local state = dofile('HXIChecklist/key_item_state.lua');

assert(state.has_key_item(385) == nil);
assert(state.handle_packet({ id = 0x055, data = key_item_packet(0, { 385, 388, 395 }) }));
assert(state.has_key_item(385) == true);
assert(state.has_key_item(386) == false);
assert(state.has_key_item(388) == true);
assert(state.has_key_item(395) == true);
assert(state.has_key_item(512) == nil);

assert(state.handle_packet({ id = 0x055, data = key_item_packet(3, { 1856, 1874 }) }));
assert(state.has_key_item(1856) == true);
assert(state.has_key_item(1857) == false);
assert(state.has_key_item(1874) == true);

local cache = state.export_cache();
assert(cache.version == 1);
assert(#cache.groups[0] == 0x80);
assert(#cache.groups[3] == 0x80);

assert(state.handle_packet({ id = 0x00A, data = '' }));
local cached_value, cached_note = state.has_key_item(385);
assert(cached_value == true);
assert(cached_note:find('saved key-item state', 1, true));

state.clear();
assert(state.has_key_item(385) == nil);
assert(state.load_cache(cache));
assert(state.has_key_item(386) == false);
assert(state.load_cache({ version = 1, groups = { [0] = 'invalid' } }) == false);
assert(state.has_key_item(385) == nil);

print('key-item packet fixture: passed');
