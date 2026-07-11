param(
    [string]$RepoRoot = ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))),

    [string]$ManifestPath = (Join-Path $PSScriptRoot "validation_manifest.json"),

    [ValidateSet("baseline", "remediated")]
    [string]$Profile = "baseline",

    [string]$ReportPath = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot "i0_test_lib.ps1")


function Read-I0Utf8Text {
    param([Parameter(Mandatory = $true)][string]$Path)
    $encoding = New-Object System.Text.UTF8Encoding($false, $true)
    return [System.IO.File]::ReadAllText($Path, $encoding)
}


function Read-I0CsvDocument {
    param([Parameter(Mandatory = $true)][string]$Path)

    $text = Read-I0Utf8Text -Path $Path
    $rows = New-Object System.Collections.Generic.List[object]
    $errors = New-Object System.Collections.Generic.List[string]
    $currentRow = New-Object System.Collections.Generic.List[string]
    $field = New-Object System.Text.StringBuilder
    $inQuotes = $false
    $afterQuote = $false
    $lineNumber = 1
    $rowStartLine = 1
    $lastWasRowTerminator = $false
    $index = 0

    while ($index -lt $text.Length) {
        $character = $text[$index]
        if ($inQuotes) {
            if ($character -eq [char]34) {
                if ($index + 1 -lt $text.Length -and $text[$index + 1] -eq [char]34) {
                    [void]$field.Append([char]34)
                    $index += 2
                    $lastWasRowTerminator = $false
                    continue
                }
                $inQuotes = $false
                $afterQuote = $true
                $index += 1
                continue
            }
            if ($character -eq [char]13) {
                [void]$field.Append([char]13)
                if ($index + 1 -lt $text.Length -and $text[$index + 1] -eq [char]10) {
                    [void]$field.Append([char]10)
                    $index += 1
                }
                $lineNumber += 1
                $index += 1
                continue
            }
            if ($character -eq [char]10) {
                [void]$field.Append([char]10)
                $lineNumber += 1
                $index += 1
                continue
            }
            [void]$field.Append($character)
            $index += 1
            continue
        }

        if ($afterQuote -and $character -notin @([char]44, [char]13, [char]10)) {
            [void]$errors.Add("line $lineNumber contains a character after a closing quote")
            $afterQuote = $false
        }
        if ($character -eq [char]34) {
            if ($field.Length -ne 0) {
                [void]$errors.Add("line $lineNumber contains a quote inside an unquoted field")
                [void]$field.Append($character)
            }
            else {
                $inQuotes = $true
            }
            $lastWasRowTerminator = $false
            $index += 1
            continue
        }
        if ($character -eq [char]44) {
            [void]$currentRow.Add($field.ToString())
            [void]$field.Clear()
            $afterQuote = $false
            $lastWasRowTerminator = $false
            $index += 1
            continue
        }
        if ($character -eq [char]13 -or $character -eq [char]10) {
            [void]$currentRow.Add($field.ToString())
            [void]$field.Clear()
            $rowValues = [string[]]$currentRow.ToArray()
            [void]$rows.Add([pscustomobject][ordered]@{
                line_number = $rowStartLine
                fields = $rowValues
            })
            $currentRow = New-Object System.Collections.Generic.List[string]
            $afterQuote = $false
            if ($character -eq [char]13 -and $index + 1 -lt $text.Length -and $text[$index + 1] -eq [char]10) {
                $index += 1
            }
            $lineNumber += 1
            $rowStartLine = $lineNumber
            $lastWasRowTerminator = $true
            $index += 1
            continue
        }
        [void]$field.Append($character)
        $afterQuote = $false
        $lastWasRowTerminator = $false
        $index += 1
    }

    if ($inQuotes) {
        [void]$errors.Add("CSV ended inside a quoted field that began on or before line $rowStartLine")
    }
    if ($text.Length -gt 0 -and -not $lastWasRowTerminator) {
        [void]$currentRow.Add($field.ToString())
        $rowValues = [string[]]$currentRow.ToArray()
        [void]$rows.Add([pscustomobject][ordered]@{
            line_number = $rowStartLine
            fields = $rowValues
        })
    }
    return [pscustomobject][ordered]@{
        rows = $rows.ToArray()
        errors = $errors.ToArray()
    }
}


function Get-I0GdFunctionBlock {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$FunctionName
    )
    $pattern = '(?ms)^func\s+' + [regex]::Escape($FunctionName) + '\b.*?(?=^func\s+|\z)'
    $match = [regex]::Match($Text, $pattern)
    if ($match.Success) {
        return $match.Value
    }
    return ""
}


