







<#
    .SYNOPSIS
        Calculates the probabiliites of outcome for die rolls and card flips.

    .DESCRIPTION



    
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

$Count = "Counting"
$Node = "Nodetree"


$global:aryFaces = @()               #an array of each face of a node
$global:aryResults = @()             #An array of every possible result.
$global:aryResultsTemp = @()         #Temporar array used to create the array of every possible result.
$global:arySummary = @()             #An array summarizing the total occurances of every possbile result (e.g. how many results have three 6's)

$showDebug = $false
$showDebug = $true
$showDebug = $false




######################################################################
## New-ResultTable
## Creates a table containing all the possible outcomes
## This routine is best suited for dice and similar models, 
## where each node value can occure on each die.  It is not suited
## for card draw modles where a single instance of a card can only
## be drawn once.
######################################################################


function New-ResultTable {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Nodes                      #the number of items dice rolled, cards drawn, etc.
    )
    
    #Seed the result array by creating an entry for every possible result of a single node

    write-host "Adding Node: 1" -ForegroundColor Green
    foreach($value in $global:aryFaces){
        $objResult = New-Object -TypeName PSObject
        $NameText = "$node + 1"
        Add-Member -InputObject $objResult -MemberType 'NoteProperty' -Name $NameText -Value $value
        $global:aryResults += $objResult
    }


    #Step through each node after the last
    for ($i = 2; $i -le $Nodes; $i++) {
        Add-ResultNode -nodeNum $i
    }




}




######################################################################
## Add-ResultMetaProperties
## Adds properties to each node used to tally the outcome of that 
## result (e.g. hightest, lowest, sums, etc.)
######################################################################

function Add-ResultMetaProperties {

    #Create an empty array to hold the new results.
    $global:aryResultsTemp = @()
        
    if($showDebug ) {
        write-host "Adding Result Tally Properties" -ForegroundColor Green
    }

    #step through each result
    $resultCount = 0
    foreach($result in $global:aryResults){

        $resultCount = $resultCount + 1
        
        #create a clone of the current result
        $TempEntry = New-Object -TypeName PSObject
        $result.psobject.properties | ForEach-Object {
            $TempEntry | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value
        }

        #add metadata about the result
        Add-Member -InputObject $TempEntry -MemberType 'NoteProperty' -Name "ResultID" -Value $resultCount
        Add-Member -InputObject $TempEntry -MemberType 'NoteProperty' -Name "HighFace" -Value "Undefined"
        Add-Member -InputObject $TempEntry -MemberType 'NoteProperty' -Name "LowFace" -Value "Undefined"

        #add metadata to each outcome for each item listed in the summary table
        foreach($line in $arySummary) {
            $lineName = $line.face + $Count
            Add-Member -InputObject $TempEntry -MemberType 'NoteProperty' -Name $lineName -Value 0
        }
    
        #Add the new result to the new result table
        $global:aryResultsTemp += $TempEntry

        
    }
    #replace the old result table with the new result table
    $global:aryResults = $global:aryResultsTemp
}







######################################################################
## Add-ResultNode
## Steps through each existing result and adds an entry for each possible
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

function Add-ResultNode {
    param(
        [int]$nodeNum
    )

    write-host "Adding Node: $nodenum " -ForegroundColor Green

    #Create an empty array to hold the new results.
    $global:aryResultsTemp = @()
    
    #step through each result
    foreach($result in $global:aryResults){
        #step through each possible outcome of the current node
        foreach($value in $global:aryFaces){

            #create a copy of the current result
            $TempEntry = New-Object -TypeName PSObject
            $result.psobject.properties | ForEach-Object {
                $TempEntry | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value
            }
            
            #add outcome for this itteration of the node to the result
            $name = $Node + $nodeNum
            Add-Member -InputObject $TempEntry -MemberType 'NoteProperty' -Name $name -Value $value

            #Add the new result to the new result table
            $global:aryResultsTemp += $TempEntry
        }
    }
    #replace the old result table with the new result table
    $global:aryResults = $global:aryResultsTemp
}








######################################################################
## Build Summary Array
######################################################################
function New-SummaryTable{

    #step through each value in the side array
    foreach ($face in $aryFaces) {
        
        #check to see if the value of the face is already in the summary array
        $match = $false
        foreach ($line in $global:arySummary) {
            if($line.face -eq $face){
                $match = $true
            }
        }
    
        #if there is NO match add the value of the face to the summary array
        if(!$match) {
            $objLine = New-Object -TypeName PSObject
            Add-Member -InputObject $objLine -MemberType 'NoteProperty' -Name 'Face' -Value $face
            #add a property to the summary line object for each node in the result
            for($i = 1; $i -le $nodes; $i++){
                $name = $Node + $i
                Add-Member -InputObject $objLine -MemberType 'NoteProperty' -Name $name -Value 0
            }

            #add the line object to the summary array
            $global:arySummary += $objLine
        }
    }

    #disply for debugging
    if($showDebug) {Display-SummaryTable}
}




######################################################################
## Tally-ResultTableMetaData
## Steps through each result in the table and adds metadata (highest, lowest. etc.)
######################################################################

