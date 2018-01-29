





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
$nodes = 4

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

function Count-DiceCombos {


    write-host "Count"


    foreach($Combo in $aryCombos) {
        write-host "combo $Combo"
        foreach($entry in $Combo) {
            write-host $entry
        }

    }




    write-host "Total Combos: $($aryCombos.count)"




}









    
######################################################################
## Main
######################################################################

#Process based on system

if ($system -eq 'xw') {
    #All possible values a node can have (e.g. heads and tails, etc...).
    #$global:aryValues = @("*","H","H","H","f","f","-","-")
    $global:aryValues = @(1,2,3,4)
    
    #Create the table of all possible combinations
    Create-DiceComboTable -Nodes $nodes



    #test Output
    Write-Host $aryCombos.Count
    #$aryCombos

    Count-DiceCombos
    

    #test
    #$url = "http://sp13/sites/1/2/3"
    #$charCount = ($url.ToCharArray() | Where-Object {$_ -eq '/'} | Measure-Object).Count
    #Write-Host "CC: $charCount"




}





