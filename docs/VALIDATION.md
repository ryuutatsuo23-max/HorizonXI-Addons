# Validation — v0.2.5

## Target box hiding while keeping the target arrow

Ashita's `targetwindow_t` layout identifies four box/icon coordinates at
offsets `0x4C` through `0x52`, while the main-target and sub-target arrow
coordinates are separate fields at `0xBC` through `0xC2`. The target option now
moves only the four box/icon coordinates off-screen. It leaves the target
primitive visible and does not write the arrow coordinates, target state,
entity data, or draw code.

On uncheck, pause, reset, settings replacement, logout, or unload, the addon
restores only coordinates still carrying its off-screen value and only through
the currently authoritative target object. A changed or stale object is not
written. This narrower behavior still needs an in-game check with a normal
target, sub-target selection, target death/reraise, lock-on, and unload.

All **37 offline tests** pass. The new tests cover independent target-box
coordinates, untouched arrow coordinates and primitive visibility, idempotent
per-frame behavior, restoration, partial-write recovery, settings replacement,
and validated 16-bit adapter access.

## Fishing compatibility, cast bar, and reset confirmation

The author reported that hiding the native party list also hid the hooked-fish
HP bar. The party option now releases only its own hide while either the local
or server player status is one of the known fishing states, then reapplies it
after fishing ends. Other selected controls stay hidden. If the player entity
cannot be read, the party option fails open and reports a blocked state rather
than risk suppressing the fish HP bar.

The cast-bar option resolves the native `menu    casttime` record
with a complete 44-byte descriptor signature whose relocated object-slot
pointer is the only wildcard. That signature has exactly one match in the
offline supported client build, at descriptor VA `0x10370A90`; its slot is RVA
`0x575F0C`. There is no fixed-address fallback. The control uses the existing
primitive ownership and restoration path and waits without writing when the
cast-bar object does not exist. The author confirmed that it hides the cast bar
in game; a sub-second flash can occur before the next frame applies the hide.

Clicking **Reset choices** now opens a modal with **Reset** and **Cancel**.
Nothing changes or saves until Reset is selected. The explicit
`/hxiuibegone restore` command remains immediate.

All **37 offline tests** pass. New coverage checks the fishing pause/reapply
lifecycle, fail-open behavior, local and server fishing status fields, cast-bar
independence and absence, and both reset-dialog outcomes. Windows calls and
game memory remain simulated. The author subsequently confirmed the fishing
and cast-bar results; the reset dialog appearance still needs an in-game check.

## Quick toggle and hover hints

Added `/hxiuibegone toggle` (also `/hxiui toggle`) using the existing pause/resume
path. It changes only the saved enabled state, preserves all individual choices,
and leaves the settings window open or closed as it was.

Checkbox hints appear on hover, including disabled options. The clock caveat has
moved from a permanent line to its hint; the target label still warns about the
arrow. Signature checks, memory operations, restoration, and the quiet zoning
fix are unchanged.

All 37 offline tests pass, including both toggle aliases, mixed saved choices,
pause/resume writes and restoration, closed/open settings, and invalid arguments.
Hover-only hints and disabled checkbox hints were checked with simulated ImGui
callbacks. Actual tooltip appearance still needs an in-game check.

## Clock message fix

The author reported a repeated clock-restoration warning during zoning/loading
with clock hiding enabled. Version 0.2.2 removes that informational notification
when the session changes. The same-session restoration check, `/clock off` and
`/clock on` commands, and real error reporting are unchanged. Manual `/clock`
commands and their chat output are not intercepted or filtered.

The existing clock regression now covers a direct character change, a temporary
login gap, return to the same or a different character, one-time reapplication,
and restoration when unchecked, all without the removed message. All 28 offline
tests pass. The fix still needs an in-game zoning check.

## Reported in game

The author tested the addon on their HorizonXI / Ashita v4 setup and reported:

| Feature | Result |
| --- | --- |
| Party list | Hiding works; its fishing pause was confirmed to restore the hooked-fish HP bar. |
| Compass / radar | Hiding works. |
| Clock | Hiding works. |
| Connection info | Hides and returns when unchecked. |
| Target box | The earlier whole-primitive hide removed the arrow. The new box-only behavior needs an in-game check. |
| Cast bar | Hiding works; the bar can flash for less than a second before disappearing. |
| Alliance 1 and 2 | Not tested. |
| Settings window | Author supplied the v0.2.1 preview shown in the README. |

These are author-reported results, not comprehensive compatibility claims.
The screenshot confirms the displayed layout; it does not prove every command
or lifecycle path. Mail/friend notifications, zoning, character changes,
unload/reload combinations, and other addons still need broader testing.

## Offline checks

All **37 tests** pass against the Lua modules using LuaJIT through Lupa.
They cover independent selections, default settings, command handling, a closed
window at startup, opening/closing settings, saved hides while settings are
closed, restoration, missing signatures, conflicts, changed code, partial write
failures, and retrying failed protection restoration. Windows calls and memory
are simulated. All four Lua files also pass syntax checks.

Earlier static analysis verified the connection branch against an offline copy
of the supported client. The production Lua patch changed one byte in a test
buffer and restored it exactly. No client executable is bundled or required for
the public test suite. There are no unconditional fixed-address fallbacks.

## Safety and limitations

- Unchecked panels remain under the game's control; they are not forced visible.
- The addon restores changes it owns and refuses to overwrite unexpected code.
- Clock restoration uses `/clock on`; the previous clock preference is unknown.
- Nothing here establishes compatibility with every FFXI client build.
- No game files, save files, network packets, or other addons are modified.
- Temporary changes to the running client's UI memory are part of how hiding
  works. Runtime checks cannot guarantee compatibility with every other patch.

The historical research documents are retained for source context. Their
pre-implementation statements describe the earlier research stage; this file
records the release's current validation status.
