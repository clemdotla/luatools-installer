$repo = "https://raw.githubusercontent.com/clemdotla/steam-menu/refs/heads/main"
$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }


function GetTemp {
    if (-not $env:TEMP -or -not (Test-Path $env:TEMP)) {
        if ($env:LOCALAPPDATA -and (Test-Path $env:LOCALAPPDATA)) {
            $env:TEMP = Join-Path $env:LOCALAPPDATA "Temp"
        }
        if (-not $env:TEMP -or -not (Test-Path $env:TEMP)) {
            $env:TEMP = Join-Path $root "temp"
        }
    }
    $script:temp = Join-Path $env:TEMP "clemdotla"

    if (-not (Test-Path $temp)) {
        New-Item -ItemType Directory -Path $temp -Force | Out-Null
    }
}


function global:Fetch {
    param ([string]$path, [boolean]$raw = $true)

    $localPath = Join-Path $root $path
    $tempPath = Join-Path $temp $path
    if (Test-Path $localPath) {
        return $(if ($raw) {Get-Content $localPath -Raw} else {$localPath})
    # } elseif (Test-Path $tempPath) {
    #     return $(if ($raw) {Get-Content $tempPath -Raw} else {$tempPath})
    } else {
        try {
            $url = "$repo/$path"
            $res = Invoke-RestMethod -Uri $url -ErrorAction Stop
            
            if ($raw) {
                return $res
            } else {
                New-Item -ItemType Directory -Path (Split-Path $tempPath) -Force | Out-Null
                Set-Content -Path $tempPath -Value $res
                return $tempPath
            }
        } catch {
            # Write-Warning "Unable to load $path from $url"
            return $false
        }
    }

    return $output
}

$imported = @()
function global:Import([string]$path) {
    if ($imported -contains $path) { return }
    
    $path = Join-Path "modules" $path
    $output = Fetch $path $false
    if (!$output) { return }

    Import-Module $output -Force
    $imported += $path
}



function Main() {
    GetTemp
    Import "misc.psm1"

    LoadLang ([System.Globalization.CultureInfo]::InstalledUICulture.TwoLetterISOLanguageName)
    Log "Log" $(Strings("welcome"))
    GetSteam
    
    Import "menu.psm1"

    while ($true) {
        $menu = @(
            "manage-plugin", "manage-steamtools", "manage-millennium",
            "fixes",
            "credits", "information"
            "exit"
        )

        $res = HandleMenu $menu
        if ($res -eq "exit") { break }

        Import "menu\$($res).psm1"
        try {
            & "Invoke-$($res -replace '-', '')"
        } catch {
            Log "Err" $(Strings("failed-option"))
        }
    }
    

    # Clearing temp (to stay up-to-date + cleaner)
    Remove-item $temp -Recurse -Force -ErrorAction SilentlyContinue
}
Main

