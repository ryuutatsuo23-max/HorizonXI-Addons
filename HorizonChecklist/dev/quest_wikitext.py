"""Conservative reader for public MediaWiki Quest Header data (offline only)."""
import html
import json
import re
from pathlib import Path


def split_top(value):
    parts, start, braces, links, index = [], 0, 0, 0, 0
    while index < len(value):
        pair = value[index:index + 2]
        if pair in ('{{', '}}', '[[', ']]'):
            if pair == '{{': braces += 1
            elif pair == '}}': braces -= 1
            elif pair == '[[': links += 1
            else: links -= 1
            if braces < 0 or links < 0:
                raise ValueError('Unbalanced wiki delimiters')
            index += 2
            continue
        if value[index] == '|' and braces == 0 and links == 0:
            parts.append(value[start:index].strip())
            start = index + 1
        index += 1
    if braces or links:
        raise ValueError('Unbalanced wiki delimiters')
    parts.append(value[start:].strip())
    return parts


def template_end(value, start):
    depth, index = 0, start
    while index < len(value) - 1:
        pair = value[index:index + 2]
        if pair == '{{':
            depth += 1; index += 2
        elif pair == '}}':
            depth -= 1; index += 2
            if depth == 0:
                return index
        else:
            index += 1
    raise ValueError('Unclosed wiki template')


def header_fields(wikitext):
    value = re.sub(r'<!--.*?-->', '', wikitext, flags=re.S)
    match = re.search(r'\{\{\s*(?:Template:)?(?:Quest(?:[ _]Header)?|Borghertz[ _]Quest)\s*[|}]', value, re.I)
    if not match:
        return {}
    end = template_end(value, match.start())
    fields = {}
    parts = split_top(value[match.start()+2:end-2])
    for part in parts[1:]:
        if '=' not in part:
            continue
        key, content = part.split('=', 1)
        key = key.strip().lower().replace('_', ' ')
        if key in fields and fields[key] != content.strip():
            raise ValueError('Conflicting header field: ' + key)
        fields[key] = content.strip()
    if parts[0].lower().removeprefix('template:') == 'borghertz quest':
        # Template:Borghertz Quest, reviewed 2026-09-04. Preserve started vs completed,
        # and distinguish optional coffer rewards from completing the hands quest.
        if not all(fields.get(key) for key in ('job', 'previous quest', 'hands item', 'hands key')):
            return {}
        optional = '<br>'.join(fields[key] for key in ('item 2', 'item 3') if fields.get(key))
        return {
            'rewards': fields['hands item'] + ('<br>Optional coffer rewards:<br>' + optional if optional else ''),
            'requirements': fields['job'] + " 50+<br>Must have started " + fields['previous quest']
                + "<br>No other Borghertz's Hands quest active. Optional coffers require the corresponding main job.",
            'items needed': fields['hands key'] + '<br>Old Gauntlets<br>Shadow Flames'
                + '<br>Coffer lockpicking is an alternative to the key; see Source.',
        }
    return fields


class UnverifiedField(ValueError):
    pass


