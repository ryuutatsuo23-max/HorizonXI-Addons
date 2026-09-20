package.path = 'HXIChecklist/?.lua;' .. package.path;
string.fmt = string.format;
package.preload.common = function() return {} end;
for _, name in ipairs({ 'key_item_state', 'quest_state', 'mission_state' }) do
    package.preload[name] = function() return {} end;
end
local magic = require('magic_data');
local boundaries = { 1, 20, 21, 40, 41, 60, 61, 75 };
local resources = {};
for index, entry in ipairs(magic.entries) do
    resources[entry.resource_id] = { Name = { [1] = entry.resource_name },
        Skill = entry.skill_id, Index = entry.resource_id,
        LevelRequired = { [4] = 75, [6] = boundaries[(index - 1) % 8 + 1] } };
end
local player = { GetLoginStatus = function() return 2 end,
    HasSpellData = function() return true end, HasSpell = function() return true end };
AshitaCore = {
    GetMemoryManager = function() return { GetPlayer = function() return player end } end,
    GetResourceManager = function() return { GetSpellById = function(_, id) return resources[id] end } end,
};
local catalog = require('catalog');
local snapshot = catalog.build_snapshot({ categories = {
    { id = 'magic_skills', name = 'Spells', entries = magic.spell_entries, views = magic.spell_views },
    { id = 'summoning', name = 'Summoning', entries = magic.summoning_entries, views = magic.song_views },
    { id = 'ninjutsu', name = 'Ninjutsu', entries = magic.ninjutsu_entries, views = magic.song_views },
} }, {});
local ui = require('checklist_ui');
local settings = { show_completed = true };
local state = { search = { '' }, selected_views = {}, spell_level_ranges = {} };
for _, category in ipairs(snapshot.categories) do
    state.active_tab = category.id;
    for view_index, view in ipairs(category.views) do
        state.selected_views[category.id] = view_index;
        for band = 1, (category.id == 'magic_skills' and 5 or 1) do
            state.spell_level_ranges[view.id] = band;
            local range = category.id == 'magic_skills' and magic.song_views[band] or view;
            local expected = 0;
            for _, item in ipairs(category.entries) do
                assert(item.minimum_level <= 75 and item.job_levels:find('WHM Lv.75', 1, true));
                if (not view.magic_skill or view.magic_skill == item.magic_skill)
                    and (not range.level_min or (item.minimum_level >= range.level_min and item.minimum_level <= range.level_max)) then
                    expected = expected + 1;
                end
            end
            assert(#ui.build_export(snapshot, { entries = {} }, settings, state).rows == expected);
        end
    end
end
assert(state.spell_level_ranges.dark_magic == 5 and state.spell_level_ranges.healing_magic == 5);
print('Every spell category, Summoning, Ninjutsu, lowest job levels, and all range exports passed');
