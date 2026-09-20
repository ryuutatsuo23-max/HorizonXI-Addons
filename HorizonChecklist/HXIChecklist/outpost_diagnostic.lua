-- Opt-in, one-shot observation only. No packet writes, game actions, or disk IO.
local diagnostic = {};
local deadline, captured = nil, nil;
local function unsigned(data, offset, size)
    local value = 0;
    for index = 0, size - 1 do value = value + data:byte(offset + index + 1) * 256 ^ index end;
    return value;
end
function diagnostic.clear()
    deadline, captured = nil, nil;
end
function diagnostic.arm(now)
    diagnostic.clear();
    deadline = (now or os.time()) + 60;
end
function diagnostic.status(now)
    if deadline and (now or os.time()) >= deadline then deadline = nil end;
    return deadline and 'Armed' or captured and 'Captured' or 'Off';
end
function diagnostic.handle_packet(e, now)
    if type(e) ~= 'table' or e.injected or e.blocked then return false end;
    if e.id == 0x00A or e.id == 0x00B then diagnostic.clear(); return false end;
    if diagnostic.status(now) ~= 'Armed' or e.id ~= 0x034 then return false end;
    if type(e.data) ~= 'string' or #e.data < 0x34 then return false end;
    -- Only this menu header and parameter block are retained. No character ID,
    -- player name, inventory contents, or whole-packet dump is recorded.
    captured = {
        npc = unsigned(e.data, 0x04, 4),
        npc_index = unsigned(e.data, 0x28, 2),
        zone = unsigned(e.data, 0x2A, 2),
        menu = unsigned(e.data, 0x2C, 2),
        parameters = e.data:sub(0x09, 0x28),
    };
    deadline = nil;
    return true;
end
function diagnostic.lines(now)
    local status = diagnostic.status(now);
    if not captured then return { 'Outpost diagnostic: ' .. status .. '. No menu captured.' } end;
    local lines = {
        ('Unverified menu: zone=%d menu=%d NPC=%d index=%d'):format(
            captured.zone, captured.menu, captured.npc, captured.npc_index),
    };
    for start = 1, 32, 16 do
        local bytes = {};
        for index = start, start + 15 do bytes[#bytes + 1] = ('%02X'):format(captured.parameters:byte(index)) end;
        lines[#lines + 1] = ('Parameters +%02X: %s'):format(start - 1, table.concat(bytes, ' '));
    end
    lines[#lines + 1] = 'No unlock interpretation. Review parameter values before sharing.';
    return lines;
end
return diagnostic;
