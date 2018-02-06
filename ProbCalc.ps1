





<#
    .SYNOPSIS
        Calculates the probabiliites of restults for die rolls and card flips.

    .DESCRIPTION

    
    .PARAMETER Computer
    
    
    
    .EXAMPLE
        
    

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
$system = 'xWing'

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
        $global:aryCombos = $global:aryCombosTemp
    }

    


######################################################################
## Count-XWingResults
## Counts counts how many times each result is present in the table of all
## possible restuls and displays.
######################################################################

function Count-XWingResults {



    $nodeCritCount = 0
    $nodeHitCount = 0
    $nodeEvadeCount = 0
    $nodeFocusCount = 0
    $nodeBlankCount = 0
    $totalCount = 0
    
    $event1CritCount = 0
    $event2CritCount = 0
    $event3CritCount = 0
    $event4CritCount = 0
    $event5CritCount = 0
    
    $event1HitCount = 0
    $event2HitCount = 0
    $event3HitCount = 0
    $event4HitCount = 0
    $event5HitCount = 0
    
    $event1EvadeCount = 0
    $event2EvadeCount = 0
    $event3EvadeCount = 0
    $event4EvadeCount = 0
    $event5EvadeCount = 0
    
    $event1FocusCount = 0
    $event2FocusCount = 0
    $event3FocusCount = 0
    $event4FocusCount = 0
    $event5FocusCount = 0
    
    $event1BlankCount = 0
    $event2BlankCount = 0
    $event3BlankCount = 0
    $event4BlankCount = 0
    $event5BlankCount = 0
    


    #step through each entry in the combo
    foreach($Combo in $aryCombos) {
        Count-OccurancesInEntry -lookfor $cCrit -combo $Combo -nodeCritCount ([ref]$nodeCritCount) -nodeHitCount ([ref]$nodeHitCount) -nodeEvadeCount ([ref]$nodeEvadeCount) -nodeFocusCount ([ref]$nodeFocusCount) -nodeBlankCount ([ref]$nodeBlankCount)
        $totalCount = $totalCount +1

        if ($nodeCritCount -eq 1) {
            $event1CritCount = $event1CritCount +1
        } elseif ($nodeCritCount -eq 2) {
            $event1CritCount = $event1CritCount +1
            $event2CritCount = $event2CritCount +1
        } elseif ($nodeCritCount -eq 3) {
            $event1CritCount = $event1CritCount +1
            $event2CritCount = $event2CritCount +1
            $event3CritCount = $event3CritCount +1
        } elseif ($nodeCritCount -eq 4) {
            $event1CritCount = $event1CritCount +1
            $event2CritCount = $event2CritCount +1
            $event3CritCount = $event3CritCount +1
            $event4CritCount = $event4CritCount +1
        } elseif ($nodeCritCount -eq 5) {
            $event1CritCount = $event1CritCount +1
            $event2CritCount = $event2CritCount +1
            $event3CritCount = $event3CritCount +1
            $event4CritCount = $event4CritCount +1
            $event5CritCount = $event5CritCount +1
        }
    
        if ($nodeHitCount -eq 1) {
            $event1HitCount = $event1HitCount +1
        } elseif ($nodeHitCount -eq 2) {
            $event1HitCount = $event1HitCount +1
            $event2HitCount = $event2HitCount +1
        } elseif ($nodeHitCount -eq 3) {
            $event1HitCount = $event1HitCount +1
            $event2HitCount = $event2HitCount +1
            $event3HitCount = $event3HitCount +1
        } elseif ($nodeHitCount -eq 4) {
            $event1HitCount = $event1HitCount +1
            $event2HitCount = $event2HitCount +1
            $event3HitCount = $event3HitCount +1
            $event4HitCount = $event4HitCount +1
        } elseif ($nodeHitCount -eq 5) {
            $event1HitCount = $event1HitCount +1
            $event2HitCount = $event2HitCount +1
            $event3HitCount = $event3HitCount +1
            $event4HitCount = $event4HitCount +1
            $event5HitCount = $event5HitCount +1
        }
    
        if ($nodeEvadeCount -eq 1) {
            $event1EvadeCount = $event1EvadeCount +1
        } elseif ($nodeEvadeCount -eq 2) {
            $event1EvadeCount = $event1EvadeCount +1
            $event2EvadeCount = $event2EvadeCount +1
        } elseif ($nodeEvadeCount -eq 3) {
            $event1EvadeCount = $event1EvadeCount +1
            $event2EvadeCount = $event2EvadeCount +1
            $event3EvadeCount = $event3EvadeCount +1
        } elseif ($nodeEvadeCount -eq 4) {
            $event1EvadeCount = $event1EvadeCount +1
            $event2EvadeCount = $event2EvadeCount +1
            $event3EvadeCount = $event3EvadeCount +1
            $event4EvadeCount = $event4EvadeCount +1
        } elseif ($nodeEvadeCount -eq 5) {
            $event1EvadeCount = $event1EvadeCount +1
            $event2EvadeCount = $event2EvadeCount +1
            $event3EvadeCount = $event3EvadeCount +1
            $event4EvadeCount = $event4EvadeCount +1
            $event5EvadeCount = $event5EvadeCount +1
        }
    
    
        if ($nodeFocusCount -eq 1) {
            $event1FocusCount = $event1FocusCount +1
        } elseif ($nodeFocusCount -eq 2) {
            $event1FocusCount = $event1FocusCount +1
            $event2FocusCount = $event2FocusCount +1
        } elseif ($nodeFocusCount -eq 3) {
            $event1FocusCount = $event1FocusCount +1
            $event2FocusCount = $event2FocusCount +1
            $event3FocusCount = $event3FocusCount +1
        } elseif ($nodeFocusCount -eq 4) {
            $event1FocusCount = $event1FocusCount +1
            $event2FocusCount = $event2FocusCount +1
            $event3FocusCount = $event3FocusCount +1
            $event4FocusCount = $event4FocusCount +1
        } elseif ($nodeFocusCount -eq 5) {
            $event1FocusCount = $event1FocusCount +1
            $event2FocusCount = $event2FocusCount +1
            $event3FocusCount = $event3FocusCount +1
            $event4FocusCount = $event4FocusCount +1
            $event5FocusCount = $event5FocusCount +1
        }
    
    
        if ($nodeBlankCount -eq 1) {
            $event1BlankCount = $event1BlankCount +1
        } elseif ($nodeBlankCount -eq 2) {
            $event1BlankCount = $event1BlankCount +1
            $event2BlankCount = $event2BlankCount +1
        } elseif ($nodeBlankCount -eq 3) {
            $event1BlankCount = $event1BlankCount +1
            $event2BlankCount = $event2BlankCount +1
            $event3BlankCount = $event3BlankCount +1
        } elseif ($nodeBlankCount -eq 4) {
            $event1BlankCount = $event1BlankCount +1
            $event2BlankCount = $event2BlankCount +1
            $event3BlankCount = $event3BlankCount +1
            $event4BlankCount = $event4BlankCount +1
        } elseif ($nodeBlankCount -eq 5) {
            $event1BlankCount = $event1BlankCount +1
            $event2BlankCount = $event2BlankCount +1
            $event3BlankCount = $event3BlankCount +1
            $event4BlankCount = $event4BlankCount +1
            $event5BlankCount = $event5BlankCount +1
        }
    
    
    
        write-host "Event $totalCount - Nodes: $Combo  Results:  C: $nodeCritCount / H: $nodeHitCount / E: $nodeEvadeCount / F: $nodeFocusCount / B: $nodeBlankCount" 
    }

    write-host ""
    Write-host ("{0,10}  {1,24}" -f "Total:","$totalCount") 
    Write-host ("{0,10}  {1,24}  {2,24}  {3,24}  {4,24}  {5,24}" -f "Crits:",  "1: $event1CritCount ($($event1CritCount/$totalCount))",  "2: $event2CritCount ($($event2CritCount/$totalCount))",  "3: $event3CritCount ($($event3CritCount/$totalCount))",  "4: $event4CritCount ($($event4CritCount/$totalCount))",  "5: $event5CritCount ($($event5CritCount/$totalCount))") 
    Write-host ("{0,10}  {1,24}  {2,24}  {3,24}  {4,24}  {5,24}" -f "Hits:",   "1: $event1HitCount ($($event1HitCount/$totalCount))",    "2: $event2HitCount ($($event2HitCount/$totalCount))",    "3: $event3HitCount ($($event3HitCount/$totalCount))",    "4: $event4HitCount ($($event4HitCount/$totalCount))",    "5: $event5HitCount ($($event5HitCount/$totalCount))") 
    Write-host ("{0,10}  {1,24}  {2,24}  {3,24}  {4,24}  {5,24}" -f "Focuses:","1: $event1FocusCount ($($event1FocusCount/$totalCount))","2: $event2FocusCount ($($event2FocusCount/$totalCount))","3: $event3FocusCount ($($event3FocusCount/$totalCount))","4: $event4FocusCount ($($event4FocusCount/$totalCount))","5: $event5FocusCount ($($event5FocusCount/$totalCount))") 
    Write-host ("{0,10}  {1,24}  {2,24}  {3,24}  {4,24}  {5,24}" -f "Evades:", "1: $event1EvadeCount ($($event1EvadeCount/$totalCount))","2: $event2EvadeCount ($($event2EvadeCount/$totalCount))","3: $event3EvadeCount ($($event3EvadeCount/$totalCount))","4: $event4EvadeCount ($($event4EvadeCount/$totalCount))","5: $event5EvadeCount ($($event5EvadeCount/$totalCount))") 
    Write-host ("{0,10}  {1,24}  {2,24}  {3,24}  {4,24}  {5,24}" -f "Blanks:", "1: $event1BlankCount ($($event1BlankCount/$totalCount))","2: $event2BlankCount ($($event2BlankCount/$totalCount))","3: $event3BlankCount ($($event3BlankCount/$totalCount))","4: $event4BlankCount ($($event4BlankCount/$totalCount))","5: $event5BlankCount ($($event5BlankCount/$totalCount))") 
}

