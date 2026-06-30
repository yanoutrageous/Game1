param(
    [string]$RepoRoot = (Get-Location).Path,
    [string]$ExpectedMainHash = "786c898388896eb6654e3a3a96fe4aef5cdb32fe",
    [string]$GodotExe = "D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe",
    [switch]$RunGodot
)

$ErrorActionPreference = "Stop"
$failures = New-Object System.Collections.Generic.List[string]
$notes = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$Message) {
    $script:failures.Add($Message) | Out-Null
}

function Add-Note([string]$Message) {
    $script:notes.Add($Message) | Out-Null
}

function Invoke-Git([string[]]$GitArgs, [switch]$AllowFailure) {
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & git -C $script:GitRoot @GitArgs 2>&1
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldPreference
    }
    if ($code -ne 0 -and -not $AllowFailure) {
        throw "git $($GitArgs -join ' ') failed: $output"
    }
    return [pscustomobject]@{ Code = $code; Output = ($output -join "`n") }
}

$resolvedRoot = & git -C $RepoRoot rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($resolvedRoot)) {
    Write-Host "M4S_METADATA_BRANCH_CLEAN_CHECKOUT=FAIL"
    Write-Host "FAIL: not inside a git worktree: $RepoRoot"
    exit 1
}

$script:GitRoot = (Resolve-Path -LiteralPath $resolvedRoot.Trim()).Path
Write-Host "M4S metadata / branch / clean checkout validation"
Write-Host "git_root=$script:GitRoot"

$branch = (Invoke-Git -GitArgs @("branch", "--show-current")).Output.Trim()
$head = (Invoke-Git -GitArgs @("rev-parse", "HEAD")).Output.Trim()
$main = (Invoke-Git -GitArgs @("rev-parse", "main")).Output.Trim()
$originMain = (Invoke-Git -GitArgs @("rev-parse", "origin/main")).Output.Trim()

Write-Host "branch=$branch"
Write-Host "HEAD=$head"
Write-Host "main=$main"
Write-Host "origin/main=$originMain"

if ($branch -eq "main") {
    Add-Failure "M4S validation must not run as a direct main working branch."
}
if ($main -ne $originMain) {
    Add-Failure "main and origin/main differ: main=$main origin/main=$originMain"
}
if ($ExpectedMainHash -and $main -ne $ExpectedMainHash) {
    Add-Failure "main hash does not match expected M4 baseline: expected=$ExpectedMainHash actual=$main"
}

$requiredFiles = @(
    ".gitignore",
    ".gitattributes",
    "docs/00_governance/M4_REPOSITORY_SYNC_METADATA_POLICY.md",
    "docs/00_governance/BRANCH_GOVERNANCE_LEDGER.md",
    "docs/10_current/CURRENT_STATE.md",
    "docs/INDEX.md"
)
foreach ($path in $requiredFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $script:GitRoot $path) -PathType Leaf)) {
        Add-Failure "Missing required M4S file: $path"
    }
}

$ignoreProbePaths = @(
    "Godot/GraytailGodot/data/assets/asset_manifest.m4s_probe.translation",
    "Godot/GraytailGodot/scripts/m4s_probe.gd.uid",
    "Godot/GraytailGodot/.godot/m4s_probe.cache"
)
foreach ($probe in $ignoreProbePaths) {
    $ignored = Invoke-Git -GitArgs @("check-ignore", "-q", $probe) -AllowFailure
    if ($ignored.Code -ne 0) {
        Add-Failure "Generated metadata path is not ignored: $probe"
    }
}

$staged = (Invoke-Git -GitArgs @("diff", "--cached", "--name-only")).Output -split "`r?`n" | Where-Object { $_ -ne "" }
$forbiddenStaged = $staged | Where-Object {
    $_ -match '^Godot/GraytailGodot/project\.godot$' -or
    $_ -match '\.gd\.uid$' -or
    $_ -match '\.translation$' -or
    $_ -match '\.import$' -or
    $_ -match '(^|/)\.godot(/|$)' -or
    $_ -match '^D:/AGAME1/Base Docs' -or
    $_ -match '^D:/AGAME1/Connection' -or
    $_ -match '^D:/AGAME1/Base Art'
}
if ($forbiddenStaged.Count -gt 0) {
    Add-Failure "Forbidden generated/external paths are staged: $($forbiddenStaged -join ', ')"
}

$ledgerPath = Join-Path $script:GitRoot "docs/00_governance/BRANCH_GOVERNANCE_LEDGER.md"
if (Test-Path -LiteralPath $ledgerPath) {
    $ledgerText = Get-Content -LiteralPath $ledgerPath -Raw -Encoding UTF8
    if ($ledgerText -notmatch "M4S" -or $ledgerText -notmatch "godot/m4s-metadata-branch-clean-checkout-finalization") {
        Add-Failure "Branch governance ledger does not record M4S finalization branch."
    }
}

$policyPath = Join-Path $script:GitRoot "docs/00_governance/M4_REPOSITORY_SYNC_METADATA_POLICY.md"
if (Test-Path -LiteralPath $policyPath) {
    $policyText = Get-Content -LiteralPath $policyPath -Raw -Encoding UTF8
    if ($policyText -notmatch "project.godot" -or $policyText -notmatch "\.gd\.uid" -or $policyText -notmatch "\.translation") {
        Add-Failure "Metadata policy does not cover project.godot / .gd.uid / .translation."
    }
}

if ($RunGodot) {
    if (-not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) {
        Add-Failure "Godot executable missing: $GodotExe"
    } else {
        $projectPath = Join-Path $script:GitRoot "Godot/GraytailGodot"
        Write-Host "godot_editor_import=RUN"
        & $GodotExe --headless --editor --path $projectPath --quit
        $editorCode = $LASTEXITCODE
        if ($editorCode -ne 0) {
            Add-Failure "Godot editor/import failed with exit code $editorCode"
        }
        Write-Host "godot_project_load=RUN"
        & $GodotExe --headless --path $projectPath --quit
        $loadCode = $LASTEXITCODE
        if ($loadCode -ne 0) {
            Add-Failure "Godot project-load/parser failed with exit code $loadCode"
        }
        Add-Note "Godot validation is project-load/parser only; no gameplay runtime PASS or manual playtest PASS declared."
    }
} else {
    Add-Note "Godot smoke NOT RUN by this validator invocation; pass -RunGodot to execute editor/import and project-load."
}

foreach ($note in $notes) {
    Write-Host "NOTE: $note"
}

if ($failures.Count -gt 0) {
    Write-Host "M4S_METADATA_BRANCH_CLEAN_CHECKOUT=FAIL"
    foreach ($failure in $failures) {
        Write-Host "FAIL: $failure"
    }
    exit 1
}

Write-Host "M4S_METADATA_BRANCH_CLEAN_CHECKOUT=PASS"
Write-Host "No gameplay runtime PASS or manual playtest PASS is declared."
exit 0
