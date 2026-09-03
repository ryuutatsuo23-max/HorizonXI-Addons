# HorizonChecklist repository / HXIChecklist addon

HXIChecklist is a source-only Ashita v4 checklist foundation for private-server testing. It is behaviorally inspired by [XIchecklist](https://github.com/HiPotionQ8/XIchecklist), but this implementation is written for Ashita v4 and uses a deliberately small HorizonXI-oriented starter profile.

Version 0.3.0 is not a complete HorizonXI checklist. It proves three narrow pieces:

- live, read-only spell ownership through `IPlayer:HasSpell`;
- live, read-only map key-item ownership from the incoming `0x055` key-item log;
- passive current/completed state for the 19-entry Bastok quest pilot, with no manual completion fallback.

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
- `key_item_state.lua`
- `quest_state.lua`

Copy the whole `HXIChecklist` folder so these six files stay together.

## Commands

- `/hc`, `/hcheck`, `/hxichecklist`, or `/horizonchecklist`: toggle the window.
- `/hc show` and `/hc hide`: explicitly show or hide it.
- `/hc refresh`: clear resource-name caches and refresh the snapshot.
- `/hc status`: print the current profile summary.
- `/hc scale <75-150>`: adjust window font scale.

## State labels

- `Checked` / `Missing`: read from the logged-in character through Ashita.
- `Completed` / `Accepted` / `Not Accepted`: decoded from both incoming Bastok quest logs. `Not Accepted` claims only that neither bit is set, not that the quest is currently obtainable.
- `UNKNOWN`: the client state or source status is unresolved and is excluded from the denominator.
- `UNAVAILABLE`: the source reports the entry inactive; it is excluded from the denominator.

`Wiki-listed` is evidence that a wiki page exists, not proof that the content is currently active or matches every server detail. See [docs/SOURCES.md](docs/SOURCES.md) for provenance and [docs/VALIDATION.md](docs/VALIDATION.md) for the private-server checklist.

Map and Bastok quest packet state are cached in Ashita's existing character-specific settings folder, keyed by character name and server ID. Reloading the addon or logging back into the same character can reuse the cache without zoning. A character with no valid cache shows `UNKNOWN` and must zone once so the client sends the incoming logs; the addon never requests them.

Each incoming key-item or complete Bastok quest-log update refreshes that character's cache. The versioned `cached_state` container is the extension point for future packet-derived categories. Direct spell ownership remains live-only because Ashita exposes it immediately.

## Data compatibility

Existing legacy manual-mark values are left untouched in settings for compatibility but are no longer displayed or used by the mapped Bastok pilot. Cached packet state uses Ashita's character-scoped settings; switching characters loads a different cache. Future profile growth should retain existing IDs and extend the versioned cache without silently converting unknown state into missing or complete.

## Explicitly deferred

- missions, fame, RoE, objectives, other quest regions, and quests outside the 19-entry Bastok pilot;
- retail-only XIchecklist categories not verified against HorizonXI;
- automatic imports from upstream or the HorizonXI wiki;
- live HorizonXI deployment, publishing, or approval submission.

The quest pilot should be validated independently on the local private server before its packet mapping or profile scope is expanded.
