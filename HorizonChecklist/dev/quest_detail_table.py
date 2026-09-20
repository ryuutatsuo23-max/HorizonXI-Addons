"""Read a reviewed wiki category table and emit a narrow apply_patch (no file writes).

Coordinates and rewards come from category tables; optional individual-page
infobox inputs add partial prerequisite summaries. This developer tool never
runs inside the addon and does not infer character eligibility.
"""
import argparse
import html
import json
import re
import sys
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlsplit
from quest_wikitext import api_pages, wiki_details

LINK = re.compile(r'\[([^\[\]]*)\]\((https://[^\s]+)(?:\s+"(?:\\.|[^"\\])*")?\)')


def plain(value):
    if 'Information Needed' in value or 'Verification Needed' in value:
        return None
    value = re.sub(r'~~.*?~~', '', value)
    value = re.sub(r'!\[[^\]]*\]\([^)]*\)', '', value)
    for _ in range(3):
        value = LINK.sub(lambda match: match[1], value)
    value = re.sub(r'\b(or|and)\s*<br\s*/?>', r'\1 ', value, flags=re.I)
    value = re.sub(r'<br\s*/?>', '; ', value, flags=re.I)
    value = html.unescape(value).replace('\\', '').replace('_', '').replace('*', '')
    value = ' '.join(value.split()).strip()
    value = re.sub(r'(;\s*){2,}', '; ', value).strip(' ;').replace(':;', ':')
    if value.lower() in ('see below', 'see quest page'):
        value = 'See Source for options'
    if any(token in value for token in ('http', '[', ']', '<', '>', '~')):
        raise ValueError('Unparsed markup: ' + value)
    return None if value in ('', '-', '--', '---', '—', '?', '???') else value


def title(url):
    parts = urlsplit(url)
    return unquote(parse_qs(parts.query).get('title', [parts.path.lstrip('/')])[0]).replace('_', ' ')


def table_rows(markdown):
    headers = None
    result = {}
    for line in markdown.splitlines():
        if not line.startswith('|'):
            headers = None
            continue
        cells = [cell.strip() for cell in line.strip('|').split('|')]
        if cells[0] == 'Quest':
            headers = cells if all(key in cells for key in ('NPC', 'Pos.', 'Reward')) else None
            continue
        if not headers or len(cells) != len(headers):
            continue
        row = dict(zip(headers, cells))
        match = LINK.search(row['Quest'])
        if not match:
            continue
        key = title(match[2])
        fields = {'npc_coordinates': plain(row['Pos.']), 'rewards': plain(row['Reward'])}
        fields = {name: value for name, value in fields.items() if value is not None}
        # A category's reward cell can be a summary, not a guaranteed amount.
        if 'rewards' in fields:
            fields['rewards'] += ' (category listing; see Source for conditions)'
        if key in result and result[key] != fields:
            raise ValueError('Conflicting rows: ' + key)
        result[key] = fields
    return result


def lua_string(value):
    return "'" + value.replace('\\', '\\\\').replace("'", "\\'") + "'"


def page_details(markdown):
    """Extract only explicit infobox fields; never infer eligibility from prose."""
    if '| Starting NPC |' not in markdown:
        return {}
    result, requirements, reward_lines = {}, [], []
    in_box, in_rewards, previous = False, False, False
    labels = {'Required Fame', 'Additional Requirements', 'Requirements', 'Items Needed',
              'Level Restriction', 'Level Requirement', 'Job Requirement'}
    for line in markdown.splitlines():
        if line.startswith('##'):
            if in_box:
                break
            continue
        if not line.startswith('|'):
            in_rewards = False
            continue
        cells = [cell.strip() for cell in line.strip('|').split('|')]
        if cells[0] == 'Starting NPC':
            in_box = True
        if not in_box:
            continue
        if 'Previous Quest' in cells[0]:
            previous = True
            continue
        if previous and not cells[0].startswith('---'):
            value = plain(cells[0])
            if value and value.lower() != 'none':
                requirements.append('Previous quest listed: ' + value)
            previous = False
        field_label = cells[0].rstrip(':')
        if field_label in labels and len(cells) == 2:
            value = plain(cells[1])
            if value:
                label = field_label
                if label == 'Required Fame':
                    if re.search(r'\bLevel non\b', value, re.I):
                        value = "Unconfirmed (source wording: '" + value + "')"
                    else:
                        value = value.replace('Level ', 'Fame ')
                requirements.append(label + ': ' + value)
        if cells[0] == 'Rewards':
            in_rewards = True
            if len(cells) == 2:
                value = plain(cells[1])
                if value:
                    reward_lines.append(value)
            continue
        if in_rewards and len(cells) == 1:
            value = plain(cells[0])
            if value and not value.startswith('---'):
                reward_lines.append(value)
    if reward_lines:
        result['rewards'] = '; '.join(reward_lines) + ' (see Source for conditions)'
    if requirements:
        result['prerequisites'] = '; '.join(requirements).rstrip('. ') + '. Source summary only; other conditions may apply.'
    return result


