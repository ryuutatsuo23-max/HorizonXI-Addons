# Private-server validation checklist

Use a local private Ashita v4 server/client first. This is not a HorizonXI approval or deployment procedure.

## Load and settings

- [ ] Copy the inner `HXIChecklist` folder to the private client's `addons` directory.
- [ ] Load with `/addon load HXIChecklist` and confirm no Lua error.
- [ ] Toggle with `/hc`; show/hide and window close should remain synchronized.
- [ ] Change scale and filters, reload the addon, and confirm they persist for that character.
- [ ] Compare 75%, 100%, and 150% and confirm the addon text visibly changes size at each setting.
- [ ] On a character with no cache, confirm all seven quest-area catalogs show no manual checkboxes and unresolved rows are `UNKNOWN`.
- [ ] After receiving the logs once, unload/reload the addon without zoning and confirm map and all seven quest-area states restore from cache.
- [ ] Log into another character and confirm it does not inherit the first character's cached state.
- [ ] Return to the first character and confirm its own cache restores.

## Magic Skills

- [ ] Confirm the top-level `Magic Skills` tab contains `Spells & Songs` and `Blue Magic` subtabs without widening the main tab bar.
- [ ] Open `Magic Skills` and confirm its compact `Category` selector contains, in order: All Magic, Dark, Divine, Elemental, Enfeebling, Enhancing, Healing, Summoning, Ninjutsu, Songs.
- [ ] Switch among several categories and confirm the selector does not widen the addon window or show a horizontal tab strip.
- [ ] With completed entries visible, confirm `All Magic` contains 316 rows and the individual categories contain 15, 8, 60, 19, 76, 22, 17, 23, and 76 rows respectively.
- [ ] Compare at least one learned and one unlearned spell in each category against the in-game magic list.
- [ ] Confirm `Sleepga` and `Sleepga II` resolve normally rather than showing `UNKNOWN` from the same-name monster resources.
- [ ] Search for a spell while switching inner tabs; confirm only matching spells in the selected view are shown.
- [ ] Open several spell Source buttons, including `Dispel`, and confirm they lead to the expected HorizonXI Wiki pages.
- [ ] In `Summoning`, compare one unlocked and one locked avatar or spirit against the in-game magic list; confirm Blood Pacts are absent.
- [ ] In `Ninjutsu`, compare one learned and one unlearned spell; confirm ninja tools are absent.
- [ ] In `Songs`, compare one learned and one unlearned song, and confirm `Lightning Threnody` does not show `UNKNOWN` because of the client's shortened resource name.
- [ ] Confirm a separator line appears below the `Category` selector before the first ownership row.
- [ ] Confirm every visible Magic row uses aligned columns for the spell, Source button, separator, and job-level requirements.
- [ ] Confirm `Absorb-ACC` displays `DRK Lv.61`, then compare several single-job and multi-job requirements against the private client's spell information.
- [ ] Resize and scale the addon; confirm long multi-job requirements wrap without overlapping spell names or Source buttons.
- [ ] In a narrow window, confirm full `JOB Lv.#` requirements wrap cleanly within the resizable column.
- [ ] Drag both vertical Magic-table separators and confirm the spell, Source, and job-level columns resize without overlap.
- [ ] Confirm the resize hint and brighter vertical separators are clearly visible.
- [ ] Confirm multi-job requirements use commas and no slash separators remain.

## Blue Magic

- [ ] Open `Magic Skills` > `Blue Magic` and confirm the level selector contains All Levels, Levels 1-20, Levels 21-40, Levels 41-60, and Levels 61-75.
- [ ] With completed and missing rows visible, confirm All Levels contains 106 rows and the four bands contain 20, 20, 28, and 38 rows.
- [ ] Compare several learned and unlearned spells against the in-game Blue Magic list. Learned rows should say `Learned`; unlearned rows should say `Not learned`; unloaded or mismatched spell data must remain `UNKNOWN`.
- [ ] Confirm Foot Kick shows `Level 1 / Slashing / Lizard Killer`, Vanity Dive shows Horizon level 28, Quadratic Continuum shows level 54, and Winds of Promyvion shows level 56.
- [ ] Confirm Quadratic Continuum and Winds of Promyvion resolve normally rather than showing `UNKNOWN` from the client's abbreviated resource names.
- [ ] Search by spell name, type, trait, and level; then switch level bands and confirm both filters apply together.
- [ ] Drag both vertical dividers and resize/scale the window. Spell names, Source buttons, and Level / Type / Trait text should not overlap.
- [ ] Export All Levels and one filtered level band; confirm status, spell, learn level, type, set trait, and source columns match the visible rows.
- [ ] Confirm Source opens the HorizonXI Blue Magic category. The addon must not claim an exact learning monster or zone in this version.

