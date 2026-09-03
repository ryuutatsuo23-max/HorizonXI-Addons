# Sources and evidence boundaries

Profile snapshot: `2026-09-03-foundation.10`.

## Upstream inspiration

- [HiPotionQ8/XIchecklist](https://github.com/HiPotionQ8/XIchecklist): behavioral inspiration and requested conversion target. No Lua implementation code was copied. Its `maps/story.lua` table at commit [`04baf17b2b0373883407a94ce0b6a72274a31ba6`](https://github.com/HiPotionQ8/XIchecklist/blob/04baf17b2b0373883407a94ce0b6a72274a31ba6/maps/story.lua) supplies the Bastok ordering for indices 0 through 92 and 82 named San d'Oria entries through index 119.
- [Windower/Lua packet definitions](https://github.com/Windower/Lua/tree/dev/addons/libs/packets) and Windower's generated key-item resources: protocol and numeric-ID cross-checks for the read-only map implementation. No Windower implementation code is bundled.

## Ashita v4 behavior

The live checks use Ashita v4's installed interface annotations and established addon patterns:

- resolve imported spells with `IResourceManager:GetSpellById`, validate the English name and magic-skill ID, then read `IPlayer:HasSpell`; name lookup remains a fallback for entries without an explicit ID;
- resolve and validate key-item IDs with `IResourceManager:GetString`, then read the incoming `0x055` ownership bit; a positive `IPlayer:HasKeyItem` remains a pre-log fallback;
- persist per-character preferences with Ashita's `settings` library;
- read current numeric magic-related skills with `IPlayer:GetCombatSkill`, `combatskill_t:GetSkill`, and `combatskill_t:IsCapped`;
- read spell job requirements from the already name- and skill-validated `ISpell.LevelRequired` client resource, limited to Horizon's twenty level-75-era jobs and levels 1 through 75;
- draw the checklist with Ashita's `imgui` library.

Version 0.11.0 passively reads the incoming `0x055` key-item log for map ownership and the incoming `0x056` quest log for the Bastok and San d'Oria catalogs. The key-item layout has 64 availability bytes from offset `0x04`, 64 examined bytes, and a group value at offset `0x84`; HXIChecklist reads only the availability bytes and group. The quest layout has 32 flag bytes from offset `0x04` and a type value at offset `0x24`; San d'Oria current/completed types are `0x0050`/`0x0090`, and Bastok types are `0x0058`/`0x0098`. It never changes, blocks, injects, or requests a packet.

Decoded key-item groups and each nation's paired quest logs are hex-encoded separately into a versioned cache within Ashita's settings library. Ashita v4 stores that settings block under its character-name and server-ID path and invokes the registered callback when the active character changes. Invalid, incomplete, or absent cache data fails closed to `UNKNOWN`; packet data from one character is never intentionally reused for another.

## HorizonXI magic catalog

The 2026-09-03 snapshot follows the six user-requested HorizonXI Wiki category pages:

- [Dark Magic](https://horizonffxi.wiki/Dark_Magic): 15 spells.
- [Divine Magic](https://horizonffxi.wiki/Divine_Magic): 8 spells.
- [Elemental Magic](https://horizonffxi.wiki/Elemental_Magic): 60 spells.
- [Enfeebling Magic](https://horizonffxi.wiki/Enfeebling_Magic): 19 spells.
- [Enhancing Magic](https://horizonffxi.wiki/Enhancing_Magic): 76 spells.
- [Healing Magic](https://horizonffxi.wiki/Healing_Magic): 22 spells.

Those six catalogs contain 200 unique player spells. A row was included only when it appeared in the relevant HorizonXI Wiki category and matched a learnable client spell resource in that same skill with at least one job level at or below HorizonXI's level-75 cap. Client IDs, skill IDs, learnable flags, and job levels were cross-checked against [Windower/Resources](https://github.com/Windower/Resources) at commit `67948a3ce609ac614e889002268470859be319d5`.

Category and guide pages were not treated as spells. `Enlight` was excluded because its client job level is 85. The monster-only/unlearnable `Bindga`, `Diaga II`, and `Slowga` resources were excluded. `Sleepga` and `Sleepga II` use the learnable client IDs 273 and 274 rather than same-name unlearnable resources. These filters are deliberately conservative; a wiki listing is evidence, not a guarantee that a spell is obtainable on the current server build.

Version 0.5.0 adds 116 ownership rows from the current Horizon job lists:

- [Summoner summons](https://horizonffxi.wiki/Summoner#Summons): 17 rows, comprising the nine listed avatars and eight elemental spirits. Blood Pacts and unrelated pages in the broader Summoning Magic category are not ownership rows.
- [Ninja Ninjutsu list](https://horizonffxi.wiki/Ninja#Ninjutsu_List): 23 rows. Ninja tools, guides, and client spells absent from the Horizon job list are excluded.
- [Bard song list](https://horizonffxi.wiki/Bard#Song_List): 76 rows. `Raptor Mazurka` and `Adventurer's Dirge` exist in the client resources but are absent from the current Horizon Bard list and are therefore excluded rather than guessed available.

These additions bring `All Magic` to 316 unique ownership entries. Summoning uses client skill ID 38, Ninjutsu 39, and Songs 40. The displayed `Lightning Threnody` row validates against the client's shortened English resource name `Ltng. Threnody`. Singing, String Instrument, and Wind Instrument are numeric skill values—not additional song ownership lists—and appear only in the separate live `Skill Levels` view.

The job-level text beside each ownership row comes from the same locally installed client spell resource used to validate its ID, English name, and magic-skill ID. Only WAR through SCH and requirements from level 1 through 75 are displayed. This is client metadata for the private test installation, not a new claim that every listed spell is currently obtainable on HorizonXI.

## Numeric skill levels

The `Skill Levels` view reads client combat-skill indices 32 through 42: Divine, Healing, Enhancing, Enfeebling, Elemental, Dark, Summoning, Ninjutsu, Singing, String Instrument, and Wind Instrument. Each row shows the raw integer returned by Ashita plus Ashita's boolean capped flag. It does not calculate caps from jobs, levels, merits, equipment, food, or server rules.

This view is informational and live-only. It is not added to the ownership catalog or progress denominator and is not written to the character cache. If the character is not logged in or a memory read fails, the affected value remains visibly unavailable rather than being inferred.

## HorizonXI maps and nation quests

The Maps catalog contains the 72 rows in the HorizonXI Wiki's [Magical Maps table](https://horizonffxi.wiki/Category:Magical_Maps): 28 Original-area maps, 16 Rise of the Zilart maps, 17 Chains of Promathia maps, and 11 Treasures of Aht Urhgan maps. A `wiki_listed` label means only that the table identifies the map; it is not a claim of current server availability. Rows with an existing individual page link to it; rows whose table link is a red link retain the category table as their evidence source.

All 72 numeric IDs and English resource names were cross-checked against Windower/Resources `resources_data/key_items.lua` at commit [`67948a3ce609ac614e889002268470859be319d5`](https://github.com/Windower/Resources/blob/67948a3ce609ac614e889002268470859be319d5/resources_data/key_items.lua). Runtime code also verifies each numeric ID back against Ashita's English key-item resource name before reading the corresponding `0x055` ownership bit. The broader client resource contains maps absent from HorizonXI's table; those are excluded. In particular, `Map of the Uleguerand Range` and temporary Assault-area maps are not inferred into this catalog merely because client records exist.

Vendor costs come only from the Purchased tables in the HorizonXI Wiki [Map Guide](https://horizonffxi.wiki/Map_Guide). Thirty catalog maps have a listed price: 27 in gil and three in Imperial Standing. Price spelling is normalized to `gil`; amounts and currency are otherwise preserved. The guide's `Nahmau` and `Havlung` display typos are matched conservatively through their linked Nashmau and Halvung map targets.

The other 42 rows use the corresponding `Obtained` value from the HorizonXI Wiki [Magical Maps table](https://horizonffxi.wiki/Category:Magical_Maps). Quest titles are prefixed `Quest`, mission rows are prefixed `Mission`, and the source's generic `Mini-quest`, `Chest`, and `Coffer` wording is retained. `Map of Alza'daal Ruins` uses the Map Guide's more specific `Undersea Scouting` mission title in place of the category table's NPC-only value. These are sourced acquisition summaries, not claims that the current private-server implementation exactly matches every wiki step.

The Bastok catalog contains every named XIchecklist client slot from index 0 through 92. The original nineteen pilot rows preserve the stable `HXQ-0001` through `HXQ-0019` IDs and their local pilot notes; new rows use index-derived IDs. The [HorizonXI Bastok Quests category](https://horizonffxi.wiki/Category:Bastok_Quests) supplies current source links, starting-location groupings, and its displayed fame column. A wiki listing is evidence, not a guarantee that the quest is active or implemented identically on the current server.

The category page has location/fame table rows for 88 client quests: 67 show numeric Bastok fame levels and 21 show no listed fame value. Four more client quests appear only in the category's flat quest list, so their fame remains `Unknown`. `Synergistic Pursuits` appears in a location table despite being absent from that flat list; the location-table row is retained as its evidence. `A Proper Burial` appears in XIchecklist's client ordering but in neither HorizonXI category section, so both its evidence state and fame remain explicit `Unknown`. This produces 92 client rows with some category evidence and one unresolved availability row without inventing missing facts.

Evidence exceptions remain visible:

- `HXQ-0003` (`A Proper Burial`) is `unknown` and excluded from known totals.
- `HXQ-0012` (`All by Myself`) retains the pilot's `reported_inactive` boundary and is excluded from progress totals.
- `HXQ-0015` (`Father Figure`) retains the pilot's `reported_active` label; that report still requires private-server verification.
- `A Discerning Eye (Bastok)`, `Bait and Switch`, `Fully Mental Alchemist`, and `Trust: Bastok` are category-listed but have `Unknown` fame because no matching location/fame row exists.

There is no manual completion fallback for the mapped Bastok catalog. Until both live logs or a valid cache exist for the current character, rows remain `UNKNOWN`. A private-server result is still not proof of HorizonXI approval or universal server compatibility.

The San d'Oria catalog contains all 82 named entries in XIchecklist's San d'Oria client-log ordering. The [HorizonXI San d'Oria Quests category](https://horizonffxi.wiki/Category:San_d%27Oria_Quests) provides location, type, NPC, and fame evidence for 79 entries: 60 numeric fame values and 19 values not listed. [Port San d'Oria](https://horizonffxi.wiki/Port_San_d%27Oria) separately references `Lure of the Wildcat (San d'Oria)`, but its individual page and fame value are unresolved. `Atelloune's Lament` and `Trust: San d'Oria` have no resolved current Horizon source, so their availability and fame stay `Unknown`. This yields 80 rows with some Horizon evidence, two explicit availability unknowns, and three unknown fame values without inventing missing facts.

San d'Oria state uses its own character-cache key and does not change the established Bastok cache format. There is no manual completion fallback for either nation catalog. Until both live logs or a valid cache exist for the relevant nation and character, its rows remain `UNKNOWN`.

## Maintenance rule

New profile entries should have a stable ID, a source URL, an evidence label, and a concise description of any uncertainty. Do not infer `active`, `complete`, or `unavailable` from missing data. Changes that add packet parsing should document packet provenance and be tested with synthetic fixtures before any live-server review.
