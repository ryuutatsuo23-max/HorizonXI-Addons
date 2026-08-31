from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT

from lupa import luajit21


def load_controller():
    lua = luajit21.LuaRuntime(unpack_returned_tuples=True)
    lua.globals().test_addon_path = ADDON.as_posix()
    lua.execute("package.path = test_addon_path .. '/?.lua;' .. package.path")
    connection = lua.eval("require('connection_patch')")
    module = lua.execute((ADDON / "native_ui.lua").read_text(encoding="utf-8"))
    state = {
        "mem": {},
        "writes": [],
        "clock": [],
        "loaded": set(),
        "session": 123,
    }
    signatures = {
        str(module.signatures.party): 0x401000,
        str(module.signatures.alliance): 0x401100,
        str(module.signatures.compass): 0x401200,
        str(connection.signature): 0x401300,
    }
    mem = state["mem"]
    mem[0x401000 + 0x19] = 0x402000
    mem[0x401000 + 0x23] = 0x402004
    mem[0x401100 + 0x01] = 0x402008
    mem[0x401100 + 0x07] = 0x40200C
    objects = {}
    for index, slot in enumerate((0x402000, 0x402004, 0x402008, 0x40200C)):
        first = 0x500000 + index * 0x100
        obj = 0x510000 + index * 0x100
        objects[slot] = obj
        mem[slot] = first
        mem[first + 8] = obj
        mem[obj + 0x69] = 1
        mem[obj + 0x6A] = 1
    mem[0x401200 + 0x24] = 1
    # Supported dispatcher fixture with synthetic, relocated CALL destinations.
    dispatcher = bytearray.fromhex(
        '83EC08568BF1578D4424088B4E0833FF5066897C240C66897C240E'
        '66897C241066897C2412E89692F1FF8B46142BC7741B48752A'
        '8B4C240A8B54240851528D4E44E82AFDFFFF5F5E83C408C3'
        '8B44240A8B4C240850518D4E1CE852FBFFFF5F5E83C408C3')
    for offset, target in ((0x25, 0x403000), (0x41, 0x404000), (0x59, 0x405000)):
        dispatcher[offset + 1:offset + 5] = (target - (0x401300 + offset + 5)).to_bytes(4, 'little', signed=True)
    for start, data in ((0x401300, dispatcher),
                        (0x404000, bytes.fromhex('83EC10A1000046005685C057894C24080F8460010000A100104600530530460000')),
                        (0x405000, bytes.fromhex('83EC0C5355568BF1576A008B46106A0085C06880808080'))):
        mem.update({start + i: value for i, value in enumerate(data)})

    io = lua.table()
    io.find = lambda pattern: signatures.get(str(pattern))
    io.in_module = lambda address, size: 0x400000 <= address and address + size <= 0x480000
    io.valid = lambda address, size, writable: address >= 0x400000
    io.read8 = lambda address: mem.get(address, 0)
    io.read_bytes = lambda address, size: bytes(mem.get(address + i, 0) for i in range(size))
    io.read32 = lambda address: (int.from_bytes(io.read_bytes(address, 4), 'little')
                                 if 0x401300 <= address < 0x401364 else mem.get(address, 0))

    def write8(address, value):
        mem[address] = value
        state["writes"].append((address, value))

    io.write8 = write8
    io.patch8 = write8
    io.finish_patch = lambda address: None
    io.loaded = lambda name: str(name).lower() in state["loaded"]
    io.session = lambda: state["session"]
    io.clock = lambda hidden: state["clock"].append(bool(hidden))
    messages = []
    controller = module.new(io, lambda message: messages.append(str(message)))
    controller.initialize(controller)
    return lua, module, controller, state, objects, messages


def config(lua, **values):
    result = lua.table(enabled=True, party=False, alliance1=False,
                       alliance2=False, target=False, compass=False, clock=False, connection=False)
    for key, value in values.items():
        result[key] = value
    return result


def call(controller, name, *args):
    return getattr(controller, name)(controller, *args)


def test_each_requested_control_is_available_in_synthetic_matching_client():
    _, module, controller, _, _, _ = load_controller()
    for control in module.controls.values():
        assert controller.rows[control.key].available is True