function New-I0StaticCheck {
    param(
        [Parameter(Mandatory = $true)][string]$Code,
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][AllowNull()][object[]]$ExpectedRedCodes,
        $Details = $null
    )
    $isExpectedRed = @($ExpectedRedCodes) -contains $Code
    $status = if ($Condition) {
        if ($isExpectedRed) { "UNEXPECTED_GREEN" } else { "PASS" }
    }
    else {
        if ($isExpectedRed) { "EXPECTED_RED" } else { "FAIL" }
    }
    return [pscustomobject][ordered]@{
        code = $Code
        status = $status
        condition_satisfied = $Condition
        expected_red = $isExpectedRed
        details = $Details
    }
}


$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$profileProperty = $manifest.profiles.PSObject.Properties[$Profile]
if ($null -eq $profileProperty) {
    throw "Validation profile is missing from manifest: $Profile"
}
$expectedRedCodes = @($profileProperty.Value.expected_red_codes | ForEach-Object { [string]$_ })
$repo = Get-I0CanonicalPath -Path $RepoRoot
Assert-I0PathWithin -Path $repo -Root ([string]$manifest.workspace_root) -Label "static validation repo"

$checks = New-Object System.Collections.Generic.List[object]
$requiredRelativePaths = @(
    [string]$manifest.static_contract.save_adapter_relative_path,
    [string]$manifest.static_contract.asset_catalog_relative_path,
    [string]$manifest.static_contract.asset_manifest_relative_path,
    [string]$manifest.static_contract.project_settings_relative_path,
    [string]$manifest.static_contract.run_scene_relative_path,
    [string]$manifest.godot.environment_probe_relative_path
) + @($manifest.runners | ForEach-Object { [string]$_.relative_path })
$missingPaths = @($requiredRelativePaths | Where-Object { -not (Test-Path -LiteralPath (Join-Path $repo ($_.Replace('/', '\'))) -PathType Leaf) })
[void]$checks.Add((New-I0StaticCheck -Code "STATIC_REQUIRED_PATHS" -Condition ($missingPaths.Count -eq 0) -ExpectedRedCodes $expectedRedCodes -Details ([pscustomobject]@{ missing = $missingPaths })))

$projectPath = Join-Path $repo (([string]$manifest.static_contract.project_settings_relative_path).Replace('/', '\'))
$projectText = Read-I0Utf8Text -Path $projectPath
$missingProjectMarkers = @($manifest.static_contract.required_project_markers | Where-Object { $projectText.IndexOf([string]$_, [System.StringComparison]::Ordinal) -lt 0 })
[void]$checks.Add((New-I0StaticCheck -Code "STATIC_PROJECT_DECLARATION" -Condition ($missingProjectMarkers.Count -eq 0) -ExpectedRedCodes $expectedRedCodes -Details ([pscustomobject]@{ missing_markers = $missingProjectMarkers })))

$runnerDirectory = Join-Path $repo 'tools'
$actualRunnerPaths = @(Get-ChildItem -LiteralPath $runnerDirectory -File -Filter 'godot_*_runner.gd' | ForEach-Object { Get-I0RelativePath -Path $_.FullName -Root $repo } | Sort-Object)
$manifestRunnerPaths = @($manifest.runners | ForEach-Object { [string]$_.relative_path } | Sort-Object -Unique)
$runnerPathDifference = @(Compare-Object -ReferenceObject $manifestRunnerPaths -DifferenceObject $actualRunnerPaths)
$runnerMarkerFailures = New-Object System.Collections.Generic.List[string]
foreach ($runner in $manifest.runners) {
    $runnerPath = Join-Path $repo (([string]$runner.relative_path).Replace('/', '\'))
    if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf)) {
        continue
    }
    $runnerText = Read-I0Utf8Text -Path $runnerPath
    if ($runnerText.IndexOf([string]$runner.pass_marker, [System.StringComparison]::Ordinal) -lt 0) {
        [void]$runnerMarkerFailures.Add("$($runner.id):missing pass marker")
    }
    if ($runnerText.IndexOf([string]$runner.fail_marker, [System.StringComparison]::Ordinal) -lt 0) {
        [void]$runnerMarkerFailures.Add("$($runner.id):missing fail marker")
    }
}
$runnerIds = @($manifest.runners | ForEach-Object { [string]$_.id })
$runnerIdsUnique = @($runnerIds | Sort-Object -Unique)
$expectedRunnerCaseCount = [int]$manifest.static_contract.expected_runner_case_count
$runnerInventoryOk = ($expectedRunnerCaseCount -gt 0 -and $manifest.runners.Count -eq $expectedRunnerCaseCount -and $runnerIds.Count -eq $runnerIdsUnique.Count -and $runnerPathDifference.Count -eq 0 -and $runnerMarkerFailures.Count -eq 0)
[void]$checks.Add((New-I0StaticCheck -Code "STATIC_RUNNER_INVENTORY" -Condition $runnerInventoryOk -ExpectedRedCodes $expectedRedCodes -Details ([pscustomobject]@{
    expected_count = $expectedRunnerCaseCount
    manifest_count = $manifest.runners.Count
    path_difference = $runnerPathDifference
    marker_failures = $runnerMarkerFailures.ToArray()
})))

$g37 = @($manifest.runners | Where-Object { [string]$_.id -eq 'G37_COMMAND_SEQUENCE' })
$g39 = @($manifest.runners | Where-Object { [string]$_.id -eq 'G39_NAVIGATION_BOUNDARY' })
$mappingOk = ($g37.Count -eq 1 -and @($g37[0].coverage) -contains 'command' -and $g39.Count -eq 1 -and @($g39[0].coverage) -contains 'ui')
[void]$checks.Add((New-I0StaticCheck -Code "STATIC_CMD_UI_RUNNER_MAPPING" -Condition $mappingOk -ExpectedRedCodes $expectedRedCodes -Details ([pscustomobject]@{
    command_runner = if ($g37.Count -eq 1) { [string]$g37[0].relative_path } else { '(missing)' }
    ui_runner = if ($g39.Count -eq 1) { [string]$g39[0].relative_path } else { '(missing)' }
})))

$saveAdapterPath = Join-Path $repo (([string]$manifest.static_contract.save_adapter_relative_path).Replace('/', '\'))
$saveAdapterText = Read-I0Utf8Text -Path $saveAdapterPath
$defaultProgressBlock = Get-I0GdFunctionBlock -Text $saveAdapterText -FunctionName 'default_meta_progress'
$normalizeProgressBlock = Get-I0GdFunctionBlock -Text $saveAdapterText -FunctionName '_normalize_meta_progress'
$saveHasDefault = $defaultProgressBlock -match '["'']abandon_count["'']\s*:'
$saveHasNormalization = $normalizeProgressBlock -match 'result\s*\[\s*["'']abandon_count["'']\s*\]\s*='
[void]$checks.Add((New-I0StaticCheck -Code "SAVE_ABANDON_COUNT" -Condition ($saveHasDefault -and $saveHasNormalization) -ExpectedRedCodes $expectedRedCodes -Details ([pscustomobject]@{
    default_contains_abandon_count = $saveHasDefault
    normalization_preserves_abandon_count = $saveHasNormalization
})))

$assetManifestPath = Join-Path $repo (([string]$manifest.static_contract.asset_manifest_relative_path).Replace('/', '\'))
$csv = Read-I0CsvDocument -Path $assetManifestPath
[void]$checks.Add((New-I0StaticCheck -Code "STATIC_CSV_RFC4180_SYNTAX" -Condition ($csv.errors.Count -eq 0) -ExpectedRedCodes $expectedRedCodes -Details ([pscustomobject]@{ errors = @($csv.errors) })))
$nonBlankRows = @($csv.rows | Where-Object { @($_.fields).Count -gt 1 -or [string]$_.fields[0] -ne '' })
$header = if ($nonBlankRows.Count -gt 0) { @($nonBlankRows[0].fields) } else { @() }
$expectedHeader = @($manifest.static_contract.asset_manifest_expected_headers | ForEach-Object { [string]$_ })
$expectedWidth = $expectedHeader.Count
$expectedDataRowCount = [int]$manifest.static_contract.asset_manifest_expected_data_row_count
$actualDataRowCount = [Math]::Max(0, $nonBlankRows.Count - 1)
$headerExactMatch = (($header -join "`n") -ceq ($expectedHeader -join "`n"))
$widthViolations = New-Object System.Collections.Generic.List[object]
if ($header.Count -gt 0) {
    foreach ($row in @($nonBlankRows | Select-Object -Skip 1)) {
        $rowWidth = @($row.fields).Count
        if ($rowWidth -ne $expectedWidth) {
            [void]$widthViolations.Add([pscustomobject][ordered]@{
                line_number = $row.line_number
                expected_width = $expectedWidth
                actual_width = $rowWidth
            })
        }
    }
}
$assetCatalogPath = Join-Path $repo (([string]$manifest.static_contract.asset_catalog_relative_path).Replace('/', '\'))
$assetCatalogText = Read-I0Utf8Text -Path $assetCatalogPath
$catalogUsesCsvParser = ($assetCatalogText -match '\.get_csv_line\s*\(') -and ($assetCatalogText -notmatch '\.split\s*\(\s*["''],["'']')
$csvWidthOk = ($headerExactMatch -and $expectedWidth -eq 17 -and $expectedDataRowCount -eq 179 -and $actualDataRowCount -eq $expectedDataRowCount -and $widthViolations.Count -eq 0 -and $catalogUsesCsvParser)
[void]$checks.Add((New-I0StaticCheck -Code "CSV_ASSET_MANIFEST_WIDTH" -Condition $csvWidthOk -ExpectedRedCodes $expectedRedCodes -Details ([pscustomobject]@{
    header_width = $header.Count
    expected_width = $expectedWidth
    expected_width_is_17 = ($expectedWidth -eq 17)
    header_exact_match = $headerExactMatch
    expected_headers = $expectedHeader
    actual_headers = $header
    data_row_count = $actualDataRowCount
    expected_data_row_count = $expectedDataRowCount
    data_row_count_valid = ($expectedDataRowCount -eq 179 -and $actualDataRowCount -eq $expectedDataRowCount)
    data_width_valid = ($expectedWidth -eq 17 -and $widthViolations.Count -eq 0)
    parser_is_csv_aware = $catalogUsesCsvParser
    width_violations = $widthViolations.ToArray()
})))

$missingHeaders = @($manifest.static_contract.asset_manifest_required_headers | Where-Object { $header -notcontains [string]$_ })
[void]$checks.Add((New-I0StaticCheck -Code "STATIC_ASSET_MANIFEST_HEADERS" -Condition ($missingHeaders.Count -eq 0 -and $headerExactMatch -and $expectedWidth -eq 17) -ExpectedRedCodes $expectedRedCodes -Details ([pscustomobject]@{ missing_headers = $missingHeaders; exact_ordered_schema = $headerExactMatch; expected_width = $expectedWidth })))
$assetIdIndex = [Array]::IndexOf([object[]]$header, 'asset_id')
$emptyAssetIdLines = New-Object System.Collections.Generic.List[int]
$duplicateAssetIds = New-Object System.Collections.Generic.List[string]
$seenAssetIds = @{}
if ($assetIdIndex -ge 0) {
    foreach ($row in @($nonBlankRows | Select-Object -Skip 1)) {
        $fields = @($row.fields)
        $assetId = if ($assetIdIndex -lt $fields.Count) { [string]$fields[$assetIdIndex] } else { '' }
        if ([string]::IsNullOrWhiteSpace($assetId)) {
            [void]$emptyAssetIdLines.Add([int]$row.line_number)
        }
        elseif ($seenAssetIds.ContainsKey($assetId)) {
            [void]$duplicateAssetIds.Add($assetId)
        }
        else {
            $seenAssetIds[$assetId] = $true
        }
    }
}
$assetIdentityOk = ($assetIdIndex -ge 0 -and $expectedDataRowCount -eq 179 -and $actualDataRowCount -eq $expectedDataRowCount -and $emptyAssetIdLines.Count -eq 0 -and $duplicateAssetIds.Count -eq 0)
[void]$checks.Add((New-I0StaticCheck -Code "STATIC_ASSET_MANIFEST_IDENTITIES" -Condition $assetIdentityOk -ExpectedRedCodes $expectedRedCodes -Details ([pscustomobject]@{
    empty_asset_id_lines = $emptyAssetIdLines.ToArray()
    duplicate_asset_ids = @($duplicateAssetIds | Sort-Object -Unique)
    expected_data_row_count = $expectedDataRowCount
    actual_data_row_count = $actualDataRowCount
})))

$declaredInputActions = @([regex]::Matches($projectText, '(?m)^([A-Za-z0-9_]+)=\{\r?$') | ForEach-Object { $_.Groups[1].Value })
$missingInputActions = @($manifest.static_contract.required_input_actions | Where-Object { $declaredInputActions -notcontains [string]$_ })
$emptyInputEventActions = New-Object System.Collections.Generic.List[string]
foreach ($requiredActionValue in $manifest.static_contract.required_input_actions) {
    $requiredAction = [string]$requiredActionValue
    if ($missingInputActions -contains $requiredAction) {
        continue
    }
    $actionPattern = '(?ms)^' + [regex]::Escape($requiredAction) + '=\{\r?\n(?<body>.*?)^\}\r?$'
    $actionMatch = [regex]::Match($projectText, $actionPattern)
    if (-not $actionMatch.Success -or $actionMatch.Groups['body'].Value -notmatch '"events"\s*:\s*\[\s*Object\s*\(') {
        [void]$emptyInputEventActions.Add($requiredAction)
    }
}
[void]$checks.Add((New-I0StaticCheck -Code "INPUT_REQUIRED_ACTIONS" -Condition ($missingInputActions.Count -eq 0 -and $emptyInputEventActions.Count -eq 0) -ExpectedRedCodes $expectedRedCodes -Details ([pscustomobject]@{
    required_actions = @($manifest.static_contract.required_input_actions)
    missing_actions = $missingInputActions
    actions_without_object_event = $emptyInputEventActions.ToArray()
})))

$runScenePath = Join-Path $repo (([string]$manifest.static_contract.run_scene_relative_path).Replace('/', '\'))
$runSceneText = Read-I0Utf8Text -Path $runScenePath
$toggleBlock = Get-I0GdFunctionBlock -Text $runSceneText -FunctionName '_toggle_debug_panel'
$openBlock = Get-I0GdFunctionBlock -Text $runSceneText -FunctionName '_open_debug_panel'
$toggleCanShow = ($toggleBlock -match 'debug_panel\.visible\s*=\s*not\s+debug_panel\.visible') -or ($toggleBlock -match 'debug_panel\.visible\s*=\s*true')
$openCanShow = $openBlock -match 'debug_panel\.visible\s*=\s*true'
$toggleGatePresent = $toggleBlock -match '(?ms)if\s+not\s+_can_use_debug_tools\(\)\s*:.*?debug_panel\.visible\s*=\s*false.*?return'
$openGatePresent = $openBlock -match '(?ms)if\s+not\s+_can_use_debug_tools\(\)\s*:.*?debug_panel\.visible\s*=\s*false.*?return'
$debugGatePresent = $toggleGatePresent -and $openGatePresent
[void]$checks.Add((New-I0StaticCheck -Code "DEBUG_SURFACE_TOGGLES" -Condition ($toggleCanShow -and $openCanShow -and $debugGatePresent) -ExpectedRedCodes $expectedRedCodes -Details ([pscustomobject]@{
    toggle_can_show_panel = $toggleCanShow
    open_can_show_panel = $openCanShow
    gate_present = $debugGatePresent
    toggle_gate_present = $toggleGatePresent
    open_gate_present = $openGatePresent
})))

$actualExpectedRedCodes = @($checks | Where-Object { $_.status -eq 'EXPECTED_RED' } | ForEach-Object { $_.code } | Sort-Object)
$expectedSorted = @($expectedRedCodes | Sort-Object)
$redExactMatch = (($expectedSorted -join "`n") -ceq ($actualExpectedRedCodes -join "`n"))
$unexpectedChecks = @($checks | Where-Object { $_.status -in @('FAIL', 'UNEXPECTED_GREEN') })
$contractOk = ($redExactMatch -and $unexpectedChecks.Count -eq 0)
$result = [pscustomobject][ordered]@{
    schema_version = 1
    suite_id = [string]$manifest.suite_id
    profile = $Profile
    repo_root = $repo
    generated_utc = [DateTime]::UtcNow.ToString('o')
    expected_red_codes = $expectedSorted
    actual_expected_red_codes = $actualExpectedRedCodes
    expected_red_exact_match = $redExactMatch
    unexpected_check_codes = @($unexpectedChecks | ForEach-Object { $_.code })
    checks = $checks.ToArray()
    overall_status = if ($contractOk) { 'PASS' } else { 'FAIL' }
}

if (-not [string]::IsNullOrWhiteSpace($ReportPath)) {
    Write-I0Json -Value $result -Path $ReportPath
}
Write-Output ("I0_STATIC_BASELINE_JSON=" + ($result | ConvertTo-Json -Depth 30 -Compress))
if ($contractOk) {
    exit 0
}
exit 1
