-- Passive Bastok mission reader. No rank/order inference or outgoing packets.
-- 0x056: type 0x00D0 has Bastok completion bits at 0x0C (8 bytes);
-- type 0xFFFF has nation at 0x04 and current nation mission at 0x08.
local mission_state = {};
local live, cached = {}, {};

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

local function complete_pair(value)
    return value.completed ~= nil and value.nation ~= nil and value.current ~= nil;
end

function mission_state.handle_packet(e)
    if e.id == 0x00A then
        live = {};
        return true;
    end
    if e.id ~= 0x056 or type(e.data) ~= 'string' or #e.data < 0x26 then
        return false;
    end
    local log_type = unsigned(e.data, 0x24, 2);
    if log_type == 0x00D0 then
        live.completed = e.data:sub(0x0D, 0x14);
    elseif log_type == 0xFFFF then
        local nation = unsigned(e.data, 0x04, 4);
        local current = unsigned(e.data, 0x08, 4);
        if not integer(nation, 2) or not integer(current, 65535) then return false end;
        live.nation, live.current = nation, current;
    else
        return false;
    end
    if complete_pair(live) then
        cached = { completed = live.completed, nation = live.nation, current = live.current };
    end
    return true;
end

function mission_state.get_bastok(index)
    if not integer(index, 63) then return nil, 'Invalid Bastok mission index.' end;
    local selected, source;
    if complete_pair(live) then selected, source = live, 'live';
    elseif complete_pair(cached) then selected, source = cached, 'cache';
    else
        return nil, 'No paired Bastok mission logs are saved for this character yet. Zone once after loading the addon.';
    end
    local byte = selected.completed:byte(math.floor(index / 8) + 1);
    local completed = math.floor(byte / 2 ^ (index % 8)) % 2 == 1;
    local current = false;
    if selected.nation == 1 then
        if selected.current <= 23 then
            -- XIchecklist/LSB IDs 6-9 are travel stages of The Emissary (ID 5).
            current = selected.current == index
                or (index == 5 and selected.current >= 6 and selected.current <= 9);
        elseif selected.current ~= 65535 then
            -- Keep an unexpected ID unknown, never coerce it into mission zero.
            current = nil;
        end
    end
    return { completed = completed, current = current, source = source,
        nation = selected.nation, current_id = selected.current }, nil;
end

function mission_state.load_cache(value)
    live, cached = {}, {};
    if type(value) ~= 'table' or value.version ~= 1
        or not integer(value.nation, 2) or not integer(value.current, 65535)
        or type(value.completed) ~= 'string' or #value.completed ~= 16
        or value.completed:find('[^0-9A-Fa-f]') then return false end;
    cached = {
        nation = value.nation, current = value.current,
        completed = value.completed:gsub('..', function(byte) return string.char(tonumber(byte, 16)) end),
    };
    return true;
end

function mission_state.export_cache()
    if not complete_pair(live) then return nil end;
    return { version = 1, nation = live.nation, current = live.current,
        completed = live.completed:gsub('.', function(byte) return string.format('%02X', byte:byte()) end),
    };
end

function mission_state.clear()
    live, cached = {}, {};
end

return mission_state;
