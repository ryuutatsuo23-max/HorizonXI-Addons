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

## Skill Levels

- [ ] Open `Skill Levels` and confirm it lists, in order: Divine, Healing, Enhancing, Enfeebling, Elemental, Dark, Summoning, Ninjutsu, Singing, String Instrument, and Wind Instrument.
- [ ] Compare several displayed numbers, including Singing and both instrument skills, with the in-game Skills menu.
- [ ] Compare at least one capped and one uncapped skill; confirm the rows show `Capped` and `Training` consistently with the client.
- [ ] Confirm opening or refreshing `Skill Levels` does not change the header progress totals or any Magic Skills ownership label.
- [ ] Reload the addon and switch characters; confirm values are read live for the active character without requiring a zone or reusing cached values.
- [ ] Check the view before character data is available and confirm it shows `Unavailable` rather than a guessed zero.

## Quest navigation

- [ ] Confirm the top-level tabs are `Magic Skills`, `Maps`, `Quests`, and `Skill Levels`.
- [ ] Open `Quests` and switch the `Area` dropdown among Bastok, San d'Oria, Windurst, Jeuno, and Other Areas; confirm descriptions, area totals, rows, and Fame labels follow the selected area without changing overall progress.
- [ ] Choose a different `Location` in each area, switch away and back, and confirm each selection is retained during the session.
- [ ] Confirm Magic Skills and Maps still use their existing `Category` selectors.
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

## Safety observation

- [ ] Confirm ordinary play produces no addon-generated actions, targeting, movement, or chat.
- [ ] Confirm unload/reload does not alter game state.
- [ ] Record the exact addon commit, Ashita build, private-server build, and any discrepancies.

Do not promote a successful private-server check to a claim of HorizonXI compatibility. Before any HorizonXI use, prepare the exact release diff and follow the current server approval process.
