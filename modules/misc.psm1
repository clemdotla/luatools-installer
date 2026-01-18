$existingFunctions = Get-ChildItem Function: | Select-Object -ExpandProperty Name
# --------------


# Colors: Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White
function Log {
    param ([string]$Type, [string]$Message, [boolean]$NoNewline = $false)
    
    $Type = $Type.ToUpper()
    switch ($Type) {
        "OK"   { $foreground = "Green" }
        "INFO" { $foreground = "Blue" }
        "ERR"  { $foreground = "Red" }
        "WARN" { $foreground = "Yellow" }
        "LOG"  { $foreground = "Magenta" }
        "AUX"  { $foreground = "DarkGray" }
        default { $foreground = "White" }
    }

    $date = Get-Date -Format "HH:mm:ss"
    $prefix = if ($NoNewline) { "`r[$date] " } else { "[$date] " }
    Write-Host $prefix -ForegroundColor "Cyan" -NoNewline

    Write-Host [$Type] $Message -ForegroundColor $foreground -NoNewline:$NoNewline
}
function Clr {
    if (!($args -contains "nocls")) {
        Clear-Host
    }
}

# ------

function LoadLang([string]$lang = "en") {
    $res = Fetch "locals\$lang.json"
    if (!($res)) {
        if ($lang -eq "en") {
            Log "ERR" "Language file not found"
            exit
        } else {
            Log "WARN" "Language $lang not found, falling back to english"

            LoadLang "en"
            return
        }
    }

    $res = $res | ConvertFrom-Json

    $script:strings = $res
    $script:en_strings = if ($lang -eq "en") { $res } else { Fetch "locals\en.json" | ConvertFrom-Json }
}
function Strings {
    param ([string]$key)

    return $(
        if ($strings.$key) {$strings.$key} 
        elseif ($en_strings.$key) {$en_strings.$key} 
        else {$key}
    )
}


# ------

function Remove-ItemIfExists {
    param(
        [Parameter(ValueFromPipeline)]
        $path
    )
    process {
        if (Test-Path $path) { Remove-Item -Path $path -Recurse -Force }
    }
}

function Stop-Steam {
    Stop-Process -Name "steam" -Force
}


# ------

function GetSteam {
    $registries = @(
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam",
        "HKCU:\SOFTWARE\Valve\Steam"
    )

    foreach ($reg in $registries) {
        if (!(Test-Path $reg)) { continue }

        $path = (Get-ItemProperty -Path $reg -Name "InstallPath" -ErrorAction SilentlyContinue).InstallPath

        if ($path -and (Test-Path $path)) {
            $global:steam = $path
            Log "OK" "$(Strings("found-steam")) `"$path`""
            
            break
        }
    }

    if (!$global:steam) {
        Log "ERR" $(Strings("steam-not-found"))
        exit
    }
}


$publicFunctions = (Get-ChildItem Function: | Select-Object -ExpandProperty Name) | Where-Object { ($_ -notin $existingFunctions) -and ($_ -notlike "_*") }
Export-ModuleMember -Function $publicFunctions