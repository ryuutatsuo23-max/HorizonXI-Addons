-- MIT: independent, read-only death observer for explicitly bound camp spawns.
-- Protocol reference: Ashita libs/lin/packets.lua ParseBasic (0x29).
-- Meanings checked in local simplelog/lib/res/action_messages.lua.
local camps = require('camps');
local bit = require('bit');
local M = {};
local observations = {};
local diagnostics = setmetatable({}, {__mode = 'k'});
-- Diagnostic history is never used to authorize a death after evidence expires.
local history = setmetatable({}, {__mode = 'k'});
local sightings = setmetatable({}, {__mode = 'k'});
local zoning = false;
local confirmation_grace_seconds = 2;
local death_messages = {[6]=true, [20]=true, [113]=true, [406]=true, [605]=true, [646]=true};

local function uint(data, offset, size)
    local value = 0;
    for i = 0, size - 1 do value = value + data:byte(offset + i + 1) * 256 ^ i; end
    return value;
end

function M.parse(e)
    -- Combat-log addons may block the original after displaying replacement text.
    -- Observe the original server event without changing its blocked flag.
    if e.id ~= 0x29 or e.injected == true
        or type(e.data) ~= 'string' or type(e.size) ~= 'number'
        or e.size < 0x1A or #e.data < 0x1A then return nil; end
    local message = bit.band(uint(e.data, 0x18, 2), 0x7FFF);
    if not death_messages[message] then return nil; end
    return {id = uint(e.data, 0x08, 4), index = uint(e.data, 0x16, 2)};
end

function M.reset()
    observations = {};
    diagnostics = setmetatable({}, {__mode = 'k'});
    history = setmetatable({}, {__mode = 'k'});
    sightings = setmetatable({}, {__mode = 'k'});
end

function M.is_alive(config, camp, now)
    local sighting = sightings[camp];
    return config.camps_enabled and not zoning and sighting ~= nil
        and sighting.binding == camp.binding and now >= sighting.at
        and now - sighting.at <= confirmation_grace_seconds;
end

-- Read zone independently: an entity may be gone when its defeat arrives.
function M.zone()
    local ok, zone = pcall(function()
        local party = AshitaCore:GetMemoryManager():GetParty();
        if not party or party:GetMemberIsActive(0) == 0 then return nil; end
        return party:GetMemberZone(0);
    end);
    return ok and zone or nil;
end

function M.describe(config, camp, now)
    local observed = observations[camp];
    local status = 'Waiting for a living observation of this exact spawn';
    if not config.camps_enabled or not camp.auto_death then status = 'Automatic tracking off';
    elseif zoning then status = 'Waiting for zoning to finish';
    elseif observed and observed.binding == camp.binding then
        if observed.phase == 'alive' and now >= observed.confirmed_at
            and now - observed.confirmed_at <= confirmation_grace_seconds then
            status = 'Armed - exact spawn confirmed; awaiting explicit defeat';
        elseif observed.phase == 'dead' or observed.phase == 'awaiting' then
            status = 'Death handled - waiting to observe the next living spawn';
        else status = 'Spawn confirmation expired'; end
    end
    local last = diagnostics[camp];
    return status, last and last.binding == camp.binding and last.text
        or 'No supported defeat message received for this binding';
end

-- Also used when binding. Fail closed when identity or live entity reads are unavailable.
function M.read(index)
    local ok, result, reason = pcall(function()
        local memory = AshitaCore:GetMemoryManager();
        local entity, party = memory:GetEntity(), memory:GetParty();
        if not party or party:GetMemberIsActive(0) == 0 then return nil, 'party unavailable'; end
        local zone = party:GetMemberZone(0);
        local flags = entity:GetSpawnFlags(index);
        local render = entity:GetRenderFlags0(index);
        if bit.band(flags, 0x10) == 0 or bit.band(flags, 0x03) ~= 0 then
            return nil, string.format('spawn flags rejected (0x%X)', flags);
        end
        if bit.band(render, 0x200) == 0 or bit.band(render, 0x4000) ~= 0 then
            return nil, string.format('render flags rejected (0x%X)', render);
        end
        return {zone = zone, id = entity:GetServerId(index), index = index,
            name = entity:GetName(index), hp = entity:GetHPPercent(index)};
    end);
    if not ok then return nil, 'entity API read failed'; end
    return result, reason;
end

local function matches(binding, live)
    return live and live.zone == binding.zone and live.index == binding.index
        and live.id == binding.id and live.name == binding.name;
end

local function read_summary(binding, live, reason)
    if live == nil then return reason or 'entity unavailable'; end
    if not matches(binding, live) then return 'identity mismatch'; end
    return 'matching identity, HP=' .. tostring(live.hp) .. '%';
