# Outpost menu diagnostic (0.29.1)

For research only. This does not add an Outpost checklist or interpret unlocks.

1. Copy the complete updated addon folder and reload it.
2. Stand near a home-nation or Jeuno Outpost warp NPC, with its menu closed.
3. Run `/hc outpostdiag arm`, then manually open that NPC's warp menu within 60 seconds. Avoid other NPC interactions while armed.
4. After the capture notice, run `/hc outpostdiag show`. Review the output, then share it with a screenshot of the warp menu and the NPC name, current nation, and main-job level. Identify one destination you know is unlocked and one you know is not. No character name is needed.
5. Use `/hc outpostdiag off` to clear the observation. `/hc outpostdiag status` reports Armed, Captured, or Off.

One capture is retained in memory. Arming again clears the prior capture. Zoning, leaving the zone, settings/profile reload, or addon reload clears it. It expires after 60 seconds without a capture. No addon files, settings, or progress are written by this diagnostic; `show` prints locally in the chat log.

The first non-injected, non-blocked incoming `0x034` menu packet of sufficient length is captured, regardless of NPC. Output contains zone/menu IDs, NPC entity ID/index, and the 32 menu-parameter bytes at offset `0x08`. The parameter meanings are unverified and may include values such as prices or balances. It is not a character packet dump, but review it before sharing. A non-Outpost capture must be discarded, not interpreted.

The diagnostic does not send packets, select menu options, move, warp, or automate interaction. If no capture occurs, report that result and the NPC/menu shown; do not treat it as evidence that destinations are locked. Some interactions may use another packet type, which this narrowly scoped diagnostic intentionally does not record.

Offline verification: synthetic one-shot, timeout, packet-length, injected/blocked-packet, zero/unknown-data, event-preservation, and zoning-reset tests. No live capture has been performed by the agent. Reliable Outpost unlock mapping remains pending comparison of known states and restrictions.
