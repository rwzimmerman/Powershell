







<#
    .SYNOPSIS
        Calculates the probabiliites of restults for die rolls and card flips.

    .DESCRIPTION
        Generates an array containing all possible outcomes of a random event, then counts how many times a set
        of outcomes occurs.  For example if three 6-sided dice were reolled and results summed the number of times 18,
        17, 16, etc occured would be counted.

        EVENT is one complete occurance of a 'random' event.  (e.g. the result of rolling 3 dice, or a hand of 5 cards)
        NODE is a single element of an event (e.g. a 1 die, or a 1 card)
        VALUE is result of single node in an event.  (e.g. rolling a "six" on 1 die, or a "queen" on a single card)



    
    .PARAMETER Nodes
    
    
    
    .EXAMPLE
        
    

    .INPUTS

    .OUTPUTS

    .NOTES 
        Author: Robert Zimmerman
        Updated: Jan 2018

    .LINK
        
#> 





#https://weblogs.asp.net/soever/powershell-return-values-from-a-function-through-reference-parameters


######################################################################
## Variables
######################################################################

#how many nodes (coins flipped, dice rolled, etc...)
$nodes = 3

#the system being used
$system = 'xWing'


$global:aryFaces = @()               #an array of each face of a node
$global:aryEvents = @()              #An array of every possible event.
$global:aryEventsTemp = @()          #Temporar array used to create the array of every possible event.
$global:aryResults = @()             #An summarizing the restuls of each possible event (e.g. how many events have three 6's)

$showDebug = $false
$showDebug = $true
$showDebug = $false




######################################################################
## New-EventTable
## Creates a table containing all the possible outcomes
## This routine is best suited for dice and similar models, 
## where each node value can occure on each die.  It is not suited
## for card draw modles where a single instance of a card can only
## be drawn once.
######################################################################


function New-EventTable {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Nodes                      #the number of items dice rolled, cards drawn, etc.
    )
    
    #Seed the event array by creating an entry for each possible outcome
    #for a single node

    write-host "Adding Node: 1" -ForegroundColor Green
    foreach($value in $global:aryFaces){
        $objEvent = New-Object -TypeName PSObject
        Add-Member -InputObject $objEvent -MemberType 'NoteProperty' -Name 'Node1' -Value $value
        $global:aryEvents += $objEvent
    }


    #Step through each node after the last
    for ($i = 2; $i -le $Nodes; $i++) {
        Add-EventNode -nodeNum $i
    }


    #Add properties to each event to summarize the event (highest face, lowest face, etc.)
    Add-EventMetaProperties


    #display debug info
    if($showDebug) {Display-EventTable}   


}




######################################################################
## Add-EventMetaProperties
## Adds properties to each node used to tally the result of that 
## event (e.g. hightest, lowest, sums, etc.)
######################################################################

function Add-EventMetaProperties {

    #Create an empty array to hold the new events.
    $global:aryEventsTemp = @()
        
    if($showDebug ) {
        write-host "Adding Event Tally Properties" -ForegroundColor Green
    }

    #step through each event
    $eventCount = 0
    foreach($event in $global:aryEvents){

        $eventCount = $eventCount + 1
        
        #create a clone of the current event
        $TempEntry = New-Object -TypeName PSObject
        $event.psobject.properties | ForEach-Object {
            $TempEntry | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value
        }

        #add metadata about the event
        Add-Member -InputObject $TempEntry -MemberType 'NoteProperty' -Name "EventID" -Value $eventCount
        Add-Member -InputObject $TempEntry -MemberType 'NoteProperty' -Name "HighFace" -Value "Undefined"
        Add-Member -InputObject $TempEntry -MemberType 'NoteProperty' -Name "LowFace" -Value "Undefined"

        #add metadata for each result in the results table
        foreach($result in $aryResults) {
            $resultText = $result.result + "Count"
            Add-Member -InputObject $TempEntry -MemberType 'NoteProperty' -Name $resultText -Value "Undefined"
        }
    
        #Add the new event to the new event table
        $global:aryEventsTemp += $TempEntry

        
    }
    #replace the old event table with the new event table
    $global:aryEvents = $global:aryEventsTemp
}







######################################################################
## Add-EventNode
## Steps through each existing event and adds an entry for each possible
## value of the current node.
## Example if the current table is coin flips and looks like:
## Heads
## Tails
## after this function the table will look like
## Heads,Heads
## Heads,Tails
## Tails,Heads
## Tails,Tails
######################################################################

