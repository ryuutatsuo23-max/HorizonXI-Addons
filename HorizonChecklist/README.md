# HXIChecklist

HXIChecklist is a read-only checklist addon for Final Fantasy XI on Ashita v4. It helps you review character progress using a HorizonXI-oriented catalog and links every sourced entry back to the HorizonXI Wiki.

Current version: **0.29.1**

Profile: **2026-09-08-foundation.29**

> [!IMPORTANT]
> HXIChecklist has not been approved by HorizonXI. The current build is intended for private-server testing until the exact release has completed HorizonXI's addon review process.

## Features

- Checks ownership of 316 spells, summons, ninjutsu, and songs.
- Tracks 106 level-75-era Blue Magic spells with sourced learn levels, spell types, and set traits.
- Magic Skills contains Spells, Songs, Summoning, Ninjutsu, and Blue Magic. Each has level ranges (1–20, 21–40, 41–60, 61–75), including every Spells category. Spells use the lowest listed job requirement; all requirements stay visible. Export visible follows the selected subtab and filters.
- Inventory Expansions tracks 17 capacity milestones for Gobbiebag, Mog Safe, and Mog Locker. The 11 linked quest rows keep their quest-log status but do not count again in overall progress. Unreadable capacities stay Unknown; Locker lease status is not tracked.
- Crafting shows nine live skills/ranks and the next guild-test item. Search and export work; checklist status filters and totals do not apply. Recipes and guild key items are excluded.
- Hover the blue heading or a category's `(?)` for detailed notes.
- Access & Travel includes permanent Dynamis and dungeon-access key items. Sea remains mission-based; consumed Limbus entry items are excluded. Skill Levels now uses a resizable table, with clearer dividers throughout the addon.
- Shows live values for 11 magic-related skills.
- Tracks 72 map key items and shows where each map is obtained.
- Tracks 10 permanent access and travel unlocks directly from character key items.
- Tracks all 12 Horizon-era advanced job unlocks directly from character job levels.
- Tracks the 14 level-75-era quest-unlocked weapon skills from validated quest logs without counting those quests twice in overall progress.
- Tracks the client quest logs for Bastok, San d'Oria, Windurst, Jeuno, Other Areas, Outlands, and Aht Urhgan.
- Includes four Horizon-specific quests with optional per-character manual completion.
- Tracks San d'Oria, Bastok, Windurst, Rise of the Zilart, Chains of Promathia, and Treasures of Aht Urhgan missions.
- Provides search, visibility, area, location, quest-type, rank, and current/accepted filters.
- Keeps the main navigation compact: Quests, Missions, Magic Skills, and a grouped Others/Key Items tab.
- Shows expandable NPC, coordinates, rewards, and prerequisite references where sourced.
- Keeps Source buttons and draggable table dividers available throughout the main lists.
- Exports the rows currently visible on any tab as a spreadsheet-ready TSV file.

The addon only reads character data and incoming logs. It does not send or request packets, automate gameplay, move the character, target anything, send chat, write game memory, or access the web while running.

## Installation

1. Download the ZIP from the [latest release](https://github.com/ryuutatsuo23-max/HorizonChecklist/releases/latest).
2. Extract the included `HXIChecklist` folder into your Ashita v4 `addons` directory.
3. Log into a character and run:

```text
/addon load HXIChecklist
```

4. The window starts hidden. Use `/hc` to show or hide it.
5. Zone once after installing so the client can naturally send its quest and mission logs. Future reloads can use the per-character cache.

To update, replace the complete `HXIChecklist` folder with the folder from the new release. Do not copy the repository's outer folder into `addons`.

## Commands

| Command | Action |
| --- | --- |
| `/hc` | Toggle the window |
| `/hc show` | Show the window |
| `/hc hide` | Hide the window |
| `/hc refresh` | Refresh the displayed state and resource lookups |
| `/hc status` | Print the current profile summary |
| `/hc export` | Export the visible rows from the active tab |
| `/hc scale 75-150` | Set the interface scale percentage |

The longer aliases `/hcheck`, `/hxichecklist`, and `/horizonchecklist` also toggle the window.

The **Export visible** button and `/hc export` use the active tab or active Others/Key Items subtab and its current search, dropdown, visibility, Accepted-only, or Current-only filters. Files are written locally to `addons/HXIChecklist/exports/` as tab-separated `.tsv` files that can be opened or pasted into Google Sheets. They are never uploaded by the addon.

**Show accepted/current** controls active quests and missions. **Show missing/not accepted/not current** controls the remaining known-open rows, including unmarked manual quests. These are independent from Completed, Unknown, and Unavailable so you can export only the status groups you want.

## Understanding the labels

- **Checked / Missing:** scroll, summon, ninjutsu, song, or map ownership read from the character.
- **Learned / Not learned:** Blue Magic ownership read live from the character's spell data.
- **Reached / Not reached:** the observed container capacity meets or falls below an inventory milestone. This does not imply quest completion or an active Mog Locker lease.
- **Unlocked / Locked:** permanent access and travel key items read from the character.
- **Unlocked / Locked:** advanced-job availability read directly from the character's job level.
- **Unlocked / In progress / Locked:** quest-unlocked weapon-skill state read from the corresponding client quest log.
- **Completed / Accepted / Not Accepted:** quest-log bits reported by the client. Not Accepted only means neither client bit is set; it does not guarantee that a quest is currently obtainable.
- **Current**, **Current / Done**, **Not current:** mission-log state. Earlier missions are never assumed complete from rank or story order. Promathia has current-only tracking, so non-current rows remain UNKNOWN.
- **Manual / Manual done:** completion marked by you for a supported Horizon-specific quest.
- **UNKNOWN:** the addon does not have enough client or source evidence. It is excluded from progress totals.
- **UNAVAILABLE:** the reviewed source reports the entry inactive. It is excluded from progress totals.

Wiki-listed information is reference material, not proof that every entry is currently active or that every requirement applies unchanged. Missing information remains visibly unknown instead of being guessed.

## Saved data

Quest logs, key-item ownership, mission state, and manual custom-quest marks are stored through Ashita's character-specific settings. Maps and Access & Travel reuse the same key-item cache; Weapon Skills reuse the quest cache and add no separate saved state; Job Unlocks and Blue Magic are read live and are not saved. Switching characters loads a separate cache. Search, dropdown choices, Current/Accepted-only filters, and expanded rows are session-only.

## Current scope

This is an intentionally incomplete foundation. Wings of the Goddess and later storylines, Assaults, live fame points, Records of Eminence, objectives, skill-level, relic, mythic, and later-era weapon skills, calculated skill caps, equipment/food bonuses, geomancy, and unverified Blue Magic learning locations are not included yet. The HorizonXI Wiki currently labels its Aht Urhgan mission list as planned content, so those rows are reference-first and do not claim server availability.

For the technical evidence, packet boundaries, catalog decisions, and known uncertainty, see [Source notes](docs/SOURCES.md). For manual testing steps, see the [Validation checklist](docs/VALIDATION.md). Credits and upstream acknowledgements are in [CREDITS.md](CREDITS.md).

## License

HXIChecklist is available under the [MIT License](LICENSE).
