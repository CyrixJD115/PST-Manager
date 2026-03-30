$ErrorActionPreference = "Stop"

$PSTDL_REPO = "CyrixJD115/PST-DL"
$PSTDL_RAW_BASE = "https://raw.githubusercontent.com/$PSTDL_REPO/main"
$PSTDL_DIR = Join-Path $env:LOCALAPPDATA "pstdl"
$PSTDL_SCRIPT = Join-Path $PSTDL_DIR "pstdl.ps1"

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
Write-Host -ForegroundColor White "════════════════════════════════════════════════════════"
Write-Host ""
Write-Host -ForegroundColor White "Installing pstdl..."
Write-Host ""

New-Item -ItemType Directory -Path $PSTDL_DIR -Force | Out-Null

Write-Host -ForegroundColor Yellow "> Downloading pstdl..."
try {
    Invoke-WebRequest -Uri "${PSTDL_RAW_BASE}/.Windows/pstdl.ps1" -OutFile $PSTDL_SCRIPT -UseBasicParsing
} catch {
    Write-Host -ForegroundColor Red "x Error: Failed to download pstdl. $($_.Exception.Message)"
    exit 1
}

Write-Host -ForegroundColor Green "* Downloaded to: " -NoNewline
Write-Host -ForegroundColor Cyan $PSTDL_SCRIPT
Write-Host ""

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$PSTDL_DIR*") {
    $newPath = if ($userPath) { "$userPath;$PSTDL_DIR" } else { $PSTDL_DIR }
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host -ForegroundColor Green "* Added $PSTDL_DIR to user PATH"
} else {
    Write-Host -ForegroundColor Gray "  $PSTDL_DIR already in PATH"
}

Write-Host ""
Write-Host -ForegroundColor White "════════════════════════════════════════════════════════"
Write-Host ""
Write-Host -ForegroundColor Green "pstdl installed successfully!"
Write-Host ""
Write-Host -ForegroundColor White "Next steps:"
Write-Host ""
Write-Host -ForegroundColor Gray "  Reload your terminal, then:"
Write-Host ""
Write-Host -ForegroundColor Cyan "  pstdl -i" -NoNewline; Write-Host -ForegroundColor Gray "    Install PalworldSaveTools"
Write-Host -ForegroundColor Cyan "  pstdl -h" -NoNewline; Write-Host -ForegroundColor Gray "    Show all commands"
Write-Host ""