## Skill Levels

- [ ] Open `Skill Levels` and confirm it lists, in order: Divine, Healing, Enhancing, Enfeebling, Elemental, Dark, Summoning, Ninjutsu, Singing, String Instrument, and Wind Instrument.
- [ ] Compare several displayed numbers, including Singing and both instrument skills, with the in-game Skills menu.
- [ ] Compare at least one capped and one uncapped skill; confirm the rows show `Capped` and `Training` consistently with the client.
- [ ] Confirm opening or refreshing `Skill Levels` does not change the header progress totals or any Magic Skills ownership label.
- [ ] Reload the addon and switch characters; confirm values are read live for the active character without requiring a zone or reusing cached values.
- [ ] Check the view before character data is available and confirm it shows `Unavailable` rather than a guessed zero.

## Quest navigation

- [ ] Confirm the top-level tabs are `Quests`, `Missions`, `Magic Skills`, and `Others/Key Items`.
- [ ] Open `Quests` and switch the `Area` dropdown among Bastok, San d'Oria, Windurst, Jeuno, and Other Areas; confirm descriptions, area totals, rows, and Fame labels follow the selected area without changing overall progress.
- [ ] Choose a different `Location` in each area, switch away and back, and confirm each selection is retained during the session.
- [ ] Confirm Spells & Songs and Maps still use their existing `Category` selectors.
- [ ] Test a narrow window at 75%, 100%, and 150% scale; confirm dropdowns, Source buttons, and draggable dividers remain usable.

## Maps and quest live state

