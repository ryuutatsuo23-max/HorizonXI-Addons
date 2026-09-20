package.path = 'HXIChecklist/?.lua;' .. package.path;
string.fmt = string.format;
package.preload.common = function() return {} end;
package.preload.key_item_state = function() return {
    has_key_item = function() error('Blue Magic must not read key items.') end,
} end;
package.preload.quest_state = function() return {
    get_area = function() error('Blue Magic must not infer from quests.') end,
} end;
package.preload.mission_state = function() return {
    get_area = function() error('Blue Magic must not read mission state.') end,
} end;
package.preload.job_levels = function() return {
    format = function() error('Blue Magic uses sourced Horizon learn levels.') end,
} end;

local data = require('blue_magic_data');
local resources = {};
for _, entry in ipairs(data.entries) do
    resources[entry.resource_id] = {
        Name = { [1] = entry.resource_name },
        Skill = 43,
        Index = entry.resource_id,
        Id = entry.resource_id,
    };
end

local logged_in = true;
local spell_data_loaded = true;
local learned = { [577] = true, [667] = true };
local player = {};
function player:GetLoginStatus() return logged_in and 2 or 1 end;
function player:HasSpellData() return spell_data_loaded end;
function player:HasSpell(id) return learned[id] == true end;
local resource_manager = {};
function resource_manager:GetSpellById(id) return resources[id] end;
AshitaCore = {
    GetMemoryManager = function() return { GetPlayer = function() return player end } end,
    GetResourceManager = function() return resource_manager end,
};

local catalog = require('catalog');
local profile = { version = 'synthetic', categories = { {
    id = 'blue_magic', name = 'Blue Magic', views = data.views, entries = data.entries,
} } };
local snapshot = catalog.build_snapshot(profile, {});
assert(snapshot.summary.complete == 2 and snapshot.summary.open == 104
    and snapshot.summary.known_total == 106 and snapshot.summary.unknown == 0);
assert(snapshot.categories[1].entries[1].state_label == 'Learned');
assert(snapshot.categories[1].entries[2].state_label == 'Not learned');
assert(snapshot.categories[1].entries[1].job_levels == 'BLU Lv.1');

spell_data_loaded = false;
snapshot = catalog.build_snapshot(profile, {});
assert(snapshot.summary.unknown == 106 and snapshot.summary.known_total == 0);

spell_data_loaded = true;
resources[577].Skill = 42;
catalog.invalidate();
snapshot = catalog.build_snapshot(profile, {});
assert(snapshot.categories[1].entries[1].state == 'unknown');
assert(snapshot.summary.complete == 1 and snapshot.summary.open == 104
    and snapshot.summary.unknown == 1);

logged_in = false;
catalog.invalidate();
snapshot = catalog.build_snapshot(profile, {});
assert(snapshot.summary.unknown == 106 and snapshot.summary.known_total == 0);

print('Blue Magic live ownership and fail-closed state passed');
