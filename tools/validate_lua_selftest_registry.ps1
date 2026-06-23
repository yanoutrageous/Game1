$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$testFile = Join-Path $repoRoot 'scripts\tests\minefield_selftest.lua'

if (-not (Test-Path -LiteralPath $testFile -PathType Leaf)) {
    Write-Output 'LUA_SELFTEST_REGISTRY_VALIDATION=FAIL'
    Write-Output "MISSING_TEST_FILE=$testFile"
    exit 1
}

$text = Get-Content -LiteralPath $testFile -Raw
$definedMatches = [regex]::Matches($text, '(?m)^\s*local\s+function\s+(test[A-Za-z0-9_]+)\s*\(')
$registeredMatches = [regex]::Matches($text, 'fn\s*=\s*(test[A-Za-z0-9_]+)')

$defined = @()
foreach ($match in $definedMatches) {
    $defined += $match.Groups[1].Value
}

$registered = @()
foreach ($match in $registeredMatches) {
    $registered += $match.Groups[1].Value
}

$definedSet = @{}
foreach ($name in $defined) {
    $definedSet[$name] = $true
}

$registeredSet = @{}
foreach ($name in $registered) {
    $registeredSet[$name] = $true
}

$missingRegistrations = @()
foreach ($name in $defined) {
    if (-not $registeredSet.ContainsKey($name)) {
        $missingRegistrations += $name
    }
}

$unknownRegistrations = @()
foreach ($name in $registered) {
    if (-not $definedSet.ContainsKey($name)) {
        $unknownRegistrations += $name
    }
}

$duplicateRegistrations = @()
$registrationGroups = $registered | Group-Object
foreach ($group in $registrationGroups) {
    if ($group.Count -gt 1) {
        $duplicateRegistrations += ("{0} x{1}" -f $group.Name, $group.Count)
    }
}

if (($defined.Count -eq 0) -or ($registered.Count -eq 0) -or ($missingRegistrations.Count -gt 0) -or ($unknownRegistrations.Count -gt 0) -or ($duplicateRegistrations.Count -gt 0)) {
    Write-Output 'LUA_SELFTEST_REGISTRY_VALIDATION=FAIL'
    Write-Output "REPO_ROOT=$repoRoot"
    Write-Output "TEST_FILE=$testFile"
    Write-Output "DEFINED_TESTS=$($defined.Count)"
    Write-Output "REGISTERED_TESTS=$($registered.Count)"
    Write-Output "MISSING_REGISTRATIONS=$($missingRegistrations.Count)"
    foreach ($name in $missingRegistrations) {
        Write-Output "MISSING_REGISTRATION=$name"
    }
    Write-Output "UNKNOWN_REGISTRATIONS=$($unknownRegistrations.Count)"
    foreach ($name in $unknownRegistrations) {
        Write-Output "UNKNOWN_REGISTRATION=$name"
    }
    Write-Output "DUPLICATE_REGISTRATIONS=$($duplicateRegistrations.Count)"
    foreach ($name in $duplicateRegistrations) {
        Write-Output "DUPLICATE_REGISTRATION=$name"
    }
    exit 1
}

Write-Output 'LUA_SELFTEST_REGISTRY_VALIDATION=PASS'
Write-Output "REPO_ROOT=$repoRoot"
Write-Output "TEST_FILE=$testFile"
Write-Output "DEFINED_TESTS=$($defined.Count)"
Write-Output "REGISTERED_TESTS=$($registered.Count)"
exit 0