function  Tally-ResultTableMetaData {


    #step through each result
    for ($i = 0; $i -le $global:aryResults.count -1; $i++) {

        #Tally the result of each individual result
        Tally-ResultMetaData
    }

    #Display-ResultTable
}

    
        

######################################################################
## Add-ResultMetaData
## Steps through ONE result and tallies the  metadata
## - Counts the number of times each face occurs (e.g. if three faces resulted in Hit then HitCount = 3)
######################################################################

function  Tally-ResultMetaData {

    
    #Step through each property in the result
    foreach($prop in  $global:aryResults[$i].psobject.Properties) {
        #get the property name
        $propName = $prop.name
        #if the property has the string "node" in it, then its value is the face value for that node of the result.
        if($propName -match $node) {
            #Get the face result for that node
            $propValue = $prop.value
            #determine the property that will record the tally total for that face of the result record
            $propTally = $propValue + $Count

            #step through each property in the event object
            foreach($prop in  $global:aryResults[$i].psobject.Properties) {
                #if the name of the property matches the name of the face tally property increment it by 1
                if($prop.name -eq $propTally) {
                    $prop.value = $prop.value +1
                }
            }
        }
    }
}



######################################################################
## Tally-Summarytable
######################################################################

function Tally-Summarytable {


    #step through each result in the result array
    foreach ($result in $aryResults) {


        #step through each property in each result
        foreach($prop in $result.psobject.Properties) {

            #if the value of the property is greather than 0 check to see if is is a tally
            if($prop.value -gt 0) {
                #if the property name contains $Count then it is the tally of a face for that result
                if($prop.name -match $Count) {
                    #get the face the tally is for
                    $FaceName = [string]$($prop.name).replace($Count,"")
                    #get the number of times the face occured in this result
                    $FaceCount = $prop.value
                    #get the name of the tally in the summary table to be incremented
                    $TallyName = $node + $FaceCount
                    Increment-SummaryTable $FaceName $FaceCount
                }
            }
        }
    }
}






######################################################################
## Increment-SummaryTable
## Increments the appropriate enty in the summary table for the given
## input.
## Example if Blank, 2 is the input then this function will find
## the "2" property of the "Blank" line object in the summary table
## and increment the count by 1.
######################################################################



function Increment-SummaryTable {
    param(
        [string]$FaceName,           #The name of the face that needs to be incremented
        [int]$Occurances             #How many time the face occured in the result being summarized
    )

    #the property conresponding to the number of occurances in the result
    $PropOcc = $node + $Occurances

    #Step through each line of the summary array
    foreach ($line in $global:arySummary) {
        #check if this is the line for the matching face
        if($line.face -eq $FaceName) {
            #Step through each property in the line item
            foreach ($lineProp in $line.psobject.properties) {
                #If the Occurance count of the property matches then increment the summary count
                if($PropOcc -eq $($lineProp.name)){
                    $lineProp.value = $lineProp.value +1
                }
            }
        }
    }
}




######################################################################
## Display various tables to the screen for debugging purposes
######################################################################

function Display-ResultTable {
    Write-Host 
    Write-Host "Results Table" -ForegroundColor Green
    foreach($result in $aryResults) {
        write-host $result -ForegroundColor Yellow
    }
}

function Display-FacesTable {
    Write-Host 
    Write-Host "Faces Table" -ForegroundColor Green
    foreach($face in $aryFaces) {
        write-host $face -ForegroundColor Yellow
    }
}

function Display-SummaryTable {
    Write-Host 
    Write-Host "Summary Table" -ForegroundColor Green
    foreach($line in $arySummary) {
        write-host $line -ForegroundColor Yellow
    }
}


function Display-EventData {
    Write-Host 
    Write-Host "Event Data" -ForegroundColor Green
    Write-Host " Nodes:  $nodes" 
    Write-Host " Faces:  $($($global:aryFaces).count)"
    Write-Host " Events: $($($global:aryResults).count)"
    
}



######################################################################
## Main
######################################################################

#Process based on system

if ($system -eq 'xWing') {

    # Array representing one die (aka node) with one entry per face.
    # This script assumes values will be listed from lowest (left) to highest (right)
    $global:aryFaces = @("Blank","Blank","Focus","Focus","Hit","Hit","Hit","Crit")
    $global:aryFaces = @("Blank","Crit")
    $global:aryFaces = @("Blank","Blank","Hit","Crit")
    $global:aryFaces = @("Blank","Blank","Blank","Focus","Focus","Evade","Evade","Evade")
    $global:aryFaces = @("Blank","Blank","Focus","Focus","Hit","Hit","Hit","Crit")
    
    #Create the table to store the summarized totals for each face
    New-SummaryTable

    #Create the table of all possible results
    New-ResultTable -Nodes $nodes

    #Add metadata properties to each result.  These poperties will hold sumarization data (e.g. highest face) about the result.
    Add-ResultMetaProperties
    
    #Count the occurances of each face in each result and record the totals in the metadata properties of each result object in the table.
    Tally-ResultTableMetaData

    #Count the occurance of each face quantitn in each result and summarize the totals in the Summary table.
    Tally-Summarytable
    
    Display-EventData
    #Display-ResultTable
    Display-SummaryTable
    #Display-FacesTable
    
    

}



