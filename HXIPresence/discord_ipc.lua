require('common');

local ffi = require('ffi');
local json = require('json');

pcall(ffi.cdef, [[
    void* __stdcall CreateFileA(
        const char* file_name,
        unsigned long desired_access,
        unsigned long share_mode,
        void* security_attributes,
        unsigned long creation_disposition,
        unsigned long flags_and_attributes,
        void* template_file
    );
]]);
pcall(ffi.cdef, [[
    int __stdcall WriteFile(
        void* file,
        const void* buffer,
        unsigned long bytes_to_write,
        unsigned long* bytes_written,
        void* overlapped
    );
]]);
pcall(ffi.cdef, [[
    int __stdcall ReadFile(
        void* file,
        void* buffer,
        unsigned long bytes_to_read,
        unsigned long* bytes_read,
        void* overlapped
    );
]]);
pcall(ffi.cdef, [[
    int __stdcall PeekNamedPipe(
        void* pipe,
        void* buffer,
        unsigned long buffer_size,
        unsigned long* bytes_read,
        unsigned long* total_bytes_available,
        unsigned long* bytes_left_this_message
    );
]]);
pcall(ffi.cdef, [[
    int __stdcall CloseHandle(void* object);
]]);
pcall(ffi.cdef, [[
    unsigned long __stdcall GetLastError(void);
]]);
pcall(ffi.cdef, [[
    unsigned long __stdcall GetCurrentProcessId(void);
]]);

local discord_ipc = {};
local kernel32 = ffi.load('kernel32');

local generic_read_write = 0xC0000000;
local open_existing = 3;
local invalid_handle = ffi.cast('void*', -1);
local maximum_frame_size = 1024 * 1024;

local opcode_handshake = 0;
local opcode_frame = 1;
local opcode_close = 2;
local opcode_ping = 3;
local opcode_pong = 4;

local state = {
    handle = nil,
    receive_buffer = '',
    nonce = 0,
    last_error = 0,
    ready = false,
    last_activity_ack_nonce = nil,
    last_activity_error_nonce = nil,
    last_activity_error = '',
};

local function is_open()
    return state.handle ~= nil;
end

local function close_handle()
    if state.handle ~= nil then
        kernel32.CloseHandle(state.handle);
        state.handle = nil;
    end
    state.receive_buffer = '';
    state.ready = false;
end

local function fail_with_last_error()
    state.last_error = tonumber(kernel32.GetLastError());
    close_handle();
    return false, state.last_error;
end

local function write_all(value)
    local written = ffi.new('unsigned long[1]');
    local ok = kernel32.WriteFile(
        state.handle,
        value,
        #value,
        written,
        nil
    );
    if ok == 0 or tonumber(written[0]) ~= #value then
        return fail_with_last_error();
    end
    return true;
end

local function send_frame(opcode, payload)
    if not is_open() then
        return false, 'not connected';
    end

    if type(payload) ~= 'string' or #payload > maximum_frame_size then
        return false, 'invalid payload';
    end

    local header = ffi.new('uint32_t[2]');
    header[0] = opcode;
    header[1] = #payload;
    return write_all(ffi.string(header, 8) .. payload);
end

local function next_nonce()
    state.nonce = state.nonce + 1;
    return ('%d-%d'):fmt(os.time(), state.nonce);
end

local function parse_received_frames()
    while #state.receive_buffer >= 8 do
        local header = ffi.new('uint32_t[2]');
        ffi.copy(header, state.receive_buffer, 8);
        local opcode = tonumber(header[0]);
        local payload_size = tonumber(header[1]);

        if payload_size < 0 or payload_size > maximum_frame_size then
            state.last_error = -1;
            close_handle();
            return false, 'Discord returned an invalid frame size.';
        end

        local frame_size = 8 + payload_size;
        if #state.receive_buffer < frame_size then
            return true;
        end

        local payload = state.receive_buffer:sub(9, frame_size);
        state.receive_buffer = state.receive_buffer:sub(frame_size + 1);

        if opcode == opcode_close then
            close_handle();
            return false, 'Discord closed the IPC connection.';
        end
        if opcode == opcode_ping then
            local ok, reason = send_frame(opcode_pong, payload);
            if not ok then
                return false, reason;
            end
        end
        if opcode == opcode_frame then
            local decoded_ok, response = pcall(json.decode, payload);
            if decoded_ok and type(response) == 'table' then
                if response.evt == 'READY' then
                    state.ready = true;
                elseif response.cmd == 'SET_ACTIVITY' and response.evt == 'ERROR' then
                    state.last_activity_error_nonce = response.nonce;
                    state.last_activity_error = response.data ~= nil
                        and tostring(response.data.message or 'Discord rejected the activity.')
                        or 'Discord rejected the activity.';
                elseif response.cmd == 'SET_ACTIVITY' and response.nonce ~= nil then
                    state.last_activity_ack_nonce = response.nonce;
                    state.last_activity_error_nonce = nil;
                    state.last_activity_error = '';
                end
            end
        end
    end
    return true;