#https://weblogs.asp.net/soever/powershell-return-values-from-a-function-through-reference-parameters
#counts the number of times a value appears in each entry.
#and entry is a array of each reslut of a roll.
function Count-OccurancesInEntry  {
    param (
        [int]$lookfor, 
        [int[]]$combo,
        [ref]$nodeCritCount,
        [ref]$nodeHitCount,
        [ref]$nodeEvadeCount,
        [ref]$nodeFocusCount,
        [ref]$nodeBlankCount
        )

    
    $nodeCritCount.value = 0
    $nodeHitCount.value = 0
    $nodeEvadeCount.value = 0
    $nodeFocusCount.value = 0
    $nodeBlankCount.value = 0
    
    foreach ($entry in $combo) {
        if($entry -eq $cCrit) {
            $nodeCritCount.value = $nodeCritCount.value +1
        }elseif ($entry -eq $cHit) {
            $nodeHitCount.value = $nodeHitCount.value +1
        }elseif ($entry -eq $cEvade) {
            $nodeEvadeCount.value = $nodeEvadeCount.value +1
        }elseif ($entry -eq $cFocus) {
            $nodeFocusCount.value = $nodeFocusCount.value +1
        }elseif ($entry -eq $cBlank) {
            $nodeBlankCount.value = $nodeBlankCount.value +1
        }
    
    }
    
}







    
######################################################################
## Main
######################################################################

#Process based on system

if ($system -eq 'xWing') {

    # Variable representing the die faces in xWing (Crit, Hit, Evade, Focus and Blank)
    Set-Variable cCrit  -option Constant -value 3 -Scope Global
    Set-Variable cHit   -option Constant -value 2 -Scope Global
    Set-Variable cEvade -option Constant -value 4 -Scope Global
    Set-Variable cFocus -option Constant -value 1 -Scope Global
    Set-Variable cBlank -option Constant -value 0 -Scope Global

    # Array representing one die (aka node) with one entry per face.
    $global:aryValues = @($cBlank,$cBlank,$cFocus,$cFocus,$cHit,$cHit,$cHit,$cCrit)
    
    #Create the table of all possible results
    Create-DiceComboTable -Nodes $nodes

    #Count the results of the table containing all possible results
    Count-XWingResults
    



}