- [ ] On first use for a character, zone once so the incoming key-item and quest logs are received.
- [ ] Open `Maps` and confirm its selector contains, in order: All Maps, Original Areas, Rise of the Zilart, Chains of Promathia, Treasures of Aht Urhgan.
- [ ] With completed entries visible, confirm `All Maps` contains 72 rows and the individual categories contain 28, 16, 17, and 11 rows respectively.
- [ ] Compare at least one owned and one unowned map in each available expansion category against Key Items.
- [ ] Confirm an Aht Urhgan map resolves after zoning; these IDs exercise key-item group 3 rather than the original-area group 0.
- [ ] Open several map Source buttons. Existing map pages should open directly; category-only evidence rows should open the HorizonXI Magical Maps table.
- [ ] Confirm map Source buttons align vertically beside the map names.
- [ ] Confirm the Obtained column shows `200 gil` for the three nation-area maps, `600 gil` for the Jeuno Area, and `3,000 gil` for Qufim Island.
- [ ] In Treasures of Aht Urhgan, confirm Al Zahbi shows `600 gil`, Nashmau shows `3,000 gil`, and Mamook, Arrapago Reef, and Halvung show `2,000 Imperial Standing`.
- [ ] Confirm Bostaunieux Oubliette shows `Quest: The Sand Charm`; compare several other quest, mission, mini-quest, chest, and coffer rows with their Source pages.
- [ ] Drag both Maps dividers and confirm Map, Source, and Obtained columns resize without overlap, including long quest titles and Imperial Standing values.
- [ ] Before that first zone, confirm unresolved map state is `UNKNOWN`, never falsely `Missing`.
- [ ] In `Quests`, select Area `Bastok` and confirm its Location selector contains All Locations, Bastok Markets, Bastok Mines, Metalworks, Port Bastok, Lower Jeuno, Beadeaux, and Unresolved.
- [ ] With completed entries visible, confirm `All Locations` contains 93 rows and includes both early entries such as `The Siren's Tear` and high-index entries such as `Trust: Bastok`.
- [ ] Confirm Quest and Source columns align vertically and Bastok Fame appears in the third column.
- [ ] Drag both Bastok dividers and confirm Quest, Source, and Bastok Fame columns resize without overlap.
- [ ] Compare several numeric fame rows against their Source pages, including `The Bare Bones` at Fame 1, `The Return of the Adventurer` at Fame 3, and `Wish Upon a Star` at Fame 5.
- [ ] Confirm job/weapon-skill rows whose Horizon table shows no fame display `Not listed`, not a guessed level.
- [ ] Confirm the five rows without a sourced fame table value display `Unknown`.
- [ ] Before that first zone and with no cache, confirm Bastok quest rows are `UNKNOWN` and have no checkboxes.
- [ ] After zoning, compare one current, one completed, and one neither-current-nor-completed quest against the in-game Bastok quest logs; expect `Accepted`, `Completed`, and `Not Accepted`.
- [ ] Include at least one quest above index 85 in the comparison to exercise the expanded packet-bit range.
- [ ] In `Quests`, select Area `San d'Oria` and confirm its Location selector contains All Locations, Northern San d'Oria, Southern San d'Oria, Port San d'Oria, Chateau d'Oraguille, Bostaunieux Oubliette, West Ronfaure, and Unresolved.
- [ ] With completed entries visible, confirm `All Locations` contains 82 named rows, ending with high-index entries including `Trust: San d'Oria` at index 119.
- [ ] Confirm numeric San d'Oria requirements display as `Fame X`; confirm 19 entries show `Not listed` and three show `Unknown`.
- [ ] Confirm `Atelloune's Lament` and `Trust: San d'Oria` remain `UNKNOWN` source states rather than being guessed available.
- [ ] After zoning, compare one accepted, one completed, and one neither-current-nor-completed San d'Oria quest, including an entry above index 113.
- [ ] Drag both San d'Oria dividers and confirm Quest, Source, and San d'Oria Fame columns resize without overlap.
- [ ] In `Quests`, select Area `Windurst` and confirm its Location selector contains All Locations, Windurst Woods, Windurst Waters North, Windurst Waters South, Port Windurst, Windurst Walls, Heavens Tower, and Unresolved.
- [ ] With completed entries visible, confirm `All Locations` contains 90 named rows, including `Trust: Windurst` at index 96.
- [ ] Confirm numeric Windurst requirements display as `Fame X`; confirm 22 entries show `Not listed` and three show `Unknown`.
- [ ] Confirm `Trust: Windurst` remains `UNKNOWN` source state rather than being guessed available.
- [ ] Enable `Show unavailable` and confirm Let Sleeping Dogs Lie, Nothing Matters, Escort for Hire (Windurst), and A Discerning Eye (Windurst) display `UNAVAILABLE`.
- [ ] Confirm `A Chocobo Riding Game (Windurst)` and `Dyer's Woad Quest` are absent because they have no matched XIchecklist client-log indices.
- [ ] After zoning, compare one accepted, one completed, and one neither-current-nor-completed Windurst quest, including a high-index entry.
- [ ] Drag both Windurst dividers and confirm Quest, Source, and Windurst Fame columns resize without overlap.
- [ ] In `Quests`, select Area `Jeuno` and confirm Location contains All Locations, Lower Jeuno, Upper Jeuno, Ru'Lude Gardens, Port Jeuno, and Unresolved.
- [ ] With all filters enabled, confirm Jeuno has 146 named client rows, including `In Defiant Challenge` at index 128 and `The Flying Machine of Eld` at index 186; confirm `Omni Aketon` is absent because its client-log index is unresolved.
- [ ] Confirm numeric Jeuno requirements display as `Fame X`, including `Crest of Davoi` at Fame 2 and `The Gobbiebag Part I` at Fame 3. Confirm 47 rows show `Not listed` and 67 show `Unknown` fame.
- [ ] On first upgrade, confirm the existing nation/map caches still restore while uncached Jeuno remains `UNKNOWN` until its logs arrive.
- [ ] After zoning, compare one accepted, one completed, and one neither-current-nor-completed Jeuno quest against the game logs, including a limit-break quest above index 127.
- [ ] Reload without zoning and confirm Jeuno restores from its own character cache; switch characters and confirm Jeuno data does not leak between characters.
- [ ] Drag both Jeuno dividers and check Source buttons, fame labels, and location selections in a narrow window.
- [ ] Select `Other Areas`; confirm Selbina, Mhaura, both Tavnazian Safehold levels, Mog House, the smaller source locations, and Unresolved are available under Location.
- [ ] With all filters enabled, confirm Other Areas contains 91 rows; Selbina contains 11, Mhaura 16, and the two Tavnazian views contain six and 13 respectively.
- [ ] Confirm `The Sand Charm` shows `Mhaura Fame 4` and `An Explorer's Footsteps` shows `Selbina Fame 1`. The Mog House quests should show `Fame 3/5/7 (see source)` individually, with a tooltip explaining the unspecified fame region.
- [ ] Confirm `The Big One` is `UNAVAILABLE`; the three verification-needed headgear quests remain `UNKNOWN` when neither live flag is set.
- [ ] Confirm existing area/map caches survive the upgrade, while first-time Other state waits for its logs. Zone once, compare accepted/completed/not-accepted quests against the game's Other log, and then reload without zoning to verify cache restoration.
- [ ] Switch characters and confirm Other state is isolated. Check a narrow window and all three scales; Source alignment, fame wrapping, and draggable dividers should remain usable.
- [ ] Test immediately after login or zoning; unresolved client data must show `UNKNOWN`, never a false missing state.
- [ ] Use `/hc refresh` after login and verify unresolved resource names remain explicit.

## Outlands upgrade

