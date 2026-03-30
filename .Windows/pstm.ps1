$ErrorActionPreference = "Stop"

$PSTM_VERSION = "1.0.0"
$PSTM_REPO = "CyrixJD115/PST-Manager"
$PST_REPO = "deafdudecomputers/PalworldSaveTools"
$PSTM_RAW_BASE = "https://raw.githubusercontent.com/$PSTM_REPO/main"

$PST_DATA_DIR = Join-Path $env:LOCALAPPDATA "palworldsavetools"
$PSTM_DIR = Join-Path $env:LOCALAPPDATA "pstm"
$PSTM_SCRIPT = Join-Path $PSTM_DIR "pstm.ps1"

function Show-Banner {
    Write-Host ""
    Write-Host -ForegroundColor White @"
██████╗ ███████╗████████╗    ██████╗ ██╗     
██╔══██╗██╔════╝╚══██╔══╝    ██╔══██╗██║     
██████╔╝███████╗   ██║       ██║  ██║██║     
██╔═══╝ ╚════██║   ██║       ██║  ██║██║     
██║     ███████║   ██║       ██████╔╝███████╗
╚═╝     ╚══════╝   ╚═╝       ╚═════╝ ╚══════╝
"@
    Write-Host ""
}

function Show-Divider {
    Write-Host -ForegroundColor White "════════════════════════════════════════════════════════"
}

function Show-Help {
    Show-Banner
    Write-Host -ForegroundColor White "pstm v${PSTM_VERSION}" -NoNewline
    Write-Host " - PST Manager"
    Write-Host ""
    Show-Divider
    Write-Host ""
    Write-Host -ForegroundColor White "Usage:"
    Write-Host "  pstm [command]"
    Write-Host ""
    Write-Host -ForegroundColor White "Commands:"
    Write-Host ""
    Write-Host -ForegroundColor Green "  -h" -NoNewline; Write-Host -ForegroundColor Green ", -help" -NoNewline; Write-Host "            Show this help message"
    Write-Host -ForegroundColor Green "  -i" -NoNewline; Write-Host -ForegroundColor Green ", -install" -NoNewline; Write-Host "          Download and install PalworldSaveTools"
    Write-Host -ForegroundColor Green "  -u" -NoNewline; Write-Host -ForegroundColor Green ", -upgrade" -NoNewline; Write-Host "          Update PalworldSaveTools to the latest version"
    Write-Host -ForegroundColor Green "  -uninstall" -NoNewline; Write-Host "            Uninstall PalworldSaveTools"
    Write-Host -ForegroundColor Green "  -v" -NoNewline; Write-Host -ForegroundColor Green ", -version" -NoNewline; Write-Host "         Show pstm and remote PST version"
    Write-Host -ForegroundColor Green "  -g" -NoNewline; Write-Host -ForegroundColor Green ", -github" -NoNewline; Write-Host "          Open PalworldSaveTools GitHub page"
    Write-Host -ForegroundColor Green "  -uninstall-all" -NoNewline; Write-Host "        Uninstall pstm and PalworldSaveTools"
    Write-Host -ForegroundColor Green "  -update-self" -NoNewline; Write-Host "          Update pstm to the latest version"
    Write-Host ""
    Show-Divider
    Write-Host ""
}

function Get-LatestPstTag {
    $apiUrl = "https://api.github.com/repos/$PST_REPO/releases"
    try {
        $releases = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        foreach ($rel in $releases) {
            $tag = $rel.tag_name
            if ($tag -notmatch '-beta' -and $tag -notmatch '-pre' -and $tag -notmatch '-alpha') {
                return $tag
            }
        }
    } catch {}
    return ""
}

function Get-LatestPstmVersion {
    $apiUrl = "https://api.github.com/repos/$PSTM_REPO/releases/latest"
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        $tag = $response.tag_name
        if ($tag) { return $tag.TrimStart('v') }
    } catch {}
    return ""
}

function Find-SevenZip {
    if (Get-Command 7z -ErrorAction SilentlyContinue) { return "7z" }
    if (Test-Path "C:\Program Files\7-Zip\7z.exe") { return "C:\Program Files\7-Zip\7z.exe" }
    if (Test-Path "C:\Program Files (x86)\7-Zip\7z.exe") { return "C:\Program Files (x86)\7-Zip\7z.exe" }
    if (Get-Command 7zr -ErrorAction SilentlyContinue) { return "7zr" }
    return $null
}

