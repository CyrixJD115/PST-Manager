$ErrorActionPreference = "Stop"

$PSTM_VERSION = "1.0.8"
$PSTM_REPO = "CyrixJD115/PST-Manager"
$PST_REPO = "deafdudecomputers/PalworldSaveTools"
$PSTM_RAW_BASE = "https://raw.githubusercontent.com/$PSTM_REPO/main"
$PSTM_VERSION_URL = "$PSTM_RAW_BASE/version.yaml"

$PST_DATA_DIR = Join-Path $env:LOCALAPPDATA "palworldsavetools"
$PSTM_DIR = Join-Path $env:LOCALAPPDATA "pstm"
$PSTM_SCRIPT = Join-Path $PSTM_DIR "pstm.ps1"

function Show-Banner {
    Write-Host ""
    Write-Host -ForegroundColor White @"
██████╗ ███████╗████████╗███╗   ███╗
██╔══██╗██╔════╝╚══██╔══╝████╗ ████║
██████╔╝███████╗   ██║   ██╔████╔██║
██╔═══╝ ╚════██║   ██║   ██║╚██╔╝██║
██║     ███████║   ██║   ██║ ╚═╝ ██║
╚═╝     ╚══════╝   ╚═╝   ╚═╝     ╚═╝
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
    Write-Host -ForegroundColor Green "  -v" -NoNewline; Write-Host -ForegroundColor Green ", -version" -NoNewline; Write-Host "         Show pstm and remote PST version"
    Write-Host -ForegroundColor Green "  -i" -NoNewline; Write-Host -ForegroundColor Green ", -install" -NoNewline; Write-Host "          Download and install PalworldSaveTools"
    Write-Host -ForegroundColor Green "  run" -NoNewline; Write-Host "                Run PalworldSaveTools"
    Write-Host -ForegroundColor Green "  -u" -NoNewline; Write-Host -ForegroundColor Green ", -upgrade" -NoNewline; Write-Host "          Update PalworldSaveTools to the latest version"
    Write-Host -ForegroundColor Green "  -update-self" -NoNewline; Write-Host "          Update pstm to the latest version"
    Write-Host -ForegroundColor Green "  -g" -NoNewline; Write-Host -ForegroundColor Green ", -github" -NoNewline; Write-Host "          Open PalworldSaveTools GitHub page"
    Write-Host -ForegroundColor Green "  -uninstall" -NoNewline; Write-Host "            Uninstall PalworldSaveTools"
    Write-Host -ForegroundColor Green "  -uninstall-all" -NoNewline; Write-Host "        Uninstall pstm and PalworldSaveTools"
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

function Compare-Versions {
    param([string]$V1, [string]$V2)
    $a1 = $V1 -split '\.'
    $a2 = $V2 -split '\.'
    $len = [Math]::Max($a1.Count, $a2.Count)
    for ($i = 0; $i -lt $len; $i++) {
        $n1 = if ($i -lt $a1.Count) { [int]$a1[$i] } else { 0 }
        $n2 = if ($i -lt $a2.Count) { [int]$a2[$i] } else { 0 }
        if ($n1 -gt $n2) { return 1 }
        if ($n1 -lt $n2) { return -1 }
    }
    return 0
}

function Get-LatestPstmVersion {
    try {
        $yaml = Invoke-RestMethod -Uri $PSTM_VERSION_URL -UseBasicParsing
        $match = [regex]::Match($yaml, 'version:\s*"([^"]+)"')
        if (-not $match.Success) {
            $match = [regex]::Match($yaml, 'version:\s+([0-9][0-9.]*[0-9])')
        }
        if ($match.Success) {
            return $match.Groups[1].Value.TrimStart('v')
        }
    } catch {}
    return ""
}

function Ensure-Uv {
    try {
        uv --version | Out-Null
        return
    } catch {}

    Write-Host -ForegroundColor Yellow "> uv not found. Installing uv..."
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")

    try {
        uv --version | Out-Null
        Write-Host -ForegroundColor Green "* uv installed successfully!"
    } catch {
        Write-Host -ForegroundColor Red "x Error: Failed to install uv."
        throw "uv install failed"
    }
}

function New-PstLauncher {
    $pstPs1 = Join-Path $PST_DATA_DIR "pst.ps1"
    $sourceDir = Join-Path $PST_DATA_DIR "source"
    $icoPath = Join-Path $PST_DATA_DIR "pstm.ico"
    $shortcutPath = Join-Path $env:USERPROFILE "Desktop\PST.lnk"

    $content = @"
Set-Location "$sourceDir"
uv python install 3.13
uv run ./start.py `$args
"@
    Set-Content -Path $pstPs1 -Value $content -Force
    Write-Host -ForegroundColor Green "* Launcher generated: " -NoNewline
    Write-Host -ForegroundColor Cyan $pstPs1

    try {
        Write-Host -ForegroundColor Yellow "> Downloading icon..."
        Invoke-WebRequest -Uri "${PSTM_RAW_BASE}/pstm.ico" -OutFile $icoPath -UseBasicParsing
        Write-Host -ForegroundColor Green "* Icon downloaded: " -NoNewline
        Write-Host -ForegroundColor Cyan $icoPath
    } catch {
        Write-Host -ForegroundColor Yellow "! Warning: Failed to download icon."
    }

    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$pstPs1`""
    $Shortcut.WorkingDirectory = $sourceDir
    if (Test-Path $icoPath) {
        $Shortcut.IconLocation = $icoPath
    }
    $Shortcut.Save()
    Write-Host -ForegroundColor Green "* Desktop shortcut created: " -NoNewline
    Write-Host -ForegroundColor Cyan $shortcutPath
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

    $downloadUrl = "https://github.com/$PST_REPO/archive/refs/tags/$tagName.zip"
    $outputFilename = Join-Path $env:TEMP "PalworldSaveTools-$version.zip"

    Write-Host -ForegroundColor Yellow "> Step 1/4: Downloading source code..."
    Write-Host -ForegroundColor Cyan "  URL: " -NoNewline
    Write-Host -ForegroundColor White $downloadUrl
    Write-Host ""

    try {
        if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
            $null = & curl.exe -L -# -o $outputFilename $downloadUrl 2>&1
            if ($LASTEXITCODE -ne 0) { throw "curl.exe failed (exit code: $LASTEXITCODE)" }
        } else {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFilename -UseBasicParsing
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

    Write-Host -ForegroundColor Yellow "> Step 2/4: Extracting archive..."
    Write-Host -ForegroundColor Cyan "  Extracting to: " -NoNewline
    Write-Host -ForegroundColor White "$PST_DATA_DIR\source"
    Write-Host ""

    if (Test-Path $PST_DATA_DIR) {
        Remove-Item $PST_DATA_DIR -Recurse -Force
    }
    New-Item -ItemType Directory -Path $PST_DATA_DIR -Force | Out-Null

    try {
        $extractTmp = Join-Path $env:TEMP "PST_extract_$version"
        if (Test-Path $extractTmp) { Remove-Item $extractTmp -Recurse -Force }
        Expand-Archive -Path $outputFilename -DestinationPath $extractTmp -Force

        $extractedDir = Join-Path $extractTmp "PalworldSaveTools-$version"
        if (Test-Path $extractedDir) {
            Move-Item -Path $extractedDir -Destination (Join-Path $PST_DATA_DIR "source") -Force
        } else {
            Write-Host -ForegroundColor Red "x Error: Failed to find extracted directory."
            exit 1
        }
        Remove-Item $extractTmp -Recurse -Force -ErrorAction SilentlyContinue
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
    Ensure-Uv
    New-PstLauncher
    Write-Host ""

    Show-Divider
    Write-Host ""
    Write-Host -ForegroundColor Green -NoNewline "Setup Complete!"
    Write-Host ""
    Write-Host ""
    Write-Host -ForegroundColor White "How to run:"
    Write-Host ""
    Write-Host -ForegroundColor Cyan "  pstm run"
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

    $downloadUrl = "https://github.com/$PST_REPO/archive/refs/tags/$tagName.zip"
    $outputFilename = Join-Path $env:TEMP "PalworldSaveTools-$version.zip"

    Write-Host -ForegroundColor Yellow "> Step 1/4: Downloading source code..."
    Write-Host -ForegroundColor Cyan "  URL: " -NoNewline
    Write-Host -ForegroundColor White $downloadUrl
    Write-Host ""

    try {
        if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
            $null = & curl.exe -L -# -o $outputFilename $downloadUrl 2>&1
            if ($LASTEXITCODE -ne 0) { throw "curl.exe failed (exit code: $LASTEXITCODE)" }
        } else {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFilename -UseBasicParsing
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

    Write-Host -ForegroundColor Yellow "> Step 2/4: Extracting archive..."
    Write-Host -ForegroundColor Cyan "  Extracting to: " -NoNewline
    Write-Host -ForegroundColor White "$PST_DATA_DIR\source"
    Write-Host ""

    Remove-Item $PST_DATA_DIR -Recurse -Force
    New-Item -ItemType Directory -Path $PST_DATA_DIR -Force | Out-Null

    try {
        $extractTmp = Join-Path $env:TEMP "PST_extract_$version"
        if (Test-Path $extractTmp) { Remove-Item $extractTmp -Recurse -Force }
        Expand-Archive -Path $outputFilename -DestinationPath $extractTmp -Force

        $extractedDir = Join-Path $extractTmp "PalworldSaveTools-$version"
        if (Test-Path $extractedDir) {
            Move-Item -Path $extractedDir -Destination (Join-Path $PST_DATA_DIR "source") -Force
        } else {
            Write-Host -ForegroundColor Red "x Error: Failed to find extracted directory."
            exit 1
        }
        Remove-Item $extractTmp -Recurse -Force -ErrorAction SilentlyContinue
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
    Ensure-Uv
    New-PstLauncher
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
        $shortcutPath = Join-Path $env:USERPROFILE "Desktop\PST.lnk"
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
        $shortcutPath = Join-Path $env:USERPROFILE "Desktop\PST.lnk"
        if (Test-Path $shortcutPath) { Remove-Item $shortcutPath -Force }
        if (Test-Path $PST_DATA_DIR) { Remove-Item $PST_DATA_DIR -Recurse -Force }

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

function Run-PST {
    $pstPs1 = Join-Path $PST_DATA_DIR "pst.ps1"

    if (Test-Path $pstPs1) {
        & $pstPs1 @args
    } else {
        Write-Host -ForegroundColor Red "x Error: PalworldSaveTools is not installed."
        Write-Host -ForegroundColor Yellow "  Run " -NoNewline
        Write-Host -ForegroundColor Cyan "pstm -i" -NoNewline
        Write-Host -ForegroundColor Yellow " to install first."
        exit 1
    }
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
if ($remoteVer) {
    $cmp = Compare-Versions -V1 $remoteVer -V2 $PSTM_VERSION
    if ($cmp -eq 1) {
        Write-Host -ForegroundColor Yellow "> pstm update available: v$PSTM_VERSION -> v$remoteVer (auto-updating...)"
        Update-Self
    } elseif ($cmp -eq -1) {
        Write-Host -ForegroundColor Yellow "Warning: local version (v$PSTM_VERSION) is ahead of remote (v$remoteVer). Skipping update."
    }
}

$command = if ($args.Count -gt 0) { $args[0] } else { "" }

switch ($command) {
    { $_ -in "-h", "--help", "" } { Show-Help }
    { $_ -in "-i", "-install" } { Install-PST }
    { $_ -in "-u", "-upgrade" } { Upgrade-PST }
    { $_ -in "-v", "-version" } { Show-Version }
    { $_ -in "-g", "-github" } { Open-GitHub }
    "run" { Run-PST }
    "-uninstall" { Uninstall-PST }
    "-uninstall-all" { Uninstall-All }
    "-update-self" {
        Show-Banner
        Write-Host -ForegroundColor Yellow "> Checking for pstm update..."
        $remoteVer = Get-LatestPstmVersion
        if (-not $remoteVer) {
            Write-Host -ForegroundColor Red "x Error: Could not fetch remote version."
        } else {
            $cmp = Compare-Versions -V1 $remoteVer -V2 $PSTM_VERSION
            if ($cmp -eq 1) {
                Update-Self
            } elseif ($cmp -eq 0) {
                Write-Host -ForegroundColor Green "* pstm is already up to date (v$PSTM_VERSION)."
            } else {
                Write-Host -ForegroundColor Yellow "Warning: local version (v$PSTM_VERSION) is ahead of remote (v$remoteVer). Skipping update."
            }
        }
    }
    default {
        Write-Host -ForegroundColor Red "x Unknown command: $command"
        Write-Host -ForegroundColor Yellow "  Run " -NoNewline
        Write-Host -ForegroundColor Cyan "pstm -h" -NoNewline
        Write-Host -ForegroundColor Yellow " for help."
        exit 1
    }
}
