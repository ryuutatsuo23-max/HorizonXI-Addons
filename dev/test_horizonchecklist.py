import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "HXIChecklist"
PROFILE = PACKAGE / "horizon_profile.lua"


class HorizonChecklistSourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.profile = PROFILE.read_text(encoding="utf-8")
        cls.main = (PACKAGE / "HXIChecklist.lua").read_text(encoding="utf-8")
        cls.catalog = (PACKAGE / "catalog.lua").read_text(encoding="utf-8")
        cls.ui = (PACKAGE / "checklist_ui.lua").read_text(encoding="utf-8")
        cls.key_item_state = (PACKAGE / "key_item_state.lua").read_text(
            encoding="utf-8"
        )
        cls.quest_state = (PACKAGE / "quest_state.lua").read_text(
            encoding="utf-8"
        )

    def test_copy_ready_package_contains_only_runtime_lua(self):
        self.assertEqual(
            {path.name for path in PACKAGE.iterdir()},
            {
                "HXIChecklist.lua",
                "catalog.lua",
                "checklist_ui.lua",
                "horizon_profile.lua",
                "key_item_state.lua",
                "quest_state.lua",
            },
        )

    def test_expected_profile_size(self):
        self.assertEqual(self.profile.count("kind = 'spell'"), 12)
        self.assertEqual(self.profile.count("kind = 'key_item'"), 8)
        self.assertEqual(self.profile.count("kind = 'manual'"), 19)

    def test_map_ids_are_explicit_and_stable(self):
        expected = {
            "map.san_doria": 385,
            "map.bastok": 386,
            "map.windurst": 387,
            "map.jeuno": 388,
            "map.zeruhn": 395,
            "map.ghelsba": 404,
            "map.palborough": 406,
            "map.giddeus": 408,
        }
        found = {
            entry_id: int(resource_id)
            for entry_id, resource_id in re.findall(
                r"id = '(map\.[^']+)'.*?resource_id = (\d+)", self.profile
            )
        }
        self.assertEqual(found, expected)
        self.assertIn("id_matches_name(identifier)", self.catalog)
        self.assertIn("identifier <= 0", self.catalog)

    def test_entry_ids_are_unique(self):
        entry_ids = re.findall(
            r"\{ id = '([^']+)',(?: reference_id = '[^']+',)? kind = '(?:spell|key_item|manual)'",
            self.profile,
        )
        self.assertEqual(len(entry_ids), 39)
        self.assertEqual(len(entry_ids), len(set(entry_ids)))

    def test_all_entries_are_sourced(self):
        entry_lines = [
            line for line in self.profile.splitlines()
            if "kind = 'spell'" in line
            or "kind = 'key_item'" in line
            or "kind = 'manual'" in line
        ]
        self.assertEqual(len(entry_lines), 39)
        for line in entry_lines:
            self.assertRegex(line, r"source_url = 'https://")
            self.assertRegex(line, r"availability = '(?:reported_active|wiki_listed|unknown|reported_inactive)'")

    def test_manual_ids_preserve_pilot_range(self):
        ids = re.findall(r"reference_id = '(HXQ-\d{4})'", self.profile)
        expected = [f"HXQ-{number:04d}" for number in range(1, 20)]
        self.assertEqual(ids, expected)

    def test_bastok_pilot_indices_are_explicit_and_stable(self):
        expected = {
            "HXQ-0001": 38,
            "HXQ-0002": 14,
            "HXQ-0003": 87,
            "HXQ-0004": 44,
            "HXQ-0005": 74,
            "HXQ-0006": 41,
            "HXQ-0007": 12,
            "HXQ-0008": 21,
            "HXQ-0009": 16,
            "HXQ-0010": 11,
            "HXQ-0011": 13,
            "HXQ-0012": 76,
            "HXQ-0013": 10,
            "HXQ-0014": 22,
            "HXQ-0015": 29,
            "HXQ-0016": 30,
            "HXQ-0017": 34,
            "HXQ-0018": 64,
            "HXQ-0019": 85,
        }
        found = {
            entry_id: int(quest_index)
            for entry_id, quest_index in re.findall(
                r"id = '(HXQ-\d{4})'.*?quest_area = 'bastok'.*?quest_index = (\d+)",
                self.profile,
            )
        }
        self.assertEqual(found, expected)

    def test_unknown_and_inactive_are_explicit(self):
        self.assertIn("id = 'HXQ-0003'", self.profile)
        self.assertIn("availability = 'unknown'", self.profile)
        self.assertIn("id = 'HXQ-0012'", self.profile)
        self.assertIn("availability = 'reported_inactive'", self.profile)
        self.assertIn("if entry.availability == 'reported_inactive'", self.catalog)
        self.assertIn("return 'unknown'", self.catalog)

        unknown_check = "if entry.availability == 'unknown'"
        manual_check = "if manual_completed[entry.id] == true"
        manual_branch = self.catalog.index("if entry.kind == 'manual'")
        self.assertLess(
            self.catalog.index(unknown_check, manual_branch),
            self.catalog.index(manual_check, manual_branch),
        )

    def test_no_outgoing_packet_or_input_automation_surface(self):
        combined = "\n".join(
            path.read_text(encoding="utf-8")
            for path in PACKAGE.glob("*.lua")
        ).lower()
        forbidden = (
            "packet_out",
            "queuecommand",
            "injectincoming",
            "injectoutgoing",
            "keybinder",
            "loadstring",
        )
        for token in forbidden:
            self.assertNotIn(token, combined)
        self.assertIn("ashita.events.register('packet_in'", self.main)

    def test_direct_checks_use_read_only_player_interfaces(self):
        self.assertIn("player:HasSpell(identifier)", self.catalog)
        self.assertIn("player:HasKeyItem(identifier)", self.catalog)
        self.assertIn("manager:GetSpellByName", self.catalog)
        self.assertIn("manager:GetString('keyitems.names'", self.catalog)

    def test_key_item_log_parser_is_read_only_and_fail_closed(self):
        self.assertIn("e.id ~= 0x055", self.key_item_state)
        self.assertIn("available_offset = 0x04", self.key_item_state)
        self.assertIn("available_length = 0x40", self.key_item_state)
        self.assertIn("type_offset = 0x84", self.key_item_state)
        self.assertIn("key_items_per_group = 0x200", self.key_item_state)
        self.assertIn("key_item_state.has_key_item(identifier)", self.catalog)
        self.assertIn("return 'unknown', packet_note", self.catalog)

    def test_quest_log_parser_is_bastok_only_and_fail_closed(self):
        self.assertIn("e.id ~= 0x056", self.quest_state)
        self.assertIn("flags_offset = 0x04", self.quest_state)
        self.assertIn("flags_length = 0x20", self.quest_state)
        self.assertIn("type_offset = 0x24", self.quest_state)
        self.assertIn("bastok_current_type = 0x0058", self.quest_state)
        self.assertIn("bastok_completed_type = 0x0098", self.quest_state)
        self.assertIn("logs.current == nil or logs.completed == nil", self.quest_state)
        self.assertIn("quest_state.get_bastok(entry.quest_index)", self.catalog)
        for state in ("auto_complete", "auto_current", "auto_not_logged"):
            self.assertIn(state, self.catalog)

    def test_requested_state_badges_and_unknown_color(self):
        expected_badges = {
            "complete": "Checked",
            "missing": "Missing",
            "auto_current": "Accepted",
            "auto_not_logged": "Not Accepted",
        }
        for state, badge in expected_badges.items():
            self.assertIn(f"{state} = '{badge}'", self.ui)
        self.assertIn("unknown = { 1.00, 0.30, 0.30, 1.00 }", self.ui)
        self.assertIn("auto_complete = 'AUTO DONE'", self.ui)

    def test_commands_are_addon_local(self):
        self.assertIn("addon.name = 'HXIChecklist'", self.main)
        for command in ("/hxichecklist", "/horizonchecklist", "/hcheck", "/hc"):
            self.assertIn(f"'{command}'", self.main)
        self.assertNotIn("ashita.events.register('packet_out'", self.main)


if __name__ == "__main__":
    unittest.main()
