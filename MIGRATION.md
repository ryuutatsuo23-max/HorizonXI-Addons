# Repository consolidation

Prepared on 2026-09-20 from the published `main` branches of:

| Original repository | Imported commit | Destination |
| --- | --- | --- |
| [HXIUIBegone](https://github.com/ryuutatsuo23-max/HXIUIBegone) | `983eb2539be89235398095427b536ee681d6988c` | `HXIUIBegone/` |
| [HorizonScout](https://github.com/ryuutatsuo23-max/HorizonScout) | `7123b5b310d86c31148c4696b103c451f7438f74` | `HorizonScout/` |
| [HorizonChecklist](https://github.com/ryuutatsuo23-max/HorizonChecklist) | `072017fb0850a6ae8babc2fc3ed6fff352b6e7be` | `HorizonChecklist/` |
| [HXIPresence](https://github.com/ryuutatsuo23-max/HXIPresence) | `fcaae5db3c9d888acc30c5316e8a14b8f32448dc` | `HXIPresence/` |

## Preservation

The imported directory trees are identical to the corresponding source commit trees. No addon code, settings defaults, sounds, licenses, or existing documentation was changed. Each import is a merge with the original main-branch tip as a parent, preserving original commit IDs, authorship, and reachable history without squashing or rewriting.

Original tags are retained with repository prefixes, such as `HXIUIBegone/v0.2.8` and `HorizonChecklist/v0.21.0`. These tags still resolve to the original commits and original single-repository layouts; they are not combined-repository releases. Original annotated-tag messages remain unchanged.

Historical commits predate the folder prefixes. To inspect an addon's original history, use its imported commit above or its prefixed tags. A path-limited log on a new addon folder may stop at its import boundary.

Only published main-branch source and tagged history are published here. Other remote development branches, local uncommitted changes, installed addon files, personal settings, and unrelated projects are excluded. In particular, unpublished changes in the local HorizonChecklist checkout were not imported.

## Releases and tooling

GitHub issues, pull requests, release pages, and binary release attachments remain in the original repositories. They are not Git history and were not migrated. The original repositories were archived on 2026-09-20 after migration notices and links to this collection were added. Their existing releases and downloads remain available. There is no automatic synchronization between them and this collection.

No source repository contains a tracked `.github` workflow or submodule requiring migration. Existing per-addon development files are preserved. Run tools from their respective addon folders and review assumptions about Git-root paths before using them to publish future releases.

HXIUIBegone's existing packaging script reads root-level files from a historical Git ref. To package the preserved v0.2.8 source, run from `HXIUIBegone/`:

```text
python dev/package_release.py --ref HXIUIBegone/v0.2.8 --output dist/import-v0.2.8
```

Do not give that unchanged script a new combined-repository commit: files in new commits are beneath `HXIUIBegone/`. Adapting future release tooling is separate from this source-preserving consolidation.

## Validation boundary

The migration is verified by comparing all four imported Git tree IDs with the source trees, checking source-commit ancestry and namespaced tags, and checking Git integrity and whitespace. Runtime code is unchanged; this migration is not an additional in-game validation of the addons.
