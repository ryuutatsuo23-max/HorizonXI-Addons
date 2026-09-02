# Developer notes

These files are for maintaining HXIUIBegone. They are not included in the install
ZIP, and users do not need Python to run the addon.

## Offline tests

From the repository root:

```text
python -m pip install -r dev/requirements.txt
python dev/test_hxiuibegone.py
```

The 37 tests run the Lua code with simulated memory and Windows calls. They do
not attach to the game. See [validation notes](../docs/VALIDATION.md) for coverage.

## Release ZIP

```text
python dev/package_release.py --ref v0.2.5 --output dist/install-v0.2.5
```

Use a new output directory for each build. The script deliberately packages
only the four runtime Lua files and LICENSE from the supplied Git ref, plus
the current CREDITS.md. It verifies the ZIP and writes SHA256SUMS.txt. No tests,
screenshots, research, Git metadata, or packaging tools are included.

For a packaging-only correction, keep the code tag unchanged, replace the ZIP
and checksum together, and explain the correction in the release notes. Verify
the public download against the new checksum after uploading.

## Source and license

[Source provenance](../docs/SOURCES.md) records the upstream sources. The current
addon retains GPL-3.0-or-later because its party controls are identified as
adapted from GPL-covered Ashita code. Do not replace the license with MIT unless
the upstream permissions or the implementation's provenance justify that change.