function New-DesktopShortcut {
    $exePath = Join-Path $PST_DATA_DIR "PalworldSaveTools.exe"
    if (-not (Test-Path $exePath)) {
        $exePath = Get-ChildItem -Path $PST_DATA_DIR -Filter "PalworldSaveTools.exe" -Recurse | Select-Object -First 1 -ExpandProperty FullName
    }

    if ($exePath -and (Test-Path $exePath)) {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktop "PalworldSaveTools.lnk"
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $exePath
        $shortcut.WorkingDirectory = Split-Path $exePath
        $shortcut.Description = "PalworldSaveTools"
        $shortcut.Save()
        Write-Host -ForegroundColor Green "* Desktop shortcut created!"
    } else {
        Write-Host -ForegroundColor Yellow "  Warning: Could not find PalworldSaveTools.exe for shortcut."
    }
}

function Install-PST {
    Show-Banner
    Show-Divider
    Write-Host ""
    Write-Host -ForegroundColor White "Installing PalworldSaveTools"
    Write-Host ""

    Write-Host -ForegroundColor Yellow "> Fetching latest release info..."
    Write-Host ""

    $tagName = Get-LatestPstTag
    if (-not $tagName) {
        Write-Host ""
        Write-Host -ForegroundColor Red "x Error: Failed to find the latest non-beta release."
        Write-Host -ForegroundColor Red "  Check your internet connection."
        exit 1
    }

    $version = $tagName.TrimStart('v')
    Write-Host -ForegroundColor Green "* Latest version found:" -NoNewline
    Write-Host -ForegroundColor White " $tagName"
    Write-Host ""

    $downloadUrl = "https://github.com/$PST_REPO/releases/download/$tagName/PST_standalone_v$version.7z"
    $outputFilename = Join-Path $env:TEMP "PST_standalone_v$version.7z"

    Write-Host -ForegroundColor Yellow "> Step 1/4: Downloading release..."
    Write-Host -ForegroundColor Cyan "  URL: " -NoNewline
    Write-Host -ForegroundColor White $downloadUrl
    Write-Host ""

    try {
        if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
            & curl.exe -L -# -o $outputFilename $downloadUrl 2>$null
            if ($LASTEXITCODE -ne 0) { throw "curl.exe failed" }
        } else {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFilename
        }

        $fileSize = (Get-Item $outputFilename).Length / 1MB
        $fileSizeStr = "{0:N1} MB" -f $fileSize
        Write-Host -ForegroundColor Green "* Download Complete! " -NoNewline
        Write-Host -ForegroundColor White "($fileSizeStr)"
    } catch {
        Write-Host ""
        Write-Host -ForegroundColor Red "x Error: Download failed. $($_.Exception.Message)"
        exit 1
    }
    Write-Host ""

    $sevenZip = Find-SevenZip
    if (-not $sevenZip) {
        Write-Host -ForegroundColor Red "x Error: 7-Zip not found. Please install 7-Zip."
        exit 1
    }

    Write-Host -ForegroundColor Yellow "> Step 2/4: Extracting archive..."
    Write-Host -ForegroundColor Cyan "  Extracting to: " -NoNewline
    Write-Host -ForegroundColor White $PST_DATA_DIR
    Write-Host ""

    if (Test-Path $PST_DATA_DIR) {
        Remove-Item $PST_DATA_DIR -Recurse -Force
    }
    New-Item -ItemType Directory -Path $PST_DATA_DIR -Force | Out-Null

    try {
        & $sevenZip x "$outputFilename" -o"$PST_DATA_DIR" -y | Out-Null
        Write-Host -ForegroundColor Green "* Extraction Complete!"
    } catch {
        Write-Host ""
        Write-Host -ForegroundColor Red "x Error: Extraction failed. $($_.Exception.Message)"
        exit 1
    }
    Write-Host ""

    Write-Host -ForegroundColor Yellow "> Step 3/4: Cleaning up..."
    Write-Host ""

    try {
        Remove-Item $outputFilename -Force -ErrorAction Stop
        Write-Host -ForegroundColor Green "* Cleanup Complete!"
    } catch {
        Write-Host ""
        Write-Host -ForegroundColor Red "x Error: Failed to delete file. $($_.Exception.Message)"
    }
    Write-Host ""

    Write-Host -ForegroundColor Yellow "> Step 4/4: Finalizing..."
    Write-Host ""
    New-DesktopShortcut
    Write-Host ""

    Show-Divider
    Write-Host ""
    Write-Host -ForegroundColor Green -NoNewline "Setup Complete!"
    Write-Host ""
    Write-Host ""
    Write-Host -ForegroundColor White "How to run:"
    Write-Host ""
    Write-Host -ForegroundColor Green "  Double-click PalworldSaveTools on your Desktop"
    Write-Host ""
    Write-Host -ForegroundColor Cyan "  Or: " -NoNewline
    Write-Host -ForegroundColor White $PST_DATA_DIR
    Write-Host ""
}

