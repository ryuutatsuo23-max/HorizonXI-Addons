package.path = 'HXIChecklist/?.lua;' .. package.path;
string.fmt = string.format;
package.preload.common = function() return {} end;
package.preload.key_item_state = function() return {
    has_key_item = function() error('Weapon-skill rows must not read key items.') end,
} end;
package.preload.mission_state = function() return {
    get_area = function() error('Weapon-skill rows must not read mission state.') end,
} end;
package.preload.job_levels = function() return { format = function() return nil end } end;
package.preload.quest_state = function() return {
    get_area = function(_, index)
        if index == 69 then return { completed = true, current = false, source = 'live' } end;
        if index == 13 then return { completed = false, current = true, source = 'cache' } end;
        return { completed = false, current = false, source = 'live' };
    end,
} end;

AshitaCore = { GetMemoryManager = function() return {
    GetPlayer = function() return {
        HasWeaponSkill = function() error('Current-job availability must not determine permanent unlocks.') end,
    } end,
} end };

local data = require('weapon_skill_data');
local catalog = require('catalog');
assert(#data.views == 15 and #data.entries == 14);
local ids, skill_ids, weapon_types = {}, {}, {};
for _, entry in ipairs(data.entries) do
    assert(entry.id:find('^weapon_skill%.'));
    assert(entry.kind == 'weapon_skill');
    assert(type(entry.weapon_skill_id) == 'number');
    assert(not ids[entry.id] and not skill_ids[entry.weapon_skill_id]);
    assert(entry.quest_area and type(entry.quest_index) == 'number');
    assert(entry.availability == 'wiki_listed');
    assert(entry.source_url:find('^https://horizonffxi%.wiki/'));
    assert(type(entry.unlock_quest) == 'string' and entry.unlock_quest ~= '');
    ids[entry.id], skill_ids[entry.weapon_skill_id] = true, true;
    weapon_types[entry.weapon_type] = true;
end
assert(data.entries[1].name == 'Asuran Fists' and data.entries[1].weapon_skill_id == 9);
assert(data.entries[14].name == 'Detonator' and data.entries[14].weapon_skill_id == 215);
assert(weapon_types['Hand-to-Hand'] and weapon_types.Marksmanship);

local profile = { version = 'synthetic', categories = { {
    id = 'weapon_skills', name = 'Weapon Skills', counts_toward_profile = false,
    views = data.views, entries = data.entries,
} } };
local snapshot = catalog.build_snapshot(profile, {});
local category = snapshot.categories[1];
assert(category.summary.complete == 1 and category.summary.open == 13
    and category.summary.known_total == 14);
assert(category.entries[1].state == 'auto_complete'
    and category.entries[1].state_label == 'Unlocked');
assert(category.entries[2].state == 'auto_current'
    and category.entries[2].state_label == 'In progress');
assert(category.entries[3].state == 'auto_not_logged'
    and category.entries[3].state_label == 'Locked');
assert(snapshot.summary.entries == 0 and snapshot.summary.known_total == 0
    and snapshot.summary.complete == 0);
print('weapon-skill catalog, quest-log tracking, and non-duplicated profile totals passed');