- [ ] Copy the updated inner folder (16 runtime Lua files), reload the addon, and select Quests > Area > Outlands. Confirm the header shows profile `2026-09-03-foundation.14`.
- [ ] With all filters enabled, confirm 57 rows and nine Location choices. Kazham has 14 rows, Norg 21, Rabao 11, and Unresolved six.
- [ ] Confirm The Sahagin's Stash shows Norg Fame 4, The Missing Piece shows Rabao Fame 4, and the latter's tooltip explains the table/page discrepancy.
- [ ] Confirm Divine Might and Divine Might (Repeat) have distinct rows and Source targets. Confirm category-listed red links open the category evidence, not an edit page.
- [ ] Confirm both vertical dividers resize Quest, Source, and Required Fame columns; test narrow widths and 75%, 100%, and 150% scale.
- [ ] Confirm location selection survives switching areas in the session and Show unknown hides unresolved rows without changing the counts.
- [ ] Confirm existing quest/map caches survive the upgrade. Before Outlands' first log pair, its state must remain unknown rather than Not Accepted.
- [ ] Zone after loading the new version; compare accepted, completed, and neither-bit quests with the game's Outlands log, including a Norg/Rabao entry above index 127.
- [ ] Reload without zoning to verify Outlands cache restoration. Switch characters and verify state is isolated.

## Aht Urhgan upgrade

- [ ] Copy the updated inner folder (17 runtime Lua files), reload, and confirm profile `2026-09-03-foundation.15`. Select Quests > Area > Aht Urhgan without adding any new top-level tab.
- [ ] Enable Show completed/Show unknown and confirm 72 rows with eight Location choices. Whitegate has 53, Al Zahbi 3, Nashmau 9, Bastok Markets 1, Wajaom Woodlands 2, Arrapago Reef 3, and Mount Zhayolm 1.
- [ ] Confirm Cook-a-roon?, Totoroon's Treasure Hunt, and the Promotion: titles are readable. Confirm Source links open an existing quest page or the supporting category table.
- [ ] Confirm Required Fame displays N/A, with a tooltip explaining the no-fame source statement and warning that other requirements may apply. Existing areas must keep their previous numeric/unknown/unlisted labels.
- [ ] Drag both dividers and test a narrow window at all three scales. Location choices should survive switching areas during the session.
- [ ] Before receiving the first Aht Urhgan log pair, expect UNKNOWN, not Not Accepted. Existing areas and map caches should restore normally.
- [ ] Zone after reloading; compare an accepted, completed, and neither-bit quest with the game's Aht Urhgan quest log, including a higher mapped index such as a promotion or Ashu Talif quest.
- [ ] Confirm there are no separate Assault mission rows. Where possible, compare status before/after mission or Assault-state changes and confirm unrelated quest rows stay unchanged.
- [ ] Reload without zoning to check cache restoration. Switch characters and confirm Aht Urhgan and existing areas retain separate character data.

## Horizon Custom manual tracking

- [ ] Copy the updated inner folder (18 runtime files), reload, and confirm profile `2026-09-04-foundation.17`. Select Quests > Horizon Custom; this section requires no zone for its manual marks.
- [ ] Confirm four rows and four Location choices: All Locations, Ru'Lude Gardens, Windurst Woods, and Mount Zhayolm.
- [ ] Confirm only the custom rows have checkboxes and display Manual/Manual done, never Accepted or Not Accepted. Mapped areas retain their prior read-only states.
- [ ] Check Omni Aketon; confirm the custom and global completed counts increase by one. With Show completed off, confirm the row disappears. Turn it on, uncheck, and confirm the counts return.
- [ ] Disable Show unknown and confirm unmarked custom rows remain visible, including Fill In and A Mind Unbound with Unknown fame.
- [ ] Reload without zoning; confirm checked custom entries restore. Change characters and confirm marks are isolated; return and confirm the original marks restore.
- [ ] Confirm Omni Aketon and Dyer's Woad Quest show None fame, while Fill In and A Mind Unbound show Unknown. Read the provisional-title and repeatable-at-least-once caveats in tooltips.
- [ ] Check Source links, location switching, both draggable dividers, and 75/100/150% scales. Existing caches and marks should remain unchanged except for custom boxes deliberately toggled during this test.

## Quest-type filters

- [ ] In Quests, select Artifact and Job Unlock under Type; confirm the rows match the sourced tags and Source buttons/dividers still work.
- [ ] Combine Type with Location, search, and Show completed; confirm empty intersections show the no-matches message and All Types clears the type restriction.
- [ ] Switch areas and return; confirm each area retains its Type selection for the session. Reload and confirm All Types returns, without changing saved marks or quest caches.
- [ ] Confirm Type does not change area/global totals. Unknown Type remains distinct from UNKNOWN status and the Show unknown checkbox.
- [ ] Confirm Type sits beside Location when space permits and wraps below it in narrow windows at 75/100/150% scale. No extra top-level tabs should appear.

## Accepted-only and expandable quest details

