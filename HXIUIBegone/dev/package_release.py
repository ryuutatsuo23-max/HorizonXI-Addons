"""Package tagged addon code, its license, and current credits; no dev files.

Example: python dev/package_release.py --ref v0.2.2 --output dist/install-v0.2.2
Python is only needed by maintainers to build the ZIP, not to use the addon.
"""
import argparse
import hashlib
from pathlib import Path
import re
import subprocess
import zipfile


REPO = Path(__file__).resolve().parents[1]
RUNTIME_FILES = (
    "HXIUIBegone.lua", "native_ui.lua", "memory_io.lua", "connection_patch.lua",
)


def git(*args):
    return subprocess.check_output(["git", *args], cwd=REPO)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ref", required=True, help="Git tag or commit for the addon code")
    parser.add_argument("--output", required=True, type=Path, help="Destination directory")
    args = parser.parse_args()
    commit = git("rev-parse", "--verify", args.ref + "^{commit}").decode().strip()
    files = {name: git("show", f"{commit}:{name}") for name in (*RUNTIME_FILES, "LICENSE")}
    # Current credits allow repackaging older tags without changing their code.
    files["CREDITS.md"] = (REPO / "CREDITS.md").read_bytes().replace(b"\r\n", b"\n")
    match = re.search(rb"addon\.version\s*=\s*'([0-9]+\.[0-9]+\.[0-9]+)'", files["HXIUIBegone.lua"])
    if not match:
        raise ValueError("Tagged addon version is missing or invalid")
    version = match[1].decode("ascii")
    output = args.output / f"HXIUIBegone-v{version}.zip"
    checksum = args.output / "SHA256SUMS.txt"
    if output.exists() or checksum.exists():
        raise FileExistsError("Output already exists; choose a new directory")
    args.output.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "x", zipfile.ZIP_DEFLATED) as archive:
        for name, content in files.items():
            entry = zipfile.ZipInfo("HXIUIBegone/" + name)
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.external_attr = 0o100644 << 16
            archive.writestr(entry, content)
    with zipfile.ZipFile(output) as archive:
        if archive.testzip() is not None:
            raise ValueError("ZIP integrity check failed")
        if archive.namelist() != ["HXIUIBegone/" + name for name in files]:
            raise ValueError("Unexpected ZIP contents")
        for name, content in files.items():
            if archive.read("HXIUIBegone/" + name) != content:
                raise ValueError(f"ZIP content mismatch: {name}")
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    checksum.write_text(f"{digest}  {output.name}\n", encoding="ascii")
    print(f"Code commit: {commit}")
    print(f"Package: {output} ({len(files)} files)")
    print(f"SHA-256: {digest}")


if __name__ == "__main__":
    main()