def test_unchecked_controls_do_not_write_and_party_hide_restores_owned_bytes():
    lua, _, controller, state, objects, _ = load_controller()
    call(controller, "tick", config(lua))
    assert state["writes"] == []
    party = objects[0x402000]
    call(controller, "tick", config(lua, party=True))
    assert state["mem"][party + 0x69] == 0
    assert state["mem"][party + 0x6A] == 0
    call(controller, "tick", config(lua))
    assert state["mem"][party + 0x69] == 1
    assert state["mem"][party + 0x6A] == 1


def test_preexisting_hidden_primitive_is_not_forced_visible_on_release():
    lua, _, controller, state, objects, _ = load_controller()
    target = objects[0x402004]
    state["mem"][target + 0x69] = 0
    state["mem"][target + 0x6A] = 0
    call(controller, "tick", config(lua, target=True))
    call(controller, "tick", config(lua))
    assert state["mem"][target + 0x69] == 0
    assert state["mem"][target + 0x6A] == 0


def test_compass_and_clock_apply_once_and_restore():
    lua, _, controller, state, _, _ = load_controller()
    address = 0x401200 + 0x24
    selected = config(lua, compass=True, clock=True)
    call(controller, "tick", selected)
    call(controller, "tick", selected)
    assert state["mem"][address] == 0
    assert state["clock"] == [True]
    call(controller, "tick", config(lua))
    assert state["mem"][address] == 1
    assert state["clock"] == [True, False]


def test_known_conflicts_release_owned_controls_and_block_further_writes():
    lua, _, controller, state, objects, _ = load_controller()
    selected = config(lua, party=True, compass=True, clock=True)
    call(controller, "tick", selected)
    state["loaded"].update(("hideparty", "fancycompass"))
    call(controller, "tick", selected)
    assert state["mem"][objects[0x402000] + 0x69] == 1
    assert state["mem"][0x401200 + 0x24] == 1
    assert state["clock"] == [True, False]
    assert str(controller.rows.party.status).startswith("Blocked")
    assert str(controller.rows.compass.status).startswith("Blocked")


def test_clock_session_changes_are_quiet_and_keep_restoration_safe():
    lua, _, controller, state, _, messages = load_controller()
    call(controller, "tick", config(lua, clock=True))
    state["session"] = 456
    call(controller, "tick", config(lua))
    assert state["clock"] == [True]
    assert messages == []

    # A zoning-like login gap must also be quiet, without queuing /clock on.
    for returning_session in (123, 456):
        lua, _, controller, state, _, messages = load_controller()
        selected = config(lua, clock=True)
        call(controller, "tick", selected)
        state["session"] = 0
        call(controller, "tick", selected)
        call(controller, "tick", selected)
        assert state["clock"] == [True]
        assert messages == []
        state["session"] = returning_session
        call(controller, "tick", selected)
        call(controller, "tick", selected)
        assert state["clock"] == [True, True]  # reapply once after login
        call(controller, "tick", config(lua))
        assert state["clock"] == [True, True, False]  # unchecking still restores
        assert messages == []


def test_all_four_frame_controls_are_independent():
    for key, slot in (("party", 0x402000), ("target", 0x402004),
                      ("alliance1", 0x402008), ("alliance2", 0x40200C)):
        lua, _, controller, state, objects, _ = load_controller()
        call(controller, "tick", config(lua, **{key: True}))
        for candidate, obj in objects.items():
            assert state["mem"][obj + 0x69] == (0 if candidate == slot else 1)
        call(controller, "restore")
        assert all(state["mem"][obj + 0x69] == 1 for obj in objects.values())


def test_replaced_objects_are_not_written_through_stale_cached_pointers():
    lua, _, controller, state, objects, _ = load_controller()
    call(controller, "tick", config(lua, party=True))
    old = objects[0x402000]
    replacement = 0x590000
    state["mem"][0x500000 + 8] = replacement
    state["mem"][replacement + 0x69] = 1
    state["mem"][replacement + 0x6A] = 1
    state["writes"].clear()
    call(controller, "tick", config(lua, party=True))
    call(controller, "restore")
    assert all(address not in (old + 0x69, old + 0x6A)
               for address, _ in state["writes"])
    assert state["mem"][replacement + 0x69] == 1


def test_missing_signatures_and_prepatched_compass_never_write():
    lua, _, controller, state, _, _ = load_controller()
    controller.io.find = lambda pattern: None
    call(controller, "recheck")
    call(controller, "tick", config(lua, party=True, compass=True))
    assert controller.rows.party.available is False
    assert controller.rows.compass.available is False
    assert state["writes"] == []

    lua, _, controller, state, _, _ = load_controller()
    state["mem"][0x401200 + 0x24] = 0
    call(controller, "recheck")
    call(controller, "tick", config(lua, compass=True))
    assert controller.rows.compass.available is False
    assert state["writes"] == []