- [ ] With an active mapped quest, enable Accepted only. Confirm only Accepted rows remain, in combination with Location, Type, search, and visibility checkboxes; area/global totals must not change.
- [ ] In Horizon Custom, confirm Accepted only hides manual rows and explains why. Disable it to restore the rows. Magic, Maps, and numeric Skill Levels must not be affected.
- [ ] Expand and collapse a mapped quest with +/-. Confirm NPC, coordinates, rewards, and prerequisite summaries wrap beneath the correct row, with Source and fame still aligned; test both dividers and 75/100/150% scale in narrow/wide windows.
- [ ] Expand a custom quest, toggle its completion checkbox separately, and confirm expanding/collapsing does not mark completion or save settings. Confirm other areas display Not yet verified for missing detail fields.
- [ ] Check Gourmet shows the 100-350 gil range with the source caveat. Read the requirement-summary disclaimer; no eligibility is inferred from inventory, jobs, or fame.
- [ ] Reload: Accepted only and expanded rows should reset, while character quest caches and manual marks remain unchanged.

## Evidence and totals

### Bastok Missions (0.20.0 / foundation.19)

- [ ] Copy all 20 runtime Lua files, reload, and confirm profile `2026-09-04-foundation.19`. Existing quests, maps, skills, and custom marks should remain intact.
- [ ] Open Missions > Storyline: Bastok. With visibility filters enabled, confirm 20 main missions in 1-1 through 9-2 order, not alphabetical order, and Rank choices All Ranks plus 1 through 9.
- [ ] Before the first paired mission logs, expect UNKNOWN. Zone once; compare the addon against the game's current/completed Bastok mission log, including optional missions that were skipped. A higher rank/later mission must not mark those complete.
- [ ] Confirm Current only is separate from Accepted only in Quests, combines with Rank/search, and does not change totals. A currently repeated mission with a completion bit should show Current / Done, count complete once, and remain visible even with Show completed off.
- [ ] If possible, observe The Emissary during travel stages: only the one 2-3 row should be current. Stage completion must not mark the main mission complete prematurely.
- [ ] On a non-Bastok character, the other nation's current mission must not show as current in Bastok. Previously completed Bastok missions should still reflect their own completion bits.
- [ ] Expand a gate-guard mission and Magicite. Verify the four named guard locations and Goggehn's H-10 location against Source. Check the alternate Magicite gil reward and the partial-prerequisite disclaimer.
- [ ] Drag both dividers with long details expanded; check Source alignment and wrapping at 75/100/150% scale in narrow/wide windows. Mission expansion must not toggle completion or save UI filter state.
- [ ] Reload without zoning after receiving both logs: mission progress should restore from the saved character cache. Switch characters and back; no mission, quest, or manual-mark data should leak between characters.
- [ ] Confirm ordinary gameplay produces no addon-generated requests, packets, actions, chat, or movement. Treat mismatches as observations to investigate, not permission to change packet mappings speculatively.

### Remaining-area details (0.19.1 / foundation.18)

- [ ] Copy the updated inner HXIChecklist folder and reload; confirm profile `2026-09-04-foundation.18`. No new zoning is required for static detail fields if quest-state caches are already populated.
- [ ] Expand quests in San d'Oria, Windurst, Jeuno, Other Areas, Outlands, and Aht Urhgan. Check coordinates, rewards, and partial prerequisite summaries against Source; missing fields must still say Not yet verified.
- [ ] Inspect a Borghertz artifact quest: optional coffer rewards must be distinguished from the hands reward, and the earlier quest must be described as started rather than completed.
- [ ] Read a source-conflict note and an unverified-requirement note. Neither should silently change the fame column or imply the character meets the requirements.
- [ ] With long details expanded, drag both dividers and test narrow/wide windows at 75/100/150% scale. Source buttons should remain aligned and details should not overlap the next row.
- [ ] Confirm Accepted only, Type/Location/search filters, totals, custom marks, and existing quest states behave as before. This update must not change character saves or add Missions.

- [ ] Confirm `A Proper Burial` displays `UNKNOWN` and is excluded from the denominator.
- [ ] Enable `Show unavailable`; confirm `All by Myself` displays `UNAVAILABLE` and is excluded.
- [ ] Open several Source buttons and confirm they lead to the expected HorizonXI Wiki pages.
- [ ] Confirm the header clearly says the profile is intentionally incomplete.

### Remaining mission storylines (0.21.0 / foundation.20)

