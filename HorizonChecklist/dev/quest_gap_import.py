"""Emit narrow patches for source-resolvable gaps in existing quest catalogs.

Inputs are current HorizonXI category markdown and MediaWiki API responses saved
under the ignored .firecrawl directory. Existing populated fields and explicit
Unknown values are never replaced.
"""
import argparse
import re
import sys
from pathlib import Path

from quest_detail_table import lua_string, merge_details, table_rows, title
from quest_wikitext import api_pages, wiki_details


ROOT = Path(__file__).resolve().parents[1]
AREAS = ('bastok', 'sandoria', 'windurst', 'jeuno', 'other', 'outlands', 'ahturhgan')
FAME_NAMES = {
    'bastok': 'Bastok', 'jeuno': 'Jeuno', 'kazham': 'Kazham', 'norg': 'Norg',
    "san d'oria": "San d'Oria", 'tavnazian safehold': 'Tavnazian Safehold',
    'tenshodo': 'Tenshodo', 'windurst': 'Windurst',
}


def field(line, name):
    match = re.search(r"\b" + re.escape(name) + r" = '((?:\\.|[^'])*)'", line)
    return match[1] if match else None


def proposed_line(line, category_rows, pages):
    source_url = field(line, 'source_url')
    if not source_url:
        return line
    source_title = title(source_url)
    table_fields = dict(category_rows.get(source_title, {}))
    page_fields = wiki_details(pages[source_title]) if source_title in pages else {}
    table_fame = re.search(r'\bfame_level = (\d+)', line)
    fame_region = field(line, 'fame_region')
    fields = merge_details(
        table_fields, page_fields, table_fame[1] if table_fame else None, fame_region)

    additions = {}
    for name in ('npc', 'quest_location', 'npc_coordinates', 'rewards', 'prerequisites'):
        if name in fields and not re.search(r'\b' + re.escape(name) + r' =', line):
            additions[name] = fields[name]

    # A category-table dash remains honest, but a numeric regional fame in the
    # linked Quest Header can make the user-facing fame column more useful.
    if "fame_label = 'Not listed'" in line:
        fame = re.search(r'Required Fame: (?:(.+?) Fame )?(\d+)', fields.get('prerequisites', ''))
        if fame:
            region = FAME_NAMES.get((fame[1] or '').lower(), fame[1])
            label = ((region + ' Fame ') if region else 'Fame ') + fame[2]
            replacement = ', fame_level = ' + fame[2]
            if region:
                replacement += ', fame_region = ' + lua_string(region)
            replacement += ', fame_note = ' + lua_string(
                'The category table does not list a fame value; the linked Quest Header explicitly lists ' + label + '.')
            line = re.sub(
                r", fame_label = 'Not listed'(?:, fame_note = '(?:\\.|[^'])*')?",
                replacement, line, count=1)

    if additions:
        encoded = ', '.join(name + ' = ' + lua_string(value) for name, value in additions.items())
        line = line.replace('source_url =', encoded + ', source_url =', 1)
    return line


def main():
    sys.stdout.reconfigure(encoding='utf-8', newline='\n')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('area', choices=AREAS)
    args = parser.parse_args()
    catalog = ROOT / 'HXIChecklist' / (args.area + '_quest_data.lua')
    category = ROOT / '.firecrawl' / ('current-' + args.area + '-quests.md')
    pages = api_pages(sorted((ROOT / '.firecrawl').glob('current-' + args.area + '-quest-api-*.md')))
    category_rows = table_rows(category.read_text(encoding='utf-8'))
    changes = []
    for old in catalog.read_text(encoding='utf-8').splitlines():
        if not old.lstrip().startswith('{ id ='):
            continue
        new = proposed_line(old, category_rows, pages)
        if new != old:
            changes.append((old, new))
    if not changes:
        print('')
        return
    print('*** Begin Patch')
    print('*** Update File: ' + catalog.resolve().as_posix())
    for old, new in changes:
        print('@@')
        print('-' + old)
        print('+' + new)
    print('*** End Patch')


if __name__ == '__main__':
    main()
