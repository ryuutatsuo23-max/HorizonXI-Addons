-- SPDX-License-Identifier: GPL-3.0-or-later
-- Ashita/Windows adapter. No external-process handles or game-file writes.
local ffi = require('ffi');
local bit = require('bit');

ffi.cdef[[
typedef struct {
    void* BaseAddress;
    void* AllocationBase;
    uint32_t AllocationProtect;
    size_t RegionSize;
    uint32_t State;
    uint32_t Protect;
    uint32_t Type;
} HXIB_MEMORY_BASIC_INFORMATION;
size_t __stdcall VirtualQuery(const void* address, void* buffer, size_t length);
void* __stdcall GetCurrentProcess(void);
int __stdcall FlushInstructionCache(void* process, const void* address, size_t length);
]];

local kernel = ffi.load('kernel32');
local info = ffi.new('HXIB_MEMORY_BASIC_INFORMATION[1]');
local M = {};
local pending_protection = {};

function M.valid(address, size, writable)
    if ffi.sizeof('void*') ~= 4 or type(address) ~= 'number'
        or address < 0x10000 or address + size > 0x100000000 then
        return false;
    end
    if kernel.VirtualQuery(ffi.cast('const void*', address), info, ffi.sizeof(info[0])) == 0 then
        return false;
    end
    local region = info[0];
    local protection = tonumber(region.Protect);
    local base = tonumber(ffi.cast('uintptr_t', region.BaseAddress));
    if region.State ~= 0x1000 or bit.band(protection, 0x100) ~= 0
        or address + size > base + tonumber(region.RegionSize) then
        return false;
    end
    local access = bit.band(protection, 0xFF);
    if writable then
        return access == 0x04 or access == 0x08 or access == 0x40 or access == 0x80;
    end
    return access == 0x02 or access == 0x04 or access == 0x08
        or access == 0x20 or access == 0x40 or access == 0x80;
end

function M.read8(address)
    assert(M.valid(address, 1, false), 'Unreadable UI byte.');
    return ashita.memory.read_uint8(address);
end

function M.read32(address)
    assert(M.valid(address, 4, false), 'Unreadable UI pointer.');
    return ashita.memory.read_uint32(address);
end

function M.read_bytes(address, size)
    assert(type(size) == 'number' and size > 0 and size <= 256 and size % 1 == 0,
        'Invalid code-check length.');
    assert(M.valid(address, size, false), 'Unreadable code range.');
    return ffi.string(ffi.cast('const char*', address), size);
end

function M.write8(address, value)
    assert(M.valid(address, 1, true), 'UI byte is not writable.');
    ashita.memory.write_uint8(address, value);
    assert(M.read8(address) == value, 'UI byte write did not take effect.');
end

-- Compass and connection code bytes need temporary page protection changes.
function M.finish_patch(address)
    local previous = pending_protection[address];
    if previous == nil then return; end
    assert(ashita.memory.protect(address, 1, previous), 'Could not restore code page protection.');
    pending_protection[address] = nil;
end

function M.patch8(address, value)
    -- Never replace the real original protection with a failed attempt's RWX state.
    M.finish_patch(address);
    assert(M.valid(address, 1, false), 'Code byte is not readable.');
    local success, previous = ashita.memory.unprotect(address, 1);
    assert(success and previous, 'Could not change code page protection.');
    pending_protection[address] = previous;
    local wrote, problem = pcall(function()
        M.write8(address, value);
        assert(kernel.FlushInstructionCache(kernel.GetCurrentProcess(),
            ffi.cast('const void*', address), 1) ~= 0, 'Could not flush code instruction cache.');
    end);
    M.finish_patch(address);
    assert(wrote, problem);
end

function M.in_module(address, size)
    local base = ashita.memory.get_base('FFXiMain.dll');
    local length = ashita.memory.get_size('FFXiMain.dll');
    return base ~= 0 and address >= base and address + size <= base + length;
end

function M.find(pattern)
    -- Require exactly one match, never guess between multiple candidates.
    local first = ashita.memory.find('FFXiMain.dll', 0, pattern, 0, 0);
    if first == 0 or ashita.memory.find('FFXiMain.dll', 0, pattern, 0, 1) ~= 0 then
        return nil;
    end
    return first;
end

function M.loaded(name)
    assert(AddonManager ~= nil, 'AddonManager is unavailable; cannot check conflicts.');
    return AddonManager:IsLoaded(name);
end

function M.session()
    local memory = AshitaCore:GetMemoryManager();
    if memory:GetPlayer():GetLoginStatus() ~= 2 then return 0; end
    -- Used only in memory to avoid delivering clock commands to another character.
    return memory:GetParty():GetMemberServerId(0);
end

function M.clock(hidden)
    AshitaCore:GetChatManager():QueueCommand(-1, hidden and '/clock off' or '/clock on');
end

return M;
