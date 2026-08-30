-- SPDX-License-Identifier: GPL-3.0-or-later
-- Selective netstat drawing bypass. See NATIVE-UI-RESEARCH-2026-08-30.md.
-- No network-state, mode/timer, menu-pointer, or game-file writes.
local M = {};

-- Entire supported dispatcher: fixed branch destinations/epilogues, with only
-- the three relative CALL operands wildcarded. Never use a fixed game address.
M.signature = '83EC08568BF1578D4424088B4E0833FF5066897C240C66897C240E'
    .. '66897C241066897C2412E8????????8B46142BC7741B48752A'
    .. '8B4C240A8B54240851528D4E44E8????????5F5E83C408C3'
    .. '8B44240A8B4C240850518D4E1CE8????????5F5E83C408C3';
local length, offset = 0x64, 0x32;
local connection_prefix = '83EC10A1????????5685C057894C24080F8460010000A1????????530530460000';
local alternate_prefix = '83EC0C5355568BF1576A008B46106A0085C06880808080';

local function matches(bytes, pattern)
    for index = 1, #pattern / 2 do
        local pair = pattern:sub(index * 2 - 1, index * 2);
        if pair ~= '??' and bytes:byte(index) ~= tonumber(pair, 16) then return false; end
    end
    return #bytes == #pattern / 2;
end

local function read(io, address, size)
    assert(io.in_module(address, size), 'Connection code is outside the game module.');
    return io.read_bytes(address, size);
end

function M.discover(io)
    local start = io.find(M.signature);
    assert(start, 'Connection signature missing or ambiguous.');
    local original = read(io, start, length);
    assert(matches(original, M.signature), 'Connection dispatcher changed during discovery.');
    local function destination(call_offset, prefix)
        local displacement = io.read32(start + call_offset + 1);
        if displacement >= 0x80000000 then displacement = displacement - 0x100000000; end
        local target = start + call_offset + 5 + displacement;
        assert(io.in_module(target, 1), 'Connection call target is outside the game module.');
        if prefix then
            assert(matches(read(io, target, #prefix / 2), prefix), 'Unsupported connection draw function.');
        end
    end
    destination(0x25);
    destination(0x41, connection_prefix);
    destination(0x59, alternate_prefix);
    return {start = start, address = start + offset, original = original,
        hidden = original:sub(1, offset) .. string.char(0xEB) .. original:sub(offset + 2)};
end

function M.check(io, patch, hidden)
    assert(read(io, patch.start, length) == (hidden and patch.hidden or patch.original),
        'Connection dispatcher changed; refusing to overwrite another patch.');
end

function M.hide(io, patch)
    M.check(io, patch, false);
    -- Branch before the argument pushes. NOPing the CALL would unbalance the stack.
    io.patch8(patch.address, 0xEB);
    M.check(io, patch, true);
end

function M.restore(io, patch)
    io.finish_patch(patch.address);
    local current = read(io, patch.start, length);
    if current == patch.original then return; end
    assert(current == patch.hidden, 'Connection restoration blocked by changed code.');
    io.patch8(patch.address, 0x75);
    M.check(io, patch, false);
end

return M;
