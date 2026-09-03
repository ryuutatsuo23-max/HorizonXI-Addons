# Private-server validation checklist

Use a local private Ashita v4 server/client first. This is not a HorizonXI approval or deployment procedure.

## Load and settings

- [ ] Copy the inner `HXIChecklist` folder to the private client's `addons` directory.
- [ ] Load with `/addon load HXIChecklist` and confirm no Lua error.
- [ ] Toggle with `/hc`; show/hide and window close should remain synchronized.
- [ ] Change scale and filters, reload the addon, and confirm they persist for that character.
- [ ] On a character with no cache, confirm the Bastok pilot shows no manual checkboxes and unresolved rows are `UNKNOWN`.
- [ ] After receiving the logs once, unload/reload the addon without zoning and confirm map and Bastok quest states restore from cache.
- [ ] Log into another character and confirm it does not inherit the first character's cached state.
- [ ] Return to the first character and confirm its own cache restores.

## Magic Skills

- [ ] Open `Magic Skills` and confirm the inner tabs appear in this order: All Magic, Dark, Divine, Elemental, Enfeebling, Enhancing, Healing.
- [ ] With completed entries visible, confirm `All Magic` contains 200 rows and the skill tabs contain 15, 8, 60, 19, 76, and 22 rows respectively.
- [ ] Compare at least one learned and one unlearned spell in each skill tab against the in-game magic list.
- [ ] Confirm `Sleepga` and `Sleepga II` resolve normally rather than showing `UNKNOWN` from the same-name monster resources.
- [ ] Search for a spell while switching inner tabs; confirm only matching spells in the selected view are shown.
- [ ] Open several spell Source buttons, including `Dispel`, and confirm they lead to the expected HorizonXI Wiki pages.

## Maps and quest live state

- [ ] On first use for a character, zone once so the incoming key-item and quest logs are received.
- [ ] Compare at least one owned and one unowned starter map against Key Items.
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