- [ ] Copy all 25 runtime Lua files, reload, and confirm profile `2026-09-07-foundation.20`. Existing quest, map, skill, custom-mark, and Bastok mission data must remain intact.
- [ ] Zone once, then switch Missions > Storyline among Bastok, San d'Oria, Windurst, Rise of the Zilart, Chains of Promathia, and Treasures of Aht Urhgan. Confirm counts 20, 20, 20, 18, 34, and 48 and no additional top-level tabs.
- [ ] On matching-nation characters, compare San d'Oria and Windurst current/completed rows against the game. On a different allegiance, confirm current state is not borrowed while explicit prior completion remains visible.
- [ ] If possible, observe Journey Abroad or The Three Kingdoms travel stages. Each must keep only its single 2-3 main row current; travel-stage bits must not complete that row.
- [ ] Compare Zilart current and several explicit completion bits. If an unexpected packet-stage ID appears, record it; the addon should show unresolved open rows as UNKNOWN rather than selecting the nearest mission.
- [ ] For Promathia, confirm exactly the current numbered mission is `Current`, including a 3-3 or 5-3 branch if available. Every non-current Promathia row must remain UNKNOWN and excluded from totals because no completion bitfield is used.
- [ ] On a character that declined or has not started Zilart/Promathia, confirm mission 1 is not falsely shown Current. Report any discrepancy with the observed packet/state; do not infer from later story access.
- [ ] Review Aht Urhgan as reference-first planned content. Compare any current/completed state the client supplies, but do not treat the wiki listing or an empty log as proof that a mission is active or unavailable.
- [ ] Expand rows in each storyline. Category-sourced rewards should display; unresearched NPC/location/coordinates should say `See Source`. Source buttons and the two draggable dividers must stay aligned at 75/100/150% scale and narrow/wide widths.
- [ ] Toggle Current only, storyline-specific Rank/Chapter selectors, search, and visibility filters. Filters must not change totals, save settings, or affect Quests > Accepted only.
- [ ] Reload without zoning after logs are cached, then switch characters and back. Each mission storyline must restore independently without leaking state or altering the existing Bastok cache.
- [ ] Confirm no Wings of the Goddess, Assault, add-on scenario, Adoulin, or Rhapsodies rows were added, and ordinary play produces no addon-generated packet requests, actions, chat, targeting, or movement.

### Visible tab export (0.22.0)

- [ ] Copy all 26 runtime Lua files, reload, and confirm the addon loads with profile `2026-09-07-foundation.21` without changing existing character data.
- [ ] Select Quests, choose an Area, Location, and Type, set the visibility and Accepted-only filters, and enter a search term. Click **Export visible** and confirm the chat message reports the exact visible row count.
- [ ] Disable Completed, Unknown, Unavailable, and **Show missing/not accepted/not current**; confirm only Accepted quests or Current missions remain. Then disable **Show accepted/current** and enable the other-open filter; confirm only Missing, Not Accepted, Not Current, or unmarked manual rows remain as applicable.
- [ ] Open the generated `.tsv` in `addons/HXIChecklist/exports/`. Confirm its rows match the currently displayed quests and include status, area, location, type, required fame, NPC, coordinates, rewards, prerequisites, and Source URL columns.
- [ ] Repeat with Magic Skills, Maps, Missions, and Skill Levels. Confirm category/storyline selectors and Current-only are honored, tabs do not export one another, and tab/newline characters cannot split a value into unintended rows or columns.
- [ ] Run `/hc export`, export twice within one second if practical, and confirm it creates a new uniquely named file rather than overwriting an earlier export.
- [ ] Confirm exporting does not change progress totals, filters, settings, manual quest marks, cached logs, or gameplay state.
- [ ] Reload and confirm the two new visibility choices are restored without changing older settings files that did not contain them.
- [ ] Confirm local `exports/` files are ignored by Git and excluded from any release ZIP; they may contain personal character progress.

### Mission detail enrichment (foundation.21)

- [ ] Reload HXIChecklist and confirm profile `2026-09-07-foundation.21`; existing character progress, manual marks, filters, exports, and mission state must remain unchanged.
- [ ] Expand several rows in every Missions storyline. Confirm the NPC/target, location, coordinates, rewards, and prerequisites remain readable at 75/100/150% scale and narrow/wide widths.
- [ ] Check a nation gate-guard mission. Its coordinate field should say `Varies by gate guard`; San d'Oria and Windurst Magicite should instead show Nelcabrit G-9 and Pakh Jatalfih I-9 respectively.
- [ ] Check a mission with a source-listed coordinate, such as Immortal Sentries. It should show Naja Salaheem, Salaheem's Sentinels / Aht Urhgan Whitegate, and I-10.
- [ ] Check a mission whose header has no separate start. It should explicitly say `No separate start listed` and `Continues from previous mission`, not invent an NPC or coordinate.
- [ ] Open Zilart mission 9 and mission 14 Source buttons. Confirm they lead to `Ro'Maeve(Mission)` and `Ark Angels` respectively.
- [ ] Confirm Current/Completed/Unknown states and progress totals are identical to the prior profile; this pass changes reference details only.

