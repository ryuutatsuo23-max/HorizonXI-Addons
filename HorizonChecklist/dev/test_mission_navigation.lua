string.fmt = string.format;
bit = { bor = function() return 0 end };
local ui = dofile('HXIChecklist/checklist_ui.lua');
local settings = {scale_percent=100,show_completed=false,show_unknown=true,show_unavailable=true};
local state = {window_open={true},search={''},selected_views={},accepted_only=true};
local summary = {complete=2,known_total=3,unknown=1,unavailable=0};
local entries = {
    {id='m0',name='First',mission_number='1-1',mission_rank=1,state='auto_complete'},
    {id='m1',name='Second',mission_number='1-2',mission_rank=1,state='mission_current'},
    {id='m2',name='Third',mission_number='1-3',mission_rank=1,state='mission_repeat'},
    {id='m3',name='Fourth',mission_number='2-1',mission_rank=2,state='mission_not_current'},
    {id='m4',name='Fifth',mission_number='2-2',mission_rank=2,state='unknown'},
};
for _, item in ipairs(entries) do
    item.source_url='https://example.test/' .. item.id;
    item.npc='Guard'; item.quest_location='Bastok'; item.npc_coordinates='H-8';
    item.rewards='Conditional reward'; item.prerequisites='Partial source summary';
end
local categories = {
    {id='magic_skills',name='Magic Skills',summary=summary,entries={}},
    {id='maps',name='Maps',summary=summary,entries={}},
    {id='bastok_quests',name='Bastok Quests',summary=summary,entries={}},
    {id='bastok_missions',name='Bastok Missions',mission_area='bastok',mission_view_label='Rank',summary=summary,entries=entries,
        views={{id='all',name='All Ranks'},{id='rank_1',name='Rank 1',mission_rank=1},{id='rank_2',name='Rank 2',mission_rank=2}}},
};
local function frame(interaction, width)
    interaction=interaction or {};
    local seen={tabs={},texts={},combos={},columns={},source={},checks={}};
    local id, combo, column;
    local imgui=setmetatable({
        Begin=function() return true end, BeginTabBar=function() return true end,
        BeginTabItem=function(name) seen.tabs[#seen.tabs+1]=name; return name==(interaction.tab or 'Missions') end,
        BeginCombo=function(label, preview) combo=label; seen.combos[label]=preview; return true end,
        Selectable=function(label) return combo=='Rank##bastok_missions' and interaction.rank and label:find('##'..interaction.rank,1,true)~=nil end,
        Checkbox=function(label,value)
            seen.checks[label]=true;
            if label=='Current only' and interaction.toggle_current then value[1]=not value[1]; return true end;
            return false;
        end,
        PushID=function(value) id=value end,
        SmallButton=function(label)
            if label=='Source' then seen.source[id]=column; return interaction.source==id end;
            return label:find('##mission_details',1,true) and interaction.expand==id;
        end,
        Text=function(value) seen.texts[value]=true end,
        TextWrapped=function(value) seen.texts[value]=true end,
        TextColored=function(_,value) seen.texts[value]=true end,
        GetWindowWidth=function() return width or 760 end,
        GetFontSize=function() return 12 end,
        CalcTextSize=function(value) return #value * 7 * settings.scale_percent / 100 end,
        IsItemHovered=function() return false end,
        BeginTable=function(name,count) assert(count==3); seen.table=name; return true end,
        TableSetupColumn=function(name) seen.columns[name]=true end,
        TableSetColumnIndex=function(value) column=value end,
    },{__index=function() return function() return false end end});
    local actions=setmetatable({open_source=function(url) seen.opened=url end},
        {__index=function() return function() error('Mission UI must not save, refresh, or mark completion') end end});
    ui.render({version='test',scope_note='test'},{summary=summary,categories=categories},{entries={}},settings,state,actions,imgui);
    assert(table.concat(seen.tabs,'|')=='Magic Skills|Maps|Quests|Missions|Skill Levels');
    return seen;
end
local first=frame();
assert(first.combos['Storyline##MissionStory']=='Bastok' and first.combos['Rank##bastok_missions']=='All Ranks');
assert(first.columns.Mission and first.columns.Source and first.columns['Rank / Type']);
assert(not first.checks['Accepted only'] and not first.checks['##custom_completion_m1']);
assert(first.texts['1-2 Second'] and first.texts['2-1 Fourth'] and not first.texts['1-1 First']);
local only=frame({toggle_current=true});
assert(only.texts['1-2 Second'] and only.texts['1-3 Third'] and not only.texts['2-1 Fourth'] and not only.texts['2-2 Fifth']);
assert(only.texts['[Current / Done]'], 'A current repeat stays visible even with completed rows hidden');
local open=frame({expand='m1',source='m1'});
assert(open.texts['NPC: Guard'] and open.texts['Coordinates: H-8'] and open.texts['Rewards: Conditional reward']);
assert(open.source.m1==1 and open.source.m2==1 and open.opened=='https://example.test/m1');
frame({expand='m1'}); assert(not state.expanded_missions.m1);
local empty=frame({rank='rank_2'}); assert(empty.texts['No entries match the current filters.']);
frame({tab='Quests'}); assert(state.mission_current_only and state.accepted_only);
frame({rank='all',toggle_current=true});
state.search[1]='Fourth'; assert(frame().texts['2-1 Fourth'] and not frame().texts['1-2 Second']); state.search[1]='';
settings.show_unknown=false; assert(not frame().texts['2-2 Fifth']);
settings.show_completed=true; assert(frame().texts['1-1 First']);
for _, scale in ipairs({75,100,150}) do
    settings.scale_percent=scale;
    for _, width in ipairs({400,760}) do assert(frame({expand='m3'},width).source.m3==1) end;
end
assert(summary.complete==2 and summary.known_total==3, 'Navigation cannot mutate progress totals');
print('mission tab, rank/current filters, repeated-current visibility, detail expansion, and Source alignment passed');
