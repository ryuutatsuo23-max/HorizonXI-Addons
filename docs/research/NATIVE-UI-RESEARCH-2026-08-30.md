# Expanded native UI research - 2026-08-30

> Historical research record from before implementation. Connection hiding is
> now implemented and reported working. See [current validation](../VALIDATION.md).
> The local analysis tools and artifacts mentioned below are not distributed
> with this repository or required to use the addon.

**A concrete connection-display hiding candidate was found by static analysis
of the user's exact on-disk client. It has not been applied or tested in game.**
This advances the earlier source-only investigation: we now have a named native
menu, its object slot, its drawing callback, and an independently reachable
connection-display branch. A companion C++ plugin is no longer the first route
to investigate; a guarded Lua code-byte patch could fit HXIUIBegone's existing
compass-patch architecture.

Only research notes and offline analysis tools were changed. HXIUIBegone's Lua,
installed addons, settings, game files, and original release ZIP are untouched.
No process attachment, live memory reads/writes, packet injection, game input,
or maintainer messages were performed. This document is not live validation.

## What unlocked the investigation

[atom0s's POL1 article](https://atom0s.wordpress.com/2015/01/02/unpacking-ffxi-related-files/)
describes the client's packed code section. The installed DLL has a zero-length
on-disk `.text` section and a `POL1` section. Its entrypoint's decompression
instructions match the documented format. An independent bounded Python decoder
reconstructed 3,298,350 code bytes in the research process, exactly matching the
declared `.text` virtual size. No executable was loaded and no unpacked DLL was
written. This explains the earlier zero matches in the packed file; it was not
evidence that the working UI signatures were wrong.

[Windower/Fenestra's native-menu lookup](https://github.com/Windower/Fenestra/blob/e5bfb6442f49bdb4d31859bff6218bbeb1bea620/core/src/hooks/ffximain.cpp#L82-L90)
documents a 0x2C-byte menu record with 8-byte type/name fields and an object-slot
pointer at +0x20. Its lookup signature resolves a table in this client. Walking
that static table yields 366 entries. As a cross-check, its `partywin` and
`targetwi` slots exactly match those resolved by HXIUIBegone's existing party
signature. The table also contains `netstat `.

The old atom0s `xiunpack` repository linked by the article returns HTTP 404.
No downloaded unpacker executable or third-party script was run.

## Exact-build connection display evidence

DLL SHA-256:
`bda769e226d71a43335c105fd6f72ed19af0a3d815a079b367356de0731a0d9a`.
All addresses below are **RVAs relative to the preferred image base**, not live
pointers. They must not become unconditional hardcoded addon offsets.

| Item | Static finding |
| --- | --- |
| Native menu | `menu    netstat `; descriptor RVA `0x372140` |
| Object slot | RVA `0x62ED24`; named directly by the menu descriptor |
| Construction | Initializes a 0x7C-byte object and assigns vtable RVA `0x3361D8` |
| Drawing callback | Vtable +0x10 points to RVA `0x1FF8A0` |
| Connection branch | Mode field at object +0x14 equal to 1 calls RVA `0x1FF610` |
| Other branch | Mode 0 calls RVA `0x1FF450`; notification-like icons/counts, exact meanings not fully established |
| Network data | Connection branch reads three values through simple getters from the same network-status data object previously identified by the public R0 reader signature |
| Rendering | Formats numbers, resolves two label strings, draws sprites and a third numeric value; positions and data flow are consistent with the S/R and percentage display |
| Primitive gate | Generic menu rendering checks primitive +0x6A before calling its attached object's vtable +0x10 |

The connection branch's three value getters only return data; they do not
transmit or receive packets. The network object's update callback is distinct
from its drawing callback. The exact icon/label resources have not been decoded,
so the final visual mapping remains a live-test requirement.

## Preferred candidate for a future test build

The unique decoded-code pattern is:

```text
8B46142BC774??4875??8B4C240A8B54240851528D4E44E8
```

It matches once in this exact build, at RVA `0x1FF8CA`. At match +8, a two-byte
`JNE` (`75 2A`) bypasses the connection-render block when the mode is not 1.
The hypothetical replacement `EB 2A` would always bypass that block. The earlier
mode-0 branch remains reachable, and execution lands on the existing balanced
function epilogue. This is a static control-flow conclusion, not a demonstrated
in-game outcome. The replacement was **not** applied to either a game file or
live memory.

This is preferable to hiding the whole `netstat` primitive because the latter
would suppress both modes. It also avoids writing the connection counters or
the mode/timer fields. The alternate branch may cover mail/friend notifications;
preserving its code path does not yet prove every notification behaves normally.

Do not simply NOP the drawing call: two arguments are pushed before it and the
callee returns with `ret 8`. Removing the call alone would leave the stack
unbalanced. The candidate branch skips those pushes too.

A test implementation would need unique module-bounded scanning, instruction
and destination checks, original-byte ownership/restoration, clear unsupported
status, and no fallback addresses. Preserve existing settings and default the
new option off. Test arrows, S/R labels and values, percentage, notifications,
unchecking, unload, zoning, and interactions with other UI addons independently.
Expect this branch to affect the combined connection display; retaining only
the percentage would be a separate requirement.

## Other useful findings retained

| Area | Evidence | Status / limit |
| --- | --- | --- |
| Target box versus overhead arrows | `targetwi` constructor points to vtable RVA `0x332DA8`; draw callback is RVA `0x14EBA0`. Its later sprite blocks at `0x14EF1C` and `0x14EF5A` use coordinate pairs populated by its separate target-update callback. Earlier blocks draw box text/HP and other details. | Stronger lead for separating box drawing from target markers. No box-only patch is validated. The handler also changes state/help behavior, so skipping large regions blindly is inappropriate. Keep current target checkbox unchecked. |
| Status icons | [HealsCodes/statustimers](https://github.com/HealsCodes/statustimers/blob/89e2c0abd4baa6936d0ea1fce879fa275d9c3847/addons/statustimers/block_native.lua) supplies three native-icon patches. | In this client's decoded code their match counts are **1 / 2 / 1**. The second signature, `7D??33C05EC20400C6`, is ambiguous. Do not copy its first-match behavior into HXIUIBegone without resolving both sites. |
| Cast bar | Native `casttime` record, object-slot RVA `0x575F0C`. The full 44-byte descriptor is unique in the supported offline build. | Added as a guarded experimental control in 0.2.4 using the existing primitive ownership path. Hiding and restoration still need an in-game check. |
| Spell/ability information | Native `subwindo` slot is RVA `0x5761EC`, exactly four bytes before `targetwi`'s slot. | Supports the structural relationship reported by CowXIUI. It does not by itself prove every tooltip belongs exclusively to this window. |
| Help and chat | Records include `helpwind`, `logwindo`, `logwin2 `, `fulllog ` and `chatctrl`. | Useful catalog entries, not approved hide controls. Input, dialogue, and help side effects must be considered separately. |
| Network lookalikes | `netwait ` and `netbar  ` are different records from `netstat `. | Do not select by a loose `net` substring or assume all network-named windows are this meter. |
| Menu asset modifications | [XI-View](https://github.com/Caradog/XI-View/blob/496dbe66b126bbb36cd47ed6b5c55fb302228d9a/README.md) changes UI assets; its source and documentation were checked. | No ready reversible meter checkbox found there. DAT replacement is not the preferred route for this addon. No DATs changed. |

The 366-record catalog is retained as research metadata. Most entries have not
been individually analyzed and must not automatically become settings.

## Expanded source coverage

These seven additional pinned repositories contributed 1,111 text/source files
to the search, bringing both passes to 27 snapshots and 2,875 files searched.
Search counts are not claims of line-by-line review. Public-source absence is
not proof that a method does not exist. Private discussions, inaccessible
repositories and all historical branches remain outside the completed work.

| Repository | Commit | Files searched |
| --- | --- | ---: |
| Windower/Fenestra | `e5bfb6442f49bdb4d31859bff6218bbeb1bea620` | 345 |
| Windower/packages | `756138eaf493320739a0eee7849164c4deb343a7` | 221 |
| Windower/Lua | `94a73f2a4a155d26a86fc0cc363502eef8d54713` | 473 |
| KenshiDRK/Addons | `0b5c7ade6c44729600799c1524339259df4fd01d` | 23 |
| Ivaar/Ashita-addons | `2fa0241d3e87997b42e7131c014c369775a9d0df` | 14 |
| Caradog/XI-View | `496dbe66b126bbb36cd47ed6b5c55fb302228d9a` | 22 |
| HealsCodes/statustimers | `89e2c0abd4baa6936d0ea1fce879fa275d9c3847` | 13 |

## Reproduction and retained artifacts

Research files are outside the addon release, under
`release-verification/HXIUIBegone/network-meter-audit/expanded/`:

- `offline_client.py`: exact-hash, file-only POL1 decoder and static readers.
- `verify_offline_findings.py`: validates signatures, menu-table cross-checks,
  constructor/vtable links, and candidate branch destinations/stack cleanup.
- `offline_findings.json`: structured results and explicit untested status.
- `menu_catalog.json`: all 366 static menu descriptors, not user/gameplay data.
- `offline_evidence.txt`: bounded disassembly excerpts supporting this report.
- Repository manifests and source caches for the additional public sources.

Run from the workspace root:

```text
python release-verification/HXIUIBegone/network-meter-audit/expanded/verify_offline_findings.py
```

The tool uses the already-isolated Capstone dependency in
`release-verification/HXIUIBegone/tooling`. It refuses a different DLL hash,
keeps decoded code in its own Python process, and never accesses the running
game. It writes only research outputs in its own directory. The original DLL
hash is checked again before writing results.

Completed validation establishes file/build consistency and static control flow.
It does not establish live compatibility, complete visual coverage, notification
behavior, or restoration. No new feature is marked working yet.
