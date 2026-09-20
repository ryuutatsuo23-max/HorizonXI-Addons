local skill_levels = {};

local definitions = {
    { id = 'divine_magic', name = 'Divine Magic', skill_id = 32 },
    { id = 'healing_magic', name = 'Healing Magic', skill_id = 33 },
    { id = 'enhancing_magic', name = 'Enhancing Magic', skill_id = 34 },
    { id = 'enfeebling_magic', name = 'Enfeebling Magic', skill_id = 35 },
    { id = 'elemental_magic', name = 'Elemental Magic', skill_id = 36 },
    { id = 'dark_magic', name = 'Dark Magic', skill_id = 37 },
    { id = 'summoning_magic', name = 'Summoning Magic', skill_id = 38 },
    { id = 'ninjutsu', name = 'Ninjutsu', skill_id = 39 },
    { id = 'singing', name = 'Singing', skill_id = 40 },
    { id = 'string_instrument', name = 'String Instrument', skill_id = 41 },
    { id = 'wind_instrument', name = 'Wind Instrument', skill_id = 42 },
};

local function unavailable_snapshot(note)
    local entries = {};
    for _, definition in ipairs(definitions) do
        entries[#entries + 1] = {
            id = definition.id,
            name = definition.name,
            skill_id = definition.skill_id,
            value = nil,
            capped = nil,
        };
    end
    return {
        entries = entries,
        note = note,
    };
end

function skill_levels.empty_snapshot()
    return unavailable_snapshot('Character skill data is not loaded yet.');
end

function skill_levels.build_snapshot()
    local player_ok, player = pcall(function()
        return AshitaCore:GetMemoryManager():GetPlayer();
    end);
    if not player_ok or player == nil then
        return unavailable_snapshot('Character skill data is unavailable from Ashita.');
    end

    local status_ok, login_status = pcall(function()
        return player:GetLoginStatus();
    end);
    if not status_ok or login_status ~= 2 then
        return unavailable_snapshot('Character skill data is not loaded yet.');
    end

    local entries = {};
    local unavailable = 0;
    for _, definition in ipairs(definitions) do
        local skill_ok, skill = pcall(function()
            return player:GetCombatSkill(definition.skill_id);
        end);
        local value_ok, value = pcall(function()
            return skill:GetSkill();
        end);
        local capped_ok, capped = pcall(function()
            return skill:IsCapped();
        end);

        if not skill_ok
            or skill == nil
            or not value_ok
            or type(value) ~= 'number'
            or value < 0 then
            value = nil;
            capped = nil;
            unavailable = unavailable + 1;
        else
            value = math.floor(value);
            if not capped_ok or type(capped) ~= 'boolean' then
                capped = nil;
            end
        end

        entries[#entries + 1] = {
            id = definition.id,
            name = definition.name,
            skill_id = definition.skill_id,
            value = value,
            capped = capped,
        };
    end

    return {
        entries = entries,
        note = unavailable > 0
            and string.format('%d skill value(s) are unavailable from the client.', unavailable)
            or nil,
    };
end

return skill_levels;
