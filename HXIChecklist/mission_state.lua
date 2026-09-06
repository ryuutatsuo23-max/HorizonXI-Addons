-- Passive mission reader. Uses only explicit incoming current IDs/completion bits.
-- No mission sequence, rank, reward, or related quest state is used as completion.
local mission_state = {};
local live, cached = {}, {};

local function set(values)
    local result = {};
    for _, value in ipairs(values) do result[value] = true end;
    return result;
end

local areas = {
    sandoria = { label = "San d'Oria", nation = 0, completed_type = 0x00D0,
        completed_offset = 0x04, current_type = 0xFFFF, current_offset = 0x08,
        recognized = set({0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23}),
        aliases = { [5] = set({6,7,8,9}) } },
    bastok = { label = 'Bastok', nation = 1, completed_type = 0x00D0,
        completed_offset = 0x0C, current_type = 0xFFFF, current_offset = 0x08,
        recognized = set({0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23}),
        aliases = { [5] = set({6,7,8,9}) } },
    windurst = { label = 'Windurst', nation = 2, completed_type = 0x00D0,
        completed_offset = 0x14, current_type = 0xFFFF, current_offset = 0x08,
        recognized = set({0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23}),
        aliases = { [5] = set({6,7,8,9}) } },
    zilart = { label = 'Rise of the Zilart', completed_type = 0x00D0,
        completed_offset = 0x1C, current_type = 0xFFFF, current_offset = 0x0C,
        decline_bit = 0,
        recognized = set({0,4,6,8,10,12,14,16,18,20,22,23,24,26,27,28,30,31}) },
    promathia = { label = 'Chains of Promathia', current_type = 0xFFFF,
        current_offset = 0x10, current_only = true, decline_bit = 3,
        recognized = set({101,110,118,128,137,138,218,228,238,248,257,258,318,325,
            330,331,335,339,340,341,345,349,350,358,367,368,418,428,438,447,448,
            518,530,540,542,543,546,549,550,552,553,556,559,560,562,564,568,577,
            578,618,628,638,647,648,718,728,738,748,758,800,818,828,840,850}) },
    ahturhgan = { label = 'Treasures of Aht Urhgan', completed_type = 0x00D8,
        completed_offset = 0x04, current_type = 0x0080, current_offset = 0x18,
        recognized = set({0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,
            20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,
            42,43,44,45,46,47}) },
};

local function integer(value, maximum)
    return type(value) == 'number' and value >= 0 and value <= maximum
        and value == math.floor(value);
end

local function unsigned(data, offset, length)
    local value = 0;
    for index = 0, length - 1 do
        local byte = data:byte(offset + index + 1);
        if byte == nil then return nil end;
        value = value + byte * 2 ^ (index * 8);
    end
    return value;
end

local function complete(area, value)
    local config = areas[area];
    if not config or type(value) ~= 'table' or not integer(value.current, 65535) then
        return false;
    end
    if config.decline_bit ~= nil and type(value.declined) ~= 'boolean' then return false end;
    if config.current_only then return true end;
    if type(value.completed) ~= 'string' or #value.completed ~= 8 then return false end;
    return config.nation == nil or integer(value.nation, 2);
end

local function copy_value(value)
    return { completed = value.completed, nation = value.nation, current = value.current,
        declined = value.declined };
end

