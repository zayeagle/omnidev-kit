<#
.SYNOPSIS
  Sync skills/od (SSOT) -> .cursor/skills/od, rules -> .cursor/rules,
  and (auto/opt-in) the DSH bundle $env:DSH_HOME\skills\od (default ~/.dsh/skills/od).
.DESCRIPTION
  Run before commit after editing skills/od or rules/*.mdc.
  Default: sync DSH only when the DSH home directory exists.
.EXAMPLE
  powershell -File scripts/sync-skills.ps1 -Dsh
  powershell -File scripts/sync-skills.ps1 -NoDsh
#>
# ASCII-only script body
param(
  [switch]$Dsh,
  [switch]$NoDsh
)

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

$DshHome = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $env:USERPROFILE ".dsh" }
$syncDsh = $Dsh.IsPresent -or ((-not $NoDsh.IsPresent) -and (Test-Path $DshHome))
if ($syncDsh) {
  # Full overwrite, subdirectories included: DSH discovers only <root>/<name>/SKILL.md,
  # so engine/, phases/ and templates/ must ride along as bundle resources.
  $DstDsh = Join-Path $DshHome "skills\od"
  Write-Host "Syncing $SrcSkill -> $DstDsh"
  New-Item -ItemType Directory -Path (Join-Path $DshHome "skills") -Force | Out-Null
  if (Test-Path $DstDsh) {
    Remove-Item -Recurse -Force $DstDsh
  }
  Copy-Item -Recurse -Force $SrcSkill $DstDsh
} else {
  Write-Host "Skip DSH sync (pass -Dsh to install into `$DSH_HOME/skills/od)"
}

Write-Host "OK: skills + Cursor rule synced."
Write-Host "Next: powershell -File scripts/check-compliance.ps1"
