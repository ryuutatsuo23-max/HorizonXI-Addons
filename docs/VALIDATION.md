# Validation — v0.2.3

## Quick toggle and hover hints

Added `/hxiuibegone toggle` (also `/hxiui toggle`) using the existing pause/resume
path. It changes only the saved enabled state, preserves all individual choices,
and leaves the settings window open or closed as it was.

Checkbox hints appear on hover, including disabled options. The clock caveat has
moved from a permanent line to its hint; the target label still warns about the
arrow. Signature checks, memory operations, restoration, and the quiet zoning
fix are unchanged.

All 29 offline tests pass, including both toggle aliases, mixed saved choices,
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
| Party list | Hiding works. |
| Compass / radar | Hiding works. |
| Clock | Hiding works. |
| Connection info | Hides and returns when unchecked. |
| Target box | Hiding also removes the overhead arrow; this is a known limitation. |
| Alliance 1 and 2 | Not tested. |
| Settings window | Author supplied the v0.2.1 preview shown in the README. |

These are author-reported results, not comprehensive compatibility claims.
The screenshot confirms the displayed layout; it does not prove every command
or lifecycle path. Mail/friend notifications, zoning, character changes,
unload/reload combinations, and other addons still need broader testing.

## Offline checks

All **29 tests** pass against the Lua modules using LuaJIT through Lupa.
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
