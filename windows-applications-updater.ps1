# Classes

<#
    Represents a package.
    @property { string } Name - The name of the package.
    @property { string } Id - The id of the package.
    @property { string } Version - The version of the package.
    @property { string } Available - The available version of the package.
    @property { string } Source - The source of the package.
#>
class Package {
    [string]$Name
    [string]$Id
    [string]$Version
    [string]$Available
    [string]$Source
}

# --------------------------------------------------------------------------------------------------------------------------
# Functions

<#
    Returns the index of the row containing the table headers.
    @param { string[] } Rows - The rows of the winget result.
    @param { int } CurrRowIdx - The current row index.
    @returns { int } The index of the row containing the table headers or -1 if no table headers were found.
#>
function GetRowIdxOfTableHeaders {
    param (
        [string[]]$Rows, 
        [int]$CurrRowIdx
    )
    while (($CurrRowIdx -lt ($Rows.Length - 1)) -and (-not $Rows[$CurrRowIdx + 1].StartsWith("--------------------"))) {
        $CurrRowIdx++
    }
    if ($CurrRowIdx -ge ($Rows.Length - 1)) {
        return -1
    }
    return $CurrRowIdx
}

<#
    Returns the column index of the start of the next header.
    @param { string } Row - The row containing the table headers.
    @param { int } CurrColIdx - The current column index.
    @returns { int } The column index of the start of the next header or -1 if no header was found.
#>
function GetColumnIdxOfNextTableHeader {
    param (
        [string]$Row, 
        [int]$CurrColIdx
    )
    # Find the next space character
    [int]$CurrColIdx = $Row.IndexOf(" ", $CurrColIdx)
    if ($CurrColIdx -eq -1) {
        Write-Host "Error, no next header found" -Foreground-Color Red
        return -1
    }
    # Find the first non-space character
    while (($CurrColIdx -lt $Row.Length) -and ($Row[$CurrColIdx] -eq " ")) {
        $CurrColIdx++
    }
    if ($CurrColIdx -ge ($Row.Length)) {
        Write-Host "Error, no next header found" -Foreground-Color Red
        return -1    
    }
    return $CurrColIdx
}

<#
    Returns the packages and the index of the next row.
    @param { string[] } Rows - The rows.
    @param { int } RowIdx - The current row index.
    @param { int } NameStartIdx - The index of the start of the name column.
    @param { int } IdStartIdx - The index of the start of the id column.
    @param { int } VersionStartIdx - The index of the start of the version column.
    @param { int } AvailableStartIdx - The index of the start of the available column.
    @param { int } SourceStartIdx - The index of the start of the source column.
    @returns { Package[], int } The packages and the index of the next row.
#>
function GetPackagesFromTable {
    param (
        [string[]]$Rows,
        [int]$RowIdx,
        [int]$NameStartIdx,
        [int]$IdStartIdx,
        [int]$VersionStartIdx,
        [int]$AvailableStartIdx,
        [int]$SourceStartIdx
    )
    [Package[]]$Packages = @()
    while (($RowIdx -lt $Rows.Length ) -and ($Rows[$RowIdx].Length -gt ($AvailableStartIdx )) -and (-not $Rows[$RowIdx].Contains('--include-unknown'))) {
        [string]$Row = $Rows[$RowIdx]
        [string]$Name = $Row.Substring($NameStartIdx, $IdStartIdx).Trim()
        [string]$Id = $Row.Substring($IdStartIdx, $VersionStartIdx - $IdStartIdx).Trim()
        [string]$Version = $Row.Substring($VersionStartIdx, $AvailableStartIdx - $VersionStartIdx).Trim()
        [string]$Available = $Row.Substring($AvailableStartIdx, $SourceStartIdx - $AvailableStartIdx).Trim()
        [string]$Source = $Row.Substring($SourceStartIdx, $Row.Length - $SourceStartIdx).Trim()

        [Package]$Package = [Package]::new()
        $Package.Name = $Name;
        $Package.Id = $Id;
        $Package.Version = $Version
        $Package.Available = $Available;
        $Package.Source = $Source;
        $Packages += $Package
        $RowIdx++
    }
    return $Packages, $RowIdx
}

<#
    Returns the packages that can be updated.
    @returns { Package[] } The packages that can be updated.
#>
function GetUpdateablePackages {
    [object[]]$WingetResult = winget upgrade
    [string[]]$Rows = $WingetResult.Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)
    [int]$RowIdx = 0
    [Package[]]$UpdateablePackages = @()

    ## winget upgrade will return either one or two tables
    For ([int]$i = 0; $i -lt 2; $i++) {
        [int]$HeadersRowIdx = GetRowIdxOfTableHeaders $Rows $RowIdx
        if ($HeadersRowIdx -eq -1) {
            if ($i -eq 0) {
                Write-Host "Error, no table headers found" -Foreground-Color Red
            }
            return $UpdateablePackages
        }
    
        [string]$HeadersRow = $Rows[$HeadersRowIdx]
    
        [int]$NameStartIdx = 0
        [int]$IdStartIdx = GetColumnIdxOfNextTableHeader $HeadersRow $NameStartIdx
        [int]$VersionStartIdx = GetColumnIdxOfNextTableHeader $HeadersRow $IdStartIdx
        [int]$AvailableStartIdx = GetColumnIdxOfNextTableHeader $HeadersRow $VersionStartIdx
        [int]$SourceStartIdx = GetColumnIdxOfNextTableHeader $HeadersRow $AvailableStartIdx
    
        [int]$firstRowIdx = $HeadersRowIdx + 2
        [Package[]]$Packages, [int]$RowIdx = GetPackagesFromTable $Rows $FirstRowIdx $NameStartIdx $IdStartIdx $VersionStartIdx $AvailableStartIdx $SourceStartIdx
        $UpdateablePackages += $Packages
    }
    return $UpdateablePackages
}