def merge_details(table_fields, page_fields, table_fame=None, fame_region='Bastok'):
    result = dict(table_fields)
    result.update(page_fields)
    table_reward = table_fields.get('rewards', '').split(' (')[0]
    page_reward = page_fields.get('rewards', '').split(' (')[0]
    def gil(value):
        match = re.fullmatch(r'([\d,]+)\s*(?:gil|g)', value, re.I)
        return int(match[1].replace(',', '')) if match else None
    conflicting_none = page_reward.lower() == 'none' and table_reward and table_reward.lower() != 'none'
    conflicting_gil = gil(table_reward) is not None and gil(page_reward) is not None and gil(table_reward) != gil(page_reward)
    if conflicting_none or conflicting_gil:
        result['rewards'] = ('Category lists ' + table_reward + '; quest infobox lists '
                             + page_reward + ' (conflicting sources; verify Source).')
    page_fame = re.search(r'Required Fame: ' + re.escape(fame_region) + r' Fame (\d+|none)',
                          result.get('prerequisites', ''), re.I) if fame_region else None
    if page_fame and table_fame and page_fame[1] != table_fame:
        result['prerequisites'] += (' Fame conflicts with the category table (Fame '
                                    + table_fame + '); verify with Source.')
    return result


def read_table(path, category_url):
    raw = path.read_text(encoding='utf-8')
    if path.suffix == '.json':
        document = json.loads(raw)
        matches = [page['markdown'] for page in document.get('data', {}).get('web', [])
                   if title(page.get('url', '')) == title(category_url) and page.get('markdown')]
        if len(matches) != 1:
            raise ValueError('Expected one exact category match in saved research JSON')
        raw = matches[0]
    return table_rows(raw)


def main():
    sys.stdout.reconfigure(encoding='utf-8', newline='\n')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('table', type=Path)
    parser.add_argument('catalog', type=Path)
    parser.add_argument('--patch', action='store_true')
    parser.add_argument('--pages', type=Path, help='Directory of quest-detail-<stable-id>.md files')
    parser.add_argument('--limit', type=int, default=1000, help='Maximum patch rows per reviewed batch')
    parser.add_argument('--skip-existing', action='store_true', help='Skip previously enriched rows; never overwrite them')
    parser.add_argument('--raw-api-dir', type=Path, help='Directory containing area-quest-raw-api-*.json responses')
    parser.add_argument('--audit', action='store_true', help='Print proposed detail fields as JSON without editing files')
    args = parser.parse_args()
    catalog_text = args.catalog.read_text(encoding='utf-8')
    category_url = re.search(r"source_url = '([^']+)'", catalog_text)[1]
    rows = read_table(args.table, category_url)
    area = args.catalog.stem.removesuffix('_quest_data')
    raw_pages = api_pages(args.raw_api_dir.glob(area + '-quest-raw-api-*.json')) if args.raw_api_dir else {}
    changes = []
    for line in catalog_text.splitlines():
        match = re.search(r"source_url = '([^']+)'", line)
        if not match or not line.lstrip().startswith('{ id ='):
            continue
        fields = dict(rows.get(title(match[1]), {}))
        identity = re.search(r"\{ id = '([^']+)'", line)
        table_fame = re.search(r'fame_level = (\d+)', line)
        fame_region_match = re.search(r"fame_region = '([^']+)'", line)
        fame_region = fame_region_match[1] if fame_region_match else {
            'sandoria': "San d'Oria", 'windurst': 'Windurst', 'jeuno': 'Jeuno', 'bastok': 'Bastok'
        }.get(area)
        raw_page = raw_pages.get(title(match[1]))
        if raw_page:
            fields = merge_details(fields, wiki_details(raw_page),
                                   table_fame[1] if table_fame else None, fame_region)
        if args.pages and identity:
            page = args.pages / ('quest-detail-' + identity[1] + '.md')
            if page.exists():
                table_fame = re.search(r'fame_level = (\d+)', line)
                fields = merge_details(fields, page_details(page.read_text(encoding='utf-8')),
                                       table_fame[1] if table_fame else None)
        if not fields:
            continue
        if any(name + ' =' in line for name in fields):
            if args.skip_existing:
                continue
            raise ValueError('Already enriched; review manually before replacing detail fields')
        addition = ', '.join(name + ' = ' + lua_string(value) for name, value in fields.items())
        new_line = line.replace('source_url =', addition + ', source_url =', 1)
        changes.append((line, new_line))
        if args.audit:
            print(json.dumps({'id': identity[1], **fields}, ensure_ascii=True))
    if args.patch:
        print('*** Begin Patch')
        print('*** Update File: ' + args.catalog.resolve().as_posix())
        for old, new in changes[:max(0, args.limit)]:
            print('@@\n-' + old + '\n+' + new)
        print('*** End Patch')
    elif not args.audit:
        print(f'{len(rows)} sourced table rows; {len(changes)} catalog rows matched')
        for key, fields in rows.items():
            print(key + ': ' + str(fields))


if __name__ == '__main__':
    main()
