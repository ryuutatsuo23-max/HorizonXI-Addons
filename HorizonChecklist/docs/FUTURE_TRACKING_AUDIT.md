# Future tracking audit

Read-only research, 2026-09-08. No runtime, saved-data, or category changes. No live packet capture or gameplay interaction was performed. Web evidence was fetched with Firecrawl into the ignored `.firecrawl/` directory.

## Findings

| Candidate | HorizonXI evidence | Tracking evidence | Decision |
| --- | --- | --- | --- |
| Home Points | The wiki describes one currently selected respawn point, not a verified collectible teleport network. | Retail packet definitions expose the current Home Point zone, not a list of unlocked crystals. | Do not add a completion checklist. A current-home-point information row would be a separate feature. |
| Survival Guides | No content at the reviewed HorizonXI page. This is insufficient to prove either availability or absence. | Local retail entity listings exist, but entity IDs do not establish personal unlock state. No verified Horizon reader found. | Defer. |
| Outpost warps | Explicitly documented, including Horizon-specific Jeuno travel and supply-run prerequisites. | No direct getter found in the reviewed Ashita IPlayer annotations. Generic NPC menu packets are a research lead; the outpost unlock bit layout is not verified. | Best next live diagnostic candidate, not ready for a checklist. |
| Assault | HorizonXI category currently labels the content planned. | Retail 0x056 defines separate current-Assault and completed-Assault fields. Existing addon readers deliberately do not consume them. | Strong static protocol lead; defer category until availability and mappings are validated. |
| Runic Portals | HorizonXI page currently labels the content planned and describes individually activated destinations. | The runic portal use permit is a temporary KI, not evidence that all destinations are unlocked. No verified destination-state reader found. | Defer; investigate destination menus separately. |
| Mercenary rank | HorizonXI page currently labels the content planned. | Client resources identify several Wildcat badges as temporary KIs. Current badge state is not a history of earned ranks; promotion quests already have separate quest rows. | Defer; research replacement behavior and a reliable current-rank source. |
| Nyzul progress | HorizonXI page currently labels the content planned and describes progress recorded on the Runic Disc. | Disc/key ownership IDs exist, but their presence is not the recorded floor value. No verified floor reader found. | Defer; do not infer floor completion from owning the disc. |
| Salvage, currencies, other repeatable ToAU systems | Requires a separate per-system availability check. | Remnants Permit and Assault orders are temporary. Currency totals are mutable values, not completion records. | Not permanent checklist candidates on this evidence. |

## Local technical evidence

Reviewed the local official Ashita-v4beta `addons/libs/annotations/SDK/Memory/IPlayer.lua`, the bundled Windower key-item resource table, and Windower `addons/libs/packets/fields.lua` in `release-verification/HXIUIBegone/network-meter-audit/`.

- **Assault:** incoming `0x056`, subtype `0x0080`, has a 4-byte current Assault field at offset `0x14`; the current ToAU mission is separately at `0x18`. Subtype `0x00C0` has 16 completed-Assault bytes at `0x14`, following 16 completed-ToAU-quest bytes at `0x04`. Offsets include the packet header and are static upstream definitions, not Horizon captures. Mission-ID-to-bit mappings and no-current sentinel values remain unverified.
- **Current Home Point:** incoming `0x061` has a Home Point zone field at `0x4A`. This cannot demonstrate visited crystals or a teleport collection.
- **Menu research:** incoming `0x034` carries NPC, zone, menu ID, and 32 bytes of menu parameters at `0x08`. The parameters vary by menu. Their existence does not establish an Outpost or Runic Portal bit mapping.
- **Resource traps:** runic portal use permit=782, Wildcat badges such as PSC=780 and PFC=783, and Remnants Permit=854 are listed as temporary. Runic Disc=879 and Runic Key=880 are listed as permanent, but an ownership bit does not expose their progress contents. These IDs were research leads only and were not imported.
- **Existing boundaries:** `mission_state.lua` reads current ToAU at `0x18`; `quest_state.lua` reads the first 16 bytes of the corresponding quest section. An Assault implementation must preserve those slices and receive its own synthetic tests, state namespace, and reviewed identity/bit mappings.

## Recommended next step: passive Outpost diagnostic

Do this only as a separately approved diagnostic, without adding progress totals yet:

1. Have the user manually open a known home-nation or Jeuno warp menu. Observe only incoming menu data; do not send packets, select destinations, or automate interaction.
2. Compare a known unlocked and known locked destination, identifying exact NPC/zone/menu IDs and candidate fields.
3. Distinguish supply-run completion from job-level restrictions, current nation, conquest control, price, and travel direction. A disabled menu option alone must not be labelled Locked.
4. Confirm the same interpretation after zoning/reopening, and on a second known state. Nation switching needs its own test; the wiki's report about retaining unlocks is not enough to define cache semantics.
5. Only then consider a small read-only category. Until the relevant evidence arrives, affected destinations must remain Unknown. Use synthetic fixtures and avoid retaining personal packet dumps in the repository.

No candidate in this audit is ready to be presented as verified automatic tracking yet. Outposts are the best user-facing next step; Assault has the clearest static packet lead but remains subject to the planned-content warning.

## Web sources

- [Home Point](https://horizonffxi.wiki/Home_Point)
- [Survival Guide](https://horizonffxi.wiki/Survival_Guide) — empty page at review time, not proof of nonexistence.
- [Outpost Teleportation](https://horizonffxi.wiki/Outpost_Teleportation)
- [Assault](https://horizonffxi.wiki/Category:Assault)
- [Runic Portal](https://horizonffxi.wiki/Runic_Portal)
- [Mercenary Rank](https://horizonffxi.wiki/Mercenary_Rank)
- [Nyzul Isle Investigation](https://horizonffxi.wiki/Nyzul_Isle_Investigation)

Wiki availability labels and upstream protocol definitions may change. A populated page or a field in the client is not a live-server compatibility result.
