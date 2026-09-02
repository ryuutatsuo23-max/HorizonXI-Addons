# Sources and evidence boundaries

Profile snapshot: `2026-09-03-foundation`.

## Upstream inspiration

- [HiPotionQ8/XIchecklist](https://github.com/HiPotionQ8/XIchecklist): behavioral inspiration and requested conversion target. No Lua code or data table was copied into this implementation.
- [Windower/Lua packet definitions](https://github.com/Windower/Lua/tree/dev/addons/libs/packets) and Windower's generated key-item resources: protocol and numeric-ID cross-checks for the read-only map implementation. No Windower implementation code is bundled.

## Ashita v4 behavior

The live checks use Ashita v4's installed interface annotations and established addon patterns:

- resolve spells with `IResourceManager:GetSpellByName`, then read `IPlayer:HasSpell`;
- resolve and validate key-item IDs with `IResourceManager:GetString`, then read the incoming `0x055` ownership bit; a positive `IPlayer:HasKeyItem` remains a pre-log fallback;
- persist per-character preferences with Ashita's `settings` library;
- draw the checklist with Ashita's `imgui` library.

Version 0.1.2 passively reads only the incoming `0x055` key-item log for map ownership. Its established client layout has 64 availability bytes from offset `0x04`, 64 examined bytes, and a group value at offset `0x84`; HXIChecklist reads only the availability bytes and group. It never changes, blocks, injects, or requests a packet.

## HorizonXI starter profile

The spell and map entries link to their corresponding [HorizonXI Wiki](https://horizonffxi.wiki/) pages. A `wiki_listed` label means only that the page was identified; it is not a claim of current server availability. The eight starter-map client IDs were cross-checked against the generated Windower `key_items.lua` reference bundled in this workspace; runtime code also verifies each numeric ID back against Ashita's English key-item resource name before reading the corresponding `0x055` ownership bit.

The nineteen Bastok Markets entries preserve the stable `HXQ-0001` through `HXQ-0019` IDs and requirements from the local `HorizonXI-Spreadsheet/data/reference.json` pilot. Each row retains its individual HorizonXI Wiki URL where one was resolved.

Evidence exceptions are visible in the profile:

- `HXQ-0003` is `unknown`; only the [Bastok Quests category](https://horizonffxi.wiki/Category:Bastok_Quests) is linked.
- `HXQ-0012` is `reported_inactive` and excluded from progress totals.
- `HXQ-0015` is `reported_active`; that report still requires private-server verification.
- `HXQ-0019` retains its wiki-listed pilot label but links only the category page because an individual page was unresolved.

Quest completion is manual in this release. A checked box records the user's note; it does not claim to read or verify a server quest flag.

## Maintenance rule

New profile entries should have a stable ID, a source URL, an evidence label, and a concise description of any uncertainty. Do not infer `active`, `complete`, or `unavailable` from missing data. Changes that add packet parsing should document packet provenance and be tested with synthetic fixtures before any live-server review.