end

function discord_ipc.connect(application_id)
    close_handle();
    state.last_error = 0;
    state.last_activity_ack_nonce = nil;
    state.last_activity_error_nonce = nil;
    state.last_activity_error = '';

    application_id = tostring(application_id or '');
    if not application_id:match('^%d+$') then
        return false, 'A numeric Discord application ID is required.';
    end

    for index = 0, 9 do
        local pipe_name = ('\\\\.\\pipe\\discord-ipc-%d'):fmt(index);
        local handle = kernel32.CreateFileA(
            pipe_name,
            generic_read_write,
            0,
            nil,
            open_existing,
            0,
            nil
        );
        if handle ~= invalid_handle then
            state.handle = handle;
            break
        end
    end

    if state.handle == nil then
        state.last_error = tonumber(kernel32.GetLastError());
        return false, state.last_error;
    end

    local payload = json.encode({
        v = 1,
        client_id = application_id,
    });
    local ok, reason = send_frame(opcode_handshake, payload);
    if not ok then
        return false, reason;
    end
    return true;
end

function discord_ipc.set_activity(activity)
    if not is_open() then
        return false, 'not connected';
    end
    if state.ready ~= true then
        return false, 'Discord handshake is not ready';
    end

    local args = {
        pid = tonumber(kernel32.GetCurrentProcessId()),
    };
    if activity ~= nil then
        args.activity = activity;
    end

    local nonce = next_nonce();
    local payload = json.encode({
        cmd = 'SET_ACTIVITY',
        args = args,
        nonce = nonce,
    });
    local ok, reason = send_frame(opcode_frame, payload);
    if not ok then
        return false, reason;
    end
    return true, nonce;
end

function discord_ipc.clear_activity()
    return discord_ipc.set_activity(nil);
end

function discord_ipc.tick()
    if not is_open() then
        return false;
    end

    local available = ffi.new('unsigned long[1]');
    local peek_ok = kernel32.PeekNamedPipe(
        state.handle,
        nil,
        0,
        nil,
        available,
        nil
    );
    if peek_ok == 0 then
        return fail_with_last_error();
    end

    while tonumber(available[0]) > 0 do
        local requested = math.min(tonumber(available[0]), 65536);
        local buffer = ffi.new('uint8_t[?]', requested);
        local bytes_read = ffi.new('unsigned long[1]');
        local read_ok = kernel32.ReadFile(
            state.handle,
            buffer,
            requested,
            bytes_read,
            nil
        );
        if read_ok == 0 then
            return fail_with_last_error();
        end

        local count = tonumber(bytes_read[0]);
        if count == 0 then
            break
        end
        state.receive_buffer = state.receive_buffer .. ffi.string(buffer, count);

        peek_ok = kernel32.PeekNamedPipe(
            state.handle,
            nil,
            0,
            nil,
            available,
            nil
        );
        if peek_ok == 0 then
            return fail_with_last_error();
        end
    end

    return parse_received_frames();
end

function discord_ipc.disconnect()
    close_handle();
end

function discord_ipc.is_connected()
    return is_open();
end

function discord_ipc.is_ready()
    return is_open() and state.ready == true;
end

function discord_ipc.get_last_activity_ack_nonce()
    return state.last_activity_ack_nonce;
end

function discord_ipc.get_last_activity_error()
    return state.last_activity_error_nonce, state.last_activity_error;
end

function discord_ipc.get_last_error()
    return state.last_error;
end

return discord_ipc;
