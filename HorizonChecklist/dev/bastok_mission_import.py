"""Emit a reviewed Bastok mission catalog patch from explicit local evidence."""
import re
import sys
from pathlib import Path
from quest_detail_table import lua_string, plain
from quest_wikitext import api_pages, header_fields, wiki_plain


def build(index_markdown, raw_pages, story):
    block = story.split('bastokmissions = T{', 1)[1].split('windurstmissions = T{', 1)[0]
    mapping = {name: int(index) for index, name in re.findall(r'^\s*\[(\d+)\] = \{name = "([^"]+)"', block, re.M)}
    rows = []
    for line in index_markdown.splitlines():
        if not line.startswith('|'): continue
        match = re.search(r'\[([^\]]+)\]\(https://horizonffxi.wiki/Bastok_Mission_(\d-\d)', line)
        if not match: continue
        name, number = match.groups()
        if name not in mapping: raise ValueError('Unmapped mission: ' + name)
        page = raw_pages['Bastok Mission ' + number]
        fields = header_fields(page.replace('{{Mission Header', '{{Quest Header', 1))
        if fields.get('mission name') != name: raise ValueError('Title mismatch: ' + number)
        reward = fields.get('rewards') or fields.get('reward')
        requirement = 'Bastok allegiance; sufficient rank points may be needed (see Source).'
        previous = fields.get('previous', '').split('{{!}}')[-1].strip()
        if previous:
            requirement += ' Previous mission listed: ' + previous + ' (sequence reference, not a verified mandatory gate).'
        if number == '3-2': requirement += ' This mission is optional.'
        if number == '3-3': requirement += ' Delkfutt Key or Delkfutt Key (Item) needed during the mission; obtain it if missing.'
        if number == '4-1': requirement += ' Magicite access prerequisites apply; see the linked shared walkthrough for alternatives and already-completed nation access.'
        if number == '6-2': requirement += ' Rise of the Zilart must be started to open the Oaken Door to Gilgamesh.'
        # Infobox Level may be a recommendation or battlefield cap, not an entry gate.
        if fields.get('level'): requirement += ' Source level note: ' + wiki_plain(fields['level']) + ' (see Source for context).'
        requirement += ' Partial reference only; other conditions may apply.'
        entry = {
            'id': 'bastok.mission.%03d' % mapping[name], 'kind': 'mission', 'mission_area': 'bastok',
            'mission_index': mapping[name], 'mission_number': number, 'mission_rank': int(number[0]),
            'name': name, 'mission_type': plain(line.strip('|').split('|')[-2]),
            'npc': 'Any Bastok Gate Guard', 'quest_location': 'Bastok gate-guard locations',
            'npc_coordinates': 'Argus: Port Bastok L-7; Cleades: Bastok Markets D-11; Malduc: Metalworks J-8; Rashid: Bastok Mines H-10',
            'rewards': wiki_plain(reward) + ' (see Source for conditions)', 'prerequisites': requirement,
            'availability': 'wiki_listed',
            'description': 'HorizonXI-listed Bastok mission ' + number + '. A wiki listing is not proof of current server availability.',
            'source_url': 'https://horizonffxi.wiki/Bastok_Mission_' + number,
        }
        if number == '4-1':
            entry.update(npc='Goggehn, then the embassy back door', quest_location="Ru'Lude Gardens", npc_coordinates='H-10 (Bastokan Embassy)')
        rows.append(entry)
    if len(rows) != 20 or len({row['id'] for row in rows}) != 20: raise ValueError('Expected 20 unique missions')
    return rows


def render(rows):
    output = ["local data = {};", "", "-- Main mission IDs: XIchecklist 04baf17b2b0373883407a94ce0b6a72274a31ba6.",
              "-- Names/details: HorizonXI Bastok mission pages, reviewed 2026-09-04.",
              "-- Emissary travel stages 6-9 share row 5; only bit 5 completes that row.",
              "data.source_url = 'https://horizonffxi.wiki/Category:Bastok_Missions';", "data.views = {", "    { id = 'all', name = 'All Ranks' },"]
    for rank in range(1, 10): output.append("    { id = 'rank_%d', name = 'Rank %d', mission_rank = %d }," % (rank, rank, rank))
    output += ['};', 'data.entries = {']
    for row in rows:
        output.append('    { ' + ', '.join(key + ' = ' + (str(value) if isinstance(value, int) else lua_string(value)) for key, value in row.items()) + ' },')
    return '\n'.join(output + ['};', 'return data;', ''])


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8', newline='\n')
    rows = build(Path('.firecrawl/bastok-missions.md').read_text(encoding='utf-8'),
                 api_pages([Path('.firecrawl/bastok-missions-raw-api.json')]),
                 Path('../.firecrawl/xichecklist-upstream/maps/story.lua').read_text(encoding='utf-8'))
    target = (Path('HXIChecklist') / 'bastok_mission_data.lua').resolve().as_posix()
    print('*** Begin Patch\n*** Add File: ' + target)
    for line in render(rows).splitlines(): print('+' + line)
    print('*** End Patch')
