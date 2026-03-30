# PST-DL

A cross-platform CLI version manager for [PalworldSaveTools](https://github.com/deafdudecomputers/PalworldSaveTools). Download, install, upgrade, and manage PalworldSaveTools from your terminal.

## Quick Install

**Linux / macOS:**
```bash
curl -LsSf https://raw.githubusercontent.com/CyrixJD115/PST-DL/main/.Unix/install.sh | sh
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/CyrixJD115/PST-DL/main/.Windows/install.ps1 | iex
```

## Commands

| Command | Description |
|---------|-------------|
| `pstdl` or `pstdl -h` | Show help |
| `pstdl -i` or `pstdl -install` | Download and install PalworldSaveTools |
| `pstdl -u` or `pstdl -upgrade` | Update PalworldSaveTools to the latest version |
| `pstdl -v` or `pstdl -version` | Show pstdl and remote PST version |
| `pstdl -g` or `pstdl -github` | Open PalworldSaveTools GitHub page |
| `pstdl -uninstall` | Uninstall PalworldSaveTools |
| `pstdl -uninstall-all` | Uninstall pstdl and PalworldSaveTools |
| `pstdl -update-self` | Update pstdl to the latest version |

## Project Structure

```
PST-DL/
├── .Unix/
│   ├── pstdl            # CLI tool (bash) - Linux/macOS
│   └── install.sh       # Bootstrap installer (curl | sh)
├── .Windows/
│   ├── pstdl.ps1        # CLI tool (PowerShell) - Windows
│   └── install.ps1      # Bootstrap installer (irm | iex)
└── README.md
```

## Install Locations

| Component | Windows | Linux / macOS |
|-----------|---------|---------------|
| pstdl binary | `%LOCALAPPDATA%\pstdl\pstdl.ps1` | `~/.local/bin/pstdl` |
| PST data | `%LOCALAPPDATA%\palworldsavetools\` | `~/.local/share/palworldsavetools/` |

## How It Works

### Windows
- Downloads the prepackaged `.exe` standalone release
- Extracts to `%LOCALAPPDATA%\palworldsavetools\`
- Creates a desktop shortcut to `PalworldSaveTools.exe`

### Linux / macOS
- Downloads the source code from GitHub
- Extracts to `~/.local/share/palworldsavetools/source/`
- Auto-installs [uv](https://github.com/astral-sh/uv) if not present
- Generates a `pst.sh` launcher (`uv run ./start.py`)

## Requirements

### Windows
- PowerShell 5.1+
- 7-Zip or NanaZip (for extraction)

### Linux / macOS
- Bash
- curl
- unzip

## Auto-Update

pstdl silently checks for updates on every run. If a newer version is found, it auto-updates in-place. You can also manually update with `pstdl -update-self`.

## License

This project follows the same license as PalworldSaveTools.

## Credits

- Original PalworldSaveTools by [ deafdudecomputers](https://github.com/deafdudecomputers)
- CLI download manager by [CyrixJD115](https://github.com/CyrixJD115)
