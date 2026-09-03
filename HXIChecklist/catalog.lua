require('common');

local catalog = {};
local resource_cache = {};
local key_item_state = require('key_item_state');
local quest_state = require('quest_state');

local labels = {
    complete = 'Checked',
    missing = 'Missing',
    auto_complete = 'Completed',
    auto_current = 'Accepted',
    auto_not_logged = 'Not Accepted',
    unknown = 'Unknown',
    unavailable = 'Unavailable',
};

local function clone_entry(entry)
    local result = {};
    for key, value in pairs(entry) do
        result[key] = value;
    end
    return result;
end

local function logged_in_player()
    local ok, player = pcall(function()
        return AshitaCore:GetMemoryManager():GetPlayer();
    end);
    if not ok or player == nil then
        return nil;
    end

    local status_ok, login_status = pcall(function()
        return player:GetLoginStatus();
    end);
    if not status_ok or login_status ~= 2 then
        return nil;
    end
    return player;
end

local function resource_manager()
    local ok, manager = pcall(function()
        return AshitaCore:GetResourceManager();
    end);
    return ok and manager or nil;
end

local function resolve_spell_id(entry)
    local manager = resource_manager();
    if manager == nil then
        return nil;
    end

    local expected_name = entry.resource_name or entry.name;
    if type(entry.resource_id) == 'number' then
        local resource = nil;
        local ok = pcall(function()
            resource = manager:GetSpellById(math.floor(entry.resource_id));
        end);
        if not ok or resource == nil then
            return nil;
        end

        local resource_name = resource.Name and resource.Name[1] or nil;
        if type(resource_name) ~= 'string'
            or resource_name:lower() ~= expected_name:lower() then
            return nil;
        end
        if type(entry.skill_id) == 'number'
            and resource.Skill ~= math.floor(entry.skill_id) then
            return nil;
        end
        return resource.Index or resource.Id;
    end

    local resource = nil;
    local ok = pcall(function()
        resource = manager:GetSpellByName(expected_name, 0);
    end);
    if not ok or resource == nil then
        pcall(function()
            resource = manager:GetSpellByName(expected_name, 2);
        end);
    end
    if resource == nil then
        return nil;
    end
    return resource.Index or resource.Id;
end

local function resolve_key_item_id(entry)
    local manager = resource_manager();
    if manager == nil then
        return nil;
    end

    local expected_name = entry.resource_name or entry.name;
    local function id_matches_name(identifier)
        local resolved_name = nil;
        local ok = pcall(function()
            resolved_name = manager:GetString('keyitems.names', identifier, 2);
        end);
        return ok
            and type(resolved_name) == 'string'
            and resolved_name:lower() == expected_name:lower();
    end

    if type(entry.resource_id) == 'number' then
        local identifier = math.floor(entry.resource_id);
        if identifier > 0 and id_matches_name(identifier) then
            return identifier;
        end
        return nil;
    end

    local identifier = nil;
    local ok = pcall(function()
        identifier = manager:GetString('keyitems.names', expected_name, 2);
    end);
    if not ok or type(identifier) ~= 'number' or identifier <= 0 then
        pcall(function()
            identifier = manager:GetString('keyitems.names', expected_name);
        end);
    end
    if type(identifier) ~= 'number' or identifier <= 0 then
        return nil;
    end
    identifier = math.floor(identifier);
    if not id_matches_name(identifier) then
        return nil;
    end
    return identifier;
end

local function resolve_resource_id(entry)
    if resource_cache[entry.id] ~= nil then
        return resource_cache[entry.id] or nil;
    end

    local identifier = nil;
    if entry.kind == 'spell' then
        identifier = resolve_spell_id(entry);
    elseif entry.kind == 'key_item' then
        identifier = resolve_key_item_id(entry);
    end

    resource_cache[entry.id] = identifier or false;
    return identifier;
end

