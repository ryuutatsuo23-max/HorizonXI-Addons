-- SPDX-License-Identifier: GPL-3.0-or-later
-- Party signatures and primitive visibility layout adapted from atom0s's
-- hideparty, Copyright (c) 2025 Ashita Development Team (GPL-3.0-or-later).
-- Compass signature/byte location researched from Arielfy's FancyCompass.
-- See docs/SOURCES.md. Control, validation and restoration logic is implemented here.
local connection = require('connection_patch');
local M = {};
M.controls = {
    {key = 'party', label = 'Hide party list',
        hint = 'Unload hideparty before hiding the party list.'},
    {key = 'alliance1', label = 'Hide alliance 1',
        hint = 'Hides the first alliance list.\nNot yet tested in an alliance.'},
    {key = 'alliance2', label = 'Hide alliance 2',
        hint = 'Hides the second alliance list.\nNot yet tested in an alliance.'},
    {key = 'target', label = 'Hide target box + arrow',
        hint = 'Also hides the arrow above your target.'},
    {key = 'compass', label = 'Hide compass / radar',
        hint = 'Unload FancyCompass before hiding the compass.'},
    {key = 'clock', label = 'Hide clock',
        hint = 'Unchecking turns the clock on, even if it was off before.'},
    {key = 'connection', label = 'Hide connection info (arrows, S/R, %)',
        hint = 'Hides the arrows, S/R counters, and percentage.\nMail/friend notifications are not fully tested.'},
};
M.signatures = {
    party = '66C78182000000????C7818C000000????????C781900000',
    alliance = 'A1????????8B0D????????89442424A1????????33DB89',
    compass = '33C0668B81????????483DE3000000',
};

