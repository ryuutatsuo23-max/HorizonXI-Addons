"""Generate reviewed mission catalogs from cached HorizonXI category pages.

This developer tool only consumes saved research files. Packet IDs are matched
to the pinned XIchecklist/LandSandBoat mappings; sequence never implies state.
"""
import re
import sys
from pathlib import Path

from quest_detail_table import lua_string, plain


ROOT = Path(__file__).resolve().parents[1]
WIKI = 'https://horizonffxi.wiki/'


def cells(line):
    return [part.strip() for part in line.strip().strip('|').split('|')]


def link(value):
    matches = re.findall(r'\[([^\[\]]+)\]\((https://horizonffxi\.wiki/[^\s)]+)(?:\s+"[^"]*")?\)', value)
    return matches[-1] if matches else (None, None)


def reward(value):
    value = plain(value or '') or 'Not listed'
    value = re.sub(r'None(?=[A-Z])', 'None; ', value)
    return value + ' (category listing; see Source for conditions)'


def common(area, index, number, name, mission_type, reward_text, source_url, previous=None):
    requirement = 'Previous mission listed: %s (sequence reference only). ' % previous if previous else ''
    requirement += 'See Source for the full starting conditions; sequence is not used to infer completion.'
    return {
        'id': '%s.mission.%03d' % (area, index),
        'kind': 'mission', 'mission_area': area, 'mission_index': index,
        'mission_number': number, 'name': name, 'mission_type': mission_type or 'Not listed',
        'npc': 'See Source', 'quest_location': 'See Source', 'npc_coordinates': 'See Source',
        'rewards': reward(reward_text), 'prerequisites': requirement,
        'availability': 'wiki_listed',
        'description': 'HorizonXI category listing for mission %s. A listing is not proof of current server availability.' % number,
        'source_url': source_url,
    }


def nation(path, area, nation_name):
    rows, rank, previous = [], None, None
    indices = [0, 1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23]
    for raw in path.read_text(encoding='utf-8').splitlines():
        if not raw.startswith('|') or '](' not in raw:
            continue
        values = cells(raw)
        if values[0].startswith('Rank '):
            rank = int(values.pop(0).split()[1])
        if rank is None or len(values) != 3:
            continue
        match = re.match(r'(\d+)\\?\.\s+', values[0])
        name, url = link(values[0])
        if not match or not name or '_Mission_' not in url:
            continue
        number = '%d-%s' % (rank, match.group(1))
        index = indices[len(rows)]
        row = common(area, index, number, name, plain(values[1]), values[2], url, previous)
        row['mission_rank'] = rank
        row['npc'] = 'Any %s Gate Guard' % nation_name
        row['quest_location'] = '%s gate-guard locations' % nation_name
        row['prerequisites'] = '%s allegiance; sufficient rank points may be needed. ' % nation_name + row['prerequisites']
        rows.append(row)
        previous = name
    if len(rows) != 20:
        raise ValueError('%s: expected 20 nation missions, got %d' % (area, len(rows)))
    return rows


def zilart(path):
    packet_ids = [0, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 24, 26, 27, 28, 30, 31]
    rows, previous = [], None
    for raw in path.read_text(encoding='utf-8').splitlines():
        if not raw.startswith('|') or '](' not in raw:
            continue
        values = cells(raw)
        if len(values) != 4 or not values[0].isdigit():
            continue
        number = int(values[0])
        if number < 1 or number > 18:
            continue
        name, url = link(values[1])
        if not name or name in ('Storms of Fate', 'Shadows of the Departed', 'Apocalypse Nigh'):
            continue
        row = common('zilart', packet_ids[number - 1], str(number), name,
                     (plain(values[2]) or '').replace('--', ' / '), values[3], url, previous)
        row['mission_group'] = 'Story'
        if number == 18:
            row['description'] += ' XIchecklist marks this finale as not normally completable; no completion is invented.'
        rows.append(row)
        previous = name
    if len(rows) != 18:
        raise ValueError('zilart: expected 18 missions, got %d' % len(rows))
    return rows


COP_CURRENT_IDS = {
    '1-1': [101, 110], '1-2': [118], '1-3': [128],
    '2-1': [137, 138], '2-2': [218], '2-3': [228], '2-4': [238], '2-5': [248],
    '3-1': [257, 258], '3-2': [318],
    '3-3': [325, 330, 331, 335, 339, 340, 341, 345, 349],
    '3-4': [350], '3-5': [358],
    '4-1': [367, 368], '4-2': [418], '4-3': [428], '4-4': [438],
    '5-1': [447, 448], '5-2': [518],
    '5-3': [530, 540, 542, 543, 546, 549, 550, 552, 553, 556, 559, 560, 562, 564, 568],
    '6-1': [577, 578], '6-2': [618], '6-3': [628], '6-4': [638],
    '7-1': [647, 648], '7-2': [718], '7-3': [728], '7-4': [738], '7-5': [748],
    '8-1': [758, 800], '8-2': [818], '8-3': [828], '8-4': [840], '8-5': [850],
}