def wiki_plain(value):
    value = re.sub(r'<!--.*?-->', '', value, flags=re.S)
    value = re.sub(r'<(?:s|strike|del)\b[^>]*>.*?</(?:s|strike|del)>', '', value, flags=re.S | re.I)
    value = re.sub(r'<ref\b[^>]*(?:/>|>.*?</ref>)', '', value, flags=re.S | re.I)
    value = re.sub(r'</?(?:small|b|i|strong|em)>', '', value, flags=re.I)
    while '{{' in value:
        start = value.index('{{'); end = template_end(value, start)
        parts = split_top(value[start+2:end-2])
        name = parts[0].lower().replace('_', ' ').strip()
        args = parts[1:]
        named = {}
        for arg in args:
            if '=' in arg:
                key, content = arg.split('=', 1)
                named[key.strip().lower()] = content.strip()
        if name == '!':
            replacement = '|'
        elif name in ('keyitem', 'key item') and not args:
            replacement = ''
        elif name in ('item tooltip', 'keyitem', 'key item') and args:
            replacement = wiki_plain(args[0])
        elif name in ('location', 'location tooltip', 'position') and args:
            positional = [arg for arg in args if '=' not in arg]
            if positional:
                replacement = ' / '.join(wiki_plain(arg) for arg in positional)
            else:
                locations = [named.get('area') or named.get('zone')]
                locations.extend(named.get('pos' + ('' if index == 1 else ' ' + str(index)))
                                 for index in range(1, 5))
                replacement = ' / '.join(wiki_plain(arg) for arg in locations if arg)
        elif name in ('changes', 'hxi', 'icon', 'rare', 'exclusive'):
            replacement = ''
        else:
            raise UnverifiedField('Unsupported/uncertain template: ' + name)
        value = value[:start] + replacement + value[end:]
    def link(match):
        parts = match[1].split('|')
        if parts[0].lower().startswith(('file:', 'image:')):
            return ''
        return parts[-1] if len(parts) > 1 else parts[0].split('#')[0]
    value = re.sub(r'\[\[([^\[\]]+)\]\]', link, value)
    value = re.sub(r'\b(or|and)\s*<br\s*/?>', r'\1 ', value, flags=re.I)
    value = re.sub(r'<br\s*/?>', '; ', value, flags=re.I)
    value = value.replace("'''", '').replace("''", '')
    value = html.unescape(value)
    if any(token in value for token in ('{{', '}}', '[[', ']]', 'http')) or re.search(r'<[^>]+>', value):
        raise UnverifiedField('Unsupported markup')
    value = ' '.join(value.split()).strip(' ;')
    value = re.sub(r'(;\s*){2,}', '; ', value).replace(':;', ':')
    if value.lower() in ('see below', 'see quest page'):
        value = 'See Source for options'
    return value


def api_pages(paths):
    pages, aliases = {}, {}
    for path in paths:
        raw = Path(path).read_text(encoding='utf-8').strip()
        raw = raw.removeprefix('```json').removesuffix('```').strip()
        document = json.loads(raw)
        if 'error' in document:
            raise ValueError('Wiki API error: ' + str(document['error']))
        query = document.get('query', {})
        for kind in ('normalized', 'redirects'):
            for alias in query.get(kind, []):
                aliases[alias['from'].replace('_', ' ')] = alias['to'].replace('_', ' ')
        for page in query.get('pages', []):
            if 'missing' in page or 'invalid' in page:
                continue
            revisions = page.get('revisions', [])
            if not revisions:
                continue
            pages[page['title'].replace('_', ' ')] = revisions[0]['slots']['main']['content']
    for source in aliases:
        dest, seen = source, set()
        while dest in aliases and dest not in seen:
            seen.add(dest); dest = aliases[dest]
        if dest in pages:
            pages[source] = pages[dest]
    return pages


def _location_templates(raw):
    found, cursor = [], 0
    pattern = re.compile(r'\{\{\s*(location(?:[ _]tooltip)?|position)\s*[|}]', re.I)
    while True:
        match = pattern.search(raw, cursor)
        if not match:
            return found
        end = template_end(raw, match.start())
        parts = split_top(raw[match.start() + 2:end - 2])
        positional, named = [], {}
        for part in parts[1:]:
            if '=' in part:
                key, value = part.split('=', 1)
                named[key.strip().lower()] = value.strip()
            else:
                positional.append(part.strip())
        found.append((parts[0].strip().lower().replace('_', ' '), positional, named))
        cursor = end