<#
    Returns the ids of the packages to exclude from updating.
    @returns { string[] } The ids of the packages to exclude from updating.
#>
function GetSkippablePackageIds {
    [string]$ExclusionFilePath = $PSScriptRoot + "\blackListedPackages.txt"
    [boolean]$FileExists = Test-Path -Path $ExclusionFilePath -PathType Leaf    
    if (-not $FileExists) {
        Write-Host "Exclusions file not found, all packages will be updated to their latest version" ForegroundColor Red | Write-Output
        return [string[]]@()
    }
    [object[]]$ExclusionFileContent = Get-Content $ExclusionFilePath
    [string[]]$ExcludedFileRows = $ExclusionFileContent.Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)
    $ExcludedFileRows = $ExcludedFileRows | ForEach-Object { $_.Trim() }
    [string[]]$SkippablePackageIds = @()
    For ([int]$i = 0; $i -lt $ExcludedFileRows.Length; $i++) {
        [string]$Row = $ExcludedFileRows[$i]
        if (-not $Row.StartsWith('#')) {
            $SkippablePackageIds += $Row
        }
    }
    return $SkippablePackageIds
}

<#
    Returns the packages to update and the packages to skip.
    @param { Package[] } UpdateablePackages - The packages that can be updated.
    @param { string[] } ExcludedPackageIds - The ids of the packages to exclude from updating.
    @returns { Package[], Package[] } The packages to update and the packages to skip.
#>
function GetPackagesToUpdateAndSkip {
    param (
        [Package[]]$UpdateablePackages,
        [string[]]$ExcludedPackageIds
    )
    [Package[]]$PackagesToUpdate = @()
    [Package[]]$SkippedPackages = @()
    For ([int]$i = 0; $i -lt $UpdateablePackages.Length; $i++) {
        [Package]$Package = $UpdateablePackages[$i]
        if ($ExcludedPackageIds -contains $Package.Id) {
            $SkippedPackages += $Package
        }
        else {
            $PackagesToUpdate += $Package
        }
    }
    return $PackagesToUpdate, $SkippedPackages
}

<#
    Prints the packages that are skipped.
    @param { Package[] } PackagesToSkip - The packages that are skipped.
#>
function PrintPackagesToSkip {
    param (
        [Package[]]$PackagesToSkip
    )
    If ($PackagesToSkip.Length -ge 1) {
        If ($PackagesToSkip.Length -eq 1) {
            Write-Host "Skipping the following package update because it's id was found in the exclusions file: " -ForegroundColor Red | Write-Output
        }
        else {
            Write-Host "Skipping the following package updates because their ids were found in the exclusions file: " -ForegroundColor Red | Write-Output
        }
        $PackagesToSkip | Format-Table
        Write-Host "----------------------------------------------------------------------------------------------------`n`n"
    }
}

<#
    Updates the packages.
    @param { Package[] } PackagesToUpdate - The packages to update.
#>
function PrintAndUpdatePackagesToUpdate {
    param (
        [Package[]]$PackagesToUpdate
    )
    If ($PackagesToUpdate.Length -ge 1) {
        If ($PackagesToUpdate.Length -eq 1) {
            Write-Host "Updating the following package to it's latest version: " -ForegroundColor Green | Write-Output
        }
        else {
            Write-Host "Updating the following packages to their latest version: " -ForegroundColor Green | Write-Output
        }
        $PackagesToUpdate | Format-Table
        Write-Host "----------------------------------------------------------------------------------------------------`n`n"
        For ($i = 0; $i -lt $PackagesToUpdate.Length; $i++) {
            [Package]$Package = $PackagesToUpdate[$i]
            Write-Host "Updating $($Package.Name)..." -ForegroundColor Yellow | Write-Output
            winget upgrade $($Package.Id) --exact --silent --accept-package-agreements --accept-source-agreements --force --disable-interactivity
            Write-Host "`n"
        }   
    }
}

# --------------------------------------------------------------------------------------------------------------------------
# Main

[System.Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

[Package[]]$UpdateablePackages = GetUpdateablePackages

[string[]]$SkippablePackageIds = GetSkippablePackageIds

[Package[]]$PackagesToUpdate, [Package[]]$PackagesToSkip = GetPackagesToUpdateAndSkip $UpdateablePackages $SkippablePackageIds

PrintPackagesToSkip $PackagesToSkip
PrintAndUpdatePackagesToUpdate $PackagesToUpdate

Write-Host "All updates completed.`n" -ForegroundColor Green | Write-Output
Write-Host "Click on the terminal window if you want to pause the timer"
TIMEOUT /t 5