import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "HXIChecklist"
PROFILE = PACKAGE / "horizon_profile.lua"
MAGIC_DATA = PACKAGE / "magic_data.lua"
MAP_DATA = PACKAGE / "map_data.lua"
BASTOK_QUEST_DATA = PACKAGE / "bastok_quest_data.lua"
SANDORIA_QUEST_DATA = PACKAGE / "sandoria_quest_data.lua"
WINDURST_QUEST_DATA = PACKAGE / "windurst_quest_data.lua"
JEUNO_QUEST_DATA = PACKAGE / "jeuno_quest_data.lua"
OTHER_QUEST_DATA = PACKAGE / "other_quest_data.lua"
OUTLANDS_QUEST_DATA = PACKAGE / "outlands_quest_data.lua"
AHTURHGAN_QUEST_DATA = PACKAGE / "ahturhgan_quest_data.lua"
CUSTOM_QUEST_DATA = PACKAGE / "custom_quest_data.lua"
MISSION_DATA = [
    PACKAGE / "sandoria_mission_data.lua",
    PACKAGE / "bastok_mission_data.lua",
    PACKAGE / "windurst_mission_data.lua",
    PACKAGE / "zilart_mission_data.lua",
    PACKAGE / "promathia_mission_data.lua",
    PACKAGE / "ahturhgan_mission_data.lua",
]
SKILL_LEVELS = PACKAGE / "skill_levels.lua"


class HorizonChecklistSourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.profile = PROFILE.read_text(encoding="utf-8")
        cls.magic_data = MAGIC_DATA.read_text(encoding="utf-8")
        cls.map_data = MAP_DATA.read_text(encoding="utf-8")
        cls.bastok_quest_data = BASTOK_QUEST_DATA.read_text(encoding="utf-8")
        cls.sandoria_quest_data = SANDORIA_QUEST_DATA.read_text(encoding="utf-8")
        cls.windurst_quest_data = WINDURST_QUEST_DATA.read_text(encoding="utf-8")
        cls.jeuno_quest_data = JEUNO_QUEST_DATA.read_text(encoding="utf-8")
        cls.other_quest_data = OTHER_QUEST_DATA.read_text(encoding="utf-8")
        cls.outlands_quest_data = OUTLANDS_QUEST_DATA.read_text(encoding="utf-8")
        cls.ahturhgan_quest_data = AHTURHGAN_QUEST_DATA.read_text(encoding="utf-8")
        cls.custom_quest_data = CUSTOM_QUEST_DATA.read_text(encoding="utf-8")
        cls.mission_data = [path.read_text(encoding="utf-8") for path in MISSION_DATA]
        cls.skill_levels = SKILL_LEVELS.read_text(encoding="utf-8")
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
                "mission_state.lua",
                "sandoria_mission_data.lua",
                "bastok_mission_data.lua",
                "windurst_mission_data.lua",
                "zilart_mission_data.lua",
                "promathia_mission_data.lua",
                "ahturhgan_mission_data.lua",
                "ahturhgan_quest_data.lua",
                "bastok_quest_data.lua",
                "catalog.lua",
                "custom_quest_data.lua",
                "checklist_ui.lua",
                "horizon_profile.lua",
                "job_levels.lua",
                "jeuno_quest_data.lua",
                "key_item_state.lua",
                "magic_data.lua",
                "map_data.lua",
                "other_quest_data.lua",
                "outlands_quest_data.lua",
                "quest_state.lua",
                "sandoria_quest_data.lua",
                "skill_levels.lua",
                "windurst_quest_data.lua",
            },
        )

    def test_expected_profile_size(self):
        self.assertIn("addon.version = '0.21.0'", self.main)
        self.assertIn("version = '2026-09-07-foundation.20'", self.profile)
        spell_ids = re.findall(r"^\s*\{\s*(\d+),", self.magic_data, re.MULTILINE)
        self.assertEqual(len(spell_ids), 316)
        map_ids = re.findall(r"^\s*\{ '(map\.[^']+)',\s*(\d+),", self.map_data, re.MULTILINE)
        self.assertEqual(len(map_ids), 72)
        self.assertEqual(self.bastok_quest_data.count("kind = 'manual'"), 93)
        self.assertEqual(self.sandoria_quest_data.count("kind = 'manual'"), 82)
        self.assertEqual(self.windurst_quest_data.count("kind = 'manual'"), 90)
        self.assertEqual(self.jeuno_quest_data.count("kind = 'manual'"), 146)
        self.assertEqual(self.other_quest_data.count("kind = 'manual'"), 91)
        self.assertEqual(self.outlands_quest_data.count("kind = 'manual'"), 57)
        self.assertEqual(self.ahturhgan_quest_data.count("kind = 'manual'"), 72)
        self.assertEqual(self.custom_quest_data.count("tracking = 'manual'"), 4)

    def test_magic_categories_and_counts(self):
        expected = {
            "dark_magic": 15,
            "divine_magic": 8,
            "elemental_magic": 60,
            "enfeebling_magic": 19,
            "enhancing_magic": 76,
            "healing_magic": 22,
            "summoning": 17,
            "ninjutsu": 23,
            "songs": 76,
        }
        blocks = re.findall(
            r"(?ms)^        id = '([^']+)'.*?^        spells = \{\n(.*?)^        \},\n^    \},",
            self.magic_data,
        )
        found = {
            skill_id: len(re.findall(r"^\s*\{\s*\d+,", rows, re.MULTILINE))
            for skill_id, rows in blocks
        }
        self.assertEqual(found, expected)
        for name in (
            "All Magic",
            "Dark Magic",
            "Divine Magic",
            "Elemental Magic",
            "Enfeebling Magic",
            "Enhancing Magic",
            "Healing Magic",
            "Summoning",
            "Ninjutsu",
            "Songs",
        ):
            self.assertIn(f"name = '{name}'", self.magic_data)
        self.assertIn("name = 'Magic Skills'", self.profile)
        self.assertNotIn("name = 'Starter Spells'", self.profile)

    def test_magic_rows_use_explicit_unique_client_ids(self):
        ids = [
            int(resource_id)
            for resource_id in re.findall(
                r"^\s*\{\s*(\d+),", self.magic_data, re.MULTILINE
            )
        ]
        self.assertEqual(len(ids), 316)
        self.assertEqual(len(ids), len(set(ids)))
        self.assertIn("{ 273, 'Sleepga' }", self.magic_data)
        self.assertIn("{ 274, 'Sleepga II' }", self.magic_data)
        self.assertIn("{ 260, 'Dispel', 'Dispel_(Spell)' }", self.magic_data)
        self.assertIn("{ 304, 'Diabolos' }", self.magic_data)
        self.assertIn("{ 337, 'Suiton: San' }", self.magic_data)
        self.assertIn("{ 458, 'Lightning Threnody', 'Lightning_Threnody', 'Ltng. Threnody' }", self.magic_data)
        for excluded in ("Bindga", "Diaga II", "Slowga", "Enlight"):
            self.assertNotRegex(
                self.magic_data,
                rf"\{{\s*\d+,\s*['\"]{re.escape(excluded)}['\"]",
            )

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
                r"^\s*\{ '(map\.[^']+)',\s*(\d+),", self.map_data, re.MULTILINE
            )
        }
        self.assertEqual(len(found), 72)
        self.assertEqual({key: found[key] for key in expected}, expected)
        self.assertEqual(len(found.values()), len(set(found.values())))
        self.assertEqual(found["map.al_zahbi"], 1856)
        self.assertEqual(found["map.bhaflau_thickets"], 1874)
        self.assertIn("id_matches_name(identifier)", self.catalog)
        self.assertIn("identifier <= 0", self.catalog)

    def test_map_catalog_matches_sourced_horizon_table_scope(self):
        expected = {
            "original_areas": 28,
            "rise_of_the_zilart": 16,
            "chains_of_promathia": 17,
            "treasures_of_aht_urhgan": 11,
        }
        blocks = re.findall(
            r"(?ms)^        id = '([^']+)'.*?^        maps = \{\n(.*?)^        \},\n^    \},",
            self.map_data,
        )
        found = {
            catalog_id: len(re.findall(r"^\s*\{ 'map\.", rows, re.MULTILINE))
            for catalog_id, rows in blocks
        }
        self.assertEqual(found, expected)
        for name in (
            "All Maps",
            "Original Areas",
            "Rise of the Zilart",
            "Chains of Promathia",
            "Treasures of Aht Urhgan",
        ):
            self.assertIn(f"name = '{name}'", self.map_data)
        self.assertIn("name = 'Maps'", self.profile)
        self.assertNotIn("name = 'Starter Maps'", self.profile)
        self.assertNotIn("map.uleguerand_range", self.map_data)
        self.assertNotIn("map.leujaoam_sanctum", self.map_data)

    def test_entry_ids_are_unique(self):
        quest_entry_ids = re.findall(
            r"\{\s*id = '([^']+)',(?:\s*reference_id = '[^']+',)?\s*kind = '(?:spell|key_item|manual)'",
            self.bastok_quest_data + self.sandoria_quest_data + self.windurst_quest_data + self.jeuno_quest_data + self.other_quest_data + self.outlands_quest_data + self.ahturhgan_quest_data + self.custom_quest_data,
        )
        self.assertEqual(len(quest_entry_ids), 635)
        self.assertEqual(len(quest_entry_ids), len(set(quest_entry_ids)))

        spell_ids = re.findall(r"^\s*\{\s*(\d+),", self.magic_data, re.MULTILINE)
        generated_ids = [f"spell.{resource_id}" for resource_id in spell_ids]
        map_ids = re.findall(r"^\s*\{ '(map\.[^']+)',", self.map_data, re.MULTILINE)
        mission_ids = []
        for data in self.mission_data:
            mission_ids.extend(re.findall(r"\{ id = '([^']+)'", data.split('data.entries = {')[1]))
        self.assertEqual(len(mission_ids), 160)
        all_ids = quest_entry_ids + generated_ids + map_ids + mission_ids
        self.assertEqual(len(all_ids), 1183)
        self.assertEqual(len(all_ids), len(set(all_ids)))

    def test_all_entries_are_sourced(self):
        entry_lines = [
            line for line in (
                self.bastok_quest_data
                + self.sandoria_quest_data
                + self.windurst_quest_data
                + self.jeuno_quest_data
                + self.other_quest_data
                + self.outlands_quest_data
                + self.ahturhgan_quest_data
            ).splitlines()
            if "kind = 'spell'" in line
            or "kind = 'key_item'" in line
            or "kind = 'manual'" in line
        ]
        self.assertEqual(len(entry_lines), 631)
        for line in entry_lines:
            self.assertRegex(line, r"source_url = 'https://")
            self.assertRegex(line, r"availability = '(?:reported_active|wiki_listed|unknown|reported_inactive)'")
        category_sources = re.findall(
            r"^        source_url = 'https://horizonffxi\.wiki/[^']+'",
            self.magic_data,
            re.MULTILINE,
        )
        self.assertEqual(len(category_sources), 9)
        self.assertIn("source_url = 'https://horizonffxi.wiki/' .. wiki_slug", self.magic_data)
        self.assertIn("availability = 'wiki_listed'", self.magic_data)
        self.assertIn("category_source_url = 'https://horizonffxi.wiki/Category:Magical_Maps'", self.map_data)
        self.assertIn("availability = 'wiki_listed'", self.map_data)
        self.assertIn("source_url = map[5] ~= nil", self.map_data)

    def test_manual_ids_preserve_pilot_range(self):
        ids = re.findall(r"reference_id = '(HXQ-\d{4})'", self.bastok_quest_data)
        expected = [f"HXQ-{number:04d}" for number in range(1, 20)]
        self.assertEqual(sorted(ids), expected)

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
                self.bastok_quest_data,
            )
        }
        self.assertEqual(found, expected)

    def test_unknown_and_inactive_are_explicit(self):
        self.assertIn("id = 'HXQ-0003'", self.bastok_quest_data)
        self.assertIn("availability = 'unknown'", self.bastok_quest_data)
        self.assertIn("id = 'HXQ-0012'", self.bastok_quest_data)
        self.assertIn("availability = 'reported_inactive'", self.bastok_quest_data)
        self.assertIn("if entry.availability == 'reported_inactive'", self.catalog)
        self.assertIn("return 'unknown'", self.catalog)

        self.assertIn("return 'unknown', automatic_note", self.catalog)

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
        self.assertIn("manager:GetSpellById", self.catalog)
        self.assertIn("resource.Name and resource.Name[1]", self.catalog)
        self.assertIn("resource.Skill ~= math.floor(entry.skill_id)", self.catalog)
        self.assertIn("manager:GetString('keyitems.names'", self.catalog)

    def test_magic_category_selector_filters_the_shared_snapshot(self):
        self.assertIn("views = category.views", self.catalog)
        self.assertIn("category.views and #category.views > 0", self.ui)
        self.assertIn("selected_views = {}", self.main)
        self.assertIn("selector_label or 'Category'", self.ui)
        self.assertIn("imgui.Selectable(", self.ui)
        self.assertIn("item.magic_skill ~= view.magic_skill", self.ui)
        self.assertIn("item.map_catalog ~= view.map_catalog", self.ui)
        self.assertIn("item.quest_location ~= view.quest_location", self.ui)
        self.assertNotIn("##HXIChecklistViews_", self.ui)
        self.assertIn(
            "        render_quest_type_filter(category, ui_state, imgui);\n"
            "        imgui.Separator();", self.ui)

    def test_magic_rows_align_sources_and_show_client_job_levels(self):
        job_levels = (PACKAGE / "job_levels.lua").read_text(encoding="utf-8")
        for job_id, abbreviation in enumerate(
            (
                "WAR", "MNK", "WHM", "BLM", "RDM", "THF", "PLD",
                "DRK", "BST", "BRD", "RNG", "SAM", "NIN", "DRG",
                "SMN", "BLU", "COR", "PUP", "DNC", "SCH",
            ),
            start=1,
        ):
            self.assertIn(f"{{ {job_id}, '{abbreviation}' }}", job_levels)
        self.assertIn("resource.LevelRequired", self.catalog)
        self.assertIn("job_levels.format(resource.LevelRequired, 75)", self.catalog)
        self.assertIn("item.job_levels = resolve_spell_requirements(entry)", self.catalog)
        self.assertIn("category.id == 'magic_skills'", self.ui)
        self.assertIn("imgui.BeginTable('##MagicRows', 3, table_flags)", self.ui)
        self.assertIn("ImGuiTableFlags_Resizable", self.ui)
        self.assertIn("ImGuiTableFlags_BordersInnerV", self.ui)
        self.assertIn("imgui.GetWindowWidth() * 0.35", self.ui)
        self.assertIn("ImGuiTableColumnFlags_WidthFixed, magic_width", self.ui)
        self.assertIn("imgui.CalcTextSize('Source') + 24", self.ui)
        self.assertIn("ImGuiTableColumnFlags_WidthFixed, source_width", self.ui)
        self.assertIn("imgui.TextWrapped(item.job_levels)", self.ui)
        self.assertIn("'Job levels unavailable'", self.ui)

    def test_scale_uses_supported_font_stack_fallback(self):
        self.assertIn("local function apply_font_scale(settings, imgui)", self.ui)
        self.assertIn("imgui.SetWindowFontScale(scale)", self.ui)
        self.assertIn("imgui.PushFont(nil, imgui.GetFontSize() * scale)", self.ui)
        self.assertIn("imgui.PopFont()", self.ui)

    def test_resizable_dividers_are_visible_and_explained(self):
        self.assertIn("'Drag the vertical dividers to resize columns.'", self.ui)
        self.assertIn("ImGuiCol_TableBorderStrong", self.ui)
        self.assertIn("ImGuiCol_TableBorderLight", self.ui)
        self.assertIn("imgui.PopStyleColor(2)", self.ui)
        self.assertNotIn("job_levels_compact", self.ui)

    def test_map_rows_align_sources_with_a_resizable_divider(self):
        self.assertIn("category.id == 'maps'", self.ui)
        self.assertIn("imgui.BeginTable('##MapRows', 3, table_flags)", self.ui)
        self.assertIn("ImGuiTableColumnFlags_WidthFixed, map_width", self.ui)
        self.assertIn("ImGuiTableColumnFlags_WidthFixed, source_width", self.ui)
        self.assertIn("ImGuiTableColumnFlags_WidthStretch, 1.0", self.ui)
        self.assertIn("'Drag the vertical dividers to resize Map, Source, and Obtained columns.'", self.ui)
        self.assertIn("render_map_entry(item, actions, imgui)", self.ui)
        self.assertIn("imgui.TextWrapped(item.vendor_cost)", self.ui)
        self.assertIn("imgui.TextWrapped(item.acquisition_method)", self.ui)
        self.assertIn("'Acquisition method listed in the HorizonXI Magical Maps table.'", self.ui)

    def test_bastok_quests_cover_client_indices_and_sourced_fame(self):
        pairs = [
            (int(index), name)
            for index, name in re.findall(
                r"quest_index = (\d+), name = '((?:\\'|[^'])+)'",
                self.bastok_quest_data,
            )
        ]
        self.assertEqual([index for index, _ in pairs], list(range(93)))
        self.assertEqual(len({name for _, name in pairs}), 93)
        self.assertEqual(self.bastok_quest_data.count("fame_level = "), 67)
        self.assertEqual(self.bastok_quest_data.count("fame_label = 'Not listed'"), 21)
        self.assertEqual(self.bastok_quest_data.count("fame_label = 'Unknown'"), 5)
        self.assertIn("name = 'Bastok Quests'", self.profile)
        self.assertNotIn("Bastok Markets Pilot", self.profile)
        self.assertIn("name = 'All Quests'", self.bastok_quest_data)
        self.assertIn("name = 'Unresolved'", self.bastok_quest_data)

    def test_bastok_rows_align_source_and_fame_with_resizable_dividers(self):
        self.assertIn("bastok_quests = 'Bastok'", self.ui)
        self.assertIn("sandoria_quests = \"San d'Oria\"", self.ui)
        self.assertIn("windurst_quests = 'Windurst'", self.ui)
        self.assertIn("jeuno_quests = 'Jeuno'", self.ui)
        self.assertIn("local nation_name = quest_nation_names[category.id]", self.ui)
        self.assertIn("imgui.BeginTable(('##%sRows'):fmt(category.id), 3, table_flags)", self.ui)
        self.assertIn("ImGuiTableColumnFlags_WidthFixed, quest_width", self.ui)
        self.assertIn("ImGuiTableColumnFlags_WidthFixed, source_width", self.ui)
        self.assertIn("nation_name .. ' Fame'", self.ui)
        self.assertIn("('Fame %d'):fmt(item.fame_level)", self.ui)
        self.assertIn("'Not listed'", self.ui)
        self.assertIn("'Click + for details. Drag dividers to resize Quest, Source, and %s columns.'", self.ui)
        self.assertIn("render_nation_quest_entry(item, nation_name, ui_state, actions, imgui)", self.ui)

    def test_sandoria_quests_cover_named_client_indices_and_sourced_fame(self):
        indices = [
            int(index)
            for index in re.findall(r"quest_index = (\d+)", self.sandoria_quest_data)
        ]
        self.assertEqual(len(indices), 82)
        self.assertEqual(len(indices), len(set(indices)))
        self.assertEqual(indices, sorted(indices))
        self.assertEqual(indices[0], 0)
        self.assertEqual(indices[-1], 119)
        self.assertEqual(self.sandoria_quest_data.count("fame_level = "), 60)
        self.assertEqual(self.sandoria_quest_data.count("fame_label = 'Not listed'"), 19)
        self.assertEqual(self.sandoria_quest_data.count("fame_label = 'Unknown'"), 3)
        self.assertEqual(self.sandoria_quest_data.count("availability = 'unknown'"), 2)
        self.assertIn("name = \"San d'Oria Quests\"", self.profile)
        for name in (
            "Northern San d\\'Oria",
            "Southern San d\\'Oria",
            "Port San d\\'Oria",
            "Chateau d\\'Oraguille",
            "Bostaunieux Oubliette",
            "West Ronfaure",
            "Unresolved",
        ):
            self.assertIn(f"name = '{name}'", self.sandoria_quest_data)

    def test_windurst_quests_cover_named_client_indices_and_sourced_fame(self):
        indices = [
            int(index)
            for index in re.findall(r"quest_index = (\d+)", self.windurst_quest_data)
        ]
        self.assertEqual(len(indices), 90)
        self.assertEqual(len(indices), len(set(indices)))
        self.assertEqual(indices, sorted(indices))
        self.assertEqual(indices[0], 0)
        self.assertEqual(indices[-1], 96)
        self.assertEqual(self.windurst_quest_data.count("fame_level = "), 65)
        self.assertEqual(self.windurst_quest_data.count("fame_label = 'Not listed'"), 22)
        self.assertEqual(self.windurst_quest_data.count("fame_label = 'Unknown'"), 3)
        self.assertEqual(self.windurst_quest_data.count("availability = 'unknown'"), 1)
        self.assertEqual(self.windurst_quest_data.count("availability = 'reported_inactive'"), 4)
        self.assertIn("name = 'Windurst Quests'", self.profile)
        for name in (
            "Windurst Woods",
            "Windurst Waters North",
            "Windurst Waters South",
            "Port Windurst",
            "Windurst Walls",
            "Heavens Tower",
            "Unresolved",
        ):
            self.assertIn(f"name = '{name}'", self.windurst_quest_data)
        self.assertNotIn("name = 'A Chocobo Riding Game (Windurst)'", self.windurst_quest_data)
        self.assertNotIn("name = 'Dyer\\'s Woad Quest'", self.windurst_quest_data)
        for name in (
            "Let Sleeping Dogs Lie",
            "Nothing Matters",
            "Escort for Hire (Windurst)",
            "A Discerning Eye (Windurst)",
        ):
            line = next(
                line for line in self.windurst_quest_data.splitlines()
                if f"name = '{name}'" in line
            )
            self.assertIn("availability = 'reported_inactive'", line)

    def test_jeuno_quests_preserve_client_slots_and_explicit_unknowns(self):
        indices = [int(index) for index in re.findall(r"quest_index = (\d+)", self.jeuno_quest_data)]
        self.assertEqual(len(indices), 146)
        self.assertEqual(len(indices), len(set(indices)))
        self.assertEqual(indices, sorted(indices))
        self.assertEqual((indices[0], indices[-1]), (0, 186))
        self.assertNotIn(33, indices)
        self.assertNotIn(122, indices)
        self.assertEqual(self.jeuno_quest_data.count("fame_level = "), 32)
        self.assertEqual(self.jeuno_quest_data.count("fame_label = 'Not listed'"), 47)
        self.assertEqual(self.jeuno_quest_data.count("fame_label = 'Unknown'"), 67)
        self.assertEqual(self.jeuno_quest_data.count("availability = 'unknown'"), 63)
        self.assertEqual(self.jeuno_quest_data.count("availability = 'wiki_listed'"), 83)
        self.assertIn("name = 'Jeuno Quests'", self.profile)
        self.assertNotIn("name = 'Omni Aketon'", self.jeuno_quest_data)
        self.assertIn("or entry.quest_area == 'jeuno'", self.catalog)

    def test_other_quests_keep_log_indices_availability_and_fame_context(self):
        indices = [int(index) for index in re.findall(r"quest_index = (\d+)", self.other_quest_data)]
        self.assertEqual(len(indices), 91)
        self.assertEqual(len(indices), len(set(indices)))
        self.assertEqual(indices, sorted(indices))
        self.assertEqual((indices[0], indices[-1]), (0, 209))
        self.assertNotIn(12, indices)
        self.assertNotIn(1039, indices)
        self.assertEqual(self.other_quest_data.count("fame_level = "), 19)
        self.assertEqual(self.other_quest_data.count("fame_label = 'Not listed'"), 41)
        self.assertEqual(self.other_quest_data.count("fame_label = 'Unknown'"), 31)
        self.assertEqual(self.other_quest_data.count("availability = 'wiki_listed'"), 56)
        self.assertEqual(self.other_quest_data.count("availability = 'unknown'"), 34)
        self.assertEqual(self.other_quest_data.count("availability = 'reported_inactive'"), 1)
        self.assertEqual(self.other_quest_data.count("fame_region = 'Selbina'"), 5)
        self.assertEqual(self.other_quest_data.count("fame_region = 'Mhaura'"), 11)
        self.assertNotIn("fame_region = 'Mog House'", self.other_quest_data)
        self.assertIn("other_quests = 'Other Areas'", self.ui)
        self.assertIn("and 'Required Fame' or nation_name .. ' Fame'", self.ui)
        self.assertIn("imgui.TextWrapped(item.fame_note)", self.ui)
        self.assertIn("or entry.quest_area == 'other'", self.catalog)

    def test_outlands_quests_keep_indices_sources_and_cache_wiring(self):
        indices = [int(index) for index in re.findall(r"quest_index = (\d+)", self.outlands_quest_data)]
        self.assertEqual(len(indices), 57)
        self.assertEqual(indices, sorted(set(indices)))
        self.assertEqual((indices[0], indices[-1]), (1, 203))
        for placeholder in (0, 5, 128, 198, 204):
            self.assertNotIn(placeholder, indices)
        self.assertEqual(self.outlands_quest_data.count("fame_level = "), 23)
        self.assertEqual(self.outlands_quest_data.count("fame_label = 'Not listed'"), 28)
        self.assertEqual(self.outlands_quest_data.count("availability = 'wiki_listed'"), 51)
        self.assertEqual(self.outlands_quest_data.count("availability = 'unknown'"), 6)
        self.assertIn("outlands_quests = 'Outlands'", self.ui)
        self.assertIn("or category.id == 'outlands_quests'", self.ui)
        self.assertIn("or entry.quest_area == 'outlands'", self.catalog)
        self.assertIn("current_type = 0x0078, completed_type = 0x00B8", self.quest_state)
        self.assertIn("outlands_quests = T{}", self.main)
        self.assertIn("quest_state.load_area_cache('outlands', state.settings.cached_state.outlands_quests)", self.main)
        self.assertIn("value.cached_state.outlands_quests = value.cached_state.outlands_quests or T{}", self.main)

    def test_ahturhgan_quests_keep_short_log_and_fame_boundaries(self):
        indices = [int(index) for index in re.findall(r"quest_index = (\d+)", self.ahturhgan_quest_data)]
        self.assertEqual(len(indices), 72)
        self.assertEqual(indices, sorted(set(indices)))
        self.assertEqual((indices[0], indices[-1]), (0, 103))
        for placeholder in (11, 33, 42, 89, 100, 128):
            self.assertNotIn(placeholder, indices)
        self.assertEqual(self.ahturhgan_quest_data.count("availability = 'wiki_listed'"), 72)
        self.assertEqual(self.ahturhgan_quest_data.count("fame_label = 'N/A'"), 72)
        self.assertNotIn("fame_level = ", self.ahturhgan_quest_data)
        self.assertNotIn("action=edit", self.ahturhgan_quest_data)
        self.assertIn("ahturhgan_quests = 'Aht Urhgan'", self.ui)
        self.assertIn("or category.id == 'ahturhgan_quests'", self.ui)
        self.assertIn("or entry.quest_area == 'ahturhgan'", self.catalog)
        self.assertIn("current_type = 0x0080, completed_type = 0x00C0, flags_length = 0x10", self.quest_state)
        self.assertIn("ahturhgan_quests = T{}", self.main)
        self.assertIn("quest_state.load_area_cache('ahturhgan', state.settings.cached_state.ahturhgan_quests)", self.main)
        self.assertIn("value.cached_state.ahturhgan_quests = value.cached_state.ahturhgan_quests or T{}", self.main)

    def test_map_vendor_prices_are_sourced_and_bounded(self):
        vendor_block = re.search(
            r"(?ms)^local vendor_costs = \{\n(.*?)^\};", self.map_data
        ).group(1)
        prices = re.findall(r"\['map\.[^']+'\] = '[^']+'", vendor_block)
        self.assertEqual(len(prices), 30)
        self.assertIn("['map.san_doria'] = '200 gil'", self.map_data)
        self.assertIn("['map.qufim_island'] = '3,000 gil'", self.map_data)
        self.assertIn("['map.mamook'] = '2,000 Imperial Standing'", self.map_data)
        self.assertIn("vendor_source_url = 'https://horizonffxi.wiki/Map_Guide'", self.map_data)
        self.assertIn("vendor_cost = vendor_costs[map[1]]", self.map_data)

    def test_non_vendor_maps_have_sourced_acquisition_methods(self):
        acquisition_block = re.search(
            r"(?ms)^local acquisition_methods = \{\n(.*?)^\};", self.map_data
        ).group(1)
        methods = re.findall(
            r"\['map\.[^']+'\] = (?:'[^']+'|\"[^\"]+\")",
            acquisition_block,
        )
        self.assertEqual(len(methods), 42)
        self.assertIn("['map.bostaunieux_oubliette'] = 'Quest: The Sand Charm'", self.map_data)
        self.assertIn("['map.alzadaal_ruins'] = 'Mission: Undersea Scouting'", self.map_data)
        self.assertIn("['map.ifrits_cauldron'] = 'Coffer'", self.map_data)
        self.assertIn("acquisition_method = acquisition_methods[map[1]]", self.map_data)

    def test_skill_levels_are_live_and_separate_from_checklist_state(self):
        expected = {
            "Divine Magic": 32,
            "Healing Magic": 33,
            "Enhancing Magic": 34,
            "Enfeebling Magic": 35,
            "Elemental Magic": 36,
            "Dark Magic": 37,
            "Summoning Magic": 38,
            "Ninjutsu": 39,
            "Singing": 40,
            "String Instrument": 41,
            "Wind Instrument": 42,
        }
        found = {
            name: int(skill_id)
            for name, skill_id in re.findall(
                r"name = '([^']+)', skill_id = (\d+)", self.skill_levels
            )
        }
        self.assertEqual(found, expected)
        self.assertIn("player:GetCombatSkill(definition.skill_id)", self.skill_levels)
        self.assertIn("skill:GetSkill()", self.skill_levels)
        self.assertIn("skill:IsCapped()", self.skill_levels)
        self.assertIn("player:GetLoginStatus()", self.skill_levels)
        self.assertIn("local skill_levels = require('skill_levels')", self.main)
        self.assertIn("skill_snapshot = skill_levels.empty_snapshot()", self.main)
        self.assertIn("state.skill_snapshot = skill_levels.build_snapshot()", self.main)
        self.assertIn("imgui.BeginTabItem('Skill Levels', nil)", self.ui)
        self.assertIn("excluded from checklist progress", self.ui)
        self.assertNotIn("skill_levels", self.catalog)
        self.assertNotIn("settings", self.skill_levels.lower())
        self.assertNotIn("cache", self.skill_levels.lower())

    def test_key_item_log_parser_is_read_only_and_fail_closed(self):
        self.assertIn("e.id ~= 0x055", self.key_item_state)
        self.assertIn("available_offset = 0x04", self.key_item_state)
        self.assertIn("available_length = 0x40", self.key_item_state)
        self.assertIn("type_offset = 0x84", self.key_item_state)
        self.assertIn("key_items_per_group = 0x200", self.key_item_state)
        self.assertIn("key_item_state.load_cache(cache)", self.key_item_state)
        self.assertIn("key_item_state.export_cache()", self.key_item_state)
        self.assertIn("key_item_state.has_key_item(identifier)", self.catalog)
        self.assertIn("return 'unknown', packet_note", self.catalog)

    def test_quest_log_parser_is_nation_scoped_and_fail_closed(self):
        self.assertIn("e.id ~= 0x056", self.quest_state)
        self.assertIn("flags_offset = 0x04", self.quest_state)
        self.assertIn("flags_length = 0x20", self.quest_state)
        self.assertIn("type_offset = 0x24", self.quest_state)
        self.assertIn("current_type = 0x0058", self.quest_state)
        self.assertIn("completed_type = 0x0098", self.quest_state)
        self.assertIn("current_type = 0x0050", self.quest_state)
        self.assertIn("completed_type = 0x0090", self.quest_state)
        self.assertIn("current_type = 0x0060", self.quest_state)
        self.assertIn("completed_type = 0x00A0", self.quest_state)
        self.assertIn("current_type = 0x0068", self.quest_state)
        self.assertIn("completed_type = 0x00A8", self.quest_state)
        self.assertIn("current_type = 0x0070", self.quest_state)
        self.assertIn("completed_type = 0x00B0", self.quest_state)
        self.assertIn("live_logs[area].current ~= nil", self.quest_state)
        self.assertIn("quest_state.load_cache(cache)", self.quest_state)
        self.assertIn("quest_state.export_cache()", self.quest_state)
        self.assertIn("quest_state.get_area(", self.catalog)
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
        self.assertIn("auto_complete = 'Completed'", self.ui)
        self.assertIn("auto_complete = 'Completed'", self.catalog)

    def test_packet_state_cache_is_character_scoped_by_ashita_settings(self):
        self.assertIn("cached_state = T{", self.main)
        self.assertIn("key_item_state.load_cache", self.main)
        self.assertIn("quest_state.load_area_cache", self.main)
        self.assertIn("key_item_state.export_cache", self.main)
        self.assertIn("quest_state.export_area_cache", self.main)
        self.assertIn("sandoria_quests = T{}", self.main)
        self.assertIn("windurst_quests = T{}", self.main)
        self.assertIn("jeuno_quests = T{}", self.main)
        self.assertIn("other_quests = T{}", self.main)
        self.assertIn("quest_state.load_area_cache('other', state.settings.cached_state.other_quests)", self.main)
        self.assertIn("quest_state.load_area_cache('jeuno', state.settings.cached_state.jeuno_quests)", self.main)
        self.assertIn("settings.register('settings'", self.main)
        self.assertIn("settings.save()", self.main)
        self.assertNotIn("##manual", self.ui)
        self.assertIn("catalog.set_manual_completed(profile, state.settings.manual_completed, id, completed)", self.main)

    def test_custom_quests_have_explicit_manual_scope_without_packet_ids(self):
        self.assertEqual(self.custom_quest_data.count("quest_area = 'horizon_custom'"), 4)
        self.assertNotIn("quest_index =", self.custom_quest_data)
        self.assertNotIn("horizon_custom", self.quest_state)
        self.assertEqual(self.custom_quest_data.count("fame_label = 'None'"), 2)
        self.assertEqual(self.custom_quest_data.count("fame_label = 'Unknown'"), 2)
        self.assertEqual(self.custom_quest_data.count("source_url = 'https://horizonffxi.wiki/"), 5)
        self.assertIn("custom_quests = 'Horizon Custom'", self.ui)
        self.assertIn("and entry.quest_area == 'horizon_custom' and entry.quest_index == nil", self.catalog)
        self.assertIn("manual_complete = 'Completed (manual)'", self.catalog)
        self.assertIn("manual_open = 'Not marked (manual)'", self.catalog)

    def test_commands_are_addon_local(self):
        self.assertIn("addon.name = 'HXIChecklist'", self.main)
        for command in ("/hxichecklist", "/horizonchecklist", "/hcheck", "/hc"):
            self.assertIn(f"'{command}'", self.main)
        self.assertNotIn("ashita.events.register('packet_out'", self.main)


if __name__ == "__main__":
    unittest.main()
