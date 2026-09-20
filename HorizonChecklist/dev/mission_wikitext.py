"""Conservative Mission Header extraction from cached HorizonXI wikitext."""
import re
from urllib.parse import parse_qs, unquote, urlsplit

from quest_wikitext import UnverifiedField, split_top, template_end, wiki_plain


def header_fields(wikitext):
    match = re.search(r'\{\{\s*(?:Template:)?Mission[ _]Header\s*[|}]', wikitext, re.I)
    if not match:
        return {}
    end = template_end(wikitext, match.start())
    fields, previous_key = {}, None
    for part in split_top(wikitext[match.start() + 2:end - 2])[1:]:
        if part.lstrip().startswith('{{') and previous_key:
            fields[previous_key] += ' ' + part.strip()
        elif '=' in part:
            key, content = part.split('=', 1)
            previous_key = key.strip().lower().replace('_', ' ')
            fields[previous_key] = content.strip()
        elif previous_key and part.strip():
            # A few source headers put a leading pipe before a continued
            # Start Location template. Preserve that source text.
            fields[previous_key] += ' ' + part.strip()
    return fields


def source_title(url):
    parts = urlsplit(url)
    title = parse_qs(parts.query).get('title', [parts.path.lstrip('/')])[0]
    return unquote(title).replace('_', ' ')


def clean(value):
    if not value or not value.strip():
        return None
    value = re.sub(r'(?m)^\s*[*#]+\s*', '; ', value)
    value = re.sub(r'\]\]\s*(?=\[\[)', ']]; ', value)
    value = re.sub(r'\]\]\s*(?=\{\{\s*(?:KeyItem|Rare|Exclusive)\b)', ']]; ', value, flags=re.I)
    value = re.sub(r'\}\}\s*(?=\{\{\s*(?:KeyItem|Rare|Exclusive)\b)', '}}; ', value, flags=re.I)
    value = re.sub(r'\]\]\s*(?=\()', ']] ', value)
    try:
        result = wiki_plain(value)
    except UnverifiedField:
        return None
    result = re.sub(r'\s*;\s*', '; ', result).strip(' ;')
    return result or None


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


def location_details(raw):
    value = clean(raw)
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
            candidate = clean(candidate)
            if candidate and candidate not in coordinates:
                coordinates.append(candidate)
    if not coordinates:
        coordinates = re.findall(r'(?<![A-Za-z])([A-P]-\d{1,2})(?!\d)', value, re.I)
    if coordinates:
        coordinate_choice = '|'.join(re.escape(item) for item in coordinates)
        value = re.sub(r'\s*\([^()]*(?:' + coordinate_choice + r')[^()]*\)', '', value, flags=re.I)
    for coordinate in coordinates:
        value = re.sub(r'\s*/\s*' + re.escape(coordinate) + r'\b', '', value, flags=re.I)
    value = re.sub(r'\s*,\s*$', '', value).strip()
    coordinate_text = ' / '.join(coordinates) if coordinates else ('N/A' if explicitly_unspecified else None)
    return value or None, coordinate_text


def details(wikitext, fallback=None):
    """Return only display-safe facts explicitly present in Mission Header."""
    fields = header_fields(wikitext)
    if not fields:
        return {}
    fallback = fallback or {}
    result = {}
    start_raw = fields.get('start', '')
    location_raw = fields.get('start location', '')
    npc = clean(start_raw)
    previous = clean(fields.get('previous'))

    # The shared finale header stores NPC and location in Start rather than
    # Start Location. Split its two explicit links without guessing a point.
    if not location_raw and start_raw.count('[[') >= 2 and ',' in start_raw:
        pieces = start_raw.split(',', 1)
        npc = clean(pieces[0])
        location_raw = pieces[1]

    if not location_raw and npc and ' in ' in npc:
        npc, location_raw = npc.rsplit(' in ', 1)

    if npc and npc.lower() in ('none', 'n/a'):
        npc = 'N/A'
    result['npc'] = npc or ('No separate start listed' if previous else 'Not listed')

    location, coordinates = location_details(location_raw)
    if location:
        location = re.sub(r'^Zoning into\s+', '', location, flags=re.I)
        result['quest_location'] = location
        result['npc_coordinates'] = coordinates or 'Not listed'
    elif 'gate guard' in result['npc'].lower():
        result['quest_location'] = fallback.get('quest_location', 'Nation gate-guard locations')
        result['npc_coordinates'] = 'Varies by gate guard'
    elif result['npc'] == 'N/A':
        result['quest_location'] = 'N/A'
        result['npc_coordinates'] = 'N/A'
    elif result['npc'] == 'No separate start listed':
        result['quest_location'] = 'Continues from previous mission'
        result['npc_coordinates'] = 'N/A'
    else:
        result['quest_location'] = 'Not listed'
        result['npc_coordinates'] = 'Not listed'

    reward = clean(fields.get('rewards')) or clean(fields.get('reward'))
    if reward:
        result['rewards'] = reward + ' (mission page; see Source for conditions)'

    requirements = []
    if previous and previous.lower() not in ('none', 'n/a'):
        if '|' in previous:
            previous = previous.rsplit('|', 1)[-1]
        requirements.append('Previous mission: ' + previous)
    level = clean(fields.get('level'))
    if level:
        requirements.append('Level: ' + level)
    explicit = clean(fields.get('requirements'))
    if explicit:
        requirements.append('Requirements: ' + explicit)
    items = clean(fields.get('items needed')) or clean(fields.get('item needed'))
    if items:
        requirements.append('Items needed: ' + items)
    if fallback.get('mission_rank'):
        requirements.insert(0, fallback['mission_area_name'] + ' allegiance; sufficient rank points may be needed')
    if requirements:
        result['prerequisites'] = '; '.join(requirements) + '. Source summary only; other conditions may apply.'
    else:
        result['prerequisites'] = 'No prerequisite is listed in the Mission Header; see Source for starting conditions.'
    return result