def test_compass_changed_after_discovery_is_not_overwritten():
    lua, _, controller, state, _, _ = load_controller()
    state["mem"][0x401200 + 0x24] = 9
    call(controller, "tick", config(lua, compass=True))
    assert controller.rows.compass.fault is True
    assert state["mem"][0x401200 + 0x24] == 9
    assert state["writes"] == []


def test_invalid_primitive_bytes_disable_only_that_control():
    lua, _, controller, state, objects, _ = load_controller()
    state["mem"][objects[0x402000] + 0x69] = 77
    call(controller, "tick", config(lua, party=True, alliance1=True))
    assert controller.rows.party.fault is True
    assert state["mem"][objects[0x402000] + 0x69] == 77
    assert state["mem"][objects[0x402008] + 0x69] == 0


def test_restore_is_idempotent_and_does_not_replace_an_external_compass_change():
    lua, _, controller, state, _, _ = load_controller()
    call(controller, "tick", config(lua, compass=True, clock=True))
    state["mem"][0x401200 + 0x24] = 9
    state["writes"].clear()
    call(controller, "restore")
    call(controller, "restore")
    assert state["mem"][0x401200 + 0x24] == 9
    assert state["clock"] == [True, False]
    assert state["writes"] == []


def test_partial_frame_write_failure_restores_the_first_byte():
    lua, _, controller, state, objects, _ = load_controller()
    party = objects[0x402000]
    write = controller.io.write8

    def fail_second_hide(address, value):
        if address == party + 0x6A and value == 0:
            raise RuntimeError("synthetic write failure")
        write(address, value)

    controller.io.write8 = fail_second_hide
    call(controller, "tick", config(lua, party=True))
    assert controller.rows.party.fault is True
    assert state["mem"][party + 0x69] == 1
    assert state["mem"][party + 0x6A] == 1


def test_failed_conflict_check_blocks_hiding():
    lua, _, controller, state, _, _ = load_controller()

    def failed_lookup(name):
        raise RuntimeError("synthetic missing AddonManager")

    controller.io.loaded = failed_lookup
    call(controller, "tick", config(lua, party=True, clock=True))
    assert state["writes"] == []
    assert state["clock"] == []
    assert str(controller.rows.party.status).startswith("Blocked")


def test_connection_changes_only_one_opcode_once_and_restores_on_pause():
    lua, _, controller, state, _, _ = load_controller()
    before = state['mem'].copy()
    call(controller, 'tick', config(lua, connection=True))
    call(controller, 'tick', config(lua, connection=True))
    assert state['writes'] == [(0x401332, 0xEB)]
    assert all(value == state['mem'][address] for address, value in before.items() if address != 0x401332)
    call(controller, 'tick', config(lua, enabled=False, connection=True))
    call(controller, 'restore')
    assert state['writes'] == [(0x401332, 0xEB), (0x401332, 0x75)]
    assert state['mem'] == before


def test_connection_rejects_missing_prepatched_modified_code_and_bad_call_targets():
    for address, value in ((0x401332, 0xEB), (0x401333, 0x29),
                           (0x401300, 0x90), (0x404000, 0x90), (0x405000, 0x90),
                           (0x401345, 0x7F)):
        lua, _, controller, state, _, _ = load_controller()
        state['mem'][address] = value
        call(controller, 'recheck')
        assert controller.rows.connection.available is False
        call(controller, 'tick', config(lua, connection=True))
        assert state['writes'] == []
    lua, _, controller, state, _, _ = load_controller()
    controller.io.find = lambda pattern: None  # adapter returns nil for missing OR nonunique scans
    call(controller, 'recheck')
    call(controller, 'tick', config(lua, connection=True))
    assert controller.rows.connection.available is False
    assert state['writes'] == []


def test_connection_foreign_change_before_apply_is_not_overwritten():
    lua, _, controller, state, _, _ = load_controller()
    state['mem'][0x401333] = 0x20
    call(controller, 'tick', config(lua, connection=True))
    assert state['writes'] == []
    assert controller.rows.connection.fault is True
    assert not controller.rows.connection.owned