### Conservative quest-gap resolution (foundation.22)

- [ ] Reload HXIChecklist and confirm profile `2026-09-07-foundation.22`; existing character progress, manual marks, filters, exports, quest logs, and mission state must remain unchanged.
- [ ] Expand Bastok's `Shady Business`. Confirm Required Fame shows `Tenshodo Fame 1` and its explanatory note says the linked Quest Header supplied that value.
- [ ] Expand San d'Oria rows whose headers supplied missing starts, such as `Enveloped in Darkness` (I-9), `Prelude of Black and White` (H-8), and `Methods Create Madness` (F-7).
- [ ] Check representative recovered fame values in Windurst, Jeuno, Other Areas, and Outlands. Region labels must follow the explicit header, including Norg or Tavnazian Safehold where applicable.
- [ ] Confirm the row whose source explicitly gives `Altar Room (-)` displays coordinate `N/A`, rather than inventing a grid coordinate.
- [ ] Enable Show unknown and confirm unresolved rows such as `A Proper Burial` remain Unknown. The profile must still contain 107 Unknown quest availability rows; the three `Verification Needed` Other Areas entries must not be promoted.
- [ ] Confirm remaining `Not listed` and blank detail fields are still explicit or absent when neither the refreshed category nor linked Quest Header supplies a safe value.
- [ ] Open several Source buttons and compare the displayed fact to the linked HorizonXI page. Report source drift separately; do not infer availability from a wiki listing.

### Job unlocks (0.23.0 / foundation.23)

- [ ] Copy all runtime Lua files, reload, and confirm version `0.23.0` with profile `2026-09-07-foundation.23`. Existing quest/mission caches, manual marks, settings, and exports must remain unchanged.
- [ ] Open **Job Unlocks** and confirm exactly 12 rows: PLD, DRK, BST, BRD, RNG, SMN, SAM, NIN, DRG, BLU, COR, and PUP. Starting jobs and DNC/SCH must not appear.
- [ ] Compare several jobs against the in-game Jobs list. Any job with a level of at least 1 must show `Unlocked` and its current level; an unavailable advanced job must show `Locked`.
- [ ] Test immediately after login and while zoning. If character job levels have not arrived, rows must remain `UNKNOWN` rather than briefly showing every job locked.
- [ ] Switch among All, Original, Rise of the Zilart, and Treasures of Aht Urhgan views. Confirm counts 12, 5, 4, and 3, and verify search plus the existing status visibility filters.
- [ ] Expand representative rows from each era and compare unlock quest, NPC, location, coordinates, rewards, prerequisites, and Source link with the referenced quest. These details must not affect unlock state.
- [ ] Drag both table dividers at 75/100/150% scale and narrow/wide widths. Job, Source, and Unlock Quest / Level columns must remain readable and aligned.
- [ ] Export the visible Job Unlocks rows and confirm the TSV includes status, job, abbreviation, current level, era, unlock quest, details, and Source URL.
- [ ] Confirm ordinary use does not write new job state to character settings, request packets, or alter gameplay state.

### Quest-unlocked weapon skills (0.24.0 / foundation.24)

- [ ] Copy all runtime Lua files, reload, and confirm version `0.24.0` with profile `2026-09-07-foundation.24`. Existing character settings, quest/mission caches, manual marks, and exports must remain intact.
- [ ] Open **Weapon Skills** and confirm exactly 14 rows, covering Hand-to-Hand, Dagger, Sword, Great Sword, Axe, Great Axe, Scythe, Polearm, Katana, Great Katana, Club, Staff, Archery, and Marksmanship.
- [ ] Compare completed WSNM quests with their mirror rows. Completed must show `Unlocked`, an accepted but unfinished unlock quest must show `In progress`, and a quest with neither bit set must show `Locked`.
- [ ] Confirm the overall header totals are unchanged from foundation.23. The Weapon Skills tab has its own 14-row summary, but the mirrored quests must not be counted twice globally.
- [ ] Change main/sub jobs and equipped weapons. Weapon-skill completion rows must remain based on quest history; currently usable command-list changes must not turn completed skills into Locked.
- [ ] Switch among All Weapon Types and every individual weapon filter. Verify search and the existing completed, accepted/current, missing/open, unknown, and unavailable filters.
- [ ] Expand representative rows and compare NPC, location, coordinates, rewards, prerequisites, and Source with the matching unlock quest.
- [ ] Drag both dividers at 75/100/150% scale and narrow/wide widths. Weapon Skill, Source, and Weapon / Unlock Quest columns must remain readable and aligned.
- [ ] Export the visible rows and confirm the TSV includes status, weapon skill, weapon type, unlock quest, details, and Source URL.
- [ ] Confirm the category does not request packets, invoke weapon skills, target, move, send chat, or add a new saved-state field.

