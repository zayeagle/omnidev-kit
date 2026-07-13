# Sync skills/od (SSOT) → .cursor/skills/od and rules → .cursor/rules
# Usage: pwsh scripts/sync-skills.ps1
# Run before commit after editing skills/od or rules/*.mdc

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $Root "skills\od\SKILL.md"))) {
  Write-Error "skills/od/SKILL.md not found under $Root"
}

$SrcSkill = Join-Path $Root "skills\od"
$DstSkill = Join-Path $Root ".cursor\skills\od"
$SrcRules = Join-Path $Root "rules"
$DstRules = Join-Path $Root ".cursor\rules"

Write-Host "Syncing $SrcSkill -> $DstSkill"
if (Test-Path $DstSkill) {
  Remove-Item -Recurse -Force $DstSkill
}
New-Item -ItemType Directory -Path (Split-Path $DstSkill) -Force | Out-Null
Copy-Item -Recurse -Force $SrcSkill $DstSkill

Write-Host "Syncing Cursor rules (01-omnidev-workflow.mdc)"
New-Item -ItemType Directory -Path $DstRules -Force | Out-Null
Copy-Item -Force (Join-Path $SrcRules "01-omnidev-workflow.mdc") (Join-Path $DstRules "01-omnidev-workflow.mdc")

Write-Host "OK: skills + Cursor rule synced."
Write-Host "Next: powershell -File scripts/check-compliance.ps1"
