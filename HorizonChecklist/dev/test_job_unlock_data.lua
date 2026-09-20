package.path = 'HXIChecklist/?.lua;' .. package.path;
string.fmt = string.format;
package.preload.common = function() return {} end;
package.preload.key_item_state = function() return {
    has_key_item = function() error('Job unlocks must not read key items.') end,
} end;
package.preload.quest_state = function() return {
    get_area = function() error('Job unlocks must not infer from quest logs.') end,
} end;
package.preload.mission_state = function() return {
    get_area = function() error('Job unlocks must not read mission state.') end,
} end;
package.preload.job_levels = function() return { format = function() return nil end } end;

local levels = { [1] = 1, [7] = 37, [15] = 1 };
local login_status = 2;
local failing_job = nil;
local player = {};
function player:GetLoginStatus() return login_status end;
function player:GetJobLevel(id)
    if id == failing_job then error('synthetic failed job read') end;
    return levels[id] or 0;
end
AshitaCore = { GetMemoryManager = function() return {
    GetPlayer = function() return player end,
} end };

local data = require('job_unlock_data');
local catalog = require('catalog');
assert(#data.views == 4 and #data.entries == 12);
local eras = { original = 0, rise_of_the_zilart = 0, treasures_of_aht_urhgan = 0 };
local ids, jobs = {}, {};
for _, entry in ipairs(data.entries) do
    assert(entry.id == 'job_unlock.' .. entry.abbreviation:lower());
    assert(entry.kind == 'job_unlock' and entry.job_id >= 7 and entry.job_id <= 18);
    assert(not ids[entry.id] and not jobs[entry.job_id]);
    assert(entry.availability == 'wiki_listed');
    assert(entry.source_url:find('^https://horizonffxi%.wiki/'));
    assert(type(entry.unlock_quest) == 'string' and entry.unlock_quest ~= '');
    assert(type(entry.npc) == 'string' and type(entry.quest_location) == 'string');
    ids[entry.id], jobs[entry.job_id] = true, true;
    eras[entry.job_era] = eras[entry.job_era] + 1;
end
assert(eras.original == 5 and eras.rise_of_the_zilart == 4
    and eras.treasures_of_aht_urhgan == 3);
assert(data.entries[1].name == 'Paladin' and data.entries[1].unlock_quest == "A Knight's Test");
assert(data.entries[12].name == 'Puppetmaster' and data.entries[12].unlock_quest == 'No Strings Attached');

local profile = { version = 'synthetic', categories = { {
    id = 'job_unlocks', name = 'Job Unlocks', views = data.views, entries = data.entries,
} } };
local snapshot = catalog.build_snapshot(profile, {});
assert(snapshot.summary.complete == 2 and snapshot.summary.open == 10
    and snapshot.summary.known_total == 12 and snapshot.summary.unknown == 0);
assert(snapshot.categories[1].entries[1].state == 'complete');
assert(snapshot.categories[1].entries[1].state_label == 'Unlocked');
assert(snapshot.categories[1].entries[1].current_level == 37);
assert(snapshot.categories[1].entries[2].state == 'missing');
assert(snapshot.categories[1].entries[2].state_label == 'Locked');
assert(snapshot.categories[1].entries[2].current_level == 0);

login_status = 1;
snapshot = catalog.build_snapshot(profile, {});
assert(snapshot.summary.unknown == 12 and snapshot.summary.known_total == 0);
login_status = 2; levels[1] = 0;
snapshot = catalog.build_snapshot(profile, {});
assert(snapshot.summary.unknown == 12 and snapshot.categories[1].entries[1].state_note:find('not been received', 1, true));
levels[1] = 1; failing_job = 8;
snapshot = catalog.build_snapshot(profile, {});
assert(snapshot.categories[1].entries[2].state == 'unknown');
assert(snapshot.summary.complete == 2 and snapshot.summary.open == 9 and snapshot.summary.unknown == 1);
print('job unlock catalog and direct character-level tracking passed');