function Add-EventNode {
    param(
        [int]$nodeNum
    )

    write-host "Adding Node: $nodenum " -ForegroundColor Green

    #Create an empty array to hold the new events.
    $global:aryEventsTemp = @()
    
    #step through each event
    foreach($event in $global:aryEvents){
        #step through each possible outcome of the current node
        foreach($value in $global:aryFaces){

            #create a copy of the current event
            $TempEntry = New-Object -TypeName PSObject
            $event.psobject.properties | ForEach-Object {
                $TempEntry | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value
            }
            
            #add outcome for this itteration of the node to the event
            $name = "Node" + $nodeNum
            Add-Member -InputObject $TempEntry -MemberType 'NoteProperty' -Name $name -Value $value

            #Add the new event to the new event table
            $global:aryEventsTemp += $TempEntry
        }
    }
    #replace the old event table with the new event table
    $global:aryEvents = $global:aryEventsTemp
}








######################################################################
## Build Result Array
######################################################################
function New-RestultTable{

    #step through each value in the side array
    foreach ($item in $aryFaces) {
        
        #check to see if the value of the face is already in the result table
        $match = $false
        foreach ($result in $global:aryResults) {
            if($result.result -eq $item){
                $match = $true
            }
        }
    
        #if there is NO match add the value of the face to the results array
        if(!$match) {
            $objResult = New-Object -TypeName PSObject
            Add-Member -InputObject $objResult -MemberType 'NoteProperty' -Name 'Result' -Value $item
            #add a property to the result object for each node in the event
            for($i = 1; $i -le $nodes; $i++){
                $name = "Node" + $i
                Add-Member -InputObject $objResult -MemberType 'NoteProperty' -Name $name -Value 0
            }

            #add the result object to the result array
            $global:aryResults += $objResult
        }
    }

    #disply for debugging
    if($showDebug) {Display-RestultsTable}
}




######################################################################
## Add-EventTableMetaData
## Steps through each event in the table and adds metadata (highest, lowest. etc.)
######################################################################

function  Add-EventTableMetaData {

    $eventCount = 0

    #step through each result
    foreach ($event in $global:aryEvents) {
        $eventCount = $eventCount +1        

        #create a clone of the current event
        $TempEntry = New-Object -TypeName PSObject
        $event.psobject.properties | ForEach-Object {
            $TempEntry | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value
        }

        #add metadata to the cloned event
        $TempEntry.LowFace = "Trout"
        $TempEntry.HighFace = "high"
        Add-EventMetaData 
        
        #write the updated cloned event back to the event array
        $event.LowFace = $TempEntry.LowFace
        $event.HighFace = $TempEntry.HighFace
    }

    Display-EventTable
    write-host "Event Count: $eventCount" -ForegroundColor Green

}



######################################################################
## Add-EventMetaData
## Steps through ONE event and adds metadata (highest, lowest. etc.)
######################################################################

function  Add-EventMetaData {

    
    $TempEntry.LowFace ="BJ"

    Write-Host 
    Write-Host "Event" -ForegroundColor Yellow
    $event.psobject.properties | ForEach-Object {
        write-host "$($_.name) $($_.value)"
    }
}









######################################################################
## Display various tables to the screen for debugging purposes
######################################################################

function Display-EventTable {
    Write-Host "Event Table" -ForegroundColor Green
    foreach($event in $aryEvents) {
        write-host $event -ForegroundColor Yellow
    }
}

function Display-FacesTable {
    Write-Host "Faces Table" -ForegroundColor Green
    foreach($face in $aryFaces) {
        write-host $face -ForegroundColor Yellow
    }
}

function Display-RestultsTable {
    Write-Host "Results Table" -ForegroundColor Green
    foreach($result in $aryResults) {
        write-host $result -ForegroundColor Yellow
    }
}



######################################################################
## Main
######################################################################

#Process based on system

if ($system -eq 'xWing') {

    # Array representing one die (aka node) with one entry per face.
    # This script assumes values will be listed from lowest (left) to highest (right)
    $global:aryFaces = @("Blank","Blank","Focus","Focus","Hit","Hit","Hit","Crit")
    $global:aryFaces = @("Blank","Blank","Blank","Focus","Focus","Evade","Evade","Evade")
    $global:aryFaces = @("Blank","Crit")
    $global:aryFaces = @("Blank","Blank","Hit","Crit")
    
    #Create the table to store all the results
    New-RestultTable

    #Create the table of all possible results
    New-EventTable -Nodes $nodes


    Add-EventTableMetaData
    
    #Display-EventTable
    #Display-RestultsTable
    #Display-FacesTable
    
    

}



