package.path = './HXIChecklist/?.lua;' .. package.path;

local values = {};
for skill_id = 32, 42 do
    values[skill_id] = {
        value = 100 + skill_id,
        capped = skill_id % 2 == 0,
    };
end

local login_status = 2;
local failing_skill_id = nil;
local player = {};

function player:GetLoginStatus()
    return login_status;
end

function player:GetCombatSkill(skill_id)
    if skill_id == failing_skill_id then
        error('synthetic skill read failure');
    end
    local row = values[skill_id];
    return {
        GetSkill = function()
            return row.value;
        end,
        IsCapped = function()
            return row.capped;
        end,
    };
end

AshitaCore = {
    GetMemoryManager = function()
        return {
            GetPlayer = function()
                return player;
            end,
        };
    end,
};

local skill_levels = require('skill_levels');

local snapshot = skill_levels.build_snapshot();
assert(#snapshot.entries == 11);
assert(snapshot.note == nil);
for index, entry in ipairs(snapshot.entries) do
    local expected_id = index + 31;
    assert(entry.skill_id == expected_id);
    assert(entry.value == 100 + expected_id);
    assert(entry.capped == (expected_id % 2 == 0));
end
assert(snapshot.entries[1].name == 'Divine Magic');
assert(snapshot.entries[9].name == 'Singing');
assert(snapshot.entries[10].name == 'String Instrument');
assert(snapshot.entries[11].name == 'Wind Instrument');

login_status = 0;
snapshot = skill_levels.build_snapshot();
assert(#snapshot.entries == 11);
for _, entry in ipairs(snapshot.entries) do
    assert(entry.value == nil);
    assert(entry.capped == nil);
end

login_status = 2;
failing_skill_id = 37;
snapshot = skill_levels.build_snapshot();
assert(snapshot.entries[6].skill_id == 37);
assert(snapshot.entries[6].value == nil);
assert(snapshot.entries[5].value == 136);
assert(snapshot.note ~= nil);

print('skill_levels fixture passed');
