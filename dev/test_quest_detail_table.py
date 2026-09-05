import unittest

from quest_detail_table import merge_details, page_details, plain, table_rows, title


class QuestDetailEvidenceTests(unittest.TestCase):
    def test_balanced_link_and_redlink_titles(self):
        self.assertEqual(plain('[Quest](https://horizonffxi.wiki/Quest_(Bastok) "Quest")'), 'Quest')
        self.assertEqual(title('https://horizonffxi.wiki/w/index.php?title=Quest_(Bastok)&redlink=1'), 'Quest (Bastok)')
        self.assertEqual(plain('[H-6](https://horizonffxi.wiki/Maps)'), 'H-6')

    def test_missing_is_not_none(self):
        for value in ('', '—', '???', 'None [Information Needed](https://example.test)'):
            self.assertIsNone(plain(value))
        self.assertEqual(plain('_None_'), 'None')

    def test_removed_rewards_and_escaped_link_titles(self):
        self.assertEqual(plain('New weapon<br>~~Old weapon ~~~~~~<br>~~~~~~~~'), 'New weapon')
        self.assertEqual(plain(r'["Formula"](https://horizonffxi.wiki/Formula "\"Formula\" (page does not exist)")'), '"Formula"')

    def test_only_detailed_category_tables_count(self):
        source = '''| Quest | Reward |
| [A](https://horizonffxi.wiki/A) | 999 gil |

| Quest | Type | NPC | Pos. | Reward |
| --- | --- | --- | --- | --- |
| [A](https://horizonffxi.wiki/A) | General | NPC | [H-6](https://horizonffxi.wiki/Maps) | 100 gil |
'''
        row = table_rows(source)['A']
        self.assertEqual(row['npc_coordinates'], 'H-6')
        self.assertIn('100 gil', row['rewards'])
        self.assertIn('category listing', row['rewards'])
        self.assertNotIn('prerequisites', row)

    def test_conflicting_rows_fail_closed(self):
        source = '''| Quest | NPC | Pos. | Reward |
| [A](https://horizonffxi.wiki/A) | N | H-6 | 100 gil |
| [A](https://horizonffxi.wiki/A) | N | H-7 | 100 gil |
'''
        with self.assertRaises(ValueError):
            table_rows(source)

    def test_page_requirements_and_previous_quest_preserve_context(self):
        source = '''# A
| Starting NPC | NPC (H-6) |
| Required Fame | Bastok Level 2 |
| Additional Requirements | Level 30 to finish, not to start |
| Level Restriction: | Level 30+ |
| Items Needed | Item A or<br>Item B |
| Rewards |
| 100 - 350 gil |

| Previous Quest | Next Quest |
| --- | --- |
| [B](https://horizonffxi.wiki/B) | C |

## Walkthrough
| Rewards |
| This is not an infobox reward |
'''
        row = page_details(source)
        self.assertIn('100 - 350 gil', row['rewards'])
        self.assertIn('Bastok Fame 2', row['prerequisites'])
        self.assertIn('not to start', row['prerequisites'])
        self.assertIn('Level Restriction: Level 30+', row['prerequisites'])
        self.assertIn('Item A or Item B', row['prerequisites'])
        self.assertIn('Previous quest listed: B', row['prerequisites'])
        self.assertIn('other conditions may apply', row['prerequisites'])
        self.assertNotIn('This is not', row['rewards'])

    def test_absent_page_fields_do_not_claim_no_requirements(self):
        self.assertEqual(page_details('| Starting NPC | NPC |\n| Rewards |\n| — |'), {})
        self.assertEqual(page_details('Error page'), {})

    def test_unknown_markup_fails_closed(self):
        with self.assertRaises(ValueError):
            plain('<unknown>value</unknown>')

    def test_source_conflicts_remain_explicit(self):
        result = merge_details({'rewards': '8000 gil (category listing)'},
                               {'rewards': 'None (see Source for conditions)',
                                'prerequisites': 'Required Fame: Bastok Fame 1'}, '2')
        self.assertIn('conflicting sources', result['rewards'])
        self.assertIn('8000 gil', result['rewards'])
        self.assertIn('Fame conflicts', result['prerequisites'])
        self.assertIn('conflicting sources', merge_details({'rewards': '500 gil'}, {'rewards': '550g'})['rewards'])
        self.assertEqual(merge_details({'rewards': '500 gil'}, {'rewards': '500g'})['rewards'], '500g')


if __name__ == '__main__':
    unittest.main()
