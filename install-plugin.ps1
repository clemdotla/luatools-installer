## Configure this
$Host.UI.RawUI.WindowTitle = "Luatools plugin installer | .gg/luatools"
$name = "luatools" # automatic first letter uppercase included
$link = "https://github.com/madoiscool/ltsteamplugin/releases/latest/download/ltsteamplugin.zip"
$milleniumTimer = 5 # in seconds for auto-installation

### Hey nerd, here's a "-f" argument to remove "user interactions"

# Hidden defines
$steam = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam").InstallPath
$upperName = $name.Substring(0,1).ToUpper() + $name.Substring(1).ToLower()
$isForced = $args -contains "-f"

#### Logging defines ####
function Log {
    param ([string]$Type, [string]$Message, [boolean]$NoNewline = $false)

    $Type = $Type.ToUpper()
    switch ($Type) {
        "OK"   { $foreground = "Green" }
        "INFO" { $foreground = "Cyan" }
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
Log "WARN" "Hey! Just letting you know that i'm working on a new version combining various scripts of the server"
Log "AUX" "Will include language support on THIS script too, luv y'all brazilians"
Write-Host

# To hide IEX blue box thing
$ProgressPreference = 'SilentlyContinue'


Get-Process steam -ErrorAction SilentlyContinue | Stop-Process -Force

#### Requirements part ####

# Steamtools check
# TODO: Make this prettier?
$path = Join-Path $steam "xinput1_4.dll"
if ( Test-Path $path ) {
    Log "INFO" "Steamtools already installed"
} else {
    if (($isForced)) {
        Log "AUX" "-f argument detected, skipping installation."
        Log "ERR" "Restart the script once steamtools is installed."
        exit
    }

    # Filtering the installation script
    $script = Invoke-RestMethod "https://steam.run"
    $keptLines = @()

    foreach ($line in $script -split "`n") {
        $conditions = @( # Removes lines containing one of those
            ($line -imatch "Start-Process" -and $line -imatch "steam"),
            ($line -imatch "steam\.exe"),
            ($line -imatch "Start-Sleep" -or $line -imatch "Write-Host"),
            ($line -imatch "cls" -or $line -imatch "exit"),
            ($line -imatch "Stop-Process" -and -not ($line -imatch "Get-Process"))
        )
        
        if (-not($conditions -contains $true)) {
            $keptLines += $line
        }
    }

    $SteamtoolsScript = $keptLines -join "`n"
    Log "ERR" "Steamtools not found."
    
    # Retrying with a max of 5
    for ($i = 0; $i -lt 5; $i++) {

        Log "AUX" "Install it at your own risk! Close this script if you don't want to."
        Log "WARN" "Pressing any key will install steamtools (UI-less)."
        
        [void][System.Console]::ReadKey($true)
        Write-Host
        Log "WARN" "Installing Steamtools"
        
        Invoke-Expression $SteamtoolsScript *> $null

        if ( Test-Path $path ) {
            Log "OK" "Steamtools installed"
            break
        } else {
            Log "ERR" "Steamtools installation failed, retrying..."
        }

    }
}

# Millenium check
$milleniumInstalling = $false
foreach ($file in @("millennium.dll", "python311.dll")) {
    if (!( Test-Path (Join-Path $steam $file) )) {
        
        # Ask confirmation to download (use -f to skip)
        if (!( $isForced )) {
            Log "ERR" "Millenium not found, installation process will start in 5 seconds."
            Log "WARN" "Press any key to cancel the installation."
            
            for ($i = $milleniumTimer; $i -ge 0; $i--) {
                # Wheter a key was pressed
                if ([Console]::KeyAvailable) {
                    Write-Host
                    Log "ERR" "Installation cancelled by user."
                    exit
                }

                Log "LOG" "Installing Millenium in $i second(s)... Press any key to cancel." $true
                Start-Sleep -Seconds 1
            }
            Write-Host

        } else { Log "ERR" "Millenium not found, installation process will instantly start (-f argument)." }


        Log "INFO" "Installing millenium"

        Invoke-Expression "& { $(Invoke-RestMethod 'https://clemdotla.github.io/millennium-installer-ps1/millennium.ps1') } -NoLog -DontStart -SteamPath '$steam'"

        Log "OK" "Millenium done installing"
        $milleniumInstalling = $true
        break
    }
}
if ($milleniumInstalling -eq $false) { Log "INFO" "Millenium already installed" }



#### Plugin part ####
# Ensuring \Steam\plugins
if (!( Test-Path (Join-Path $steam "plugins") )) {
    New-Item -Path (Join-Path $steam "plugins") -ItemType Directory *> $null
}


$Path = Join-Path $steam "plugins\$name" # Defaulting if no install found

# Checking for plugin named "$name"
foreach ($plugin in Get-ChildItem -Path (Join-Path $steam "plugins") -Directory) {
    $testpath = Join-Path $plugin.FullName "plugin.json"
    if (Test-Path $testpath) {
        $json = Get-Content $testpath -Raw | ConvertFrom-Json
        if ($json.name -eq $name) {
            Log "INFO" "Plugin already installed, updating it"
            $Path = $plugin.FullName # Replacing default path
            break
        }
    }
}

# Installation 
$subPath = Join-Path $env:TEMP "$name.zip"

Log "LOG" "Downloading $name"
Invoke-WebRequest -Uri $link -OutFile $subPath *> $null
Log "LOG" "Unzipping $name"
# DM clem.la on Discord if you have a way to remove the blue progression bar in the console
Expand-Archive -Path $subPath -DestinationPath $Path *>$null
Remove-Item $subPath -ErrorAction SilentlyContinue

Log "OK" "$upperName installed"


# Removing beta
$betaPath = Join-Path $steam "package\beta"
if ( Test-Path $betaPath ) {
    Remove-Item $betaPath -Recurse -Force
}
# Removing potential x32 (kinda greedy but ppl got issues and was hard to fix without knowing it was the issue, ppl don't know what they run)
$cfgPath = Join-Path $steam "steam.cfg"
if ( Test-Path $cfgPath ) {
    Remove-Item $cfgPath -Recurse -Force
}
Remove-ItemProperty -Path "HKCU:\Software\Valve\Steam" -Name "SteamCmdForceX86" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Valve\Steam" -Name "SteamCmdForceX86" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -Name "SteamCmdForceX86" -ErrorAction SilentlyContinue


# Toggling the plugin on (+turning off updateChecking to try fixing a bug where steam doesn't start)
$configPath = Join-Path $steam "ext/config.json"
$updateStatus = $true
if (-not (Test-Path $configPath)) {
    $config = @{
        general = @{
            checkForMillenniumUpdates = $false
        }
        plugins = @{
            enabledPlugins = @($name)
        }
    }
    New-Item -Path (Split-Path $configPath) -ItemType Directory -Force | Out-Null
    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
}
else {
    $rawJson = Get-Content $configPath -Raw -Encoding UTF8
    if ($rawJson -imatch '"checkForMillenniumUpdates"\s*:\s*false') {
        $updateStatus = $false
    }
    
    $config = $rawJson | ConvertFrom-Json
    
    # Disable updates to prevent steam not starting bug
    if (-not $config.general) {
        $config | Add-Member -MemberType NoteProperty -Name "general" -Value ([PSCustomObject]@{}) -Force
    }
    $config.general | Add-Member -MemberType NoteProperty -Name "checkForMillenniumUpdates" -Value $false -Force
    

    if (-not $config.plugins) {
        $config | Add-Member -MemberType NoteProperty -Name "plugins" -Value ([PSCustomObject]@{}) -Force
    }
    if (-not $config.plugins.enabledPlugins) {
        $config.plugins | Add-Member -MemberType NoteProperty -Name "enabledPlugins" -Value @() -Force
    }
    
    $pluginsList = @($config.plugins.enabledPlugins)
    if ($pluginsList -notcontains $name) {
        $pluginsList += $name
        $config.plugins.enabledPlugins = $pluginsList
    }
    
    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
}
Log "OK" "Plugin enabled"

# Result showing
Write-Host
if ($milleniumInstalling) { Log "WARN" "Steam startup will be longer, don't panic and don't touch anything in steam!" }


# Start with the "-clearbeta" argument
$exe = Join-Path $steam "steam.exe"
Start-Process $exe -ArgumentList "-clearbeta"

Log "INFO" "Starting steam"

# Related to steam not starting
# Turning back on updates
if ($updateStatus -eq $true) {
    Log "WARN" "Don't close the script yet"

    # Hard coded yeah? so what uh?
    Start-Sleep -Seconds 20
    
    $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    
    if (-not $config.general) {
        $config | Add-Member -MemberType NoteProperty -Name "general" -Value ([PSCustomObject]@{}) -Force
    }
    $config.general | Add-Member -MemberType NoteProperty -Name "checkForMillenniumUpdates" -Value $true -Force
    
    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
    
    Log "OK" "Job done, you can close this."
}