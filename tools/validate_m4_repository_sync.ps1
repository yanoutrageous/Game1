param(
    [string]$RepoRoot = (Get-Location).Path,
    [string]$ArtBranch = "godot/art15-art17-visual-ui-cleanup",
    [string]$GodotExe = "D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe",
    [switch]$RunGodot
)

$ErrorActionPreference = "Stop"
$failures = New-Object System.Collections.Generic.List[string]
$notes = New-Object System.Collections.Generic.List[string]

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

function Add-Failure([string]$Message) {
    $script:failures.Add($Message) | Out-Null
}

$resolvedRoot = & git -C $RepoRoot rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($resolvedRoot)) {
    Write-Host "M4_REPOSITORY_SYNC_VALIDATION=FAIL"
    Write-Host "FAIL: not inside a git worktree: $RepoRoot"
    exit 1
}
$script:GitRoot = ($resolvedRoot -replace '\\','/').Trim()

Write-Host "M4 repository sync validation"
Write-Host "git_root=$script:GitRoot"

$branch = (Invoke-Git -GitArgs @("branch","--show-current")).Output.Trim()
$head = (Invoke-Git -GitArgs @("rev-parse","HEAD")).Output.Trim()
$main = (Invoke-Git -GitArgs @("rev-parse","main")).Output.Trim()
$originMain = (Invoke-Git -GitArgs @("rev-parse","origin/main")).Output.Trim()
Write-Host "branch=$branch"
Write-Host "HEAD=$head"
Write-Host "main=$main"
Write-Host "origin/main=$originMain"

$trackedDirty = (Invoke-Git -GitArgs @("diff","--name-only")).Output -split "`r?`n" | Where-Object { $_ -ne "" }
$staged = (Invoke-Git -GitArgs @("diff","--cached","--name-only")).Output -split "`r?`n" | Where-Object { $_ -ne "" }
$untracked = (Invoke-Git -GitArgs @("ls-files","--others","--exclude-standard")).Output -split "`r?`n" | Where-Object { $_ -ne "" }

if ($trackedDirty.Count -gt 0 -or $staged.Count -gt 0 -or $untracked.Count -gt 0) {
    $notes.Add("dirty detected: tracked=$($trackedDirty.Count), staged=$($staged.Count), untracked=$($untracked.Count)") | Out-Null
}

$forbiddenStaged = $staged | Where-Object {
    $_ -match '^Godot/GraytailGodot/project\.godot$' -or
    $_ -match '\.(uid|translation|import)$' -or
    $_ -match '/\.godot/' -or
    $_ -match '^Godot/GraytailGodot/\.godot/'
}
if ($forbiddenStaged.Count -gt 0) {
    Add-Failure "forbidden metadata staged: $($forbiddenStaged -join ', ')"
}

$trackedGodotCache = (Invoke-Git -GitArgs @("ls-files")).Output -split "`r?`n" | Where-Object {
    $_ -match '(^|/)\.godot(/|$)' -or $_ -match '(^|/)\.import(/|$)' -or $_ -match '\.import$'
}
if ($trackedGodotCache.Count -gt 0) {
    Add-Failure "generated Godot cache/import files are tracked: $($trackedGodotCache -join ', ')"
}

$artExists = Invoke-Git -GitArgs @("rev-parse","--verify",$ArtBranch) -AllowFailure
if ($artExists.Code -ne 0) {
    Add-Failure "ART branch not found: $ArtBranch"
} else {
    $artHash = (Invoke-Git -GitArgs @("rev-parse",$ArtBranch)).Output.Trim()
    $leftRight = (Invoke-Git -GitArgs @("rev-list","--left-right","--count","main...$ArtBranch")).Output.Trim()
    Write-Host "art_branch=$ArtBranch"
    Write-Host "art_hash=$artHash"
    Write-Host "main...art=$leftRight"

    $metadataInArt = (Invoke-Git -GitArgs @("diff","--name-only","main..$ArtBranch")).Output -split "`r?`n" | Where-Object {
        $_ -match '^Godot/GraytailGodot/project\.godot$' -or
        $_ -match '\.(uid|translation|import|tscn|tres|res)$' -or
        $_ -match '(^|/)\.godot(/|$)'
    }
    if ($metadataInArt.Count -gt 0) {
        Add-Failure "ART branch contains forbidden metadata/resource paths: $($metadataInArt -join ', ')"
    }

    $diffCheck = Invoke-Git -GitArgs @("diff","--check","main..$ArtBranch") -AllowFailure
    if ($diffCheck.Code -ne 0) {
        Add-Failure "ART branch diff-check failed: $($diffCheck.Output)"
    } else {
        Write-Host "art_diff_check=PASS"
    }
}

if ($RunGodot) {
    if (-not (Test-Path -LiteralPath $GodotExe)) {
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
            Add-Failure "Godot project-load failed with exit code $loadCode"
        }
        $notes.Add("Godot validation is project-load/parser only; no gameplay runtime PASS or manual playtest PASS declared.") | Out-Null
    }
} else {
    $notes.Add("Godot two-step validation not run by this invocation; use -RunGodot to execute editor/import then project-load.") | Out-Null
}

foreach ($note in $notes) {
    Write-Host "NOTE: $note"
}

if ($failures.Count -gt 0) {
    Write-Host "M4_REPOSITORY_SYNC_VALIDATION=FAIL"
    foreach ($failure in $failures) {
        Write-Host "FAIL: $failure"
    }
    exit 1
}

Write-Host "M4_REPOSITORY_SYNC_VALIDATION=PASS"
Write-Host "No gameplay runtime PASS or manual playtest PASS is declared."
