$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
$RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot '..\..')).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
$Failures = @()
$CurrentMainHead = 'eb9f5d6a9df18bd019b424b1fca3000e56e20f3b'

function Add-Failure {
    param([string]$Message)
    $script:Failures += $Message
}

function Resolve-RepoPath {
    param([string]$RelativePath)
    $FullPath = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $RelativePath))
    if (-not ($FullPath -eq $RepoRoot -or $FullPath.StartsWith($RepoRoot + [System.IO.Path]::DirectorySeparatorChar))) {
        Add-Failure "outside repo: $RelativePath"
    }
    return $FullPath
}

function Read-RepoText {
    param([string]$RelativePath)
    $FullPath = Resolve-RepoPath $RelativePath
    if (-not [System.IO.File]::Exists($FullPath)) {
        Add-Failure "missing: $RelativePath"
        return ''
    }
    return [System.IO.File]::ReadAllText($FullPath)
}

function Test-RepoFileContains {
    param(
        [string]$RelativePath,
        [string[]]$Patterns
    )
    $Text = Read-RepoText $RelativePath
    foreach ($Pattern in $Patterns) {
        if ($Text -notmatch [regex]::Escape($Pattern)) {
            Add-Failure "missing pattern in ${RelativePath}: $Pattern"
        }
    }
}

$RequiredFiles = @(
    'docs/PROJECT_BASELINE.md',
    'docs/MILESTONES.md',
    'docs/DOCS_INDEX.md',
    'docs/NEXT_HANDOFF.md',
    'docs/handoff/HANDOFF_TEMPLATE.md'
)

foreach ($RelativePath in $RequiredFiles) {
    $FullPath = Resolve-RepoPath $RelativePath
    if (-not [System.IO.File]::Exists($FullPath)) {
        Add-Failure "required baseline doc missing: $RelativePath"
    }
}

Test-RepoFileContains 'docs/PROJECT_BASELINE.md' @(
    $CurrentMainHead,
    'G9 UI core flow baseline',
    'G10 Boundary',
    'Safety Boundary Summary',
    'Dirty handling whitelist',
    'does not represent a complete final UI',
    'does not represent complete MetaProgress',
    'does not represent complete Deploy persistence',
    'does not represent complete long-term system completion'
)

Test-RepoFileContains 'docs/NEXT_HANDOFF.md' @(
    $CurrentMainHead,
    'minimum next-chat entry',
    'G9 UI core flow baseline',
    'G10 Boundary',
    'Dirty whitelist only',
    'Do not modify `lua-prototype-main`'
)

Test-RepoFileContains 'docs/DOCS_INDEX.md' @(
    'document navigation and historical index',
    'current engineering fact source',
    'Next Conversation Minimum Reading',
    'historical references',
    'G10 is not started here'
)

Test-RepoFileContains 'docs/MILESTONES.md' @(
    'G5',
    'Asset UI Presentation Baseline',
    'G6',
    'Playable Lua Parity Core',
    'G7',
    'Playable Flow Baseline',
    'G8',
    'Asset Ledger & Settlement Core',
    'G8.1',
    'Architecture Hardening',
    'G8.2',
    'Kernel Protocol Baseline',
    'G8.2 hotfix',
    'Runtime Parse Hotfix',
    'G9 Presentation',
    'UI Presentation Layering Contracts',
    'G9 Final',
    'UI Core Flow Baseline'
)

Test-RepoFileContains 'docs/handoff/HANDOFF_TEMPLATE.md' @(
    'Stage Identity',
    'Current Fact Source',
    'Completed',
    'Explicitly Not Done',
    'Validation Results',
    'Risks And Debt',
    'Next Handoff Guide',
    'Safety Boundaries',
    'Read-Only Audit',
    'Planning',
    'Direct Execution',
    'Mainline Promotion',
    'BUG Fix',
    'Runtime Smoke'
)

Test-RepoFileContains 'docs/ENGINEERING_STATUS.md' @(
    'Pre-G10 Project Baseline Consolidation',
    $CurrentMainHead,
    'PROJECT_BASELINE.md',
    'NEXT_HANDOFF.md',
    'DOCS_INDEX.md',
    'not a complete final UI'
)

Test-RepoFileContains 'Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md' @(
    'Pre-G10 Project Baseline Consolidation',
    $CurrentMainHead,
    'PROJECT_BASELINE.md',
    'NEXT_HANDOFF.md',
    'not a complete final UI'
)

Test-RepoFileContains 'Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md' @(
    'G9 UI core flow baseline',
    'historical',
    'InventoryPanel',
    'GroundLootPanel'
)

Test-RepoFileContains 'docs/REPO_POLICY.md' @(
    'PROJECT_BASELINE.md',
    'NEXT_HANDOFF.md',
    'DOCS_INDEX.md',
    'HANDOFF_TEMPLATE.md'
)

$ForbiddenFiles = @(
    'docs/PROJECT_BASELINE.md',
    'docs/NEXT_HANDOFF.md',
    'docs/DOCS_INDEX.md',
    'docs/ENGINEERING_STATUS.md',
    'Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md'
)

foreach ($RelativePath in $ForbiddenFiles) {
    $Text = Read-RepoText $RelativePath
    if ($Text -match 'G10 implementation started|G10 has started|G10 work has begun|G10 development started') {
        Add-Failure "doc incorrectly claims G10 implementation has started: $RelativePath"
    }
}

$LuaPrototypeStatus = @(git -C $RepoRoot status --short -- lua-prototype-main)
if ($LuaPrototypeStatus.Count -gt 0) {
    Add-Failure 'lua-prototype-main has local modifications'
}

if ($Failures.Count -gt 0) {
    Write-Output 'PROJECT_BASELINE_DOCS_PRE_G10_VALIDATION=FAIL'
    foreach ($Failure in $Failures) {
        Write-Output $Failure
    }
    exit 1
}

Write-Output 'PROJECT_BASELINE_DOCS_PRE_G10_VALIDATION=PASS'
Write-Output "PROJECT_ROOT=$ProjectRoot"
Write-Output 'BASELINE_DOCS=PASS'
Write-Output 'MILESTONE_MAPPING=PASS'
Write-Output 'NEXT_HANDOFF_MINIMAL_ENTRY=PASS'
Write-Output 'HANDOFF_TEMPLATE=PASS'
Write-Output 'G10_BOUNDARY=PASS'
Write-Output 'NO_LUA_PROTOTYPE_MODIFICATION=PASS'
