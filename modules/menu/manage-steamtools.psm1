$existingFunctions = Get-ChildItem Function: | Select-Object -ExpandProperty Name
# --------------


$path = Join-Path $steam "xinput1_4.dll"
$config = Join-Path $steam "config"
function Install-steamtools() {
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
            
    Invoke-Expression $SteamtoolsScript *> $null

    if ( Test-Path $path ) {
        Log "OK" $(Strings("st-installed"))
    } else {
        Log "ERR" $(Strings("installation-failed"))
    }

}
function Uninstall-steamtools() {
    Stop-Steam
    if ( Test-Path $path ) {
        Remove-Item $path *> $null
        Log "OK" $(Strings("st-uninstalled"))
    }

    Log "LOG" $(Strings("st-wipe"))
    Log "WARN" $(Strings("st-wipe2"))
    $res = HandleMenu @("yes", "no") $false
    
    if ($res -eq "yes") {
        $files = @( "depotcache", "stplug-in", "stUI" )
        foreach ($file in $files) {
            Join-Path $config $file | Remove-ItemIfExists
        }

        Log "OK" "$(Strings("st-uninstalled"))(+)"
    }
}


function Invoke-managesteamtools() {
    $res = HandleMenu @("install", "uninstall", "return-menu")

    if ($res -eq "return-menu") { return }
    if ($res -eq "install") { Install-steamtools }
    if ($res -eq "uninstall") { Uninstall-steamtools }
}



# Exports
$publicFunctions = (Get-ChildItem Function: | Select-Object -ExpandProperty Name) | Where-Object { ($_ -notin $existingFunctions) -and ($_ -notlike "_*") }
Export-ModuleMember -Function $publicFunctions