def promathia(path):
    rows, chapter, previous = [], None, None
    for raw in path.read_text(encoding='utf-8').splitlines():
        if not raw.startswith('|') or '](' not in raw:
            continue
        values = cells(raw)
        if values[0].startswith('Chapter '):
            chapter = int(values.pop(0).split()[1])
        if chapter is None or len(values) < 3 or not re.fullmatch(r'\d+-\d+', values[0]):
            continue
        number = values[0]
        name, url = link(values[1])
        if not name or number not in COP_CURRENT_IDS:
            continue
        mission_type = plain(values[2]) if len(values) >= 4 else ('Multi-path' if number == '5-3' else 'Not listed')
        reward_text = values[-1] if len(values) >= 4 else values[2]
        ids = COP_CURRENT_IDS[number]
        row = common('promathia', ids[0], number, name, mission_type, reward_text, url, previous)
        row['mission_group'] = 'Chapter %d' % chapter
        row['mission_chapter'] = chapter
        row['current_ids'] = ids
        row['description'] += ' The client packet exposes current Promathia progress but no reviewed completion bitfield.'
        rows.append(row)
        previous = name
    if len(rows) != 34:
        raise ValueError('promathia: expected 34 numbered missions, got %d' % len(rows))
    return rows


def ahturhgan(path):
    rows, previous = [], None
    for raw in path.read_text(encoding='utf-8').splitlines():
        if not raw.startswith('|') or '](' not in raw:
            continue
        values = cells(raw)
        if len(values) != 4:
            continue
        match = re.search(r'\[(\d+)\]', values[0])
        if not match:
            continue
        number = int(match.group(1))
        name, url = link(values[1])
        if not name or not 1 <= number <= 48:
            continue
        row = common('ahturhgan', number - 1, '%02d' % number, name,
                     plain(values[2]), values[3], url, previous)
        row['mission_group'] = 'Story'
        row['description'] = ('HorizonXI currently labels this as planned Aht Urhgan mission content; '
                              'the listing is not confirmation that it is active on the server.')
        rows.append(row)
        previous = name
    if len(rows) != 48:
        raise ValueError('ahturhgan: expected 48 missions, got %d' % len(rows))
    return rows


def render(name, source_url, rows, views, reviewed_note):
    output = [
        'local data = {};', '',
        '-- Packet IDs: XIchecklist 04baf17b2b0373883407a94ce0b6a72274a31ba6.',
        '-- Names/types/rewards: HorizonXI category table, reviewed 2026-09-07.',
        '-- ' + reviewed_note,
        'data.source_url = ' + lua_string(source_url) + ';',
        'data.views = {',
    ]
    for view in views:
        parts = []
        for key, value in view.items():
            parts.append(key + ' = ' + (str(value) if isinstance(value, int) else lua_string(value)))
        output.append('    { ' + ', '.join(parts) + ' },')
    output += ['};', 'data.entries = {']
    for row in rows:
        parts = []
        for key, value in row.items():
            if isinstance(value, int):
                encoded = str(value)
            elif isinstance(value, list):
                encoded = '{ ' + ', '.join(str(item) for item in value) + ' }'
            else:
                encoded = lua_string(value)
            parts.append(key + ' = ' + encoded)
        output.append('    { ' + ', '.join(parts) + ' },')
    output += ['};', 'return data;', '']
    target = ROOT / 'HXIChecklist' / (name + '_mission_data.lua')
    target.write_text('\n'.join(output), encoding='utf-8', newline='\n')
    return target, len(rows)


def main():
    cache = ROOT / '.firecrawl'
    nation_views = [{'id': 'all', 'name': 'All Ranks'}] + [
        {'id': 'rank_%d' % rank, 'name': 'Rank %d' % rank, 'mission_rank': rank}
        for rank in range(1, 10)
    ]
    jobs = [
        ('sandoria', 'Category:San_d%27Oria_Missions',
         nation(cache / 'horizon-sandoria-missions.md', 'sandoria', "San d'Oria"), nation_views,
         'Journey Abroad stages 6-9 share row 5; only bit 5 completes that row.'),
        ('windurst', 'Category:Windurst_Missions',
         nation(cache / 'horizon-windurst-missions.md', 'windurst', 'Windurst'), nation_views,
         'Three Kingdoms stages 6-9 share row 5; only bit 5 completes that row.'),
        ('zilart', 'Category:Rise_of_the_Zilart_Missions',
         zilart(cache / 'horizon-zilart-missions.md'), [{'id': 'all', 'name': 'All Missions'}],
         'Only explicit packet IDs and completion bits are used.'),
        ('promathia', 'Category:Chains_of_Promathia_Missions',
         promathia(cache / 'horizon-promathia-missions.md'),
         [{'id': 'all', 'name': 'All Chapters'}] + [
             {'id': 'chapter_%d' % chapter, 'name': 'Chapter %d' % chapter,
              'mission_group': 'Chapter %d' % chapter} for chapter in range(1, 9)],
         'Current-only tracking: no completion state is inferred.'),
        ('ahturhgan', 'Category:Treasures_of_Aht_Urhgan_Missions',
         ahturhgan(cache / 'horizon-ahturhgan-missions.md'), [{'id': 'all', 'name': 'All Missions'}],
         'The source page labels this planned content; availability is not inferred.'),
    ]
    for name, page, rows, views, note in jobs:
        target, count = render(name, WIKI + page, rows, views, note)
        print('%s: %d entries -> %s' % (name, count, target))


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8', newline='\n')
    main()