local function direct_state(entry)
    local player = logged_in_player();
    if player == nil then
        return 'unknown', 'Character data is not loaded.';
    end

    if entry.kind == 'spell' then
        local loaded_ok, loaded = pcall(function()
            return player:HasSpellData();
        end);
        if not loaded_ok or not loaded then
            return 'unknown', 'Spell data has not been received yet.';
        end
    end

    local identifier = resolve_resource_id(entry);
    if identifier == nil then
        return 'unknown', 'The client resource name could not be resolved.';
    end

    if entry.kind == 'key_item' then
        local packet_value, packet_note = key_item_state.has_key_item(identifier);
        if packet_value ~= nil then
            return packet_value and 'complete' or 'missing', packet_note;
        end

        local fallback_ok, fallback_value = pcall(function()
            return player:HasKeyItem(identifier);
        end);
        if fallback_ok and fallback_value == true then
            return 'complete', nil;
        end
        return 'unknown', packet_note;
    end

    local ok, has_value = pcall(function()
        return player:HasSpell(identifier);
    end);
    if not ok then
        return 'unknown', 'Ashita could not read this character value.';
    end
    return has_value and 'complete' or 'missing', nil;
end

local function entry_state(entry, manual_completed)
    if entry.availability == 'reported_inactive' then
        return 'unavailable', entry.availability_note;
    end

    if entry.kind == 'manual' then
        if entry.quest_area == 'bastok' and type(entry.quest_index) == 'number' then
            local automatic, automatic_note = quest_state.get_bastok(entry.quest_index);
            if automatic ~= nil then
                local source = automatic.source == 'cache'
                    and 'the saved character cache'
                    or 'the incoming Bastok quest log';
                if automatic.completed then
                    return 'auto_complete', string.format('Completed bit is set in %s.', source);
                end
                if automatic.current then
                    return 'auto_current', string.format('Current bit is set in %s.', source);
                end
                if entry.availability == 'unknown' then
                    return 'unknown', entry.availability_note;
                end
                return 'auto_not_logged', string.format('Neither the current nor completed bit is set in %s.', source);
            end

            return 'unknown', automatic_note;
        end

        return 'unknown', entry.availability_note
            or 'No automatic state reader is available for this entry.';
    end

    return direct_state(entry);
end

local function add_to_summary(summary, item)
    summary.entries = summary.entries + 1;
    if item.state == 'complete'
        or item.state == 'auto_complete' then
        summary.complete = summary.complete + 1;
        summary.known_total = summary.known_total + 1;
    elseif item.state == 'missing'
        or item.state == 'auto_current'
        or item.state == 'auto_not_logged' then
        summary.open = summary.open + 1;
        summary.known_total = summary.known_total + 1;
    elseif item.state == 'unknown' then
        summary.unknown = summary.unknown + 1;
    elseif item.state == 'unavailable' then
        summary.unavailable = summary.unavailable + 1;
    end
end

function catalog.empty_snapshot(profile)
    return {
        profile_version = profile.version,
        categories = {},
        summary = {
            entries = 0,
            known_total = 0,
            complete = 0,
            open = 0,
            unknown = 0,
            unavailable = 0,
        },
    };
end

function catalog.build_snapshot(profile, manual_completed)
    manual_completed = manual_completed or {};
    local snapshot = catalog.empty_snapshot(profile);

    for _, category in ipairs(profile.categories) do
        local output_category = {
            id = category.id,
            name = category.name,
            description = category.description,
            views = category.views,
            entries = {},
            summary = {
                entries = 0,
                known_total = 0,
                complete = 0,
                open = 0,
                unknown = 0,
                unavailable = 0,
            },
        };

        for _, entry in ipairs(category.entries) do
            local item = clone_entry(entry);
            item.state, item.state_note = entry_state(entry, manual_completed);
            item.state_label = labels[item.state] or item.state;
            table.insert(output_category.entries, item);
            add_to_summary(output_category.summary, item);
            add_to_summary(snapshot.summary, item);
        end
        table.insert(snapshot.categories, output_category);
    end
    return snapshot;
end

function catalog.invalidate()
    resource_cache = {};
end

return catalog;
