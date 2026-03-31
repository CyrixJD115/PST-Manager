# PST Manager

A cross-platform CLI version manager for [PalworldSaveTools](https://github.com/deafdudecomputers/PalworldSaveTools). Download, install, upgrade, and manage PalworldSaveTools from your terminal.

## Quick Install

**Linux / macOS:**
```bash
curl -LsSf https://raw.githubusercontent.com/CyrixJD115/PST-Manager/main/.Unix/install.sh | sh
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/CyrixJD115/PST-Manager/main/.Windows/install.ps1 | iex
```

## Commands

- `pstm -h` or `pstm -help` - Show help
- `pstm -v` or `pstm -version` - Show pstm and remote PST version
- `pstm -i` or `pstm -install` - Download and install PalworldSaveTools
- `pstm run` - Run PalworldSaveTools
- `pstm -u` or `pstm -upgrade` - Update PalworldSaveTools to the latest version
- `pstm -update-self` - Update pstm to the latest version
- `pstm -g` or `pstm -github` - Open PalworldSaveTools GitHub page
- `pstm -uninstall` - Uninstall PalworldSaveTools
- `pstm -uninstall-all` - Uninstall pstm and PalworldSaveTools

## Project Structure

```
PST-Manager/
├── .Unix/
│   ├── pstm              # CLI tool (bash) - Linux/macOS
│   └── install.sh        # Bootstrap installer (curl | sh)
├── .Windows/
│   ├── pstm.ps1          # CLI tool (PowerShell) - Windows
│   └── install.ps1       # Bootstrap installer (irm | iex)
└── README.md
```

## Install Locations

| Component | Windows | Linux / macOS |
|-----------|---------|---------------|
| pstm binary | `%LOCALAPPDATA%\pstm\pstm.ps1` | `~/.local/bin/pstm` |
| PST data | `%LOCALAPPDATA%\palworldsavetools\` | `~/.local/share/palworldsavetools/` |

### Directory Structure (both platforms)

```
<pst_data_dir>/
├── source/       # extracted source code from .zip
└── pst           # launcher (pst.ps1 on Windows, pst on Unix)
```

## How It Works

Both platforms:
- Download the source `.zip` from GitHub tags
- Extract to `<data>/source/`
- Auto-install [uv](https://github.com/astral-sh/uv) if not present
- Generate a launcher that runs `uv python install 3.13` then `uv run ./start.py`

### Windows launcher
- Generates a `pst.ps1` launcher script
- Creates a desktop shortcut with icon

### Unix launcher
- Generates executable `pst` bash script

## Requirements

### Windows
- PowerShell 5.1+

### Linux / macOS
- Bash, curl, unzip

## Auto-Update

pstm silently checks for updates on every run. If a newer version is found, it auto-updates in-place. You can also manually update with `pstm -update-self`.

## Credits

- Original PalworldSaveTools by [deafdudecomputers](https://github.com/deafdudecomputers)
- PST Manager by [CyrixJD115](https://github.com/CyrixJD115)
