from pathlib import Path
import re
import unittest


ADDON_DIR = Path(__file__).resolve().parents[1]
MAIN_SOURCE = (ADDON_DIR / "HXIPresence.lua").read_text(encoding="utf-8")
IPC_SOURCE = (ADDON_DIR / "discord_ipc.lua").read_text(encoding="utf-8")
BUILDER_SOURCE = (ADDON_DIR / "presence_builder.lua").read_text(encoding="utf-8")
README = (ADDON_DIR / "README.md").read_text(encoding="utf-8")
LICENSE = (ADDON_DIR / "LICENSE").read_text(encoding="utf-8")


class HXIPresenceSourceTests(unittest.TestCase):
    def test_privacy_features_default_to_off(self):
        expected_false_defaults = (
            "enabled",
            "show_character_name",
            "show_job",
            "show_level",
            "show_subjob",
            "show_subjob_level",
            "show_zone",
            "show_looking_for_party",
            "show_party_size",
            "show_elapsed_time",
        )
        for setting in expected_false_defaults:
            self.assertRegex(
                MAIN_SOURCE,
                rf"\b{re.escape(setting)}\s*=\s*false\b",
                setting,
            )

    def test_character_name_is_optional_and_read_only_when_enabled(self):
        self.assertRegex(
            MAIN_SOURCE,
            r"(?s)if runtime\.settings\.show_character_name == true then\s+"
            r"character_name = trim\(party:GetMemberName\(0\)\)",
        )
        self.assertEqual(MAIN_SOURCE.count("GetMemberName(0)"), 1)
        self.assertIn("options.show_character_name == true", BUILDER_SOURCE)
        self.assertIn("table.concat(detail_parts, ' - ')", BUILDER_SOURCE)

    def test_game_access_is_read_only(self):
        forbidden = (
            "ashita.memory.write",
            "write_uint",
            "write_int",
            "WriteMemory",
            "queue_command",
            "inject_packet",
        )
        combined = MAIN_SOURCE + IPC_SOURCE + BUILDER_SOURCE
        for token in forbidden:
            self.assertNotIn(token, combined)

    def test_discord_uses_local_ipc_and_no_credentials(self):
        self.assertIn("discord-ipc-%d", IPC_SOURCE)
        self.assertIn("SET_ACTIVITY", IPC_SOURCE)
        self.assertIn("client_id", IPC_SOURCE)
        combined = MAIN_SOURCE + IPC_SOURCE + BUILDER_SOURCE
        self.assertNotRegex(combined.lower(), r"bot[_ -]?token|oauth[_ -]?token|webhook")

    def test_shared_application_id_and_settings_ui_are_present(self):
        self.assertIn("shared_application_id = '1543549056184360960'", MAIN_SOURCE)
        self.assertIn("local imgui = require('imgui')", MAIN_SOURCE)
        self.assertIn("draw_control_ui()", MAIN_SOURCE)
        self.assertIn("draw_settings_ui()", MAIN_SOURCE)
        self.assertIn("Discord presence##HXIPresenceControlEnabled", MAIN_SOURCE)
        self.assertIn("Show character name", MAIN_SOURCE)
        self.assertIn("Show current zone", MAIN_SOURCE)
        self.assertIn("Show Looking for Party status", MAIN_SOURCE)
        self.assertIn("Show party size", MAIN_SOURCE)
        self.assertIn("Use full session elapsed time", MAIN_SOURCE)
        self.assertIn(
            "Character name is read and published only when its option is enabled.",
            MAIN_SOURCE,
        )

    def test_windows_start_closed_and_settings_open_only_from_control(self):
        self.assertRegex(
            MAIN_SOURCE,
            r"local settings_ui = T\{\s*is_open = \{false\}",
        )
        self.assertRegex(
            MAIN_SOURCE,
            r"local control_ui = T\{\s*is_open = \{false\}",
        )
        self.assertIn("settings_ui.is_open[1] = true", MAIN_SOURCE)
        self.assertEqual(MAIN_SOURCE.count("settings_ui.is_open[1] = true"), 1)
        self.assertIn("Settings##HXIPresenceOpenSettings", MAIN_SOURCE)

    def test_settings_omit_duplicate_controls_and_artwork_configuration(self):
        self.assertNotIn("Enable Discord presence", MAIN_SOURCE)
        self.assertNotIn("Queue refresh", MAIN_SOURCE)
        self.assertNotIn("Disable and clear", MAIN_SOURCE)
        self.assertNotIn("imgui.Text('Artwork')", MAIN_SOURCE)
        self.assertNotIn("Asset key##", MAIN_SOURCE)
        self.assertNotIn("runtime.settings.large_image", MAIN_SOURCE)
        self.assertIn("local fixed_large_image_key = ''", MAIN_SOURCE)
        self.assertIn("local fixed_large_image_text = 'HorizonXI'", MAIN_SOURCE)
        self.assertNotIn("options.large_image_key", BUILDER_SOURCE)
        self.assertNotIn("options.large_image_text", BUILDER_SOURCE)

    def test_discord_ready_and_activity_acknowledgement_are_required(self):
        self.assertIn("response.evt == 'READY'", IPC_SOURCE)
        self.assertIn("Discord handshake is not ready", IPC_SOURCE)
        self.assertIn("get_last_activity_ack_nonce", IPC_SOURCE)
        self.assertIn("get_last_activity_error", IPC_SOURCE)
        self.assertIn("runtime.pending_publish_nonce", MAIN_SOURCE)
        self.assertIn(
            "settings_ui.feedback = 'Discord acknowledged the active presence.'",
            MAIN_SOURCE,
        )
        self.assertNotIn(
            "notify('Discord acknowledged the active presence.')",
            MAIN_SOURCE,
        )
        self.assertIn("acknowledgement_timeout_seconds = 10", MAIN_SOURCE)
        self.assertIn("Discord acknowledgement timed out; reconnecting.", MAIN_SOURCE)

    def test_baseline_presence_is_not_empty(self):
        self.assertIn("details = 'Adventuring'", BUILDER_SOURCE)
        self.assertIn("activity.details = details", BUILDER_SOURCE)

    def test_party_size_is_read_without_member_identity_and_uses_native_presence(self):
        self.assertIn("GetAlliancePartyMemberCount1()", MAIN_SOURCE)
        self.assertIn("GetMemberIsActive(member_index)", MAIN_SOURCE)
        self.assertIn("size = {math.floor(party_size), 6}", BUILDER_SOURCE)
        self.assertIn("parts[#parts + 1] = 'In Party'", BUILDER_SOURCE)
        self.assertIn("party_size > 1", BUILDER_SOURCE)

    def test_search_comments_are_not_read_or_published(self):
        combined = MAIN_SOURCE + IPC_SOURCE + BUILDER_SOURCE
        self.assertNotIn("GetSearchComment", combined)
        self.assertNotIn("SearchComment", combined)

    def test_looking_for_party_uses_the_locally_validated_read_only_flag(self):
        self.assertIn("looking_for_party_flag_mask = 0x00100000", MAIN_SOURCE)
        self.assertIn("GetRenderFlags1(player_index)", MAIN_SOURCE)
        self.assertIn(
            "bit.band(render_flags_1, looking_for_party_flag_mask) ~= 0",
            MAIN_SOURCE,
        )
        self.assertIn("snapshot.looking_for_party == true", BUILDER_SOURCE)
        self.assertIn("parts[#parts + 1] = 'Looking for Party'", BUILDER_SOURCE)
        self.assertNotIn("packet_in", MAIN_SOURCE)
        self.assertNotIn("packet_out", MAIN_SOURCE)

    def test_settings_explain_discord_lines_and_prepare_fixed_support_link(self):
        self.assertIn("Discord has two activity lines below the game title.", MAIN_SOURCE)
        self.assertIn(
            "zone, Looking for Party, and party status share the second line.",
            MAIN_SOURCE,
        )
        self.assertIn(
            "local support_url = 'https://github.com/ryuutatsuo23-max/HXIPresence'",
            MAIN_SOURCE,
        )
        self.assertIn("addon.link = support_url", MAIN_SOURCE)
        self.assertIn("Repository / support##HXIPresenceSupport", MAIN_SOURCE)
        self.assertIn("Support and feature requests", README)

    def test_character_settings_are_restored_after_login(self):
        self.assertIn(
            "settings.register('settings', 'HXIPresence_SettingsUpdate', "
            "apply_updated_settings)",
            MAIN_SOURCE,
        )
        self.assertRegex(
            MAIN_SOURCE,
            r"(?s)local function apply_updated_settings\(updated\).*?"
            r"runtime\.settings = updated;.*?"
            r"runtime\.last_connect_attempt_at = -reconnect_interval_seconds;",
        )
        self.assertIn("Saved settings restored", MAIN_SOURCE)
        self.assertIn("saved per character", README)
        self.assertIn("still starts disabled", README)

    def test_public_metadata_credits_dragohorse(self):
        self.assertIn("addon.author = 'DragoHorse'", MAIN_SOURCE)
        self.assertIn("Created by **DragoHorse**", README)
        self.assertIn("HXIPresence-v0.4.4.zip", README)

    def test_full_session_timer_survives_zoning_but_resets_on_logout(self):
        self.assertIn("return nil, login_status", MAIN_SOURCE)
        self.assertIn("local snapshot, login_status = read_player_snapshot()", MAIN_SOURCE)
        self.assertIn("update_login_state(snapshot, login_status)", MAIN_SOURCE)
        self.assertRegex(
            MAIN_SOURCE,
            r"(?s)if runtime\.session_started_at == nil then\s+"
            r"runtime\.session_started_at = os\.time\(\);\s+end",
        )
        self.assertIn(
            "if login_status ~= 0 then\n        return;\n    end",
            MAIN_SOURCE,
        )
        self.assertRegex(
            MAIN_SOURCE,
            r"(?s)if login_status ~= 0 then\s+return;\s+end\s+"
            r"runtime\.session_started_at = nil;.*?discord_ipc\.clear_activity\(\);",
        )

    def test_readme_requires_no_user_discord_application_setup(self):
        self.assertIn("No Discord Developer Portal setup is required", README)
        self.assertIn("Application ID and artwork are already configured", README)
        self.assertNotIn("Create an application in the Discord Developer Portal", README)

    def test_mit_license_is_present(self):
        self.assertIn("MIT License", LICENSE)
        self.assertIn("Copyright (c) 2026 DragoHorse", LICENSE)
        self.assertIn("THE SOFTWARE IS PROVIDED \"AS IS\"", LICENSE)
        self.assertIn("[MIT License](LICENSE)", README)

    def test_readme_has_no_developer_machine_path(self):
        self.assertNotIn("C:\\Games\\", README)
        self.assertNotIn("C:\\Users\\", README)

    def test_one_unique_command_only_toggles_the_control_window(self):
        self.assertIn("trim(args[1]):lower() ~= '/hxipresence'", MAIN_SOURCE)
        self.assertIn("control_ui.is_open[1] = not control_ui.is_open[1]", MAIN_SOURCE)
        self.assertIn("Usage: /hxipresence", MAIN_SOURCE)
        self.assertNotIn("'/hp'", MAIN_SOURCE)
        self.assertNotIn("'/horizonpresence'", MAIN_SOURCE)
        self.assertNotRegex(MAIN_SOURCE, r"command\s*==")

    def test_updates_are_bounded_and_change_driven(self):
        self.assertIn("minimum_publish_interval_seconds = 15", MAIN_SOURCE)
        self.assertIn("runtime.pending_signature == runtime.last_signature", MAIN_SOURCE)
        self.assertIn("reconnect_interval_seconds = 15", MAIN_SOURCE)
        refresh_body = re.search(
            r"local function mark_for_refresh\(\)(.*?)\nend",
            MAIN_SOURCE,
            re.S,
        )
        self.assertIsNotNone(refresh_body)
        self.assertNotIn("last_publish_at", refresh_body.group(1))

    def test_disable_and_unload_clear_presence(self):
        self.assertIn("discord_ipc.clear_activity()", MAIN_SOURCE)
        self.assertIn("HXIPresence_Unload", MAIN_SOURCE)
        self.assertRegex(MAIN_SOURCE, r"(?s)local function set_presence_enabled.*?clear_and_disconnect\(\)")

    def test_readme_and_ui_record_current_approval(self):
        self.assertIn("approved by HorizonXI staff on September 4", README)
        self.assertIn("Approved by HorizonXI staff on September 4, 2026.", MAIN_SOURCE)
        self.assertNotIn("do not load this addon on HorizonXI until it is approved", MAIN_SOURCE)
        self.assertNotIn("Only use HXIPresence on HorizonXI after it is approved", README)
        self.assertIn("/addon load HXIPresence", README)


if __name__ == "__main__":
    unittest.main()