function Upgrade-PST {
    Show-Banner
    Show-Divider
    Write-Host ""
    Write-Host -ForegroundColor White "Upgrading PalworldSaveTools"
    Write-Host ""

    if (-not (Test-Path $PST_DATA_DIR)) {
        Write-Host -ForegroundColor Red "x Error: PalworldSaveTools is not installed."
        Write-Host -ForegroundColor Yellow "  Run " -NoNewline
        Write-Host -ForegroundColor Cyan "pstm -i" -NoNewline
        Write-Host -ForegroundColor Yellow " to install first."
        exit 1
    }

    Write-Host -ForegroundColor Yellow "> Fetching latest release info..."
    Write-Host ""

    $tagName = Get-LatestPstTag
    if (-not $tagName) {
        Write-Host ""
        Write-Host -ForegroundColor Red "x Error: Failed to find the latest non-beta release."
        exit 1
    }

    $version = $tagName.TrimStart('v')
    Write-Host -ForegroundColor Green "* Latest version found:" -NoNewline
    Write-Host -ForegroundColor White " $tagName"
    Write-Host ""

    $downloadUrl = "https://github.com/$PST_REPO/releases/download/$tagName/PST_standalone_v$version.7z"
    $outputFilename = Join-Path $env:TEMP "PST_standalone_v$version.7z"

    Write-Host -ForegroundColor Yellow "> Step 1/4: Downloading release..."
    Write-Host -ForegroundColor Cyan "  URL: " -NoNewline
    Write-Host -ForegroundColor White $downloadUrl
    Write-Host ""

    try {
        if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
            & curl.exe -L -# -o $outputFilename $downloadUrl 2>$null
            if ($LASTEXITCODE -ne 0) { throw "curl.exe failed" }
        } else {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFilename
        }

        $fileSize = (Get-Item $outputFilename).Length / 1MB
        $fileSizeStr = "{0:N1} MB" -f $fileSize
        Write-Host -ForegroundColor Green "* Download Complete! " -NoNewline
        Write-Host -ForegroundColor White "($fileSizeStr)"
    } catch {
        Write-Host ""
        Write-Host -ForegroundColor Red "x Error: Download failed. $($_.Exception.Message)"
        exit 1
    }
    Write-Host ""

    $sevenZip = Find-SevenZip
    if (-not $sevenZip) {
        Write-Host -ForegroundColor Red "x Error: 7-Zip not found. Please install 7-Zip."
        exit 1
    }

    Write-Host -ForegroundColor Yellow "> Step 2/4: Extracting archive..."
    Write-Host -ForegroundColor Cyan "  Extracting to: " -NoNewline
    Write-Host -ForegroundColor White $PST_DATA_DIR
    Write-Host ""

    Remove-Item $PST_DATA_DIR -Recurse -Force
    New-Item -ItemType Directory -Path $PST_DATA_DIR -Force | Out-Null

    try {
        & $sevenZip x "$outputFilename" -o"$PST_DATA_DIR" -y | Out-Null
        Write-Host -ForegroundColor Green "* Extraction Complete!"
    } catch {
        Write-Host ""
        Write-Host -ForegroundColor Red "x Error: Extraction failed. $($_.Exception.Message)"
        exit 1
    }
    Write-Host ""

    Write-Host -ForegroundColor Yellow "> Step 3/4: Cleaning up..."
    Write-Host ""

    try {
        Remove-Item $outputFilename -Force -ErrorAction Stop
        Write-Host -ForegroundColor Green "* Cleanup Complete!"
    } catch {
        Write-Host ""
        Write-Host -ForegroundColor Red "x Error: Failed to delete file."
    }
    Write-Host ""

    Write-Host -ForegroundColor Yellow "> Step 4/4: Finalizing..."
    Write-Host ""
    New-DesktopShortcut
    Write-Host ""

    Show-Divider
    Write-Host ""
    Write-Host -ForegroundColor Green -NoNewline "Upgrade Complete!"
    Write-Host -ForegroundColor White " ($tagName)"
    Write-Host ""
}

function Uninstall-PST {
    if (-not (Test-Path $PST_DATA_DIR)) {
        Write-Host -ForegroundColor Red "x PalworldSaveTools is not installed."
        exit 1
    }

    Write-Host -ForegroundColor Yellow "> This will delete: " -NoNewline
    Write-Host -ForegroundColor Cyan $PST_DATA_DIR
    $confirm = Read-Host -Prompt "> Are you sure? [y/N]"

    if ($confirm -match '^[Yy]$') {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktop "PalworldSaveTools.lnk"
        if (Test-Path $shortcutPath) { Remove-Item $shortcutPath -Force }

        Remove-Item $PST_DATA_DIR -Recurse -Force
        Write-Host -ForegroundColor Green "* PalworldSaveTools uninstalled successfully."
    } else {
        Write-Host -ForegroundColor Gray "Cancelled."
    }
}

