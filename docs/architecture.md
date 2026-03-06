# Architecture

## How it works

Sonic 3 A.I.R. stores its user data (saves, settings, mods) in `%APPDATA%\Sonic3AIR`.

The PortableApps.com Launcher handles portability by:

1. **On launch** — Moving `Data/UserData/` to `%APPDATA%\Sonic3AIR` so the game finds its saves/settings where it expects them. Moving `Data/Sonic_Knuckles_wSonic3.bin` to `App/Sonic3AIR/` so the game finds the ROM next to its executable.
2. **On exit** — Moving both back to `Data/` and cleaning up the empty AppData folder.

No registry keys are used. The ROM location is handled by `[FilesMove]`, so no path rewriting in `config.json` is needed.

## Project structure

```text
.
├── build.sh                 # Orchestrator (prerequisites + build)
├── .env.example             # Build configuration template
├── src/
│   ├── scripts/
│   │   ├── config.sh        # Shared variables (loaded by other scripts)
│   │   ├── fetch.sh         # Download dependencies + ROM
│   │   ├── package.sh       # Assemble the package
│   │   └── setup.sh         # Check and install required system packages
│   └── template/            # Package source files (override the PA.c template)
│       ├── App/AppInfo/
│       │   ├── appinfo.ini      # Package metadata
│       │   ├── installer.ini    # Installer config
│       │   └── Launcher/
│       │       └── Sonic3AIRPortable.ini  # Launcher config (key file)
│       ├── Other/Source/
│       │   ├── Sonic3AIRPortable.ini      # User config template
│       │   └── Readme.txt                 # End-user documentation
│       └── help.html            # Help page
├── docs/
│   └── architecture.md      # This file
├── resources/               # Downloaded automatically
│   ├── Sonic 3 A.I.R/      # Game files (without ROM)
│   └── PortableApps.com_Application_Template_3.9.0/
└── build/                   # Build output (generated)
    └── Sonic3AIRPortable/   # Ready-to-use portable package
```

## Scripts

| Script                     | Role                                                              |
| -------------------------- | ----------------------------------------------------------------- |
| `build.sh`                      | Orchestrator — runs fetch then package                               |
| `src/scripts/setup.sh`          | Checks and installs required system packages                         |
| `src/scripts/config.sh`         | Shared configuration — loads `.env`, defines all paths and URLs      |
| `src/scripts/fetch.sh`          | Downloads template + game if missing, copies ROM from `ROM_PATH`     |
| `src/scripts/package.sh`        | Assembles the package from `resources/` and `src/template/` into `build/` |

`config.sh` is sourced (not executed) by the other two scripts. All variables are defined there.

## Key files

| File                                              | Role                                                        |
| ------------------------------------------------- | ----------------------------------------------------------- |
| `.env`                                            | Build configuration (ROM path, versions)                    |
| `src/template/App/AppInfo/Launcher/Sonic3AIRPortable.ini`  | Portability mechanism — ROM and userdata moves, cleanup      |
| `src/template/App/AppInfo/appinfo.ini`                     | Package metadata (name, category, version, license)         |
| `resources/Sonic 3 A.I.R/data/metadata.json`      | Game version source (auto-read at build time)               |
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

### `src/scripts/fetch.sh`

1. Download the PortableApps.com template from SourceForge if missing
2. Download Sonic 3 A.I.R. from GitHub releases if missing
3. Copy ROM from `ROM_PATH` if set, or warn if missing
4. Validate that all required directories exist

### `src/scripts/package.sh`

1. Read game version from `data/metadata.json`
2. Clean and create `build/Sonic3AIRPortable/`
3. Copy launcher `.exe` (renamed from template)
4. Copy game files (excluding `bonus/` — ~23 MB of dev tools not needed to play)
5. Copy and patch `appinfo.ini` with game version
6. Copy template icons (placeholders)
7. Create `DefaultData/UserData/` skeleton for first launch
8. Copy help page and Other/ assets
9. Print summary with versions, ROM status, and size

## ROM

The ROM (`Sonic_Knuckles_wSonic3.bin`) is separate from the game download. Set `ROM_PATH` in `.env` and the build script copies it automatically into `Data/` of the portable package.

The launcher moves it to `App/Sonic3AIR/` at launch (where the game expects it) and moves it back to `Data/` on exit. If the ROM is absent the package still builds, but the game won't start.

Guide: [How to get the ROM (post-delist)](https://docs.google.com/document/d/1oSud8dJHvdfrYbkGCfllAOp3JuTks7z4K5SwtVkXkx0)

## Customization

- **User config**: Copy `Other/Source/Sonic3AIRPortable.ini` next to `Sonic3AIRPortable.exe` to override launcher settings (splash screen, run locally, etc.).

## Testing

1. Run `build/Sonic3AIRPortable/Sonic3AIRPortable.exe` on Windows
2. Verify `%APPDATA%\Sonic3AIR` is created while the game runs
3. Close the game
4. Verify `Data/UserData/` contains the saves and settings
5. Verify `Data/Sonic_Knuckles_wSonic3.bin` is back in `Data/`
6. Verify `%APPDATA%\Sonic3AIR` no longer exists
