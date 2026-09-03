# Sources and evidence boundaries

Profile snapshot: `2026-09-03-foundation.4`.

## Upstream inspiration

- [HiPotionQ8/XIchecklist](https://github.com/HiPotionQ8/XIchecklist): behavioral inspiration and requested conversion target. No Lua implementation code was copied. Its Bastok quest ordering was used to cross-check the 19 numeric quest-index facts recorded in the profile.
- [Windower/Lua packet definitions](https://github.com/Windower/Lua/tree/dev/addons/libs/packets) and Windower's generated key-item resources: protocol and numeric-ID cross-checks for the read-only map implementation. No Windower implementation code is bundled.

## Ashita v4 behavior

The live checks use Ashita v4's installed interface annotations and established addon patterns:

- resolve imported spells with `IResourceManager:GetSpellById`, validate the English name and magic-skill ID, then read `IPlayer:HasSpell`; name lookup remains a fallback for entries without an explicit ID;
- resolve and validate key-item IDs with `IResourceManager:GetString`, then read the incoming `0x055` ownership bit; a positive `IPlayer:HasKeyItem` remains a pre-log fallback;
- persist per-character preferences with Ashita's `settings` library;
- draw the checklist with Ashita's `imgui` library.

Version 0.4.0 passively reads the incoming `0x055` key-item log for map ownership and the incoming `0x056` quest log for the Bastok pilot. The key-item layout has 64 availability bytes from offset `0x04`, 64 examined bytes, and a group value at offset `0x84`; HXIChecklist reads only the availability bytes and group. The quest layout has 32 flag bytes from offset `0x04` and a type value at offset `0x24`; the Bastok current and completed types are `0x0058` and `0x0098`. It never changes, blocks, injects, or requests a packet.

Decoded key-item groups and the paired Bastok logs are hex-encoded into a versioned cache within Ashita's settings library. Ashita v4 stores that settings block under its character-name and server-ID path and invokes the registered callback when the active character changes. Invalid, incomplete, or absent cache data fails closed to `UNKNOWN`; packet data from one character is never intentionally reused for another.

## HorizonXI magic catalog

The 2026-09-03 snapshot follows the six user-requested HorizonXI Wiki category pages:

- [Dark Magic](https://horizonffxi.wiki/Dark_Magic): 15 spells.
- [Divine Magic](https://horizonffxi.wiki/Divine_Magic): 8 spells.
- [Elemental Magic](https://horizonffxi.wiki/Elemental_Magic): 60 spells.
- [Enfeebling Magic](https://horizonffxi.wiki/Enfeebling_Magic): 19 spells.
- [Enhancing Magic](https://horizonffxi.wiki/Enhancing_Magic): 76 spells.
- [Healing Magic](https://horizonffxi.wiki/Healing_Magic): 22 spells.

The resulting catalog contains 200 unique player spells. A row was included only when it appeared in the relevant HorizonXI Wiki category and matched a learnable client spell resource in that same skill with at least one job level at or below HorizonXI's level-75 cap. Client IDs, skill IDs, learnable flags, and job levels were cross-checked against [Windower/Resources](https://github.com/Windower/Resources) at commit `67948a3ce609ac614e889002268470859be319d5`.

Category and guide pages were not treated as spells. `Enlight` was excluded because its client job level is 85. The monster-only/unlearnable `Bindga`, `Diaga II`, and `Slowga` resources were excluded. `Sleepga` and `Sleepga II` use the learnable client IDs 273 and 274 rather than same-name unlearnable resources. These filters are deliberately conservative; a wiki listing is evidence, not a guarantee that a spell is obtainable on the current server build.

## HorizonXI maps and quest pilot

The map entries link to their corresponding [HorizonXI Wiki](https://horizonffxi.wiki/) pages. A `wiki_listed` label means only that the page was identified; it is not a claim of current server availability. The eight starter-map client IDs were cross-checked against the generated Windower `key_items.lua` reference bundled in this workspace; runtime code also verifies each numeric ID back against Ashita's English key-item resource name before reading the corresponding `0x055` ownership bit.

The nineteen Bastok Markets entries preserve the stable `HXQ-0001` through `HXQ-0019` IDs and requirements from the local `HorizonXI-Spreadsheet/data/reference.json` pilot. Each row retains its individual HorizonXI Wiki URL where one was resolved. The numeric indices were cross-checked against XIchecklist's Bastok quest table and standard client ordering; the implementation reads only those 19 indices.

Evidence exceptions are visible in the profile:

- `HXQ-0003` is `unknown`; only the [Bastok Quests category](https://horizonffxi.wiki/Category:Bastok_Quests) is linked.
- `HXQ-0012` is `reported_inactive` and excluded from progress totals.
- `HXQ-0015` is `reported_active`; that report still requires private-server verification.
- `HXQ-0019` retains its wiki-listed pilot label but links only the category page because an individual page was unresolved.

There is no manual completion fallback for the mapped Bastok pilot. Until both live logs or a valid cache exist for the current character, rows remain `UNKNOWN`. A private-server result is still not proof of HorizonXI approval or universal server compatibility.

## Maintenance rule

New profile entries should have a stable ID, a source URL, an evidence label, and a concise description of any uncertainty. Do not infer `active`, `complete`, or `unavailable` from missing data. Changes that add packet parsing should document packet provenance and be tested with synthetic fixtures before any live-server review.