def test_connection_foreign_change_while_owned_blocks_restore_until_context_returns():
    for changed in (0x401332, 0x401333, 0x401300):
        lua, _, controller, state, _, messages = load_controller()
        call(controller, 'tick', config(lua, connection=True))
        own_value = state['mem'][changed]
        state['mem'][changed] = 0x90
        state['writes'].clear()
        call(controller, 'tick', config(lua, connection=True))
        assert controller.rows.connection.fault is True
        assert controller.rows.connection.owned is True
        assert call(controller, 'restore') is False
        assert call(controller, 'recheck') is False
        assert state['writes'] == []
        assert any('restoring connection' in m for m in messages)
        state['mem'][changed] = own_value
        assert call(controller, 'restore') is True
        assert state['mem'][0x401332] == 0x75


def test_connection_failed_write_after_mutation_is_recovered():
    lua, _, controller, state, _, _ = load_controller()
    write = controller.io.patch8

    def fail_after_write(address, value):
        write(address, value)
        if value == 0xEB:
            raise RuntimeError('synthetic protection/cache failure after byte changed')

    controller.io.patch8 = fail_after_write
    call(controller, 'tick', config(lua, connection=True))
    assert state['mem'][0x401332] == 0x75
    assert controller.rows.connection.fault is True
    assert controller.rows.connection.owned is False


def test_connection_failed_restore_retains_ownership_and_can_retry():
    lua, _, controller, state, _, _ = load_controller()
    call(controller, 'tick', config(lua, connection=True))
    write = controller.io.patch8

    def fail_restore(address, value):
        raise RuntimeError('synthetic unavailable writable page')

    controller.io.patch8 = fail_restore
    assert call(controller, 'restore') is False
    assert controller.rows.connection.owned is True
    assert state['mem'][0x401332] == 0xEB
    controller.io.patch8 = write
    assert call(controller, 'restore') is True
    assert state['mem'][0x401332] == 0x75


def test_connection_restores_at_logout_and_ignores_unrelated_hider_conflicts():
    lua, _, controller, state, _, _ = load_controller()
    state['loaded'].update(('hideparty', 'fancycompass'))
    call(controller, 'tick', config(lua, connection=True))
    assert state['mem'][0x401332] == 0xEB
    state['session'] = 0
    call(controller, 'tick', config(lua, connection=True))
    assert state['mem'][0x401332] == 0x75


def load_host():
    lua, module, controller, state, objects, messages = load_controller()
    lua.globals().test_native = module
    lua.globals().test_io = controller.io
    lua.execute("""
        addon = {};
        T = function(t) return t end;
        ImGuiCond_FirstUseEver = 1;
        ImGuiWindowFlags_NoSavedSettings = 256;
        ImGuiHoveredFlags_AllowWhenDisabled = 1024;
        events = {}; saved = 0; begins = 0; ends = 0; clicks = {};
        tooltips = {}; texts = {}; disabled = false;
        package.preload.common = function() return {} end;
        package.preload.native_ui = function() return test_native end;
        package.preload.memory_io = function() return test_io end;
        package.preload.settings = function() return {
            load = function(defaults) test_config = defaults; return defaults end,
            save = function() saved = saved + 1 end,
            register = function(_, _, callback) settings_callback = callback end,
        } end;
        local noop = function() end;
        package.preload.imgui = function() return {
            SetNextWindowSize = noop,
            Begin = function(_, opened)
                begins = begins + 1;
                if close_next then opened[1] = false; close_next = false end;
                return true;
            end,
            End = function() ends = ends + 1 end,
            TextWrapped = function(text) texts[#texts + 1] = text end,
            TextDisabled = noop, Separator = noop,
            BeginDisabled = function(value) disabled = value end,
            EndDisabled = function() disabled = false end, SameLine = noop,
            IsItemHovered = function(flags)
                return hovered == last_item and (not last_disabled
                    or flags == ImGuiHoveredFlags_AllowWhenDisabled);
            end,
            SetTooltip = function(text) tooltips[#tooltips + 1] = text end,
            Checkbox = function(label, value)
                last_item = label; last_disabled = disabled;
                if disabled then return false end;
                if clicks[label] ~= nil then
                    value[1] = clicks[label]; clicks[label] = nil; return true;
                end
                return false;
            end,
            Button = function() return false end,
        } end;
        ashita = {events = {register = function(kind, _, callback) events[kind] = callback end}};
        print = noop;
    """)
    lua.execute((ADDON / "HXIUIBegone.lua").read_text(encoding="utf-8"))
    return lua, state, objects