function M.new(io, notify)
    local self = {io = io, rows = {}, initialized = false, session = 0};
    for _, control in ipairs(M.controls) do
        self.rows[control.key] = {status = 'Waiting for login', available = false};
    end

    local function report(row, status)
        if row.status ~= status then
            row.status = status;
            if status:match('^Error') or status:match('^Blocked') then notify(status); end
        end
    end

    local function resolve_slot(match, offset)
        assert(match and io.in_module(match + offset, 4), 'Signature missing or ambiguous.');
        local slot = io.read32(match + offset);
        assert(slot ~= 0 and io.in_module(slot, 4), 'UI slot is outside the game module.');
        return slot;
    end

    function self:initialize()
        for _, control in ipairs(M.controls) do
            local row = self.rows[control.key];
            row.fault = nil;
            row.available = false;
            row.slot = nil;
        end
        local function scan(signature)
            local ok, result = pcall(io.find, signature);
            return ok and result or nil;
        end
        local party = scan(M.signatures.party);
        local alliance = scan(M.signatures.alliance);
        for key, source in pairs({party = {party, 0x19}, target = {party, 0x23},
            alliance1 = {alliance, 0x01}, alliance2 = {alliance, 0x07}}) do
            local row = self.rows[key];
            local ok, slot = pcall(resolve_slot, source[1], source[2]);
            row.available = ok;
            row.slot = ok and slot or nil;
            report(row, ok and 'Ready' or 'Unavailable - could not find this panel');
        end
        local row = self.rows.compass;
        local match = scan(M.signatures.compass);
        local ok, address = pcall(function()
            assert(match and io.in_module(match + 0x24, 1), 'No compass match.');
            assert(io.read8(match + 0x24) == 1, 'Compass byte is changed or unsupported.');
            return match + 0x24;
        end);
        row.available = ok;
        row.address = ok and address or nil;
        report(row, ok and 'Ready' or 'Unavailable - compass is unsupported or already hidden');
        self.rows.clock.available = true;
        report(self.rows.clock, 'Ready');
        local connection_row = self.rows.connection;
        local found, patch = pcall(connection.discover, io);
        connection_row.available = found;
        connection_row.patch = found and patch or nil;
        report(connection_row, found and 'Ready'
            or 'Unavailable - connection info is unsupported or already hidden');
        self.initialized = true;
    end

    local function primitive(row)
        if not row.slot then return nil; end
        local first = io.read32(row.slot);
        if first == 0 then return nil; end
        local object = io.read32(first + 0x08);
        if object == 0 then return nil; end
        assert(io.valid(object + 0x69, 2, true), 'Invalid UI object.');
        return object;
    end

    -- Restore only an object still reached by the authoritative slot, and only
    -- bytes still carrying our hidden value. Never write a cached, stale object.
    function self:release(key)
        local row = self.rows[key];
        if not row.owned then return true; end
        local ok = pcall(function()
            if key == 'clock' then
                -- Zoning can temporarily clear the session. Skipping restoration
                -- is expected here; never restore into a different session.
                if io.session() == row.owner_session then
                    io.clock(false);
                end
            elseif key == 'compass' then
                io.finish_patch(row.address);
                if io.read8(row.address) == 0 then io.patch8(row.address, row.original); end
            elseif key == 'connection' then
                connection.restore(io, row.patch);
            else
                local object = primitive(row);
                if object == row.object then
                    for index = 1, 2 do
                        local address = object + 0x68 + index;
                        if io.read8(address) == 0 then io.write8(address, row.original[index]); end
                    end
                end
            end
        end);
        if ok then
            row.owned = false;
            row.object = nil;
            report(row, 'Hiding stopped');
        else
            row.fault = true;
            report(row, 'Error restoring ' .. key .. '. Stop other UI-hiding addons, then Retry.');
        end
        return ok;
    end

    function self:restore()
        local success = true;
        for _, control in ipairs(M.controls) do
            if not self:release(control.key) then success = false; end
        end
        return success;
    end

    local function hide(key, row, session)
        if key == 'clock' then
            if not row.owned then
                io.clock(true);
                row.owned = true;
                row.owner_session = session;
            end
            report(row, 'Hiding enabled');
        elseif key == 'connection' then
            if not row.owned then
                connection.check(io, row.patch, false);
                row.owned = true; -- a failed write/protection change may still require restoration
                connection.hide(io, row.patch);
            else
                connection.check(io, row.patch, true);
            end
            report(row, 'Hiding enabled');
        elseif key == 'compass' then
            if not row.owned then
                assert(io.read8(row.address) == 1, 'Compass byte changed since discovery.');
                row.original = 1;
                row.owned = true; -- retain restoration responsibility even on a partial failure
                io.patch8(row.address, 0);
            else
                assert(io.read8(row.address) == 0, 'Another component changed the compass patch.');
            end
            report(row, 'Hiding enabled');
        else
            local object = primitive(row);
            if not object then
                row.owned = false;
                row.object = nil;
                report(row, 'Waiting for this panel to appear');
                return;
            end
            if not row.owned or object ~= row.object then
                local a, b = io.read8(object + 0x69), io.read8(object + 0x6A);
                assert((a == 0 or a == 1) and (b == 0 or b == 1), 'Unexpected visibility bytes.');
                row.original = {a, b};
                row.object = object;
                row.owned = true;
            end
            -- The game can refresh these flags each frame. Unticked controls
            -- are never forced visible, and incur no per-frame memory writes.
            if io.read8(object + 0x69) ~= 0 then io.write8(object + 0x69, 0); end
            if io.read8(object + 0x6A) ~= 0 then io.write8(object + 0x6A, 0); end
            report(row, 'Hiding enabled');
        end
    end

    function self:tick(config)
        local session = io.session();
        if session ~= self.session then
            if not self:restore() then return; end
            self.session = session;
        end
        if session == 0 then return; end
        if not self.initialized then self:initialize(); end
        local conflict_ok, party_conflict, compass_conflict = pcall(function()
            return io.loaded('hideparty'), io.loaded('fancycompass');
        end);
        for _, control in ipairs(M.controls) do
            local key, row = control.key, self.rows[control.key];
            local blocker = not conflict_ok and 'could not check other addons; click Retry'
                or ((key == 'clock' or key == 'compass') and compass_conflict and 'FancyCompass')
                or ((key == 'party' or key == 'alliance1' or key == 'alliance2' or key == 'target')
                    and party_conflict and 'hideparty');
            local wanted = config.enabled == true and config[key] == true;
            if blocker then
                if self:release(key) then report(row, 'Blocked - ' .. blocker
                    .. (conflict_ok and ' is loaded. Unload it first.' or '.')); end
            elseif not wanted then
                self:release(key);
                if row.available and not row.fault then report(row, 'Ready'); end
            elseif row.available and not row.fault then
                local ok = pcall(hide, key, row, session);
                if not ok then
                    self:release(key);
                    row.fault = true;
                    report(row, 'Error hiding ' .. key .. '. Click Retry.');
                end
            end
        end
    end

    function self:recheck()
        if not self:restore() then return false; end
        self.initialized = false;
        if io.session() ~= 0 then self:initialize(); end
        return true;
    end

    return self;
end

return M;
