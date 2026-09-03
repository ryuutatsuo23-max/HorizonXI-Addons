# Private-server validation checklist

Use a local private Ashita v4 server/client first. This is not a HorizonXI approval or deployment procedure.

## Load and settings

- [ ] Copy the inner `HXIChecklist` folder to the private client's `addons` directory.
- [ ] Load with `/addon load HXIChecklist` and confirm no Lua error.
- [ ] Toggle with `/hc`; show/hide and window close should remain synchronized.
- [ ] Change scale and filters, reload the addon, and confirm they persist for that character.
- [ ] Compare 75%, 100%, and 150% and confirm the addon text visibly changes size at each setting.
- [ ] On a character with no cache, confirm the Bastok pilot shows no manual checkboxes and unresolved rows are `UNKNOWN`.
- [ ] After receiving the logs once, unload/reload the addon without zoning and confirm map and Bastok quest states restore from cache.
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

## Maps and quest live state

- [ ] On first use for a character, zone once so the incoming key-item and quest logs are received.
- [ ] Open `Maps` and confirm its selector contains, in order: All Maps, Original Areas, Rise of the Zilart, Chains of Promathia, Treasures of Aht Urhgan.
- [ ] With completed entries visible, confirm `All Maps` contains 72 rows and the individual categories contain 28, 16, 17, and 11 rows respectively.
- [ ] Compare at least one owned and one unowned map in each available expansion category against Key Items.
- [ ] Confirm an Aht Urhgan map resolves after zoning; these IDs exercise key-item group 3 rather than the original-area group 0.
- [ ] Open several map Source buttons. Existing map pages should open directly; category-only evidence rows should open the HorizonXI Magical Maps table.
- [ ] Confirm map Source buttons align vertically beside the map names.
- [ ] Confirm the Price column shows `200 gil` for the three nation-area maps, `600 gil` for the Jeuno Area, and `3,000 gil` for Qufim Island.
- [ ] In Treasures of Aht Urhgan, confirm Al Zahbi shows `600 gil`, Nashmau shows `3,000 gil`, and Mamook, Arrapago Reef, and Halvung show `2,000 Imperial Standing`.
- [ ] Confirm a quest-, chest-, or coffer-only map shows a neutral dash in Price; hovering it should explain that the Map Guide lists no vendor price.
- [ ] Drag both Maps dividers and confirm Map, Source, and Price columns resize without overlap, including the long Imperial Standing values.
- [ ] Before that first zone, confirm unresolved map state is `UNKNOWN`, never falsely `Missing`.
- [ ] Before that first zone and with no cache, confirm Bastok pilot rows are `UNKNOWN` and have no checkboxes.
- [ ] After zoning, compare one current, one completed, and one neither-current-nor-completed pilot quest against the in-game Bastok quest logs; expect `Accepted`, `Completed`, and `Not Accepted`.
- [ ] Test immediately after login or zoning; unresolved client data must show `UNKNOWN`, never a false missing state.
- [ ] Use `/hc refresh` after login and verify unresolved resource names remain explicit.

## Evidence and totals

- [ ] Confirm `HXQ-0003` displays `UNKNOWN` and is excluded from the denominator.
- [ ] Enable `Show unavailable`; confirm `HXQ-0012` displays `UNAVAILABLE` and is excluded.
- [ ] Open several Source buttons and confirm they lead to the expected HorizonXI Wiki pages.
- [ ] Confirm the header clearly says the profile is intentionally incomplete.

## Safety observation

- [ ] Confirm ordinary play produces no addon-generated actions, targeting, movement, or chat.
- [ ] Confirm unload/reload does not alter game state.
- [ ] Record the exact addon commit, Ashita build, private-server build, and any discrepancies.

Do not promote a successful private-server check to a claim of HorizonXI compatibility. Before any HorizonXI use, prepare the exact release diff and follow the current server approval process.
