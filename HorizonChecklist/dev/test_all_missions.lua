string.fmt = string.format;
package.path = 'HXIChecklist/?.lua;' .. package.path;

local state = require('mission_state');
local sandoria = require('sandoria_mission_data');
local bastok = require('bastok_mission_data');
local windurst = require('windurst_mission_data');
local zilart = require('zilart_mission_data');
local promathia = require('promathia_mission_data');
local ahturhgan = require('ahturhgan_mission_data');

local catalogs = { sandoria, bastok, windurst, zilart, promathia, ahturhgan };
local counts = { 20, 20, 20, 18, 34, 48 };
local seen = {};
for catalog_index, data in ipairs(catalogs) do
    assert(#data.entries == counts[catalog_index]);
    for _, row in ipairs(data.entries) do
        assert(row.kind == 'mission' and row.mission_area and row.mission_number);
        assert(row.npc and row.npc_coordinates and row.rewards and row.prerequisites);
        assert(row.npc ~= 'See Source' and row.quest_location ~= 'See Source'
            and row.npc_coordinates ~= 'See Source');
        assert(row.source_url:find('https://horizonffxi.wiki/', 1, true) == 1);
        assert(not seen[row.id]); seen[row.id] = true;
    end
end
assert(#sandoria.views == 10 and #windurst.views == 10);
assert(#promathia.views == 9 and promathia.entries[1].mission_group == 'Chapter 1');
assert(promathia.entries[11].mission_number == '3-3');
assert(promathia.entries[11].current_ids[1] == 325
    and promathia.entries[11].current_ids[#promathia.entries[11].current_ids] == 349);
assert(zilart.entries[2].mission_index == 4 and zilart.entries[18].mission_index == 31);
assert(zilart.entries[9].source_url == "https://horizonffxi.wiki/Ro%27Maeve(Mission)");
assert(zilart.entries[14].name == 'Ark Angels'
    and zilart.entries[14].source_url == 'https://horizonffxi.wiki/Ark_Angels');
assert(sandoria.entries[10].npc == 'Nelcabrit, then the embassy back door'
    and sandoria.entries[10].npc_coordinates == "G-9 (San d'Oria Embassy)");
assert(windurst.entries[10].npc == 'Pakh Jatalfih, then the embassy back door'
    and windurst.entries[10].npc_coordinates == 'I-9 (Windurst Embassy)');
assert(ahturhgan.entries[2].npc == 'Naja Salaheem'
    and ahturhgan.entries[2].npc_coordinates == 'I-10');
assert(promathia.entries[2].npc == 'No separate start listed'
    and promathia.entries[2].quest_location == 'Continues from previous mission');
assert(ahturhgan.entries[1].description:find('planned Aht Urhgan', 1, true));

local function packet(kind, options)
    options = options or {};
    local bytes = {}; for index = 1, 40 do bytes[index] = 0 end;
    local function number(offset, value, length)
        for index = 0, length - 1 do
            bytes[offset + index + 1] = math.floor(value / 2 ^ (index * 8)) % 256;
        end
    end
    local function bits(offset, values)
        for _, value in ipairs(values or {}) do
            local position = offset + math.floor(value / 8) + 1;
            bytes[position] = bytes[position] + 2 ^ (value % 8);
        end
    end
    number(0x24, kind, 2);
    if kind == 0x00D0 then
        bits(0x04, options.sandoria); bits(0x0C, options.bastok);
        bits(0x14, options.windurst); bits(0x1C, options.zilart);
    elseif kind == 0xFFFF then
        number(0x04, options.nation or 0, 4);
        number(0x08, options.nation_current or 65535, 4);
        number(0x0C, options.zilart_current or 65535, 4);
        number(0x10, options.promathia_current or 65535, 4);
        number(0x1A, options.tales_beginning or 0, 2);
    elseif kind == 0x00D8 then
        bits(0x04, options.ahturhgan);
    elseif kind == 0x0080 then
        number(0x18, options.ahturhgan_current or 65535, 4);
    end
    return { id = 0x056, data = string.char(table.unpack(bytes)) };
end

state.clear();
local ok, changed = state.handle_packet(packet(0x00D0, {
    sandoria = {0}, bastok = {1}, windurst = {2}, zilart = {4},
}));
assert(ok and #changed == 0, 'completion halves wait for their current half');
ok, changed = state.handle_packet(packet(0xFFFF, {
    nation = 0, nation_current = 7, zilart_current = 4, promathia_current = 325,
}));
assert(ok and #changed == 5);
assert(state.get_area('sandoria', 5).current and state.get_area('sandoria', 0).completed);
assert(not state.get_area('bastok', 1).current and state.get_area('bastok', 1).completed);
assert(not state.get_area('windurst', 2).current and state.get_area('windurst', 2).completed);
assert(state.get_area('zilart', 4).current and state.get_area('zilart', 4).completed);
local cop = state.get_area('promathia', 325, {325,330,331,335,339,340,341,345,349});
assert(cop.current and cop.completed == nil and cop.current_only);
assert(not state.get_area('promathia', 318, {318}).current);
for _, area in ipairs({'sandoria','bastok','windurst','zilart','promathia'}) do
    local saved = state.export_area_cache(area); assert(saved and saved.version == 1);
    if area == 'promathia' then assert(saved.completed == nil) else assert(#saved.completed == 16) end;
end

state.clear();
assert(state.handle_packet(packet(0x0080, {ahturhgan_current = 14})));
assert(state.get_area('ahturhgan', 14) == nil);
ok, changed = state.handle_packet(packet(0x00D8, {ahturhgan = {0,47}}));
assert(ok and #changed == 1 and changed[1] == 'ahturhgan');
assert(state.get_area('ahturhgan', 14).current);
assert(state.get_area('ahturhgan', 0).completed and state.get_area('ahturhgan', 47).completed);
assert(not state.get_area('ahturhgan', 46).completed);
local toau_cache = state.export_area_cache('ahturhgan');
state.handle_packet({ id = 0x00A });
assert(state.get_area('ahturhgan', 14).source == 'cache');
state.clear(); assert(state.load_area_cache('ahturhgan', toau_cache));
assert(state.get_area('ahturhgan', 47).completed);

state.clear();
state.handle_packet(packet(0x00D0, {}));
state.handle_packet(packet(0xFFFF, { nation = 2, nation_current = 9,
    zilart_current = 3, promathia_current = 999 }));
assert(state.get_area('windurst', 5).current, 'reviewed nation travel aliases map to the main row');
assert(state.get_area('zilart', 0).current == nil, 'unrecognized Zilart gaps stay unknown');
assert(state.get_area('promathia', 110, {101,110}).current == nil,
    'unrecognized Promathia IDs stay unknown');
state.clear(); state.handle_packet(packet(0x00D0, {}));
state.handle_packet(packet(0xFFFF, {zilart_current=0, promathia_current=101, tales_beginning=9}));
assert(not state.get_area('zilart', 0).current and not state.get_area('promathia', 110, {101,110}).current,
    'declined expansion flags prevent mission-zero false positives');
for _, bad in ipairs({
    {}, {version=2,current=0,completed=string.rep('0',16)},
    {version=1,current=0,completed=string.rep('0',15)},
}) do assert(not state.load_area_cache('zilart', bad)) end;
assert(not state.load_area_cache('missing', {version=1,current=0}));
state.clear(); state.handle_packet(packet(0x00D0, {bastok={2}}));
assert(state.handle_packet(packet(0xFFFF, {nation=1, nation_current=2,
    zilart_current=4294967295, promathia_current=4294967295})));
assert(state.get_area('bastok', 2).current and state.get_area('bastok', 2).completed,
    'invalid unrelated expansion fields cannot discard valid nation state');

package.loaded.common = {};
package.loaded.key_item_state = {};
package.loaded.quest_state = {};
local catalog = require('catalog');
state.clear();
state.handle_packet(packet(0xFFFF, {promathia_current = 325}));
local snapshot = catalog.build_snapshot({version='test',categories={{
    id='promathia_missions', name='Chains of Promathia Missions', mission_area='promathia',
    entries={promathia.entries[10],promathia.entries[11],promathia.entries[12]}, views=promathia.views,
}}}, {});
assert(snapshot.summary.complete == 0 and snapshot.summary.known_total == 1 and snapshot.summary.unknown == 2);
assert(snapshot.categories[1].entries[2].state == 'mission_current');
assert(snapshot.categories[1].entries[1].state == 'unknown');

print('all six mission catalogs, packet slices, nation gates, sub-stages, caches, and Promathia fail-closed state passed');
