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

assert(state.handle_packet({ id = 0x056, data = make_packet(0x0050, { 59, 119 }) }));
assert(state.get_sandoria(59) == nil);
assert(state.handle_packet({ id = 0x056, data = make_packet(0x0090, { 0, 117 }) }));

local sandoria_current = state.get_sandoria(59);
assert(sandoria_current.current == true and sandoria_current.completed == false);
local sandoria_completed = state.get_sandoria(117);
assert(sandoria_completed.current == false and sandoria_completed.completed == true);
assert(state.get_sandoria(119).current == true);

assert(state.handle_packet({ id = 0x056, data = make_packet(0x0060, { 9, 96 }) }));
assert(state.get_windurst(9) == nil);
assert(state.handle_packet({ id = 0x056, data = make_packet(0x00A0, { 0, 95 }) }));
assert(state.get_windurst(9).current == true);
assert(state.get_windurst(95).completed == true);
assert(state.get_windurst(96).current == true);

assert(state.get_area('jeuno', 128) == nil);
assert(state.handle_packet({ id = 0x056, data = make_packet(0x0068, { 27, 128, 186 }) }));
assert(state.get_area('jeuno', 128) == nil, 'A partial log pair must remain unknown.');
assert(state.handle_packet({ id = 0x056, data = make_packet(0x00A8, { 0, 132 }) }));
assert(state.get_area('jeuno', 128).current == true);
assert(state.get_area('jeuno', 132).completed == true);
assert(state.get_area('jeuno', 186).current == true);
assert(state.get_area('jeuno', 10).completed == false, 'Bastok flags must not leak into Jeuno.');

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
local sandoria_cache = state.export_area_cache('sandoria');
local windurst_cache = state.export_area_cache('windurst');
local jeuno_cache = state.export_area_cache('jeuno');
assert(cache.version == 1);
assert(#cache.current == 0x40 and #cache.completed == 0x40);
assert(sandoria_cache.version == 1);
assert(windurst_cache.version == 1);
assert(jeuno_cache.version == 1 and #jeuno_cache.current == 0x40);

assert(state.handle_packet({ id = 0x00A, data = '' }));
local cached = state.get_bastok(34);
assert(cached.current == true and cached.source == 'cache');
assert(state.get_sandoria(117).completed == true);
assert(state.get_sandoria(117).source == 'cache');
assert(state.get_windurst(95).completed == true);
assert(state.get_windurst(95).source == 'cache');
assert(state.get_area('jeuno', 132).completed == true);
assert(state.get_area('jeuno', 132).source == 'cache');

state.clear();
assert(state.get_bastok(34) == nil);
assert(state.load_cache(cache));
assert(state.load_area_cache('sandoria', sandoria_cache));
assert(state.load_area_cache('windurst', windurst_cache));
assert(state.get_area('jeuno', 128) == nil, 'Character clearing must clear Jeuno too.');
assert(state.load_area_cache('jeuno', jeuno_cache));
assert(state.get_area('jeuno', 128).current == true);
assert(state.get_area('jeuno', 132).completed == true);
assert(state.get_area('jeuno', 186).source == 'cache');
assert(state.get_bastok(10).completed == true);
assert(state.get_bastok(10).source == 'cache');
assert(state.get_bastok(89).completed == true);
assert(state.get_bastok(92).current == true);
assert(state.get_sandoria(59).current == true);
assert(state.get_sandoria(117).completed == true);
assert(state.get_sandoria(119).current == true);
assert(state.get_windurst(9).current == true);
assert(state.get_windurst(95).completed == true);
assert(state.get_windurst(96).current == true);
assert(state.load_cache({ version = 1, current = 'invalid', completed = 'invalid' }) == false);
assert(state.get_bastok(34) == nil);
assert(state.get_sandoria(117).completed == true);
assert(state.get_windurst(95).completed == true);

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

local jeuno_profile = { version = 'synthetic', categories = {
    { id = 'jeuno_quests', name = 'Jeuno', entries = {
        { id = 'jeuno.done', kind = 'manual', quest_area = 'jeuno', quest_index = 132, availability = 'wiki_listed' },
        { id = 'jeuno.current', kind = 'manual', quest_area = 'jeuno', quest_index = 128, availability = 'wiki_listed' },
        { id = 'jeuno.open', kind = 'manual', quest_area = 'jeuno', quest_index = 1, availability = 'wiki_listed' },
        { id = 'jeuno.unknown', kind = 'manual', quest_area = 'jeuno', quest_index = 185, availability = 'unknown' },
    } },
} };
local jeuno_snapshot = catalog.build_snapshot(jeuno_profile, {});
assert(jeuno_snapshot.categories[1].entries[1].state == 'auto_complete');
assert(jeuno_snapshot.categories[1].entries[2].state == 'auto_current');
assert(jeuno_snapshot.categories[1].entries[3].state == 'auto_not_logged');
assert(jeuno_snapshot.categories[1].entries[4].state == 'unknown');
assert(jeuno_snapshot.summary.known_total == 3 and jeuno_snapshot.summary.complete == 1);
assert(state.load_area_cache('jeuno', { version = 1, current = 'invalid', completed = 'invalid' }) == false);
assert(state.get_area('jeuno', 132) == nil);
assert(state.get_sandoria(117).completed == true);
assert(state.get_windurst(95).completed == true);
assert(state.get_bastok(10).completed == true);
assert(catalog.build_snapshot(jeuno_profile, {}).summary.known_total == 0);
assert(state.handle_packet({ id = 0x056, data = make_packet(0x0068, { 128 }) }));
assert(state.handle_packet({ id = 0x056, data = make_packet(0x00A8, { 132 }) }));
local live_jeuno = catalog.build_snapshot(jeuno_profile, {});
assert(live_jeuno.categories[1].entries[1].state_note:find('incoming Jeuno quest log', 1, true));
assert(live_jeuno.categories[1].entries[2].state == 'auto_current');

-- The Other log shares a packet shape, but neither its flags nor cache may
-- be confused with the four existing areas. Completed may arrive first.
assert(state.get_area('other', 8) == nil);
assert(state.handle_packet({ id = 0x056, data = make_packet(0x00B0, { 8, 19 }) }));
assert(state.get_area('other', 8) == nil);
assert(state.export_area_cache('other') == nil);
assert(state.handle_packet({ id = 0x056, data = make_packet(0x0070, { 0, 209 }) }));
assert(state.get_area('other', 209).current == true);
assert(state.get_area('other', 8).completed == true);
assert(state.get_area('other', 10).completed == false);
assert(state.get_bastok(10).completed == true);
assert(state.get_area('jeuno', 132).completed == true);
local other_cache = state.export_area_cache('other');
assert(other_cache.version == 1 and #other_cache.current == 64 and #other_cache.completed == 64);
assert(state.handle_packet({ id = 0x00A, data = '' }));
assert(state.get_area('other', 209).source == 'cache');
assert(state.load_area_cache('other', { version = 1, current = 'invalid', completed = 'invalid' }) == false);
assert(state.get_area('other', 8) == nil);
assert(state.get_area('jeuno', 132).completed == true);
assert(state.get_bastok(10).completed == true);
assert(state.load_area_cache('other', other_cache));
assert(state.get_area('other', 209).current == true);
state.clear();
assert(state.get_area('other', 8) == nil);
assert(state.get_area('jeuno', 132) == nil);
assert(state.load_area_cache('other', other_cache));
assert(state.get_area('other', 8).completed == true);

local other_data = require('other_quest_data');
local other_profile = { version = 'synthetic', categories = {
    { id = 'other_quests', name = 'Other Areas', entries = other_data.entries },
} };
-- Refresh the full pair, clearing the synthetic high-index current flag.
assert(state.handle_packet({ id = 0x056, data = make_packet(0x0070, { 0 }) }));
assert(state.handle_packet({ id = 0x056, data = make_packet(0x00B0, { 8, 19, 70 }) }));
local other_snapshot = catalog.build_snapshot(other_profile, {});
local other_rows = {};
for _, entry in ipairs(other_snapshot.categories[1].entries) do other_rows[entry.quest_index] = entry end;
assert(other_rows[0].state == 'auto_current');
assert(other_rows[8].state == 'auto_complete');
assert(other_rows[1].state == 'auto_not_logged');
assert(other_rows[70].state == 'unavailable', 'An inactive source stays unavailable even if a bit is set.');
assert(other_rows[106].state == 'unknown' and other_rows[107].state == 'unknown' and other_rows[109].state == 'unknown');
assert(other_rows[209].state == 'unknown');
assert(other_rows[8].state_note:find('incoming Other Areas quest log', 1, true));
assert(other_rows[8].fame_region == 'Mhaura');
assert(other_snapshot.summary.known_total == 56 and other_snapshot.summary.complete == 2);
assert(other_snapshot.summary.unknown == 34 and other_snapshot.summary.unavailable == 1);
-- A different character's empty pair cannot inherit this character's flags.
local saved_other = state.export_area_cache('other');
state.clear();
local no_cache = catalog.build_snapshot(other_profile, { ['other.quest.008'] = true });
assert(no_cache.summary.known_total == 0 and no_cache.summary.unknown == 90);
assert(state.load_area_cache('other', { version = 1, current = string.rep('00', 32), completed = string.rep('00', 32) }));
assert(state.get_area('other', 8).completed == false);
assert(state.load_area_cache('other', saved_other));
assert(state.get_area('other', 8).completed == true);

-- Outlands has a separate pair and must preserve all older cache formats.
assert(state.get_area('outlands', 136) == nil);
assert(state.handle_packet({ id = 0x056, data = make_packet(0x0078, { 129, 203 }) }));
assert(state.get_area('outlands', 129) == nil);
assert(state.export_area_cache('outlands') == nil);
assert(state.handle_packet({ id = 0x056, data = make_packet(0x00B8, { 136, 164 }) }));
assert(state.get_area('outlands', 136).completed == true);
assert(state.get_area('outlands', 203).current == true);
assert(state.get_area('other', 8).completed == true);
assert(state.get_area('other', 136).completed == false);
local outlands_cache = state.export_area_cache('outlands');
assert(outlands_cache.version == 1 and #outlands_cache.current == 64 and #outlands_cache.completed == 64);
assert(state.handle_packet({ id = 0x00A, data = '' }));
assert(state.get_area('outlands', 164).source == 'cache');
assert(not state.load_area_cache('outlands', { version = 1, current = 'invalid', completed = 'invalid' }));
assert(state.get_area('outlands', 136) == nil);
assert(state.get_area('other', 8).completed == true);
assert(state.load_area_cache('outlands', outlands_cache));
local outlands_profile = { version = 'synthetic', categories = {
    { id = 'outlands_quests', name = 'Outlands', entries = require('outlands_quest_data').entries },
} };
local function outlands_rows()
    local snapshot = catalog.build_snapshot(outlands_profile, {});
    local rows = {};
    for _, entry in ipairs(snapshot.categories[1].entries) do rows[entry.quest_index] = entry end;
    return rows, snapshot.summary;
end
local rows, totals = outlands_rows();
assert(rows[129].state == 'auto_current' and rows[203].state == 'auto_current');
assert(rows[136].state == 'auto_complete' and rows[164].state == 'auto_complete');
assert(rows[163].state == 'auto_not_logged', 'Divine Might and Repeat have independent flags.');
assert(rows[1].state == 'auto_not_logged');
assert(rows[165].state == 'unknown' and rows[100].state == 'unknown');
assert(totals.known_total == 51 and totals.unknown == 6 and totals.complete == 2);
assert(rows[136].state_note:find('saved character cache', 1, true));
assert(state.handle_packet({ id = 0x056, data = make_packet(0x00B8, { 136, 164 }) }));
assert(state.handle_packet({ id = 0x056, data = make_packet(0x0078, { 129, 100 }) }));
rows, totals = outlands_rows();
assert(rows[136].state_note:find('incoming Outlands quest log', 1, true));
assert(rows[100].state == 'auto_current', 'Actual client flags still resolve source-unknown entries.');
assert(totals.known_total == 52 and totals.unknown == 5);
state.clear();
assert(state.get_area('outlands', 136) == nil);
assert(catalog.build_snapshot(outlands_profile, { ['outlands.quest.136'] = true }).summary.known_total == 0);
assert(state.load_area_cache('outlands', { version = 1, current = string.rep('00', 32), completed = string.rep('00', 32) }));
assert(state.get_area('outlands', 136).completed == false);
assert(state.load_area_cache('outlands', outlands_cache));
assert(state.get_area('outlands', 136).completed == true);
assert(state.get_area('other', 8) == nil, 'Restoring Outlands cannot restore another area.');

-- Aht Urhgan uses ONLY 16 bytes. The second half of these packets deliberately
-- sets mission/Assault data so it cannot be mistaken for quest state or cached.
assert(state.get_area('outlands', 136).completed == true);
assert(state.handle_packet({ id = 0x056, data = make_packet(0x00C0, { 2, 99, 127, 128, 255 }) }));
assert(state.get_area('ahturhgan', 2) == nil);
assert(state.export_area_cache('ahturhgan') == nil);
assert(state.handle_packet({ id = 0x056, data = make_packet(0x0080, { 5, 103, 128, 200 }) }));
assert(state.get_area('ahturhgan', 2).completed == true);
assert(state.get_area('ahturhgan', 5).current == true);
assert(state.get_area('ahturhgan', 103).current == true);
assert(state.get_area('ahturhgan', 127).completed == true);
assert(state.get_area('ahturhgan', 128) == nil and state.get_area('ahturhgan', 255) == nil);
assert(state.get_area('outlands', 136).completed == true);
local aht_cache = state.export_area_cache('ahturhgan');
assert(aht_cache.version == 1 and #aht_cache.current == 32 and #aht_cache.completed == 32);
assert(aht_cache.current:sub(-2) == '00' and aht_cache.completed:sub(-2) == '80');
assert(state.handle_packet({ id = 0x056, data = make_packet(0x0080, { 5, 103 }) }));
assert(state.handle_packet({ id = 0x056, data = make_packet(0x00C0, { 2, 99, 127 }) }));
local clean_tail_cache = state.export_area_cache('ahturhgan');
assert(clean_tail_cache.current == aht_cache.current and clean_tail_cache.completed == aht_cache.completed);
assert(state.handle_packet({ id = 0x00A, data = '' }));
assert(state.get_area('ahturhgan', 2).source == 'cache');
assert(state.load_area_cache('ahturhgan', outlands_cache) == false, 'Reject 32-byte quest caches for Aht Urhgan.');
assert(state.get_area('ahturhgan', 2) == nil);
assert(state.get_area('outlands', 136).completed == true);
assert(not state.load_area_cache('ahturhgan', { version = 1, current = string.rep('0', 31), completed = string.rep('0', 32) }));
assert(not state.load_area_cache('ahturhgan', { version = 1, current = string.rep('X', 32), completed = string.rep('0', 32) }));
assert(state.load_area_cache('ahturhgan', aht_cache));
local aht_profile = { version = 'synthetic', categories = {
    { id = 'ahturhgan_quests', name = 'Aht Urhgan', entries = require('ahturhgan_quest_data').entries },
} };
local aht_snapshot = catalog.build_snapshot(aht_profile, {});
local aht_rows = {};
for _, entry in ipairs(aht_snapshot.categories[1].entries) do aht_rows[entry.quest_index] = entry end;
assert(aht_rows[2].state == 'auto_complete' and aht_rows[99].state == 'auto_complete');
assert(aht_rows[5].state == 'auto_current' and aht_rows[103].state == 'auto_current');
assert(aht_rows[0].state == 'auto_not_logged' and aht_rows[0].fame_label == 'N/A');
assert(aht_snapshot.summary.known_total == 72 and aht_snapshot.summary.complete == 2);
assert(aht_rows[2].state_note:find('saved character cache', 1, true));
state.clear();
assert(catalog.build_snapshot(aht_profile, { ['ahturhgan.quest.002'] = true }).summary.known_total == 0);
assert(state.handle_packet({ id = 0x056, data = make_packet(0x0080, { 5 }) }));
assert(state.get_area('ahturhgan', 5) == nil, 'A current-only log cannot resolve state.');
assert(not state.handle_packet({ id = 0x056, data = make_packet(0x00C0, { 2 }):sub(1, 36) }));
assert(state.get_area('ahturhgan', 5) == nil);
assert(state.handle_packet({ id = 0x056, data = make_packet(0x00C0, { 2 }) }));
assert(catalog.build_snapshot(aht_profile, {}).categories[1].entries[1].state_note:find('incoming Aht Urhgan quest log', 1, true));
state.clear();
assert(state.load_area_cache('ahturhgan', { version = 1, current = string.rep('00', 16), completed = string.rep('00', 16) }));
assert(state.get_area('ahturhgan', 2).completed == false);
assert(state.load_area_cache('ahturhgan', aht_cache));
assert(state.get_area('ahturhgan', 2).completed == true);
assert(state.get_area('outlands', 136) == nil);
assert(state.load_area_cache('outlands', outlands_cache));
assert(state.get_area('outlands', 136).completed == true, 'Older 32-byte cache format remains supported.');

print('quest_state synthetic fixture passed');