function Uninstall-All {
    Write-Host -ForegroundColor Yellow "> This will delete:"
    Write-Host -ForegroundColor Cyan "  $PST_DATA_DIR"
    Write-Host -ForegroundColor Cyan "  $PSTM_DIR"
    Write-Host ""
    $confirm = Read-Host -Prompt "> Are you sure? [y/N]"

    if ($confirm -match '^[Yy]$') {
        if (Test-Path $PST_DATA_DIR) { Remove-Item $PST_DATA_DIR -Recurse -Force }

        $desktop = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktop "PalworldSaveTools.lnk"
        if (Test-Path $shortcutPath) { Remove-Item $shortcutPath -Force }

        Remove-Item $PSTM_DIR -Recurse -Force

        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath -like "*pstm*") {
            $newPath = ($userPath -split ';' | Where-Object { $_ -notlike "*pstm*" }) -join ';'
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            Write-Host -ForegroundColor Yellow "> Removed pstm from user PATH."
        }

        Write-Host ""
        Write-Host -ForegroundColor Green "* pstm and PalworldSaveTools fully uninstalled."
    } else {
        Write-Host -ForegroundColor Gray "Cancelled."
    }
}

function Show-Version {
    Show-Banner
    Write-Host -ForegroundColor White "pstm      v$PSTM_VERSION"
    Write-Host -ForegroundColor White "pst remote" -NoNewline; Write-Host " querying..."

    $tagName = Get-LatestPstTag
    if ($tagName) {
        Write-Host -ForegroundColor White "pst latest" -NoNewline; Write-Host -ForegroundColor Green " $tagName" -NoNewline; Write-Host " (non-beta)"
    } else {
        Write-Host -ForegroundColor White "pst latest" -NoNewline; Write-Host -ForegroundColor Red " unavailable"
    }

    $installedVer = "not installed"
    if (Test-Path $PST_DATA_DIR) { $installedVer = "installed" }
    Write-Host -ForegroundColor White "pst local " -NoNewline; Write-Host " $installedVer"
}

function Open-GitHub {
    $url = "https://github.com/$PST_REPO"
    Write-Host -ForegroundColor Cyan "> Opening: " -NoNewline
    Write-Host -ForegroundColor White $url
    Start-Process $url
}

function Update-Self {
    Write-Host -ForegroundColor Yellow "> Checking for pstm update..."
    $tmpFile = Join-Path $env:TEMP "pstm_update.ps1"

    try {
        Invoke-WebRequest -Uri "${PSTM_RAW_BASE}/.Windows/pstm.ps1" -OutFile $tmpFile -UseBasicParsing
        if ((Test-Path $tmpFile) -and ((Get-Item $tmpFile).Length -gt 0)) {
            Move-Item -Path $tmpFile -Destination $PSTM_SCRIPT -Force
            Write-Host -ForegroundColor Green "* pstm updated successfully!"
        } else {
            Write-Host -ForegroundColor Red "x Error: Downloaded file is empty."
            Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Host -ForegroundColor Red "x Error: Failed to download update. $($_.Exception.Message)"
        Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
    }
}

$remoteVer = Get-LatestPstmVersion
if ($remoteVer -and $remoteVer -ne $PSTM_VERSION) {
    Write-Host -ForegroundColor Yellow "> pstm update available: v$PSTM_VERSION -> v$remoteVer (auto-updating...)"
    Update-Self
}

$command = if ($args.Count -gt 0) { $args[0] } else { "" }

switch ($command) {
    { $_ -in "-h", "--help", "" } { Show-Help }
    { $_ -in "-i", "-install" } { Install-PST }
    { $_ -in "-u", "-upgrade" } { Upgrade-PST }
    { $_ -in "-v", "-version" } { Show-Version }
    { $_ -in "-g", "-github" } { Open-GitHub }
    "-uninstall" { Uninstall-PST }
    "-uninstall-all" { Uninstall-All }
    "-update-self" {
        Show-Banner
        Update-Self
    }
    default {
        Write-Host -ForegroundColor Red "x Unknown command: $command"
        Write-Host -ForegroundColor Yellow "  Run " -NoNewline
        Write-Host -ForegroundColor Cyan "pstm -h" -NoNewline
        Write-Host -ForegroundColor Yellow " for help."
        exit 1
    }
}