### Access and travel unlocks (0.25.0 / foundation.25)

- [ ] Copy all runtime Lua files, reload, and confirm version `0.25.0` with profile `2026-09-08-foundation.25`. Existing settings, key-item/quest/mission caches, manual marks, and exports must remain intact.
- [ ] Confirm the top-level tabs are ordered Quests, Missions, Magic Skills, and Others/Key Items. Inside Others/Key Items, confirm Maps, Access & Travel, Job Unlocks, Weapon Skills, and Skill Levels are available without crowding the main tab bar.
- [ ] Open **Access & Travel** and confirm exactly 10 rows: four Travel Services and six Gate Crystals. Jugner, Pashhow, Meriphataud, temporary mission keys, and repeatable permits must not appear.
- [ ] Compare the Airship Pass, Airship Pass for Kazham, Chocobo License, and Boarding Permit rows with the character's Key Items menu. Owned keys must show `Unlocked`; an observed absent key in a received packet group must show `Locked`.
- [ ] Compare the Holla, Dem, Mea, Vahzl, Yhoator, and Altepa crystals. Confirm the displayed acquisition text and Source links match the relevant HorizonXI pages.
- [ ] On a first-time character before the relevant `0x055` group arrives, or after deliberately breaking a resource-name fixture, confirm affected rows stay `UNKNOWN` rather than Locked.
- [ ] Switch among All Unlocks, Travel Services, and Gate Crystals. Verify counts 10, 4, and 6 plus search and the existing status visibility filters.
- [ ] Drag both table dividers at 75/100/150% scale and narrow/wide widths. Unlock, Source, and Obtained columns must remain readable and aligned.
- [ ] Export each view and confirm the TSV includes status, unlock, category, acquisition, travel use, and Source URL.
- [ ] Confirm the category does not request packets, change gameplay state, or create a new saved-data field; it must reuse the existing character key-item cache.

## Magic ranges and inventory expansions (0.27.0)

- [ ] Confirm Magic Skills order: Spells, Songs, Summoning, Ninjutsu, Blue Magic. Under Spells, confirm All plus six schools, each with independent level ranges.
- [ ] Compare a multi-job spell's lowest requirement against the range. Verify boundaries 20/21, 40/41, 60/61 and the corresponding visible export. All Levels must include rows lacking level metadata.
- [ ] After login/zoning, compare displayed Gobbiebag, Mog Safe, and Mog Locker capacities with the in-game menus. Locker zero/unreadable must remain Unknown; capacity alone must never claim current lease access.
- [ ] Check thresholds (for example, capacity 60 reaches Gobbiebag I–VI but not VII/VIII), container selection, status/search filters, draggable columns, and TSV export.
- [ ] Confirm the eleven linked quest rows still show their real quest-log status and local quest totals. Overall progress counts the capacity milestones once.
- [ ] Test another character and an unloaded/login screen to ensure no previous character capacity persists. No new saves or gameplay actions should occur.

## Crafting and compact UI (0.28.0)

- [ ] Confirm the blue heading is `HXIChecklist v0.28.0`, the long intro is hidden, and ordinary text is softer. Hover the heading/category `(?)` for notes; verify tooltips wrap normally.
- [ ] Compare all nine craft skills and ranks with the in-game skill menu, including an untrained craft. Confirm integer skill values are displayed without decimal rescaling.
- [ ] Compare the next promotion item with the guild NPC/Source. The selection must follow the actual rank, including after an early test, not a rank inferred from skill.
- [ ] Verify Veteran shows no further listed test and unknown ranks do not select an item. Test first login, zoning, character switching, and refresh for stale/unloaded values.
- [ ] Check search by craft/item, TSV export, Source buttons, and draggable columns at normal/narrow widths and 75–150% scale. Crafting must not alter checklist totals or saved data.

## Safety observation

- [ ] For v0.29.0, compare Crafting/Inventory/Skill Levels dividers at narrow/wide widths and 75–150% scale. Skill Levels should show Skill, Level, Status with draggable columns; verify 0 remains a visible value.
- [ ] Compare Dynamis and Dungeon Access key items against the character key-item list after zoning. Check all four city items separately; one item must not imply full Beaucedine access. Unresolved resource names must stay Unknown.
- [ ] Export the new groups and confirm six Dynamis rows and two Dungeon Access rows before visibility filters. No Sea/Limbus consumed entry items should be included.

- [ ] Confirm ordinary play produces no addon-generated actions, targeting, movement, or chat.
- [ ] Confirm unload/reload does not alter game state.
- [ ] Record the exact addon commit, Ashita build, private-server build, and any discrepancies.

Do not promote a successful private-server check to a claim of HorizonXI compatibility. Before any HorizonXI use, prepare the exact release diff and follow the current server approval process.
