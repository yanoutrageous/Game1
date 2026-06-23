$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$scriptsRoot = Join-Path $repoRoot 'scripts'

if (-not (Test-Path -LiteralPath $scriptsRoot -PathType Container)) {
    Write-Output 'LUA_REQUIRE_GRAPH_VALIDATION=FAIL'
    Write-Output "MISSING_SCRIPTS_ROOT=$scriptsRoot"
    exit 1
}

$luaFiles = Get-ChildItem -LiteralPath $scriptsRoot -Recurse -Filter '*.lua' -File |
    Sort-Object FullName

$requirePattern = 'require\s*\(\s*["'']([^"'']+)["'']\s*\)'
$missingProjectModules = New-Object System.Collections.Generic.List[string]
$projectRequires = New-Object System.Collections.Generic.List[string]
$externalRequires = New-Object System.Collections.Generic.List[string]
$requireCount = 0

foreach ($file in $luaFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    $matches = [regex]::Matches($text, $requirePattern)
    $relativePath = $file.FullName.Substring($repoRoot.Length).TrimStart('\', '/') -replace '\\', '/'

    foreach ($match in $matches) {
        $requireCount += 1
        $moduleName = $match.Groups[1].Value

        if ($moduleName.Contains('/')) {
            [void]$externalRequires.Add(("{0}`t{1}" -f $moduleName, $relativePath))
            continue
        }

        $parts = $moduleName -split '\.'
        $candidateRelative = [System.IO.Path]::Combine([string[]]$parts) + '.lua'
        $candidatePath = Join-Path $scriptsRoot $candidateRelative

        if (Test-Path -LiteralPath $candidatePath -PathType Leaf) {
            [void]$projectRequires.Add($moduleName)
            continue
        }

        $singleNameCandidate = Join-Path $scriptsRoot ($moduleName + '.lua')
        if (Test-Path -LiteralPath $singleNameCandidate -PathType Leaf) {
            [void]$projectRequires.Add($moduleName)
            continue
        }

        [void]$missingProjectModules.Add(("{0} -> {1} referenced by {2}" -f $moduleName, $candidatePath, $file.FullName))
    }
}

if ($missingProjectModules.Count -gt 0) {
    Write-Output 'LUA_REQUIRE_GRAPH_VALIDATION=FAIL'
    Write-Output "REPO_ROOT=$repoRoot"
    Write-Output "SCRIPTS_ROOT=$scriptsRoot"
    Write-Output "CHECKED_FILES=$($luaFiles.Count)"
    Write-Output "REQUIRE_COUNT=$requireCount"
    Write-Output "PROJECT_REQUIRE_COUNT=$($projectRequires.Count)"
    Write-Output "EXTERNAL_REQUIRE_COUNT=$($externalRequires.Count)"
    foreach ($external in ($externalRequires | Sort-Object)) {
        $parts = $external -split "`t", 2
        Write-Output ("EXTERNAL_REQUIRE={0} referenced by {1}" -f $parts[0], $parts[1])
    }
    Write-Output "MISSING_PROJECT_MODULES=$($missingProjectModules.Count)"
    foreach ($missing in $missingProjectModules) {
        Write-Output "MISSING=$missing"
    }
    exit 1
}

Write-Output 'LUA_REQUIRE_GRAPH_VALIDATION=PASS'
Write-Output "REPO_ROOT=$repoRoot"
Write-Output "SCRIPTS_ROOT=$scriptsRoot"
Write-Output "CHECKED_FILES=$($luaFiles.Count)"
Write-Output "REQUIRE_COUNT=$requireCount"
Write-Output "PROJECT_REQUIRE_COUNT=$($projectRequires.Count)"
Write-Output "EXTERNAL_REQUIRE_COUNT=$($externalRequires.Count)"
foreach ($external in ($externalRequires | Sort-Object)) {
    $parts = $external -split "`t", 2
    Write-Output ("EXTERNAL_REQUIRE={0} referenced by {1}" -f $parts[0], $parts[1])
}
exit 0
