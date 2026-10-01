# Development guide

## Requirements and layout

Python **3.9+**, standard library only. GNU Make is optional. Engine tests and installation require Factorio **2.1**. `test-client` requires the graphical game, a working display/GPU and Steam running for Steam builds.

| Path | Purpose |
| --- | --- |
| `src/` | Only files shipped in the mod ZIP |
| `tools/build.py` | Shared validation, packaging, tests and installer |
| `build.ps1` | Windows compatibility wrapper around Python |
| `tests/` | Packaging regressions and isolated Factorio harnesses |
| `dist/` | Generated ZIPs and SHA-256 sidecars; ignored by Git |
| `work/` | Isolated configs/maps/mods/logs/screenshots; ignored by Git |
| `backups/` | Installation backups; ignored by Git, preserved by clean |

## Commands

Run from the repository root. Use `python3` on macOS/Linux or `py -3`/`python` on Windows.

| Task | Behavior |
| --- | --- |
| `check` | Validate metadata, required files, changelog version, PNG dimensions, locale keys and control placeholders; no game required |
| `build` / `compile` | Validate and write the ZIP and checksum; Lua is packaged, not compiled |
| `test` | Build, load the release ZIP headlessly, and run engine behavior regressions |
| `test-client` | Run native GUI/settings tests in an isolated graphical benchmark; capture screenshots |
| `install` | Run engine tests, back up replaced files, install and enable this mod |
| `clean` | Remove `work/` and the current package/checksum/temp file; preserve source, backups, old packages and installed mods |
| `rebuild` | Clean, build and run engine tests |
| `doctor` | Resolve paths and print the executable version |

```sh
python3 tools/build.py test --factorio /path/to/factorio --data-dir /path/to/factorio/data
python3 -m unittest discover -s tests -p test_build.py -v
```

Make exposes the same tasks, plus `make test-build` for the Python regression suite. The PowerShell wrapper accepts `-Factorio`, `-DataDirectory` and `-ModDirectory`.

## Path overrides

| Environment variable | CLI flag | Purpose |
| --- | --- | --- |
| `FACTORIO_EXE` | `--factorio` | Game executable |
| `FACTORIO_DATA_DIR` | `--data-dir` | Game data directory containing `base/` |
| `FACTORIO_MOD_DIR` | `--mod-dir` | Install destination |

CLI flags take priority. Common game paths are detected; custom, portable and Flatpak setups may need overrides. macOS bundles normally use `factorio.app/Contents/MacOS/factorio` and `factorio.app/Contents/data/`.

## Packaging and installation

Packages include only `src/`, in sorted order with fixed timestamps and permissions. Text is normalized to LF. Identical source produces identical ZIP bytes with the same Python/zlib toolchain; compression implementations may differ between toolchains. Tests check repeatability despite timestamp and CRLF/LF changes.

The installer never edits saves or `mod-settings.dat`. Other mod-list entries are preserved. Replaced files are backed up to `backups/<unique-id>/`. The installed ZIP is verified before the mod list is replaced atomically. Older installed packages are retained. Close Factorio before installation, then restart it.

## Test scope

Engine tests create isolated maps and mod directories, never load user saves, and detect Lua failures even when the game exits with status zero. Processes have timeouts.

Behavior tests use real engine inventories/prototypes/render objects and a synthetic player. They cover snapping, cursor ghosts, negative coordinates, persistent references, palette uniqueness, marker cleanup, surface travel, opacity and recovery.

Native client tests use a real player and GUI, verify radio exclusivity and settings writes, and invoke input handlers programmatically. They do not establish physical keyboard behavior, all locale layouts, native Mac/Linux gameplay or real multiplayer compatibility.

Logs: `work/release-load.log`, `behavior.log`, and `client.log`. Screenshots: `work/script-output/panel.png` and `guides.png`.

## CI

GitHub Actions runs static checks, packaging regressions and packaging on Windows, macOS and Linux, then uploads ZIP/checksum artifacts. It does not download/run Factorio, create releases or publish the mod.
