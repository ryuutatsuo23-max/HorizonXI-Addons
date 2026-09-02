# HorizonChecklist repository / HXIChecklist addon

HXIChecklist is a source-only Ashita v4 checklist foundation for private-server testing. It is behaviorally inspired by [XIchecklist](https://github.com/HiPotionQ8/XIchecklist), but this implementation is written for Ashita v4 and uses a deliberately small HorizonXI-oriented starter profile.

Version 0.1.2 is not a complete HorizonXI checklist. It proves three narrow pieces:

- live, read-only spell ownership through `IPlayer:HasSpell`;
- live, read-only map key-item ownership from the incoming `0x055` key-item log;
- per-character manual quest marks for the sourced Bastok Markets pilot.

It passively reads the incoming `0x055` key-item log and registers no outgoing packet handler. It injects, modifies, or blocks no game packet, sends no gameplay input, writes no game memory, and performs no runtime web requests. The only blocked input is its own `/hc` addon command so the command is not sent to the game server.

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

Copy the whole `HXIChecklist` folder so these five files stay together.

## Commands

- `/hc`, `/hcheck`, `/hxichecklist`, or `/horizonchecklist`: toggle the window.
- `/hc show` and `/hc hide`: explicitly show or hide it.
- `/hc refresh`: clear resource-name caches and refresh the snapshot.
- `/hc status`: print the current profile summary.
- `/hc scale <75-150>`: adjust window font scale.

## State labels

- `LIVE DONE` / `LIVE MISSING`: read from the logged-in character through Ashita.
- `MANUAL DONE` / `MANUAL`: a per-character user checkbox; no quest flag is claimed.
- `UNKNOWN`: the client state or source status is unresolved and is excluded from the denominator.
- `UNAVAILABLE`: the source reports the entry inactive; it is excluded from the denominator.

`Wiki-listed` is evidence that a wiki page exists, not proof that the content is currently active or matches every server detail. See [docs/SOURCES.md](docs/SOURCES.md) for provenance and [docs/VALIDATION.md](docs/VALIDATION.md) for the private-server checklist.

Map state remains `UNKNOWN` until the client receives its key-item log. Zone once after loading or reloading HXIChecklist; the incoming log is then decoded without sending a request.

## Data compatibility

Manual marks are keyed by stable profile IDs and saved using Ashita's character-scoped settings. Future profile growth should retain existing IDs. Unknown or inactive entries are preserved rather than silently discarded or treated as complete.

## Explicitly deferred

- packet-derived quest, mission, fame, RoE, and objective state;
- retail-only XIchecklist categories not verified against HorizonXI;
- automatic imports from upstream or the HorizonXI wiki;
- live HorizonXI deployment, publishing, or approval submission.

The next sensible phase is a single, bounded quest-flag pilot using private-server packet captures and synthetic fixtures. That phase should be reviewed independently before expanding the profile.
