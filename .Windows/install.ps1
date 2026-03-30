$ErrorActionPreference = "Stop"

$PSTM_REPO = "CyrixJD115/PST-Manager"
$PSTM_RAW_BASE = "https://raw.githubusercontent.com/$PSTM_REPO/main"
$PSTM_DIR = Join-Path $env:LOCALAPPDATA "pstm"
$PSTM_SCRIPT = Join-Path $PSTM_DIR "pstm.ps1"

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
Write-Host -ForegroundColor White "Installing pstm..."
Write-Host ""

New-Item -ItemType Directory -Path $PSTM_DIR -Force | Out-Null

Write-Host -ForegroundColor Yellow "> Downloading pstm..."
try {
    Invoke-WebRequest -Uri "${PSTM_RAW_BASE}/.Windows/pstm.ps1" -OutFile $PSTM_SCRIPT -UseBasicParsing
} catch {
    Write-Host -ForegroundColor Red "x Error: Failed to download pstm. $($_.Exception.Message)"
    exit 1
}

Write-Host -ForegroundColor Green "* Downloaded to: " -NoNewline
Write-Host -ForegroundColor Cyan $PSTM_SCRIPT
Write-Host ""

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$PSTM_DIR*") {
    $newPath = if ($userPath) { "$userPath;$PSTM_DIR" } else { $PSTM_DIR }
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host -ForegroundColor Green "* Added $PSTM_DIR to user PATH"
} else {
    Write-Host -ForegroundColor Gray "  $PSTM_DIR already in PATH"
}

Write-Host ""
Write-Host -ForegroundColor White "════════════════════════════════════════════════════════"
Write-Host ""
Write-Host -ForegroundColor Green "pstm installed successfully!"
Write-Host ""
Write-Host -ForegroundColor White "Next steps:"
Write-Host ""
Write-Host -ForegroundColor Gray "  Reload your terminal, then:"
Write-Host ""
Write-Host -ForegroundColor Cyan "  pstm -i" -NoNewline; Write-Host -ForegroundColor Gray "    Install PalworldSaveTools"
Write-Host -ForegroundColor Cyan "  pstm -h" -NoNewline; Write-Host -ForegroundColor Gray "    Show all commands"
Write-Host ""
