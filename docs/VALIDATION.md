# Private-server validation checklist

Use a local private Ashita v4 server/client first. This is not a HorizonXI approval or deployment procedure.

## Load and settings

- [ ] Load with `/addon load HorizonChecklist` and confirm no Lua error.
- [ ] Toggle with `/hc`; show/hide and window close should remain synchronized.
- [ ] Change scale and filters, reload the addon, and confirm they persist for that character.
- [ ] Check one manual quest, reload, and confirm the mark persists for that character only.
- [ ] Verify another character does not inherit the first character's manual marks.

## Live state

- [ ] Compare at least one learned and one unlearned starter spell against the in-game magic list.
- [ ] Compare at least one owned and one unowned starter map against Key Items.
- [ ] Test immediately after login or zoning; unresolved client data must show `UNKNOWN`, never a false missing state.
- [ ] Use `/hc refresh` after login and verify unresolved resource names remain explicit.

## Evidence and totals

- [ ] Confirm `HXQ-0003` displays `UNKNOWN` and is excluded from the denominator.
- [ ] Enable `Show unavailable`; confirm `HXQ-0012` displays `UNAVAILABLE` and is excluded.
- [ ] Confirm checking a manual quest changes only that stable ID.
- [ ] Open several Source buttons and confirm they lead to the expected HorizonXI Wiki pages.
- [ ] Confirm the header clearly says the profile is intentionally incomplete.

## Safety observation

- [ ] Confirm ordinary play produces no addon-generated actions, targeting, movement, or chat.
- [ ] Confirm unload/reload does not alter game state.
- [ ] Record the exact addon commit, Ashita build, private-server build, and any discrepancies.

Do not promote a successful private-server check to a claim of HorizonXI compatibility. Before any HorizonXI use, prepare the exact release diff and follow the current server approval process.
