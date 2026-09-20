# HXIChecklist

HXIChecklist is a read-only checklist addon for Final Fantasy XI on Ashita v4. It helps you review character progress using a HorizonXI-oriented catalog and links every sourced entry back to the HorizonXI Wiki.

Current version: **0.21.0**

Profile: **2026-09-07-foundation.20**

> [!IMPORTANT]
> HXIChecklist has not been approved by HorizonXI. The current build is intended for private-server testing until the exact release has completed HorizonXI's addon review process.

## Features

- Checks ownership of 316 spells, summons, ninjutsu, and songs.
- Shows live values for 11 magic-related skills.
- Tracks 72 map key items and shows where each map is obtained.
- Tracks the client quest logs for Bastok, San d'Oria, Windurst, Jeuno, Other Areas, Outlands, and Aht Urhgan.
- Includes four Horizon-specific quests with optional per-character manual completion.
- Tracks San d'Oria, Bastok, Windurst, Rise of the Zilart, Chains of Promathia, and Treasures of Aht Urhgan missions.
- Provides search, visibility, area, location, quest-type, rank, and current/accepted filters.
- Shows expandable NPC, coordinates, rewards, and prerequisite references where sourced.
- Keeps Source buttons and draggable table dividers available throughout the main lists.

The addon only reads character data and incoming logs. It does not send or request packets, automate gameplay, move the character, target anything, send chat, write game memory, or access the web while running.

## Installation

1. Download the ZIP from the [latest release](https://github.com/ryuutatsuo23-max/HorizonChecklist/releases/latest).
2. Extract the included `HXIChecklist` folder into your Ashita v4 `addons` directory.
3. Log into a character and run:

```text
/addon load HXIChecklist
```

4. Use `/hc` to show or hide the window.
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
| `/hc scale 75-150` | Set the interface scale percentage |

The longer aliases `/hcheck`, `/hxichecklist`, and `/horizonchecklist` also toggle the window.

## Understanding the labels

- **Checked / Missing:** spell or map ownership read from the character.
- **Completed / Accepted / Not Accepted:** quest-log bits reported by the client. Not Accepted only means neither client bit is set; it does not guarantee that a quest is currently obtainable.
- **Current**, **Current / Done**, **Not current:** mission-log state. Earlier missions are never assumed complete from rank or story order. Promathia has current-only tracking, so non-current rows remain UNKNOWN.
- **Manual / Manual done:** completion marked by you for a supported Horizon-specific quest.
- **UNKNOWN:** the addon does not have enough client or source evidence. It is excluded from progress totals.
- **UNAVAILABLE:** the reviewed source reports the entry inactive. It is excluded from progress totals.

Wiki-listed information is reference material, not proof that every entry is currently active or that every requirement applies unchanged. Missing information remains visibly unknown instead of being guessed.

## Saved data

Quest logs, map ownership, mission state, and manual custom-quest marks are stored through Ashita's character-specific settings. Switching characters loads a separate cache. Search, dropdown choices, Current/Accepted-only filters, and expanded rows are session-only.

## Current scope

This is an intentionally incomplete foundation. Wings of the Goddess and later storylines, Assaults, live fame points, Records of Eminence, objectives, calculated skill caps, equipment/food bonuses, blue magic, and geomancy are not included yet. The HorizonXI Wiki currently labels its Aht Urhgan mission list as planned content, so those rows are reference-first and do not claim server availability.

For the technical evidence, packet boundaries, catalog decisions, and known uncertainty, see [Source notes](docs/SOURCES.md). For manual testing steps, see the [Validation checklist](docs/VALIDATION.md). Credits and upstream acknowledgements are in [CREDITS.md](CREDITS.md).

## License

HXIChecklist is available under the [MIT License](LICENSE).
