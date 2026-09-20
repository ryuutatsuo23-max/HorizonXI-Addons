string.fmt = string.format;
bit = { bor = function() return 7 end };
ImGuiCol_Text, ImGuiCol_TableBorderStrong, ImGuiCol_TableBorderLight = 1, 2, 3;
local ui = dofile('HXIChecklist/checklist_ui.lua');
local state = { window_open = { true }, active_tab = 'skill_levels', search = { '' }, selected_views = {} };
local settings = { scale_percent = 100 };
local skills = { entries = {
    { name = 'Healing', value = 51, capped = false },
    { name = 'Singing', value = 0, capped = true },
    { name = 'Unknown skill' },
    { name = 'Unknown cap', value = 10 },
} };
local snapshot = { categories = {}, summary = { complete = 0, known_total = 0, unknown = 0, unavailable = 0 } };
local seen, stack = {}, {};
local imgui = setmetatable({
    Begin = function() return true end, BeginTabBar = function() return true end,
    BeginTabItem = function(label) return label == 'Others/Key Items' or label == 'Skill Levels' end,
    PushStyleColor = function(id, color) stack[#stack + 1] = { id, color } end,
    PopStyleColor = function(count) for _ = 1, count or 1 do assert(table.remove(stack)) end end,
    BeginTable = function(id, columns, flags)
        assert(id == '##SkillLevelRows' and columns == 3 and flags == 7);
        assert(stack[2][1] == ImGuiCol_TableBorderStrong and stack[2][2][1] == 0.78);
        assert(stack[3][1] == ImGuiCol_TableBorderLight and stack[3][2][1] == 0.58);
        seen.table = true; return true;
    end,
    TableSetupColumn = function(name) seen[name] = true end,
    Text = function(text) seen[text] = true end,
    TextColored = function(_, text) seen[text] = true end,
    GetFontSize = function() return 12 end,
    GetWindowWidth = function() return 760 end,
    CalcTextSize = function(value) return #value * 7 end,
}, { __index = function() return function() return false end end });
ui.render({}, snapshot, skills, settings, state, {}, imgui);
assert(seen.table and seen.Skill and seen.Level and seen.Status);
assert(seen['51'] and seen['0'] and seen.Capped and seen.Training and seen.Unavailable and seen.Unknown);
assert(#stack == 0);
local exported = ui.build_export(snapshot, skills, settings, state);
assert(#exported.rows == 4 and exported.rows[2][2] == 0 and exported.rows[3][3] == 'Unavailable');
print('Skill Levels table, zero/unavailable values, global visible dividers, export, and style balance passed');
