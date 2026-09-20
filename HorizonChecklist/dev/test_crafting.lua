package.path = 'HXIChecklist/?.lua;' .. package.path;
string.fmt = string.format;
local data = require('crafting_data');
local crafting = require('crafting');
assert(#data.crafts == 9);
local first_items = { 'Moat Carp', 'Workbench', 'Xiphos', 'Copper Hairpin', 'Cape',
    'Rabbit Mantle', 'Shell Ring', 'Animal Glue', 'Salmon Sub Sandwich' };
for index, craft in ipairs(data.crafts) do
    assert(craft.index == index - 1 and #craft.items == 9 and craft.items[1] == first_items[index]);
    assert(craft.source_url == 'https://horizonffxi.wiki/Category:' .. craft.name .. '#Guild_Test_Items');
end
local snapshot = crafting.build_snapshot();
for _, row in ipairs(snapshot.entries) do assert(row.value == nil and row.rank_name == 'Unknown') end;
local logged, value, rank, bad_value, bad_rank, bad_reader = true, 0, 0, false, false, false;
local player = {
    GetLoginStatus = function() return logged and 2 or 1 end,
    GetCraftSkill = function(_, index)
        assert(index >= 0 and index <= 8);
        if bad_reader then error('Unavailable') end;
        return {
            GetSkill = function() if bad_value then error('Unavailable') end; return value end,
            GetRank = function() if bad_rank then error('Unavailable') end; return rank end,
        };
    end,
};
AshitaCore = { GetMemoryManager = function() return { GetPlayer = function() return player end } end };
for r = 0, 9 do
    rank, value = r, 99; -- Rank must never be inferred from this unrelated skill value.
    snapshot = crafting.build_snapshot();
    for index, row in ipairs(snapshot.entries) do
        assert(row.value == 99 and row.rank == r and row.rank_name == data.ranks[r]);
        if r < 9 then
            assert(row.test_level == r * 10 + 8 and row.test_item == data.crafts[index].items[r + 1]);
            assert(row.next_rank == data.ranks[r + 1]);
        else
            assert(row.test_item == nil and row.next_test == 'No further listed test');
        end
    end
end
value, rank = 0, 0;
assert(crafting.build_snapshot().entries[1].value == 0, 'Zero is a valid untrained skill');
for _, invalid in ipairs({ -1, 10, 1.5, 0/0, '2' }) do
    rank = invalid;
    local row = crafting.build_snapshot().entries[1];
    assert(row.rank == nil and row.test_item == nil and row.value == 0);
end
rank, value = 3, 256;
assert(crafting.build_snapshot().entries[1].value == nil);
value, bad_rank = 30, true;
assert(crafting.build_snapshot().entries[1].value == 30 and crafting.build_snapshot().entries[1].rank == nil);
bad_rank, bad_value = false, true;
assert(crafting.build_snapshot().entries[1].value == nil and crafting.build_snapshot().entries[1].rank == 3);
bad_value, bad_reader = false, true;
assert(crafting.build_snapshot().entries[1].value == nil);
bad_reader, logged = false, false;
for _, row in ipairs(crafting.build_snapshot().entries) do
    assert(row.value == nil and row.rank == nil and row.test_item == nil);
end
print('Nine crafts, 81 test items, actual ranks, integer skills, and unavailable/login guards passed');
