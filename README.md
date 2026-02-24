# Sonic 3 A.I.R. Portable (PortableApps.com)

A [PortableApps.com](https://portableapps.com/) package for [Sonic 3 Angel Island Revisited](https://sonic3air.org) — a fan-remaster of Sonic 3 & Knuckles.

The game runs entirely from a USB drive (or any portable folder) without leaving traces on the host machine.

## Quick start

### 1. Configure

```bash
cp .env.example .env
```

Edit `.env` and set `ROM_PATH` to your Sonic 3 & Knuckles ROM file. The ROM is not included and must be obtained separately — see the [ROM guide](https://docs.google.com/document/d/1oSud8dJHvdfrYbkGCfllAOp3JuTks7z4K5SwtVkXkx0).

### 2. Build

```bash
bash build.sh
```

The script downloads dependencies automatically (game + template) if missing, copies the ROM, and assembles the package into `build/Sonic3AIRPortable/`.

### 3. Run

Launch `build/Sonic3AIRPortable/Sonic3AIRPortable.exe` on Windows.

## .env variables

| Variable           | Default                | Description                                        |
| ------------------ | ---------------------- | -------------------------------------------------- |
| `ROM_PATH`         | *(empty)*              | Path to your `Sonic_Knuckles_wSonic3.bin` ROM file |
| `GAME_VERSION`     | `v24.02.02.0-stable`  | Sonic 3 A.I.R. GitHub release tag                  |
| `TEMPLATE_VERSION` | `3.9.0`                | PortableApps.com template version                  |

## Prerequisites

- Bash (WSL, Git Bash, or similar)
- `curl`, `unzip`, `rsync`

## Documentation

See [`docs/architecture.md`](docs/architecture.md) for project structure, key files, version management, and customization details.

## License

- **Sonic 3 A.I.R.** — Freeware by Eukaryot, non-commercial use only
- **PortableApps.com Launcher** — GPL (see `Other/Source/LauncherLicense.txt`)
- **This packaging** — CC BY-NC-SA 4.0