def test_host_draw_checkbox_save_and_unload_restore():
    lua, state, objects = load_host()
    lua.globals().events.load()
    lua.globals().events.d3d_present()
    assert state["writes"] == []
    assert lua.globals().begins == lua.globals().ends == 0
    event = lua.table(command="/hxiuibegone", blocked=False)
    lua.globals().events.command(event)
    assert event.blocked is True
    lua.globals().clicks["Hide party list"] = True
    lua.globals().events.d3d_present()
    assert state["mem"][objects[0x402000] + 0x69] == 0
    assert lua.globals().test_config.party is True
    assert lua.globals().saved == 1
    assert lua.globals().begins == lua.globals().ends == 1
    lua.globals().close_next = True
    lua.globals().events.d3d_present()
    lua.globals().events.d3d_present()
    assert lua.globals().begins == lua.globals().ends == 2
    assert state["mem"][objects[0x402000] + 0x69] == 0  # hiding continues while closed
    lua.globals().events.command(lua.table(command="/hxiui", blocked=False))
    lua.globals().events.d3d_present()
    assert lua.globals().begins == lua.globals().ends == 3
    lua.globals().events.unload()
    assert state["mem"][objects[0x402000] + 0x69] == 1
    assert lua.globals().test_config.party is True  # reload retains selection


def test_host_recovery_clears_selections_and_leaves_unrelated_commands_alone():
    lua, state, objects = load_host()
    event = lua.table(command="/hxiui hide party on", blocked=False)
    lua.globals().events.command(event)
    assert event.blocked is True
    assert state["mem"][objects[0x402000] + 0x69] == 0
    unrelated = lua.table(command="/echo hello", blocked=False)
    lua.globals().events.command(unrelated)
    assert unrelated.blocked is False
    lua.globals().events.command(lua.table(command="/hxiui restore", blocked=False))
    assert state["mem"][objects[0x402000] + 0x69] == 1
    assert lua.globals().test_config.party is False
    assert lua.globals().test_config.enabled is False


def test_host_toggle_pauses_and_resumes_saved_hides_without_opening_settings():
    for command in ("/hxiuibegone toggle", "/hxiui toggle"):
        lua, state, objects = load_host()
        selected = config(lua, party=True, alliance2=True, compass=True,
                          clock=True, connection=True)
        lua.globals().settings_callback(selected)
        lua.globals().events.load()
        lua.globals().events.d3d_present()
        original = dict(selected.items())
        assert lua.globals().begins == 0
        for enabled in (False, True):
            event = lua.table(command=command, blocked=False)
            lua.globals().events.command(event)
            assert event.blocked is True
            assert dict(selected.items()) == {**original, "enabled": enabled}
            assert state["mem"][objects[0x402000] + 0x69] == (0 if enabled else 1)
            assert state["mem"][objects[0x40200C] + 0x69] == (0 if enabled else 1)
            assert state["mem"][0x401224] == (0 if enabled else 1)
            assert state["mem"][0x401332] == (0xEB if enabled else 0x75)
            writes = list(state["writes"])
            lua.globals().events.d3d_present()
            assert state["writes"] == writes  # no redundant patch writes
            assert lua.globals().begins == 0
        assert state["clock"] == [True, False, True]
        assert lua.globals().saved == 2
        lua.globals().events.command(lua.table(command=command + " extra", blocked=False))
        assert dict(selected.items()) == original
        assert lua.globals().saved == 2
        # Toggling must leave an already-open settings window open too.
        lua.globals().events.command(lua.table(command="/hxiuibegone", blocked=False))
        lua.globals().events.d3d_present()
        lua.globals().events.command(lua.table(command=command, blocked=False))
        lua.globals().events.d3d_present()
        assert lua.globals().begins == 2
        lua.globals().events.unload()
        assert selected.enabled is False
        assert selected.party is True


def test_host_settings_change_releases_old_controls_before_new_settings_apply():
    lua, state, objects = load_host()
    lua.globals().events.command(lua.table(command="/hxiui hide target on", blocked=False))
    assert state["mem"][objects[0x402004] + 0x69] == 0
    lua.globals().settings_callback(config(lua, alliance2=True))
    assert state["mem"][objects[0x402004] + 0x69] == 1
    lua.globals().events.d3d_present()
    assert state["mem"][objects[0x40200C] + 0x69] == 0


