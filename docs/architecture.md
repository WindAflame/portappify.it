# Architecture

## How it works

Sonic 3 A.I.R. stores its user data (saves, settings, mods) in `%APPDATA%\Sonic3AIR`.

The PortableApps.com Launcher handles portability by:

1. **On launch** — Moving `Data/Sonic3AIR/` to `%APPDATA%\Sonic3AIR` so the game finds its data where it expects it.
2. **On exit** — Moving `%APPDATA%\Sonic3AIR` back to `Data/Sonic3AIR/` and cleaning up the empty folder.

No registry keys are used. The game's `config.json` uses `RomPath=""` which auto-detects the ROM relative to the executable, so no path rewriting is needed.

## Project structure

```text
.
├── build.sh                 # Build script
├── .env.example             # Build configuration template
├── README.md
├── docs/
│   └── architecture.md      # This file
├── resources/               # Downloaded automatically by build.sh
│   ├── Sonic 3 A.I.R/      # Game files (without ROM)
│   └── PortableApps.com_Application_Template_3.9.0/
├── src/                     # Package source files
│   ├── App/AppInfo/
│   │   ├── appinfo.ini      # Package metadata
│   │   ├── installer.ini    # Installer config
│   │   └── Launcher/
│   │       └── Sonic3AIRPortable.ini  # Launcher config (key file)
│   ├── Other/Source/
│   │   ├── Sonic3AIRPortable.ini      # User config template
│   │   └── Readme.txt                 # End-user documentation
│   └── help.html            # Help page
└── build/                   # Build output (generated)
    └── Sonic3AIRPortable/   # Ready-to-use portable package
```

## Key files

| File                                              | Role                                                        |
| ------------------------------------------------- | ----------------------------------------------------------- |
| `.env`                                            | Build configuration (ROM path, versions)                    |
| `src/App/AppInfo/Launcher/Sonic3AIRPortable.ini`  | Portability mechanism — directory moves, cleanup             |
| `src/App/AppInfo/appinfo.ini`                     | Package metadata (name, category, version, license)         |
| `resources/Sonic 3 A.I.R/data/metadata.json`     | Game version source (auto-read at build time)               |
| `build/Sonic3AIRPortable/App/AppInfo/appinfo.ini` | Built package version (patched from game metadata)          |

## Version management

The build summary shows all version info:

```text
Versions:
  Sonic 3 A.I.R.     : 24.02.02.1 (release: v24.02.02.0-stable)
  PA.c Template      : 3.9.0
  Package (appinfo)  : 24.02.02.1 (PackageVersion=24.2.2.1)
```

- **Sonic 3 A.I.R. version** — read from `resources/Sonic 3 A.I.R/data/metadata.json` (`Version` field)
- **Template version** — from `TEMPLATE_VERSION` in `.env`
- **Package version** — written into `build/Sonic3AIRPortable/App/AppInfo/appinfo.ini` (`PackageVersion` and `DisplayVersion`), auto-patched from the game metadata at build time

To check versions after a build without rebuilding:

```bash
# Game version
python3 -c "import json; print(json.load(open('resources/Sonic 3 A.I.R/data/metadata.json'))['Version'])"

# Package version (in built output)
grep 'Version=' build/Sonic3AIRPortable/App/AppInfo/appinfo.ini
```

## Build steps detail

`build.sh` performs the following:

1. Load `.env` configuration (or use defaults)
2. Download the PortableApps.com template from SourceForge if missing
3. Download Sonic 3 A.I.R. from GitHub releases if missing
4. Copy ROM from `ROM_PATH` if set, or warn if missing
5. Read game version from `data/metadata.json`
6. Clean and create `build/Sonic3AIRPortable/`
7. Copy launcher `.exe` (renamed from template)
8. Copy game files (excluding `bonus/` — ~23 MB of dev tools not needed to play)
9. Copy and patch `appinfo.ini` with game version
10. Copy template icons (placeholders)
11. Create `DefaultData/Sonic3AIR/` skeleton for first launch
12. Copy help page and Other/ assets
13. Print summary with versions, ROM status, and size

## ROM

The ROM (`Sonic_Knuckles_wSonic3.bin`) is separate from the game download. Set `ROM_PATH` in `.env` and the build script copies it automatically. Alternatively, place it directly in `resources/Sonic 3 A.I.R/` or `build/Sonic3AIRPortable/App/Sonic3AIR/`.

Guide: [How to get the ROM (post-delist)](https://docs.google.com/document/d/1oSud8dJHvdfrYbkGCfllAOp3JuTks7z4K5SwtVkXkx0)

## Customization

- **User config**: Copy `Other/Source/Sonic3AIRPortable.ini` next to `Sonic3AIRPortable.exe` to override launcher settings (splash screen, run locally, etc.).

## Testing

1. Run `build/Sonic3AIRPortable/Sonic3AIRPortable.exe` on Windows
2. Verify `%APPDATA%\Sonic3AIR` is created while the game runs
3. Close the game
4. Verify `Data/Sonic3AIR/` contains the saves and settings
5. Verify `%APPDATA%\Sonic3AIR` no longer exists
