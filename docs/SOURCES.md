# Sources and evidence boundaries

Profile snapshot: `2026-09-03-foundation`.

## Upstream inspiration

- [HiPotionQ8/XIchecklist](https://github.com/HiPotionQ8/XIchecklist): behavioral inspiration and requested conversion target. No Lua code or data table was copied into this implementation.

## Ashita v4 behavior

The live checks use Ashita v4's installed interface annotations and established addon patterns:

- resolve spells with `IResourceManager:GetSpellByName`, then read `IPlayer:HasSpell`;
- resolve key-item names with `IResourceManager:GetString('keyitems.names', ..., 2)`, then read `IPlayer:HasKeyItem`;
- persist per-character preferences with Ashita's `settings` library;
- draw the checklist with Ashita's `imgui` library.

No packet-derived state is used in version 0.1.1.

## HorizonXI starter profile

The spell and map entries link to their corresponding [HorizonXI Wiki](https://horizonffxi.wiki/) pages. A `wiki_listed` label means only that the page was identified; it is not a claim of current server availability. The eight starter-map client IDs were cross-checked against the generated Windower `key_items.lua` reference bundled in this workspace; runtime code also verifies each numeric ID back against Ashita's English key-item resource name before reading ownership.

The nineteen Bastok Markets entries preserve the stable `HXQ-0001` through `HXQ-0019` IDs and requirements from the local `HorizonXI-Spreadsheet/data/reference.json` pilot. Each row retains its individual HorizonXI Wiki URL where one was resolved.

Evidence exceptions are visible in the profile:

- `HXQ-0003` is `unknown`; only the [Bastok Quests category](https://horizonffxi.wiki/Category:Bastok_Quests) is linked.
- `HXQ-0012` is `reported_inactive` and excluded from progress totals.
- `HXQ-0015` is `reported_active`; that report still requires private-server verification.
- `HXQ-0019` retains its wiki-listed pilot label but links only the category page because an individual page was unresolved.

Quest completion is manual in this release. A checked box records the user's note; it does not claim to read or verify a server quest flag.

## Maintenance rule

New profile entries should have a stable ID, a source URL, an evidence label, and a concise description of any uncertainty. Do not infer `active`, `complete`, or `unavailable` from missing data. Changes that add packet parsing should document packet provenance and be tested with synthetic fixtures before any live-server review.
