





<#
    .SYNOPSIS
        averages

    .DESCRIPTION

    
    .PARAMETER Computer
    
    
    
    .EXAMPLE
        .\WinUpdateToolsV2.ps1 RestartComputer "robz010"
        Restarts a single machine named robz010


    .INPUTS

    .OUTPUTS

    .NOTES 
        Author: Robert Zimmerman
        Updated: Jan 2018

    .LINK
        
#> 



######################################################################
## Variables
######################################################################

#how many nodes (coins flipped, dice rolled, etc...)
$nodes = 3

#the system being used
$system = 'xw'

#Table of all possible outcomes.
$global:aryCombos = @()

#Temporayr Table used to create the table of all possible outcomes
$global:aryCombosTemp = @()








######################################################################
## Create-DiceComboTable
## Creates a table containing all the possible outcomes
## This routine is best suited for dice and similar models, 
## where each node value can occure on each die.  It is not suited
## for card draw modles where a single instance of a card can only
## be drawn once.
######################################################################


function Create-DiceComboTable {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Nodes                      #the number of items dice rolled, cards drawn, etc.
    )
    
    #Seed the possible combo array by creating an entry for each possible outcome
    #for a single node
    foreach($value in $global:aryValues){
        $global:aryCombos += $value
    }


    #Step through each node after the last
    for ($i = 2; $i -le $Nodes; $i++) {
        Add-DiceComboNode -nodeNum $i
        Write-Host "AC Count = $($global:aryCombos.Count)"
    }
}
    
    
######################################################################
## Add-DiceComboNode
## Adds nodes to the All combos table for for the Create-DiceComboTable
## function.
######################################################################

    function Add-DiceComboNode {
        param(
            [int]$nodeNum
        )

        #Create a temporary Array        
        #$aryCombosTemp = New-Object System.Collections.ArrayList
        #Cleare Temp Array
        $global:aryCombosTemp = @()
        
        Write-Host "Add Node $nodeNum"

        #step through each entry and add a new possibility for each node
        foreach($entry in $global:aryCombos){
            foreach($value in $global:aryValues){
                
                #Create a empty array for the new combo
                $TempEntry = @()
                #Add each element of the existing array to the new array
                for ($j = 0; $j -le $entry.count -1; $j++) {
                    $TempEntry += $entry[$j]
                }
                #Add the new value to the end of the new temp array.
                #We now have the old combo entry array with the new entry added to the end
                $TempEntry += $value 

                #Add the new combo array to the array of all possible combos.
                $aryCombosTempCount = $global:aryCombosTemp.count
                $global:aryCombosTemp += ""
                $global:aryCombosTemp[$aryCombosTempCount] = $TempEntry
            }
        }
        #$aryCombosTemp
        Write-Host "ACT Count = $($global:aryCombosTemp.Count)"
        $global:aryCombos = $global:aryCombosTemp
    }

    


######################################################################
## Count-DiceCombos
## Get data on Dice Combos
######################################################################

function Count-XWingComobos {


    write-host "Count"

    $critCount = 0
    $hitCount = 0
    $evadeCount = 0
    $focusCount = 0
    $blankCount = 0
    $totalCount = 0
    
    


    #step through each entry in the combo
    foreach($Combo in $aryCombos) {
        write-host "combo $Combo" -ForegroundColor red
        #write-host $entry
        Count-OccurancesInEntry -lookfor $cCrit -combo $Combo -critCount ([ref]$critCount) -hitCount ([ref]$hitCount) -evadeCount ([ref]$evadeCount) -focusCount ([ref]$focusCount) -blankCount ([ref]$blankCount)
        $totalCount = $totalCount +1

        write-host "Total Combos: $totalCount"
        write-host " Crit Count:  $critCount"
        write-host " Hit Count:   $hitCount"
        write-host " Evade Count: $evadeCount"
        write-host " Focus Count: $focusCount"
        write-host " Blank Count: $blankCount"
    

    }

    

}

#https://weblogs.asp.net/soever/powershell-return-values-from-a-function-through-reference-parameters
#counts the number of times a value appears in each entry.
#and entry is a array of each reslut of a roll.
function Count-OccurancesInEntry  {
    param (
        [int]$lookfor, 
        [int[]]$combo,
        [ref]$critCount,
        [ref]$hitCount,
        [ref]$evadeCount,
        [ref]$focusCount,
        [ref]$blankCount
        )

    
    $critCount.value = 0
    $hitCount.value = 0
    $evadeCount.value = 0
    $focusCount.value = 0
    $blankCount.value = 0
    
    foreach ($entry in $combo) {
        if($entry -eq $cCrit) {
            $critCount.value = $critCount.value +1
        }elseif ($entry -eq $cHit) {
            $hitCount.value = $hitCount.value +1
        }elseif ($entry -eq $cEvade) {
            $evadeCount.value = $evadeCount.value +1
        }elseif ($entry -eq $cFocus) {
            $focusCount.value = $focusCount.value +1
        }elseif ($entry -eq $cBlank) {
            $blankCount.value = $blankCount.value +1
        }
    
    }
    
}







    
######################################################################
## Main
######################################################################

#Process based on system

if ($system -eq 'xw') {
    #All possible values a node can have (e.g. heads and tails, etc...).
    #$global:aryValues = @("*","H","H","H","f","f","-","-")

    Set-Variable cCrit  -option Constant -value 3 -Scope Global
    Set-Variable cHit   -option Constant -value 2 -Scope Global
    Set-Variable cEvade -option Constant -value 2 -Scope Global
    Set-Variable cFocus -option Constant -value 1 -Scope Global
    Set-Variable cBlank -option Constant -value 0 -Scope Global
    $global:aryValues = @($cBlank,$cHit,$cCrit)
    
    #Create the table of all possible combinations
    Create-DiceComboTable -Nodes $nodes



    #test Output
    Write-Host $aryCombos.Count

    Count-XWingComobos
    



}



