# HorizonChecklist repository / HXIChecklist addon

HXIChecklist is a source-only Ashita v4 checklist foundation for private-server testing. It is behaviorally inspired by [XIchecklist](https://github.com/HiPotionQ8/XIchecklist), but this implementation is written for Ashita v4 and uses a deliberately bounded HorizonXI-oriented profile.

Version 0.6.3 is not a complete HorizonXI checklist. It includes four bounded pieces:

- live, read-only ownership for 316 sourced level-75-cap spells, summons, ninjutsu, and songs in nine catalogs;
- live, read-only map key-item ownership from the incoming `0x055` key-item log;
- passive current/completed state for the 19-entry Bastok quest pilot, with no manual completion fallback.
- live numeric values and client-reported cap flags for eleven magic-related skills.

The `Magic Skills` tab has a compact `Category` selector for `All Magic`, `Dark Magic`, `Divine Magic`, `Elemental Magic`, `Enfeebling Magic`, `Enhancing Magic`, `Healing Magic`, `Summoning`, `Ninjutsu`, and `Songs`. These remain learned-ownership catalog views. Magic rows align their Source buttons and show comma-separated level-75-era job requirements from the validated client spell resource, such as `DRK Lv.61`; multi-job spells list each applicable job. The visible column separators can be dragged horizontally, and the initial spell column keeps Source buttons closer to the names. When the requirement column is narrow, multi-job text switches to a shorter form and exposes the full form on hover. The separate `Skill Levels` tab reads Divine, Healing, Enhancing, Enfeebling, Elemental, Dark, Summoning, Ninjutsu, Singing, String Instrument, and Wind Instrument values directly from Ashita.

It passively reads the incoming `0x055` key-item and `0x056` quest logs and registers no outgoing packet handler. It injects, modifies, blocks, or requests no game packet, sends no gameplay input, writes no game memory, and performs no runtime web requests. The only blocked input is its own `/hc` addon command so the command is not sent to the game server.

## Safety and server status

This repository is for local private-server evaluation. It has not been submitted to or approved by HorizonXI, and it should not be represented as an approved HorizonXI addon. Keep it out of a live HorizonXI installation until the server's addon review process has approved the exact release you intend to use.

## Install for a private Ashita v4 test

1. Copy the `HXIChecklist` folder from this repository into the private test client's `addons` directory. Do not copy the repository's outer `HorizonChecklist` folder.
2. Start the test client and log into a character.
3. Run `/addon load HXIChecklist`.
4. Use `/hc` to toggle the window.

The copy-ready folder contains exactly the required runtime files:

- `HXIChecklist.lua`
- `catalog.lua`
- `checklist_ui.lua`
- `horizon_profile.lua`
- `job_levels.lua`
- `key_item_state.lua`
- `magic_data.lua`
- `quest_state.lua`
- `skill_levels.lua`

Copy the whole `HXIChecklist` folder so these nine files stay together.

## Commands

- `/hc`, `/hcheck`, `/hxichecklist`, or `/horizonchecklist`: toggle the window.
- `/hc show` and `/hc hide`: explicitly show or hide it.
- `/hc refresh`: clear resource-name caches and refresh the snapshot.
- `/hc status`: print the current profile summary.
- `/hc scale <75-150>`: adjust window font scale.

The on-screen Scale slider and `/hc scale` command resize the addon's text using Ashita v4's font-stack API when the older per-window scaling call is unavailable.

## State labels

- `Checked` / `Missing`: read from the logged-in character through Ashita. Imported spells are resolved by explicit client ID plus English name and magic-skill validation.
- `Completed` / `Accepted` / `Not Accepted`: decoded from both incoming Bastok quest logs. `Not Accepted` claims only that neither bit is set, not that the quest is currently obtainable.
- `UNKNOWN`: the client state or source status is unresolved and is excluded from the denominator.
- `UNAVAILABLE`: the source reports the entry inactive; it is excluded from the denominator.

`Wiki-listed` is evidence that a wiki page exists, not proof that the content is currently active or matches every server detail. See [docs/SOURCES.md](docs/SOURCES.md) for provenance and [docs/VALIDATION.md](docs/VALIDATION.md) for the private-server checklist.

Map and Bastok quest packet state are cached in Ashita's existing character-specific settings folder, keyed by character name and server ID. Reloading the addon or logging back into the same character can reuse the cache without zoning. A character with no valid cache shows `UNKNOWN` and must zone once so the client sends the incoming logs; the addon never requests them.

Each incoming key-item or complete Bastok quest-log update refreshes that character's cache. The versioned `cached_state` container is the extension point for future packet-derived categories. Direct spell ownership remains live-only because Ashita exposes it immediately; it does not need or write a spell cache.

Numeric skill levels are also live-only and are deliberately separate from the checklist-state system. They do not change progress totals, ownership labels, filters, or cached packet state. `Capped` and `Training` report only Ashita's current client cap flag; the addon does not calculate a job- or level-specific maximum.

## Data compatibility

Existing legacy manual-mark values are left untouched in settings for compatibility but are no longer displayed or used by the mapped Bastok pilot. Cached packet state uses Ashita's character-scoped settings; switching characters loads a different cache. Future profile growth should retain existing IDs and extend the versioned cache without silently converting unknown state into missing or complete.

## Explicitly deferred

- missions, fame, RoE, objectives, other quest regions, and quests outside the 19-entry Bastok pilot;
- calculated skill caps, equipment or food bonuses, and skill-history tracking;
- other magic systems such as blue magic and geomancy unless separately sourced and reviewed;
- retail-only XIchecklist categories not verified against HorizonXI;
- automatic imports from upstream or the HorizonXI wiki;
- live HorizonXI deployment, publishing, or approval submission.

The quest pilot should be validated independently on the local private server before its packet mapping or profile scope is expanded.
