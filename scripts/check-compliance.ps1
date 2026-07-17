# OmniDev kit compliance checks (static) - ASCII-only script body
# Usage: powershell -File scripts/check-compliance.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Failed = 0

function Fail([string]$Msg) {
  Write-Host "FAIL: $Msg" -ForegroundColor Red
  $script:Failed++
}
function Ok([string]$Msg) {
  Write-Host "OK:   $Msg" -ForegroundColor Green
}
function Read-Utf8([string]$Path) {
  return [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false))
}

$Src = Join-Path $Root "skills\od"
$Dst = Join-Path $Root ".cursor\skills\od"

if (-not (Test-Path (Join-Path $Src "SKILL.md"))) { Fail "skills/od/SKILL.md missing"; exit 1 }
if (-not (Test-Path $Dst)) {
  Fail ".cursor/skills/od missing - run scripts/sync-skills.ps1"
} else {
  foreach ($f in (Get-ChildItem -Recurse -File $Src)) {
    $rel = $f.FullName.Substring($Src.Length)
    $other = Join-Path $Dst $rel
    if (-not (Test-Path $other)) {
      Fail "Missing in .cursor: $rel"
    } elseif ((Get-FileHash $f.FullName).Hash -ne (Get-FileHash $other).Hash) {
      Fail "Drift: $rel"
    }
  }
  foreach ($f in (Get-ChildItem -Recurse -File $Dst)) {
    $rel = $f.FullName.Substring($Dst.Length)
    if (-not (Test-Path (Join-Path $Src $rel))) {
      Fail "Extra in .cursor: $rel"
    }
  }
  if ($Failed -eq 0) { Ok "skills/od <-> .cursor/skills/od identical" }
}

$r1 = Join-Path $Root "rules\01-omnidev-workflow.mdc"
$r2 = Join-Path $Root ".cursor\rules\01-omnidev-workflow.mdc"
if (-not (Test-Path $r2)) {
  Fail ".cursor/rules/01-omnidev-workflow.mdc missing"
} elseif ((Get-FileHash $r1).Hash -ne (Get-FileHash $r2).Hash) {
  Fail "rules/01 <-> .cursor/rules/01 drift"
} else {
  Ok "Cursor trigger rule synced"
}

$checks = @(
  @{ Path = "skills\od\engine\interactive-prompt.md"; Need = @('STOP', 'WAIT', 'AskQuestion', 'phase0_s_fastpath', 'Decision Matrix', 'deploy_consent', 'Markdown Fallback Table', 'box-drawing', 'pending_decision', 'codex_auto_resolve', 'allow_auto_resolve') },
  @{ Path = "skills\od\engine\trigger-gate.md"; Need = @('[\/$]od', 'Explicit non-activation feedback', 'STOP', 'pending_decision', 'A-index') },
  @{ Path = "skills\od\phases\00-assessment.md"; Need = @('phase0_s_fastpath') },
  @{ Path = "skills\od\phases\02-planning.md"; Need = @('phase2_plan_ready') },
  @{ Path = "skills\od\phases\05-deploy.md"; Need = @('deploy_consent', 'deploy_prod') },
  @{ Path = "docs\omnidev-state\config.json"; Need = @('codex_auto_resolve') },
  @{ Path = "skills\od\SKILL.md"; Need = @('\$od', '/od') },
  @{ Path = "rules\03-omnidev-workflow.codex.md"; Need = @('\$od', '/od') },
  @{ Path = "AGENTS.md"; Need = @('\$od', '/od') }
)

foreach ($c in $checks) {
  $p = Join-Path $Root $c.Path
  if (-not (Test-Path $p)) { Fail "Missing $($c.Path)"; continue }
  $text = Read-Utf8 $p
  $miss = @()
  foreach ($pat in $c.Need) {
    if ($text -notmatch $pat) { $miss += $pat }
  }
  if ($miss.Count -gt 0) {
    Fail ("{0} missing: {1}" -f $c.Path, ($miss -join ", "))
  } else {
    Ok "$($c.Path) fixtures"
  }
}

$ip = Join-Path $Root "skills\od\engine\interactive-prompt.md"
$lines = (Get-Content -Encoding utf8 $ip | Measure-Object -Line).Lines
if ($lines -gt 320) {
  Fail "interactive-prompt.md too large ($lines lines; budget 320)"
} else {
  Ok "interactive-prompt.md size ($lines lines)"
}

$ipText = Read-Utf8 $ip
if ($ipText.Contains("checkpoint / skill / phase0") -and $ipText.Contains("autoResolutionMs`` 60000")) {
  Fail "interactive-prompt.md still recommends autoResolutionMs for non-blocking prompts"
} else {
  Ok "autoResolutionMs default-off"
}

$p0 = Read-Utf8 (Join-Path $Root "skills\od\phases\00-assessment.md")
if ($p0.Contains("Skip popup entirely")) {
  Fail "00-assessment.md still skips S-level popup"
} else {
  Ok "S-level popup required"
}

$autoContinueDefault = [System.Text.Encoding]::UTF8.GetString([byte[]](
  0xE8,0x87,0xAA,0xE5,0x8A,0xA8,0xE7,0xBB,0xA7,0xE7,0xBB,0xAD,0xE9,0xBB,0x98,0xE8,0xAE,0xA4
))
foreach ($rel in @(
  "skills\od\engine\interactive-prompt.md",
  "skills\od\engine\activation.md"
)) {
  $t = Read-Utf8 (Join-Path $Root $rel)
  if ($t.Contains($autoContinueDefault)) {
    Fail "$rel still contains auto-continue-default wording"
  } else {
    Ok "$rel no auto-continue-default"
  }
}

# No CJK in SSOT docs (Unicode escapes in regex OK; ban actual Han characters)
$cjkFiles = @()
foreach ($f in (Get-ChildItem -Recurse -File (Join-Path $Root "skills\od"))) {
  $bytes = [IO.File]::ReadAllBytes($f.FullName)
  $text = [Text.Encoding]::UTF8.GetString($bytes)
  if ($text -match '[\u4e00-\u9fff]') { $cjkFiles += $f.FullName.Substring($Root.Length + 1) }
}
foreach ($f in (Get-ChildItem -Recurse -File (Join-Path $Root "rules"))) {
  $text = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($f.FullName))
  if ($text -match '[\u4e00-\u9fff]') { $cjkFiles += $f.FullName.Substring($Root.Length + 1) }
}
if ($cjkFiles.Count -gt 0) {
  Fail ("CJK characters found in: " + ($cjkFiles -join ", "))
} else {
  Ok "No CJK in skills/od or rules"
}

if ($Failed -gt 0) {
  Write-Host ""
  Write-Host "$Failed check(s) failed. Run: powershell -File scripts/sync-skills.ps1" -ForegroundColor Red
  exit 1
}
Write-Host ""
Write-Host "All compliance checks passed." -ForegroundColor Green
exit 0