def wiki_location_details(raw):
    """Return an explicit wiki location and coordinate without inferring either."""
    if not raw or not raw.strip():
        return None, None
    try:
        value = wiki_plain(raw)
    except UnverifiedField:
        return None, None
    if not value:
        return None, None
    explicitly_unspecified = bool(re.search(r'\(\s*-\s*\)\s*$', value))
    if explicitly_unspecified:
        value = re.sub(r'\s*\(\s*-\s*\)\s*$', '', value)
    coordinates = []
    for name, positional, named in _location_templates(raw):
        if name == 'location tooltip':
            candidates = [named.get('pos')]
            candidates.extend(named.get('pos ' + str(index)) for index in range(2, 5))
        else:
            candidates = positional[1:2]
            candidates.extend(named.get('pos ' + str(index)) for index in range(2, 5))
        for candidate in candidates:
            if not candidate:
                continue
            try:
                candidate = wiki_plain(candidate)
            except UnverifiedField:
                continue
            if candidate in ('-', '—'):
                explicitly_unspecified = True
                continue
            if candidate and candidate not in coordinates:
                coordinates.append(candidate)
    if not coordinates:
        coordinates = re.findall(r'(?<![A-Za-z])([A-P]-\d{1,2})(?!\d)', value, re.I)
    if coordinates:
        coordinate_choice = '|'.join(re.escape(item) for item in coordinates)
        value = re.sub(r'\s*\([^()]*(?:' + coordinate_choice + r')[^()]*\)', '', value, flags=re.I)
    for coordinate in coordinates:
        value = re.sub(r'\s*/\s*' + re.escape(coordinate) + r'\b', '', value, flags=re.I)
    if explicitly_unspecified:
        value = re.sub(r'\s*(?:;\s*|\(\s*)[-—]\s*\)?\s*$', '', value)
    value = re.sub(r'\s*,\s*$', '', value).strip()
    coordinate_text = ' / '.join(coordinates) if coordinates else ('N/A' if explicitly_unspecified else None)
    return value or None, coordinate_text


def wiki_details(wikitext, issues=None):
    fields = header_fields(wikitext)
    result, requirements, unverified = {}, [], []
    def clean(key):
        raw = fields.get(key, '')
        if not raw.strip(): return None
        try:
            value = wiki_plain(raw)
        except UnverifiedField as error:
            unverified.append(key)
            if issues is not None: issues.append((key, str(error), raw))
            return None
        return None if value in ('', '-', '—', '?', '???') else value
    reward = clean('rewards') or clean('reward')
    if reward:
        result['rewards'] = reward + ' (see Source for conditions)'
    fame, level = clean('fame'), clean('fame level') or clean('flevel')
    if level:
        requirements.append('Required Fame: ' + ((fame + ' Fame ') if fame else '') + level)
    elif fame and fame.lower() in ('none', 'n/a'):
        requirements.append('Required Fame: ' + fame)
    fame2, level2 = clean('fame 2'), clean('fame 2 level')
    if fame2 and level2:
        requirements.append('Additional fame: ' + fame2 + ' Fame ' + level2)
    for key, label in (('requirements', 'Additional Requirements'), ('additional requirements', 'Additional Requirements'),
                       ('level', 'Level Requirement'), ('level restriction', 'Level Restriction'),
                       ('items needed', 'Items Needed'), ('items', 'Items Needed'), ('items required', 'Items Needed'),
                       ('item reqs', 'Items Needed'), ('quest reqs', 'Quest Requirements'), ('previous', 'Previous quest listed')):
        value = clean(key)
        if value and not (key == 'previous' and value.lower() == 'none'):
            requirements.append(label + ': ' + value)
    if any(key not in ('reward', 'rewards') for key in unverified):
        requirements.append('Some infobox requirements remain unverified; see Source')
    if requirements:
        result['prerequisites'] = '; '.join(requirements).rstrip('. ') + '. Source summary only; other conditions may apply.'
    npc = clean('start') or clean('starting npc') or clean('start npc')
    if npc:
        result['npc'] = 'N/A' if npc.lower() in ('none', 'n/a') else npc
    location, coordinates = wiki_location_details(fields.get('start location') or fields.get('location') or '')
    if location:
        result['quest_location'] = location
    if coordinates:
        result['npc_coordinates'] = coordinates
    return result
