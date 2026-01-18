$existingFunctions = Get-ChildItem Function: | Select-Object -ExpandProperty Name
# --------------


function ShowMenu([array]$items, [boolean]$showLabel = $true) {
    if ($showLabel) { Log "LOG" $(Strings "select-option") }

    for ($i = 1; $i -lt $items.Length + 1; $i++) {        
        $label = Strings $items[$i - 1]
        Write-Host "- [$i] " -ForegroundColor Magenta -NoNewline
        Write-Host $label -ForegroundColor Blue
    }    
}    
function ListenMenu([array]$items, [boolean]$showLabel = $true) {
    Write-Host $(Strings "make-choice") -ForegroundColor Blue -NoNewline
    [int]$choice = Read-Host

    clr

    if (($choice -gt ($items.Length)) -or ($choice -lt 1)) {
        Log "ERR" "Invalid choice, please try again."
        return (HandleMenu $items $showLabel)
    }

    return $items[$choice-1]
}

function HandleMenu([array]$items, [boolean]$showLabel = $true) {
    ShowMenu $items $showLabel
    return (ListenMenu $items $showLabel)
}



# Exports
$publicFunctions = (Get-ChildItem Function: | Select-Object -ExpandProperty Name) | Where-Object { ($_ -notin $existingFunctions) -and ($_ -notlike "_*") }
Export-ModuleMember -Function $publicFunctions