# HorizonXI Addons

Four independently loadable Ashita v4 addons by DragoHorse, maintained together in one repository.

| Addon | Purpose | Source folder | In-game load command |
| --- | --- | --- | --- |
| HXIUIBegone | Hide selected parts of the native interface | [HXIUIBegone](HXIUIBegone/) | `/addon load HXIUIBegone` |
| HorizonScout | Nearby tracking, compass radar, alerts, and camp timers | [HorizonScout](HorizonScout/) | `/addon load HorizonScout` |
| HXIChecklist | Character progress checklists | [HorizonChecklist/HXIChecklist](HorizonChecklist/HXIChecklist/) | `/addon load HXIChecklist` |
| HXIPresence | Optional Discord Rich Presence | [HXIPresence](HXIPresence/) | `/addon load HXIPresence` |

## Installation

Install only the addons you want. The combined repository is not itself an addon.

For existing packaged releases, use the original download pages:

- [HXIUIBegone releases](https://github.com/ryuutatsuo23-max/HXIUIBegone/releases)
- [HorizonScout releases](https://github.com/ryuutatsuo23-max/HorizonScout/releases)
- [HorizonChecklist releases](https://github.com/ryuutatsuo23-max/HorizonChecklist/releases)
- [HXIPresence releases](https://github.com/ryuutatsuo23-max/HXIPresence/releases)

To install the current source, download or clone this repository and copy the source folder shown above into `HorizonXI/Game/addons/`. For the checklist, copy the inner `HXIChecklist` folder, not the outer `HorizonChecklist` folder. Do not copy the entire `HorizonXI-Addons` folder into `addons`.

The entrypoints must end up at:

```text
addons/
  HXIUIBegone/HXIUIBegone.lua
  HorizonScout/HorizonScout.lua
  HXIChecklist/HXIChecklist.lua
  HXIPresence/HXIPresence.lua
```

Unload an addon before replacing its files, preserve your existing settings and custom sounds, then load it again. Addon names, commands, and settings formats are unchanged by this consolidation.

Read each addon's README for requirements, usage, and validation limitations. Current source can be newer than the latest packaged release; in particular, HorizonScout's imported main branch is v0.20.1 while its latest original release is v0.16.1. Inclusion here does not extend any individual addon's server approval to other addons or versions.

## Development and history

Each folder retains its original source, documentation, credits, and license. Run existing development tools from the corresponding addon repository folder. See [migration notes](MIGRATION.md) for exact source commits, historical tags, and packaging considerations.

Report new collection issues in [HorizonXI-Addons issues](https://github.com/ryuutatsuo23-max/HorizonXI-Addons/issues), naming the affected addon. Imported addon documentation and in-app links still point to their original repositories.

## Licensing

Licenses apply separately to each addon; this collection does not relicense them:

- HXIUIBegone: [GPL-3.0-or-later](HXIUIBegone/LICENSE), with [credits](HXIUIBegone/CREDITS.md).
- HorizonScout: [MIT](HorizonScout/LICENSE).
- HorizonChecklist / HXIChecklist: [MIT](HorizonChecklist/LICENSE), with [credits](HorizonChecklist/CREDITS.md).
- HXIPresence: [MIT](HXIPresence/LICENSE).
