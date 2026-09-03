package.preload['common'] = function()
    return {};
end

package.preload['bit'] = function()
    local bit = {};

    function bit.lshift(value, shift)
        return value * (2 ^ shift);
    end

    function bit.band(left, right)
        local result = 0;
        local place = 1;
        while left > 0 and right > 0 do
            if left % 2 == 1 and right % 2 == 1 then
                result = result + place;
            end
            left = math.floor(left / 2);
            right = math.floor(right / 2);
            place = place * 2;
        end
        return result;
    end

    return bit;
end

package.preload['struct'] = function()
    return {
        unpack = function(format, data, offset)
            assert(format == 'H');
            local low, high = data:byte(offset, offset + 1);
            assert(low ~= nil and high ~= nil);
            return low + high * 256;
        end,
    };
end

local function make_packet(log_type, indices)
    local bytes = {};
    for index = 1, 40 do
        bytes[index] = 0;
    end

    for _, quest_index in ipairs(indices) do
        local position = 0x04 + math.floor(quest_index / 8) + 1;
        bytes[position] = bytes[position] + (2 ^ (quest_index % 8));
    end

    bytes[0x24 + 1] = log_type % 256;
    bytes[0x24 + 2] = math.floor(log_type / 256);

    local characters = {};
    for index = 1, #bytes do
        characters[index] = string.char(bytes[index]);
    end
    return table.concat(characters);
end

local state = dofile('HXIChecklist/quest_state.lua');

local before, before_note = state.get_bastok(34);
assert(before == nil and before_note:find('No saved Bastok quest state', 1, true));

assert(state.handle_packet({ id = 0x056, data = make_packet(0x0058, { 18, 34, 92 }) }));
assert(state.get_bastok(34) == nil);

assert(state.handle_packet({ id = 0x056, data = make_packet(0x0098, { 10, 38, 89 }) }));

local current = state.get_bastok(34);
assert(current.current == true and current.completed == false);

local completed = state.get_bastok(10);
assert(completed.current == false and completed.completed == true);

local open = state.get_bastok(14);
assert(open.current == false and open.completed == false);

local high_current = state.get_bastok(92);
assert(high_current.current == true and high_current.completed == false);

local high_completed = state.get_bastok(89);
assert(high_completed.current == false and high_completed.completed == true);

local cache = state.export_cache();
assert(cache.version == 1);
assert(#cache.current == 0x40 and #cache.completed == 0x40);

assert(state.handle_packet({ id = 0x00A, data = '' }));
local cached = state.get_bastok(34);
assert(cached.current == true and cached.source == 'cache');

state.clear();
assert(state.get_bastok(34) == nil);
assert(state.load_cache(cache));
assert(state.get_bastok(10).completed == true);
assert(state.get_bastok(10).source == 'cache');
assert(state.get_bastok(89).completed == true);
assert(state.get_bastok(92).current == true);
assert(state.load_cache({ version = 1, current = 'invalid', completed = 'invalid' }) == false);
assert(state.get_bastok(34) == nil);

assert(state.handle_packet({ id = 0x056, data = 'short' }) == false);
assert(state.handle_packet({ id = 0x056, data = make_packet(0x0048, {}) }) == false);
assert(state.get_bastok(-1) == nil);

package.path = 'HXIChecklist/?.lua;' .. package.path;
package.loaded['quest_state'] = state;

local catalog = dofile('HXIChecklist/catalog.lua');
local profile = {
    version = 'synthetic',
    categories = {
        {
            id = 'pilot',
            name = 'Pilot',
            entries = {
                { id = 'completed', kind = 'manual', quest_area = 'bastok', quest_index = 10, availability = 'wiki_listed' },
                { id = 'current', kind = 'manual', quest_area = 'bastok', quest_index = 34, availability = 'wiki_listed' },
                { id = 'open', kind = 'manual', quest_area = 'bastok', quest_index = 14, availability = 'wiki_listed' },
                { id = 'unknown', kind = 'manual', quest_area = 'bastok', quest_index = 87, availability = 'unknown', availability_note = 'Synthetic unknown.' },
                { id = 'inactive', kind = 'manual', quest_area = 'bastok', quest_index = 76, availability = 'reported_inactive', availability_note = 'Synthetic inactive.' },
            },
        },
    },
};

local fallback = catalog.build_snapshot(profile, { current = true });
assert(fallback.categories[1].entries[1].state == 'unknown');
assert(fallback.categories[1].entries[2].state == 'unknown');
assert(fallback.categories[1].entries[4].state == 'unknown');
assert(fallback.categories[1].entries[5].state == 'unavailable');
assert(fallback.summary.known_total == 0);

assert(state.load_cache(cache));

local automatic = catalog.build_snapshot(profile, { current = true });
assert(automatic.categories[1].entries[1].state == 'auto_complete');
assert(automatic.categories[1].entries[2].state == 'auto_current');
assert(automatic.categories[1].entries[3].state == 'auto_not_logged');
assert(automatic.categories[1].entries[4].state == 'unknown');
assert(automatic.categories[1].entries[5].state == 'unavailable');
assert(automatic.summary.complete == 1);
assert(automatic.summary.known_total == 3);

print('quest_state synthetic fixture passed');
