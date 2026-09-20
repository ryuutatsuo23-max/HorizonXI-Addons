import unittest

from mission_wikitext import details, header_fields, location_details, source_title


class MissionWikitextTests(unittest.TestCase):
    def test_header_continuation_and_named_location(self):
        raw = """{{Mission Header
| Mission Name = Test
| Start = [[Naja Salaheem]]
| Start Location = [[Salaheem's Sentinels]],
| {{Location Tooltip|area=Aht Urhgan Whitegate|pos=I-10|text=Whitegate (I-10)}}
| Previous = Earlier Mission
| Rewards = * [[Reward One]]
* [[Reward Two]]
}}"""
        fields = header_fields(raw)
        self.assertIn('Location Tooltip', fields['start location'])
        row = details(raw)
        self.assertEqual(row['npc'], 'Naja Salaheem')
        self.assertEqual(row['quest_location'], "Salaheem's Sentinels, Aht Urhgan Whitegate")
        self.assertEqual(row['npc_coordinates'], 'I-10')
        self.assertEqual(row['rewards'], 'Reward One; Reward Two (mission page; see Source for conditions)')
        self.assertIn('Previous mission: Earlier Mission', row['prerequisites'])

    def test_gate_guard_and_explicit_requirements(self):
        raw = """{{Mission Header
|Start=Any [[Windurst Gate Guard]]
|Previous=Windurst Mission 1-1{{!}}The Horutoto Ruins Experiment
|Level=25+
|Items Needed={{KeyItem}}[[Test Permit]][[Test Item]]
}}"""
        row = details(raw, {
            'mission_rank': 2,
            'mission_area_name': 'Windurst',
            'quest_location': 'Windurst gate-guard locations',
        })
        self.assertEqual(row['npc'], 'Any Windurst Gate Guard')
        self.assertEqual(row['quest_location'], 'Windurst gate-guard locations')
        self.assertEqual(row['npc_coordinates'], 'Varies by gate guard')
        self.assertIn('Previous mission: The Horutoto Ruins Experiment', row['prerequisites'])
        self.assertIn('Level: 25+', row['prerequisites'])
        self.assertIn('Items needed: Test Permit; Test Item', row['prerequisites'])

    def test_blank_continuation_is_not_invented(self):
        row = details('{{Mission Header|Start=|Start Location=|Previous=Earlier|Rewards=None}}')
        self.assertEqual(row['npc'], 'No separate start listed')
        self.assertEqual(row['quest_location'], 'Continues from previous mission')
        self.assertEqual(row['npc_coordinates'], 'N/A')
        self.assertEqual(row['rewards'], 'None (mission page; see Source for conditions)')

    def test_simple_location_and_source_title(self):
        self.assertEqual(location_details('{{Location|Norg|L-8}}'), ('Norg', 'L-8'))
        self.assertEqual(source_title('https://horizonffxi.wiki/Ro%27Maeve(Mission)'), "Ro'Maeve(Mission)")


if __name__ == '__main__':
    unittest.main()
