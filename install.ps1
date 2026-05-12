$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "claude-engineering-skills installer" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$repoRoot = $PSScriptRoot
$claudeHome = Join-Path $env:USERPROFILE ".claude"
$skillsTarget = Join-Path $claudeHome "skills"
$claudeMdTarget = Join-Path $claudeHome "CLAUDE.md"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $claudeHome ".backups\$timestamp"

# Create .claude if missing
if (-not (Test-Path $claudeHome)) {
    New-Item -ItemType Directory -Path $claudeHome -Force | Out-Null
    Write-Host "Created $claudeHome" -ForegroundColor Green
}

# Backup existing
$hasBackup = $false
if (Test-Path $claudeMdTarget) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Copy-Item $claudeMdTarget (Join-Path $backupDir "CLAUDE.md") -Force
    $hasBackup = $true
    Write-Host "Backed up existing CLAUDE.md" -ForegroundColor Yellow
}

if (Test-Path $skillsTarget) {
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    Copy-Item $skillsTarget (Join-Path $backupDir "skills") -Recurse -Force
    $hasBackup = $true
    Write-Host "Backed up existing skills/" -ForegroundColor Yellow
}

if ($hasBackup) {
    Write-Host "Backups saved to: $backupDir" -ForegroundColor Yellow
    Write-Host ""
}

# Install CLAUDE.md
$claudeMdSource = Join-Path $repoRoot "CLAUDE.md"
if (-not (Test-Path $claudeMdSource)) {
    Write-Host "ERROR: CLAUDE.md not found at $claudeMdSource" -ForegroundColor Red
    exit 1
}
Copy-Item $claudeMdSource $claudeMdTarget -Force
Write-Host "Installed CLAUDE.md" -ForegroundColor Green

# Remove old skills folder if exists (so removed skills are cleaned up)
if (Test-Path $skillsTarget) {
    Remove-Item $skillsTarget -Recurse -Force
}
New-Item -ItemType Directory -Path $skillsTarget -Force | Out-Null

# Install skills
$skillsSource = Join-Path $repoRoot "skills"
if (-not (Test-Path $skillsSource)) {
    Write-Host "ERROR: skills/ folder not found at $skillsSource" -ForegroundColor Red
    exit 1
}

$skillCount = 0
Get-ChildItem $skillsSource -Directory | ForEach-Object {
    $skillName = $_.Name
    $skillFile = Join-Path $_.FullName "SKILL.md"
    if (Test-Path $skillFile) {
        $destDir = Join-Path $skillsTarget $skillName
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        Copy-Item $skillFile (Join-Path $destDir "SKILL.md") -Force
        Write-Host "Installed skill: $skillName" -ForegroundColor Green
        $skillCount++
    }
}

Write-Host ""
Write-Host "Done. Installed CLAUDE.md and $skillCount skills." -ForegroundColor Cyan
Write-Host ""
Write-Host "Per-project memory at $claudeHome\projects was not touched." -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Close all existing Claude Code terminals" -ForegroundColor White
Write-Host "  2. Open a new terminal" -ForegroundColor White
Write-Host "  3. Install MCP servers (see README.md)" -ForegroundColor White
Write-Host "  4. Run: claude" -ForegroundColor White
Write-Host ""
