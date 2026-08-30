# Native connection display research - 2026-08-30

> Historical research record from before implementation. Connection hiding is
> now implemented and reported working. See [current validation](VALIDATION.md).
> The local source caches and analysis artifacts below are not distributed.

**Follow-up:** [expanded offline research](NATIVE-UI-RESEARCH-2026-08-30.md)
has now identified the native `netstat` menu and a dedicated connection-drawing
branch in this exact client. A selective hiding candidate is documented but
remains unapplied and untested in game. The record below preserves the earlier
source-only findings.

**Initial source-only result: no verified network-meter-specific hiding control found.** Ashita v4
does provide C++ plugin callbacks that can block draw calls. That establishes a
possible mechanism, not which calls draw the connection arrows, percentage, or
S/R counters. No network checkbox or runtime patch was added.

The requested scope is an independent, reversible checkbox in HXIUIBegone.
The existing clock, compass, and party controls must keep working. Target and
alliance controls stay as they are; the user leaves those unchecked.

## Evidence and rejected shortcuts

| Source | Confirmed behavior | Relevance to this request |
| --- | --- | --- |
| [Ashita example plugin, lines 655-757](https://github.com/AshitaXI/exampleplugin/blob/b67726f02fb55e6d2aef94a402ef6875384116eb/src/exampleplugin.cpp#L655-L757) | Four Direct3D primitive callbacks return a boolean to block the call when `UseDirect3D` is enabled. | Concrete rendering-level capability. No menu name or network-meter identifier is passed to these callbacks. A reliable classifier or earlier native render hook is still needed. |
| [Ashita hideui, lines 25-80](https://github.com/AshitaXI/Ashita-v4beta/blob/2e4b9c86de538ecfedabab918537c550d6378aaa/addons/hideui/hideui.lua#L25-L80) | Sets visibility on Ashita's font, primitive, and GUI managers. | Hides custom overlays, not an independent native connection display. |
| [Ashita screenshot plugin, lines 145-179](https://github.com/AshitaXI/screenshot-src/blob/2d8812fd98f652f457e273cf74bad31a4bcc3ec9/src/screenshot.cpp#L145-L179) | Its hide option uses those same three Ashita managers. | Does not supply the missing native visibility control. |
| [Thorny tHotBar callbacks](https://github.com/ThornyFFXI/tHotBar/blob/11f7f05ecac490cc2bf5c25c0180b83bf4fb0ea7/callbacks.lua#L1-L113) | Reads the active menu, event state, expanded chat, and general interface-hidden state to decide whether to render its own bar. | The interface-hidden read is not a dedicated network-meter flag. Do not turn this observation into a write. tCrossBar uses the same kind of checks. |
| [Thorny openmenus](https://github.com/ThornyFFXI/openmenus/blob/eca3403d1a6e5f02ee3234038b2768f42a290feb/openmenus.lua) | Resolves and calls specific native ability/magic menu-opening functions, crediting atom0s. | Useful evidence of native menu integration, but no general hide API or connection display entry. |
| [atom0s XiEvents opcode 0x67](https://github.com/atom0s/XiEvents/blob/3ccb5374e1cd5c1610dead0fa4288f527b29290d/OpCodes/0x0067.md) and [0x68](https://github.com/atom0s/XiEvents/blob/3ccb5374e1cd5c1610dead0fa4288f527b29290d/OpCodes/0x0068.md) | Documents whole-HUD cutscene transitions, including event-message mode and CompassDrow. Documentation explicitly targets the February 2022 retail client. | Too broad for this checkbox and not verified against this Horizon installation. Do not invoke cutscene handlers to hide one display. |
| [atom0s XiEvents opcode 0xB4](https://github.com/atom0s/XiEvents/blob/3ccb5374e1cd5c1610dead0fa4288f527b29290d/OpCodes/0x00B4.md) | Documents native menu creation/destruction for named windows such as targetwi, casttime, and eventtim. | A useful native-menu research lead, but no identified connection-meter window. It also does not prove target-box/arrow separation. |

FancyChat was not used as a hiding implementation: its previously inspected
NetStatObj path reads connection state for R0 warnings. Writing that state would
not be an evidence-based rendering change.

## Coverage and limits

Inventoried public repositories under atom0s, AshitaXI, and ThornyFFXI through
GitHub's API. Downloaded selected text/source files from the 20 commit-pinned
snapshots below and searched the resulting 1,764 files. Searches included
network/netstat/connection display terms, native menu references, visibility
handling, memory patches, and Direct3D draw callbacks. Read the relevant matches
in context. The count is files searched, not files reviewed line by line.

GitHub issue searches and the Firecrawl developer index did not provide a
meter-specific implementation. The index mostly returned general documentation
or the already-known community question. Public gists were inventoried too:
three for atom0s and none for ThornyFFXI, with no identified meter solution.

This is not an exhaustive history/branch/fork audit. Submodule contents were not
recursively fetched. Compiled-only plugin internals, private repositories, and
Discord conversations were not inspected. No claim is made that no solution
exists elsewhere. Ashita release repositories and SDK headers do not expose all
core internals or the game's native renderer source.

| Repository | Commit | Text/source files searched |
| --- | --- | ---: |
| AshitaXI/Ashita-v3 | `874285771a996c4205e3b8692d9e25965ad35628` | 423 |
| AshitaXI/Ashita-v4beta | `2e4b9c86de538ecfedabab918537c550d6378aaa` | 269 |
| AshitaXI/Documentation | `95662d9a8ec1bf4a186a66d350b60ca517706fd9` | 15 |
| AshitaXI/exampleplugin | `b67726f02fb55e6d2aef94a402ef6875384116eb` | 7 |
| AshitaXI/screenshot-src | `2d8812fd98f652f457e273cf74bad31a4bcc3ec9` | 9 |
| AshitaXI/sdktest | `ac614d51223f24f90f0f87ff143555cf4649c711` | 25 |
| AshitaXI/thirdparty-src | `9d6d77493198b40c637a03f973b936c840c60a6e` | 13 |
| atom0s/XiEvents | `3ccb5374e1cd5c1610dead0fa4288f527b29290d` | 225 |
| atom0s/XiPackets | `ebe2216a991ff88254ad600cc5bae8e3d9e80306` | 361 |
| ThornyFFXI/Ashita-v4beta | `8cf24887d104eeb02284e0050f9ac9ccceb24a8c` | 183 |
| ThornyFFXI/common | `53b86774a9c15b2f9976cb469640e4058176df14` | 8 |
| ThornyFFXI/Crossbar | `4f3e9bd55c1429c19591737a5d7581dbdea5c672` | 65 |
| ThornyFFXI/HitPoints | `dafc7312c89a350986a673e3a0a120710f517d12` | 8 |
| ThornyFFXI/MiscAshita3 | `bc3a0a00b1a547af5afca792c1f5d1863cf0f76a` | 14 |
| ThornyFFXI/MiscAshita4 | `71a9474c2c8a54de2b4668be88d59e58b9880058` | 25 |
| ThornyFFXI/openmenus | `eca3403d1a6e5f02ee3234038b2768f42a290feb` | 2 |
| ThornyFFXI/statustimers | `86407b8a6e353b335e0de0a2540fe4254f27ec63` | 13 |
| ThornyFFXI/tCrossBar | `e03759a24aeba926acec65c135a57a676c7d4976` | 32 |
| ThornyFFXI/tHotBar | `11f7f05ecac490cc2bf5c25c0180b83bf4fb0ea7` | 32 |
| ThornyFFXI/tTimers | `30bd5c7ef2e0ffde28c6dab051b2d977e7e30b4a` | 35 |

Source caches and per-repository manifests are outside the addon in
`release-verification/HXIUIBegone/network-meter-audit/`. They are research inputs,
not addon dependencies or release contents. No downloaded code was executed.

## Smallest justified next step

Identify the native connection-display object or drawing routine before adding
a checkbox. A verified native render flag/signature would fit the existing Lua
controller architecture. If the only workable method is Direct3D filtering, a
C++ companion plugin is a candidate, not yet a justified dependency: the checked
SDK examples prove those hooks for C++, not a ready-made Lua meter-hiding API.

A precise question for an Ashita maintainer, prepared here but **not sent**:

> Is there a known Ashita v4 signature, native class/window identifier, or draw
> routine for FFXI's top-right connection display (green arrows, percentage, and
> S/R counters)? We need reversible rendering-only suppression, independent of
> party/target UI, without changing network state. Does it share rendering with
> the mail notification or other indicators?

If no existing mapping is available, a separate bounded renderer investigation
would need to establish that identity first. A draw-call position or shared font
texture alone is insufficient proof: blocking it could remove unrelated text or
indicators. Verify arrows, S/R text, percentage, mail, and restoration separately.

This research did not attach to the game, read or write live memory, inject
packets, alter installed files or settings, rebuild the release ZIP, or change
addon Lua. Validation was source inspection; no gameplay success is claimed.
