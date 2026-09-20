local data = require('crafting_data');
local crafting = {};
local function integer(value, maximum)
    return type(value) == 'number' and value >= 0 and value <= maximum
        and value == math.floor(value);
end
function crafting.build_snapshot()
    local ok, player = pcall(function()
        local candidate = AshitaCore:GetMemoryManager():GetPlayer();
        if candidate:GetLoginStatus() == 2 then return candidate end;
    end);
    if not ok then player = nil end;
    local snapshot = { entries = {} };
    for _, definition in ipairs(data.crafts) do
        local entry = { id = definition.id, name = definition.name,
            source_url = definition.source_url, rank_name = 'Unknown', next_test = 'Unknown' };
        if player then
            local skill_ok, skill = pcall(function() return player:GetCraftSkill(definition.index) end);
            if skill_ok and skill then
                local value_ok, value = pcall(function() return skill:GetSkill() end);
                local rank_ok, rank = pcall(function() return skill:GetRank() end);
                -- GetSkill exposes the integer skill bits; do not divide by ten.
                if value_ok and integer(value, 255) then entry.value = value end;
                if rank_ok and integer(rank, 9) then
                    entry.rank = rank;
                    entry.rank_name = data.ranks[rank];
                    if rank < 9 then
                        entry.next_rank = data.ranks[rank + 1];
                        entry.test_level = rank * 10 + 8;
                        entry.test_item = definition.items[rank + 1];
                        entry.next_test = ('%s (Lv.%d+)'):format(entry.next_rank, entry.test_level);
                    else
                        entry.next_test = 'No further listed test';
                    end
                end
            end
        end
        snapshot.entries[#snapshot.entries + 1] = entry;
    end
    return snapshot;
end
return crafting;
