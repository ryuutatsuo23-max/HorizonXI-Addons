import json
import tempfile
import unittest
from pathlib import Path

from quest_wikitext import api_pages, header_fields, split_top, wiki_details, wiki_plain, UnverifiedField
from quest_detail_table import merge_details


class QuestWikitextTests(unittest.TestCase):
    def test_nested_pipes_and_aliases(self):
        self.assertEqual(split_top('A|[[B|C]]|{{Location|D|H-8}}'), ['A', '[[B|C]]', '{{Location|D|H-8}}'])
        self.assertEqual(wiki_plain('[[Page|Label]]<br>{{Item Tooltip|Item}}'), 'Label; Item')
        with self.assertRaises(ValueError):
            split_top('A|{{Broken')

    def test_header_variants_and_duplicate_guard(self):
        for name in ('Quest Header', 'Quest_Header', 'Template:Quest Header', 'Quest'):
            self.assertEqual(header_fields('{{' + name + '|Reward=100g}}'), {'reward': '100g'})
        with self.assertRaises(ValueError):
            header_fields('{{Quest Header|Rewards=One|Rewards=Two}}')
        self.assertEqual(header_fields('<!-- {{Quest Header|Rewards=Fake}} --> No infobox'), {})

    def test_removed_and_conditional_rewards(self):
        self.assertEqual(wiki_plain('<s>Old</s><br>New<br><small>Only on repeat</small>'), 'New; Only on repeat')
        self.assertEqual(wiki_plain('A or<br>B'), 'A or B')
        self.assertEqual(wiki_plain('Reputation: ? (>1)'), 'Reputation: ? (>1)')
        with self.assertRaises(UnverifiedField):
            wiki_plain('<span class="soa">Conditional job</span>')

    def test_uncertainty_never_becomes_none(self):
        row = wiki_details('{{Quest Header|Fame=Windurst|Fame Level=3 {{verification}}|Requirements=<span class="soa">Job</span>|Rewards=New<br><del>Removed</del>}}')
        self.assertNotIn('Fame 3', row['prerequisites'])
        self.assertIn('remain unverified', row['prerequisites'])
        self.assertEqual(row['rewards'], 'New (see Source for conditions)')
        self.assertEqual(wiki_details('{{Quest Header|Rewards=?|Requirements=}}'), {})
        self.assertIn('Required Fame: None', wiki_details('{{Quest Header|Fame=None}}')['prerequisites'])

    def test_legacy_fields_and_partial_summary(self):
        row = wiki_details('{{Quest|reward=100g|fame=Jeuno|flevel=2|item_reqs=A or<br>B|quest_reqs=[[Earlier]]|Previous=None}}')
        self.assertIn('Jeuno Fame 2', row['prerequisites'])
        self.assertIn('Items Needed: A or B', row['prerequisites'])
        self.assertIn('Quest Requirements: Earlier', row['prerequisites'])
        self.assertNotIn('Previous quest', row['prerequisites'])
        self.assertIn('other conditions may apply', row['prerequisites'])

    def test_start_location_extracts_explicit_npc_zone_and_coordinates(self):
        row = wiki_details(
            "{{Quest Header|Start=[[Curilla]]|Start Location={{Location|Chateau d'Oraguille|I-9}}|Rewards=A}}"
        )
        self.assertEqual(row['npc'], 'Curilla')
        self.assertEqual(row['quest_location'], "Chateau d'Oraguille")
        self.assertEqual(row['npc_coordinates'], 'I-9')
        self.assertEqual(
            wiki_details('{{Quest Header|Start Location={{Location|Altar Room|-}}}}')['npc_coordinates'],
            'N/A',
        )

    def test_borghertz_template_preserves_optional_and_started(self):
        row = wiki_details('{{Borghertz Quest|job=Warrior|previous quest=[[Earlier]]|hands item=[[Gloves]]|hands key=[[Key]]|item 2=[[Legs]]}}')
        self.assertIn('Must have started Earlier', row['prerequisites'])
        self.assertIn('No other Borghertz', row['prerequisites'])
        self.assertIn('lockpicking is an alternative', row['prerequisites'])
        self.assertIn('Optional coffer rewards: Legs', row['rewards'])
        self.assertEqual(wiki_details('{{Borghertz Quest|job=Warrior}}'), {})

    def test_raw_api_aliases_missing_and_errors(self):
        raw = '{{Quest Header|Rewards=A<br>B}}'
        data = {'query': {'normalized': [{'from': 'Old_Name', 'to': 'Old Name'}],
                          'redirects': [{'from': 'Old Name', 'to': 'New Name'}],
                          'pages': [{'title': 'Missing', 'missing': True},
                                    {'title': 'New Name', 'revisions': [{'slots': {'main': {'content': raw}}}]}]}}
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'fixture.json'
            path.write_text(json.dumps(data), encoding='utf-8')
            pages = api_pages([path])
            self.assertEqual(pages['Old Name'], raw)
            self.assertNotIn('Missing', pages)
            path.write_text(json.dumps({'error': {'code': 'test'}}), encoding='utf-8')
            with self.assertRaises(ValueError):
                api_pages([path])

    def test_fame_conflicts_use_explicit_region(self):
        fields = {'prerequisites': "Required Fame: San d'Oria Fame 4"}
        self.assertIn('Fame conflicts', merge_details({}, fields, '5', "San d'Oria")['prerequisites'])
        self.assertNotIn('Fame conflicts', merge_details({}, fields, '5', None)['prerequisites'])


if __name__ == '__main__':
    unittest.main()
