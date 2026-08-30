# Source provenance

HXIUIBegone 0.2.0 adds a connection-display patch independently derived from
offline analysis of the user's installed FFXiMain.dll, SHA-256
`bda769e226d71a43335c105fd6f72ed19af0a3d815a079b367356de0731a0d9a`.
No game binary or unpacked code section is distributed with the addon.

- [atom0s's POL1 description](https://atom0s.wordpress.com/2015/01/02/unpacking-ffxi-related-files/)
  enabled offline decoding for analysis, without executing or modifying the DLL.
- [Windower/Fenestra's menu table](https://github.com/Windower/Fenestra/blob/e5bfb6442f49bdb4d31859bff6218bbeb1bea620/core/src/hooks/ffximain.cpp#L82-L90)
  supplied the layout used to identify the native `netstat` object during research.
  No Windower runtime or source module is included as an addon dependency.
- See [the detailed research](NATIVE-UI-RESEARCH-2026-08-30.md) for the specific
  control-flow evidence. The new Lua module requires a unique full dispatcher
  match, checks call targets and callee prefixes, retains a code snapshot, and
  changes only the conditional branch opcode, restoring only matching owned code.

HXIUIBegone 0.1.0 was developed against these source snapshots:

- Ashita `hideparty` v1.1: party/alliance/target signatures, pointer layout,
  and primitive visibility byte layout. Repository:
  <https://github.com/AshitaXI/Ashita-v4beta/blob/main/addons/hideparty/hideparty.lua>.
  The inspected local copy is Copyright (c) 2025 Ashita Development Team and
  licensed under GPL version 3 or later.
  Its SHA-256 is
  `02e10b9e4309f9f5870ba060437476912c90f7d55ee86cb752c589a9348501eb`.
- CowXIUI commit `3f4e0731b9ef0e3d1a40dc7665f0750f935680f8`:
  evidence that the main party, two alliance panels, and target can be exposed
  as individual settings, and that target also controls the overhead arrow.
  <https://github.com/cowrevenge/CowXIUI/blob/3f4e0731b9ef0e3d1a40dc7665f0750f935680f8/modules/hideparty.lua>
- FancyCompass commit `71c5566e9f7f72880ef5af036ac0ca929caf33cc`:
  compass signature/offset evidence and the `/clock off` / `/clock on`
  behavior.
  <https://github.com/ariel-logos/FancyCompass/blob/71c5566e9f7f72880ef5af036ac0ca929caf33cc/fancycompass.lua>

HXIUIBegone does not include FancyCompass's replacement compass renderer or
CowXIUI. Its ownership checks, fail-closed validation, conflict handling,
settings panel, command interface, and restoration flow were written for this
addon.

Because the party-control implementation is adapted from GPL-covered Ashita
code, this addon is distributed under GPL version 3 or later. See `LICENSE`.