end

local function age(now, then_at)
    if then_at == nil then return 'never'; end
    return string.format('%.2fs', now - then_at);
end

function M.observe(config, now, read)
    read = read or M.read;
    if zoning or not config.camps_enabled then M.reset(); return; end
    local next_observations = {};
    for _, camp in ipairs(config.camps) do
        local binding = camp.binding;
        if binding then
            local live, read_reason = read(binding.index);
            if matches(binding, live) and type(live.hp) == 'number' and live.hp > 0 then
                sightings[camp] = {binding = binding, at = now};
            else sightings[camp] = nil; end
            local old = observations[camp];
            if old and old.binding ~= binding then old = nil; end
            if not camp.auto_death then old = nil; end
            if old and old.phase == 'dead' then sightings[camp] = nil; end
            local detail = history[camp];
            if not detail or detail.binding ~= binding then detail = {binding = binding}; end
            detail.scan_at = now;
            detail.read = read_summary(binding, live, read_reason);
            history[camp] = detail;
            if camp.auto_death and matches(binding, live) and type(live.hp) == 'number' and live.hp > 0 then
                -- After a death packet, do not re-arm on a stale living frame.
                if not old or old.phase ~= 'dead' then
                    next_observations[camp] = {binding = binding, phase = 'alive',
                        seen_at = now, confirmed_at = now};
                    detail.alive_at = now;
                    detail.confirmed_at = now;
                else next_observations[camp] = old; end
            elseif old and old.phase == 'alive'
                and (live == nil or (matches(binding, live) and live.hp == 0))
                and now >= old.confirmed_at
                and now - old.confirmed_at <= confirmation_grace_seconds then
                -- The client can report HP=0 for several scans before the defeat
                -- message. Continue this already-observed life while identity is
                -- confirmed, but never arm from a corpse or bridge a stale gap.
                if live ~= nil then
                    old.confirmed_at = now;
                    detail.confirmed_at = now;
                end
                -- Missing reads retain evidence only for the existing short grace.
                next_observations[camp] = old;
            elseif old and old.phase == 'dead' then
                -- A dead/absent observation followed by a living one permits the next cycle.
                next_observations[camp] = {binding = binding, phase = 'awaiting'};
            end
        end
    end
    observations = next_observations;
end

function M.packet(config, e, now, wall_time, read, read_zone)
    if e.id == 0x0B then zoning = true; M.reset(); return 0; end
    if e.id == 0x0A then zoning = false; M.reset(); return 0; end
    if zoning or not config.camps_enabled then return 0; end
    local death = M.parse(e);
    if not death then return 0; end
    read = read or M.read;
    local current_zone = (read_zone or M.zone)();
    local changed = 0;
    for _, camp in ipairs(config.camps) do
        local binding, observed = camp.binding, observations[camp];
        if camp.auto_death and binding and (death.id == binding.id or death.index == binding.index) then
            local live, read_reason = read(binding.index);
            local reason;
            if current_zone ~= binding.zone then reason = 'Rejected: zone unavailable or different';
            elseif death.id ~= binding.id or death.index ~= binding.index then
                reason = 'Rejected: defeat ID/index does not match binding';
            elseif not observed or observed.binding ~= binding then
                reason = 'Rejected: no recent living observation / continuous spawn confirmation';
            elseif observed.phase ~= 'alive' then reason = 'Ignored: death already handled';
            elseif now < observed.confirmed_at
                or now - observed.confirmed_at > confirmation_grace_seconds then
                reason = 'Rejected: spawn confirmation expired';
            else
                if live ~= nil and not matches(binding, live) then
                    reason = 'Rejected: current entity identity differs';
                elseif camps.record(camp, wall_time) then
                    sightings[camp] = nil;
                    observed.phase = 'dead'; changed = changed + 1;
                    reason = live == nil and 'Accepted: recent identity + explicit defeat (entity unavailable)'
                        or 'Accepted: matching explicit defeat';
                else reason = 'Rejected: invalid recording time'; end
            end
            local ok, stamp = pcall(os.date, '%H:%M:%S', wall_time);
            local detail = history[camp];
            if not detail or detail.binding ~= binding then detail = {}; end
            local evidence = ' | living age: ' .. age(now, detail.alive_at)
                .. ' | identity age: ' .. age(now, detail.confirmed_at)
                .. ' | scan age: ' .. age(now, detail.scan_at)
                .. ' | last scan: ' .. (detail.read or 'none')
                .. ' | at defeat: ' .. read_summary(binding, live, read_reason);
            diagnostics[camp] = {binding = binding,
                text = (ok and stamp or '?') .. ' - ' .. reason .. evidence};
        end
    end
    return changed;
end

return M;