local function cache_ready(area, changed)
    if complete(area, live[area]) then
        cached[area] = copy_value(live[area]);
        changed[#changed + 1] = area;
    end
end

function mission_state.handle_packet(e)
    if e.id == 0x00A then
        live = {};
        return true, {};
    end
    if e.id ~= 0x056 or type(e.data) ~= 'string' or #e.data < 0x26 then
        return false, {};
    end
    local log_type = unsigned(e.data, 0x24, 2);
    local changed, recognized = {}, false;

    if log_type == 0x00D0 then
        recognized = true;
        for _, area in ipairs({'sandoria','bastok','windurst','zilart'}) do
            local config = areas[area];
            live[area] = live[area] or {};
            live[area].completed = e.data:sub(config.completed_offset + 1, config.completed_offset + 8);
            cache_ready(area, changed);
        end
    elseif log_type == 0xFFFF then
        local nation = unsigned(e.data, 0x04, 4);
        local nation_current = unsigned(e.data, 0x08, 4);
        local zilart_current = unsigned(e.data, 0x0C, 4);
        local promathia_current = unsigned(e.data, 0x10, 4);
        local tales_beginning = unsigned(e.data, 0x1A, 2);
        if not integer(nation, 2) or not integer(nation_current, 65535)
            or not integer(tales_beginning, 65535) then
            return false, {};
        end
        recognized = true;
        for _, area in ipairs({'sandoria','bastok','windurst'}) do
            live[area] = live[area] or {};
            live[area].nation, live[area].current = nation, nation_current;
            cache_ready(area, changed);
        end
        if integer(zilart_current, 65535) then
            live.zilart = live.zilart or {};
            live.zilart.current = zilart_current;
            live.zilart.declined = math.floor(tales_beginning / 2 ^ 0) % 2 == 1;
            cache_ready('zilart', changed);
        end
        if integer(promathia_current, 65535) then
            live.promathia = { current = promathia_current,
                declined = math.floor(tales_beginning / 2 ^ 3) % 2 == 1 };
            cache_ready('promathia', changed);
        end
    elseif log_type == 0x00D8 then
        recognized = true;
        live.ahturhgan = live.ahturhgan or {};
        live.ahturhgan.completed = e.data:sub(0x05, 0x0C);
        cache_ready('ahturhgan', changed);
    elseif log_type == 0x0080 then
        local current = unsigned(e.data, 0x18, 4);
        if not integer(current, 65535) then return false, {} end;
        recognized = true;
        live.ahturhgan = live.ahturhgan or {};
        live.ahturhgan.current = current;
        cache_ready('ahturhgan', changed);
    end
    return recognized, changed;
end

local function current_matches(config, index, current, current_ids)
    if current == 65535 then return false end;
    if config.recognized and not config.recognized[current] then return nil end;
    if current == index then return true end;
    if config.aliases and config.aliases[index] and config.aliases[index][current] then return true end;
    if type(current_ids) == 'table' then
        for _, value in ipairs(current_ids) do if current == value then return true end end;
    end
    return false;
end

function mission_state.get_area(area, index, current_ids)
    local config = areas[area];
    if not config or not integer(index, config.current_only and 65535 or 63) then
        return nil, 'Invalid mission area or index.';
    end
    local selected, source;
    if complete(area, live[area]) then selected, source = live[area], 'live';
    elseif complete(area, cached[area]) then selected, source = cached[area], 'cache';
    else
        local pattern = config.current_only
            and 'No %s current-mission log is saved for this character yet. Zone once after loading the addon.'
            or 'No paired %s mission logs are saved for this character yet. Zone once after loading the addon.';
        return nil, string.format(pattern, config.label);
    end

    local completed = nil;
    if not config.current_only then
        local byte = selected.completed:byte(math.floor(index / 8) + 1);
        completed = math.floor(byte / 2 ^ (index % 8)) % 2 == 1;
    end
    local current = false;
    if selected.declined == true then
        current = false;
    elseif config.nation ~= nil and selected.nation ~= config.nation then
        current = false;
    else
        current = current_matches(config, index, selected.current, current_ids);
    end
    return { completed = completed, current = current, source = source,
        nation = selected.nation, current_id = selected.current,
        current_only = config.current_only == true }, nil;
end

function mission_state.get_bastok(index)
    return mission_state.get_area('bastok', index);
end

function mission_state.load_area_cache(area, value)
    local config = areas[area];
    if not config then return false end;
    live[area], cached[area] = nil, nil;
    if type(value) ~= 'table' or value.version ~= 1
        or not integer(value.current, 65535) then return false end;
    if config.nation ~= nil and not integer(value.nation, 2) then return false end;
    if config.decline_bit ~= nil and type(value.declined) ~= 'boolean' then return false end;
    local decoded = nil;
    if not config.current_only then
        if type(value.completed) ~= 'string' or #value.completed ~= 16
            or value.completed:find('[^0-9A-Fa-f]') then return false end;
        decoded = value.completed:gsub('..', function(byte) return string.char(tonumber(byte, 16)) end);
    end
    cached[area] = { nation = value.nation, current = value.current,
        completed = decoded, declined = value.declined };
    return true;
end

function mission_state.export_area_cache(area)
    if not complete(area, live[area]) then return nil end;
    local result = { version = 1, nation = live[area].nation, current = live[area].current,
        declined = live[area].declined };
    if live[area].completed then
        result.completed = live[area].completed:gsub('.', function(byte)
            return string.format('%02X', byte:byte());
        end);
    end
    return result;
end

function mission_state.load_cache(value)
    return mission_state.load_area_cache('bastok', value);
end

function mission_state.export_cache()
    return mission_state.export_area_cache('bastok');
end

function mission_state.clear()
    live, cached = {}, {};
end

return mission_state;