def test_host_connection_checkbox_is_default_off_saves_and_restores_on_unload():
    lua, state, _ = load_host()
    assert lua.globals().test_config.connection is False
    lua.globals().events.d3d_present()
    assert state['writes'] == []
    lua.globals().events.command(lua.table(command="/hxiuibegone", blocked=False))
    lua.globals().clicks['Hide connection info (arrows, S/R, %)'] = True
    lua.globals().events.d3d_present()
    assert lua.globals().test_config.connection is True
    assert state['mem'][0x401332] == 0xEB
    assert lua.globals().saved == 1
    lua.globals().events.unload()
    assert state['mem'][0x401332] == 0x75


def test_host_legacy_settings_keep_other_hides_and_connection_off():
    lua, state, objects = load_host()
    lua.globals().settings_callback(lua.table(enabled=True, party=True, compass=True))
    lua.globals().events.d3d_present()
    assert lua.globals().test_config.connection is False
    assert lua.globals().begins == 0  # saved hides apply without opening settings
    assert state['mem'][0x401332] == 0x75
    assert state['mem'][objects[0x402000] + 0x69] == 0
    assert state['mem'][0x401224] == 0


def load_mocked_windows_adapter():
    # Exercise the real adapter transaction using fake Windows/Ashita APIs;
    # no DLL is loaded and no operating-system memory is accessed.
    lua = luajit21.LuaRuntime(unpack_returned_tuples=True)
    lua.execute('''
        page = 0x20; memory_byte = 0x75; flushes = 0;
        fail_protect = false; fail_flush = false; protections = {};
        local kernel = {
            VirtualQuery = function(address, info)
                info[0] = {Protect = page, BaseAddress = 0x400000,
                    RegionSize = 0x10000, State = 0x1000};
                return 28;
            end,
            GetCurrentProcess = function() return -1 end,
            FlushInstructionCache = function()
                flushes = flushes + 1;
                return fail_flush and 0 or 1;
            end,
        };
        package.preload.ffi = function() return {
            cdef = function() end, load = function() return kernel end,
            new = function() return {[0] = {}} end,
            sizeof = function(value) return value == 'void*' and 4 or 28 end,
            cast = function(_, value) return value end,
        } end;
        ashita = {memory = {
            read_uint8 = function() return memory_byte end,
            write_uint8 = function(_, value) memory_byte = value end,
            unprotect = function()
                local previous = page; page = 0x40; return true, previous;
            end,
            protect = function(_, _, previous)
                protections[#protections + 1] = previous;
                if fail_protect then return false end;
                page = previous; return true;
            end,
        }};
    ''')
    adapter = lua.execute((ADDON / 'memory_io.lua').read_text(encoding='utf-8'))
    return lua, adapter


def test_adapter_protection_failure_retains_true_original_for_retry():
    lua, adapter = load_mocked_windows_adapter()
    lua.globals().fail_protect = True
    ok, _ = lua.eval('pcall')(adapter.patch8, 0x401332, 0xEB)
    assert ok is False
    assert lua.globals().memory_byte == 0xEB
    assert lua.globals().page == 0x40
    lua.globals().fail_protect = False
    adapter.patch8(0x401332, 0x75)
    assert lua.globals().page == 0x20
    assert lua.globals().memory_byte == 0x75
    assert list(lua.globals().protections.values()) == [0x20, 0x20, 0x20]
    assert lua.globals().flushes == 2


def test_adapter_flush_failure_still_restores_page_protection():
    lua, adapter = load_mocked_windows_adapter()
    lua.globals().fail_flush = True
    ok, _ = lua.eval('pcall')(adapter.patch8, 0x401332, 0xEB)
    assert ok is False
    assert lua.globals().memory_byte == 0xEB  # caller retains byte-restoration ownership
    assert lua.globals().page == 0x20
    lua.globals().fail_flush = False
    adapter.patch8(0x401332, 0x75)
    assert lua.globals().memory_byte == 0x75
    assert lua.globals().page == 0x20


if __name__ == "__main__":
    tests = [(name, test) for name, test in list(globals().items())
             if name.startswith("test_") and callable(test)]
    for name, test in tests:
        test()
        print("PASS", name)
    print(f"{len(tests)} tests passed (synthetic LuaJIT runtime; no game attachment).")
