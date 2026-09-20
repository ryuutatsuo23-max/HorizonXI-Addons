package.path = 'HXIChecklist/?.lua;' .. package.path;
local state = require('mission_state');
local data = require('bastok_mission_data');
local function packet(kind, nation, current, bits, outside)
    local bytes = {}; for i = 1, 40 do bytes[i] = 0 end;
    local function number(offset, value, length)
        for i = 0, length - 1 do bytes[offset+i+1] = math.floor(value / 2^(i*8)) % 256 end;
    end
    number(0x24, kind, 2);
    if kind == 0xFFFF then number(4, nation or 1, 4); number(8, current or 65535, 4) end;
    if kind == 0x00D0 then
        for _, index in ipairs(bits or {}) do
            local offset = 0x0D + math.floor(index / 8);
            bytes[offset] = bytes[offset] + 2^(index % 8);
        end
        if outside then
            for i = 5, 12 do bytes[i] = 255 end;
            for i = 21, 36 do bytes[i] = 255 end;
        end
    end
    return { id = 0x056, data = string.char(table.unpack(bytes)) };
end
local function pair(nation, current, bits)
    assert(state.handle_packet(packet(0x00D0, nil, nil, bits)));
    assert(state.handle_packet(packet(0xFFFF, nation, current)));
end
assert(#data.entries == 20 and #data.views == 10);
local indices = {0,1,2,3,4,5,10,11,12,13,14,15,16,17,18,19,20,21,22,23};
local seen = {};
for i, row in ipairs(data.entries) do
    assert(row.mission_index == indices[i] and row.kind == 'mission');
    assert(not seen[row.id]); seen[row.id] = true;
    assert(row.npc and row.npc_coordinates and row.rewards and row.prerequisites);
    assert(row.source_url == 'https://horizonffxi.wiki/Bastok_Mission_' .. row.mission_number);
    assert(not row.quest_index and not row.quest_area and not row.tracking);
end
assert(data.entries[10].npc_coordinates == 'H-10 (Bastokan Embassy)');
assert(data.entries[10].rewards:find('20,000 gil', 1, true));
assert(data.entries[8].prerequisites:find('optional', 1, true));

state.clear();
assert(state.get_bastok(0) == nil and state.export_cache() == nil);
assert(state.handle_packet(packet(0xFFFF, 1, 0)));
assert(state.get_bastok(0) == nil, 'One half must not imply complete state');
assert(state.handle_packet(packet(0x00D0, nil, nil, {2, 23, 63}, true)));
assert(state.get_bastok(0).current and not state.get_bastok(0).completed);
assert(state.get_bastok(2).completed and state.get_bastok(23).completed and state.get_bastok(63).completed);
assert(not state.get_bastok(1).completed, 'Other nation/Zilart bytes must not leak');
for _, index in ipairs({-1, 0.5, 64}) do assert(state.get_bastok(index) == nil) end;
assert(state.get_bastok('1') == nil);
local saved = state.export_cache();
assert(#saved.completed == 16 and saved.current == 0 and saved.nation == 1);
state.handle_packet({id=0x00A});
assert(state.get_bastok(0).source == 'cache' and state.export_cache() == nil);
state.clear(); assert(state.load_cache(saved));
assert(state.get_bastok(23).completed and state.get_bastok(0).current);
for _, stage in ipairs({5,6,7,8,9}) do
    pair(1, stage, {});
    assert(state.get_bastok(5).current and not state.get_bastok(5).completed);
end
pair(1, 65535, {6,7,8,9});
assert(not state.get_bastok(5).current and not state.get_bastok(5).completed, 'Travel bits cannot complete main mission');
pair(0, 5, {5});
assert(not state.get_bastok(5).current and state.get_bastok(5).completed, 'Current nation ID matters; old completion remains');
pair(2, 0, {}); assert(not state.get_bastok(0).current);
pair(1, 23, {}); assert(not state.get_bastok(22).completed, 'Never infer earlier completion');
pair(1, 99, {0}); assert(state.get_bastok(1).current == nil and state.get_bastok(0).completed);
local before = state.export_cache();
for _, kind in ipairs({0x0058,0x0098,0x00C0,0xFFFE}) do assert(not state.handle_packet(packet(kind))) end;
assert(not state.handle_packet(packet(0xFFFF, 3, 1)));
assert(not state.handle_packet(packet(0xFFFF, 1, 4294967295)));
assert(not state.handle_packet({id=0x056,data='short'}));
assert(not state.handle_packet({id=0x056,data=1}));
assert(not state.handle_packet({id=0x055,data=packet(0x00D0).data}));
assert(state.export_cache().completed == before.completed);
for _, bad in ipairs({{}, {version=2}, {version=1,nation=1,current=0,completed='ZZZZZZZZZZZZZZZZ'},
    {version=1,nation=1,current=0,completed=string.rep('0',64)},
    {version=1,nation=1,current='0',completed=string.rep('0',16)},
    {version=1,nation=1,current=0.5,completed=string.rep('0',16)}}) do
    assert(not state.load_cache(bad)); assert(state.get_bastok(0) == nil);
end

package.loaded.common = {};
package.loaded.key_item_state = {load_cache=function() end, handle_packet=function() return false end};
package.loaded.quest_state = {load_area_cache=function() end, clear=function() end, handle_packet=function() return false end};
local catalog = require('catalog');
local profile = {version='synthetic',categories={{id='bastok_missions',name='Bastok Missions',mission_area='bastok',entries=data.entries,views=data.views}}};
pair(1, 2, {0,2});
local snapshot = catalog.build_snapshot(profile, {});
assert(snapshot.summary.complete == 2 and snapshot.summary.known_total == 20);
assert(snapshot.categories[1].mission_area == 'bastok');
assert(snapshot.categories[1].entries[3].state == 'mission_repeat');
assert(snapshot.categories[1].entries[2].state == 'mission_not_current');
pair(1, 5, {0});
assert(catalog.build_snapshot(profile, {}).categories[1].entries[6].state == 'mission_current');
assert(not catalog.set_manual_completed(profile, {}, data.entries[1].id, true));

-- Real addon callbacks with synthetic character settings only.
local function copy(value)
    if type(value) ~= 'table' then return value end;
    local result={}; for k,v in pairs(value) do result[k]=copy(v) end; return result;
end
T=function(value) return value end; addon={};
local active, callbacks, settings_callback, shown;
local stored={one={visible=true,manual_completed={legacy=true},cached_state={version=1,bastok_quests={sentinel=true}}},two={visible=true,cached_state={version=1}}};
local character, saves='one',0;
package.loaded.horizon_profile=profile;
package.loaded.chat={}; package.loaded.imgui={};
package.loaded.skill_levels={empty_snapshot=function() return {} end,build_snapshot=function() return {} end};
package.loaded.checklist_ui={render=function(_, value) shown=value end};
package.loaded.settings={load=function() active=copy(stored[character]); return active end,
    save=function() saves=saves+1; stored[character]=copy(active) end,
    register=function(_,_,fn) settings_callback=fn end};
ashita={time={tick64=function() return 1000 end},events={register=function(event,_,fn) callbacks[event]=fn end}};
local function reload()
    callbacks={}; dofile('HXIChecklist/HXIChecklist.lua');
    -- Explicitly show the UI; saved visibility no longer opens it on startup.
    callbacks.command({command={args=function() return {
        {any=function(_, name) return name == '/hxichecklist' end}, 'show',
    } end}});
    callbacks.d3d_present();
end;
reload(); assert(shown.summary.unknown == 20);
local prior_saves=saves;
callbacks.packet_in(packet(0x00D0,nil,nil,{0})); assert(saves==prior_saves);
callbacks.packet_in(packet(0xFFFF,1,1)); callbacks.d3d_present();
assert(saves==prior_saves+1 and stored.one.cached_state.bastok_missions.current==1);
assert(stored.one.cached_state.sandoria_missions.current==1);
assert(stored.one.cached_state.windurst_missions.current==1);
assert(stored.one.cached_state.zilart_missions.current==0);
assert(stored.one.cached_state.promathia_missions.current==0);
assert(stored.one.manual_completed.legacy and stored.one.cached_state.bastok_quests.sentinel);
assert(shown.summary.complete==1);
reload(); assert(shown.summary.complete==1);
character='two'; active=copy(stored.two); settings_callback(active); callbacks.d3d_present();
assert(shown.summary.unknown==20);
callbacks.packet_in(packet(0xFFFF,1,23)); callbacks.packet_in(packet(0x00D0,nil,nil,{})); callbacks.d3d_present();
assert(shown.summary.complete==0 and stored.one.cached_state.bastok_missions.current==1);
character='one'; active=copy(stored.one); settings_callback(active); callbacks.d3d_present();
assert(shown.summary.complete==1);
callbacks.packet_in(packet(0x00D8)); callbacks.packet_in(packet(0x0080));
assert(stored.one.cached_state.ahturhgan_missions.current==0
    and #stored.one.cached_state.ahturhgan_missions.completed==16);
active.cached_state.version=99; settings_callback(active); callbacks.d3d_present();
assert(shown.summary.unknown==20, 'Unknown root schema clears mission state too');
print('Bastok mission catalog, packets, repeats, nation gates, and synthetic character persistence passed');
