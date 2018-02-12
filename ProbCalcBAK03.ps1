









<#
    .SYNOPSIS
        Calculates the percentage chance of outcomes for die rolls, card draws, etc.

    .DESCRIPTION
        Scenario - The parameters of the random event being measured.
        Result - One possible outcome the scenario.  
        Node - A single randomizaion element (e.g. one die, one card, onc coin, etc.)
        Face - A single value from a node.  (e.g three on a die, or a queen on a playing card)

        The script builds a table of all possible results of the scenario, then it counts
        how many times a given result is achieved and summarized the data.  And outputs
        the data.

        For example if in a scenario 2 coins (nodes) were flipped, each having heads and
        tails (2 faces) the scenario would have 4 possible results: HH, HT, TH, TT.
        Scenario Summary 
        2 Heads: 1
        1 Heads: 2
        1 Tails: 2
        2 Tails: 1

    
    .PARAMETER Nodes
    
    
    
    .EXAMPLE
        
    

    .INPUTS

    .OUTPUTS

    .NOTES 
        Author: Robert Zimmerman
        Updated: Feb 2018

        To Do:
        Add a "no or bettter switch" for coins and such where all faces are of equal value.
        Add "exhausted nodes" for cards where a given value can only result once
        Add "pretty summary" create out put that looks nicer and calculated percentages
        Add "reroll logic" allow for rerolls and caclute percentages after a reroll


        Array notes
        https://powershell.org/2013/09/16/powershell-performance-the-operator-and-when-to-avoid-it/


    .LINK
        
#> 


#https://weblogs.asp.net/soever/powershell-return-values-from-a-function-through-reference-parameters




param(
    [int]$NodeCount=2,            #the number of elements in the randomization (e.g. 3 cards, 2 dice, etc.)
    [string[]]$Faces,
    [switch]$XWingAtt,        #True if XWing attack dice are being used 
    [switch]$XWingDef,        #True if XWing defence dice are being used 
    [switch]$PlayingCards,    #True if a deck of playing cards are being used 
    [switch]$Malifaux,        #True if a malifuax deck of playing cards are being used including the special rules for jockers
    [switch]$ShowDebug        #if true debuging data will be displayed when the script executes.

)




#Keywords
#This scirpt uses several dynamic arrays of dynamically generated custome objects to
#generate arrays of all possible outcomes, tally those outcomes, then summarize the data.  The
#properties of those custom object are comprized of the scenarious face values and keywords.
#The script parses and sorts those objects based on the keywords below.  If a faces value
#includes a keyword that would cause the parsing to fail.  The keywords are defined here
#so they can be easily change and give values unlikely to be a face value.
[string]$delimiter = "^"
[string]$node = "Node"
[string]$count = "Amount"
[string]$orBetterCount = "OrBetter"
[string]$occurance = " Occurance Exactly" 
[string]$orBetterOccurance = " Or Better Occurances" 

#Arrays
#These are the tables that hold the results and summary data.
$aryFaces = @()               #an array of each face of a node
$aryuniqueFaces = @()         #an array of each posible face of a node. Each value occurs only once an in the same order as in the Face Array
$aryResults = @()             #An array of every possible result.
$arySummary = @()             #An array summarizing the total occurances of every possbile result (e.g. how many results have three 6's)
$aryTemp = @()                #Temporary array used in various functions



#Faces
#if a faces array is input then use it.
#if one of the 'system' (e.g. Xwing Attack Dice) switches is used then use the faces for that system.
if($Faces.count -ne 0) {
    $script:aryFaces = $Faces
}elseif($XWingAtt) {
    $script:aryFaces = @("Blank","Blank","Focus","Focus","Hit","Hit","Hit","Crit")
}elseif($XWingDef) {
    $script:aryFaces = @("Blank","Blank","Blank","Focus","Focus","Evade","Evade","Evade")
}elseif($PlayingCards) {
    $script:aryFaces = @("BJ","1H","1D","1C","1S","2H","2D","2C","2S","3H","3D","3C","3S","4H","4D","4C","4S",`
                         "5H","5D","5C","5S","6H","6D","6C","6S","7H","7D","7C","7S","8H","8D","8C","8S","9H","9D","9C","9S", `
                         "10H","10D","10C","10S","11H","11D","11C","11S","12H","12D","12C","12S","13H","13D","13C","13S","RJ")
}elseif($Malifaux) {
    $script:aryFaces = @("0-","1R","1M","1T","1C","2R","2M","2T","2C","3R","3M","3T","3C","4R","4M","4T","4C",`
                         "5R","5M","5T","5C","6R","6M","6T","6C","7R","7M","7T","7C","8R","8M","8T","8C","9R","9M","9T","9C", `
                         "10R","10M","10T","10C","11R","11M","11T","11C","12R","12M","12T","12C","13R","13M","13T","13C","14*")
}else{
    $script:aryFaces = @("Heads","Tails")
}








######################################################################
## New-ResultTable
## Creates a table containing all the possible results for the input
## faces and nodes.
######################################################################


function New-ResultTable {
    param(
        [Parameter(Mandatory=$true)]
        [int]$NodeCount                      #the number of items dice rolled, cards drawn, etc.
    )
    
    #Seed the result array by creating an entry for every possible result of a single node

    foreach($value in $script:aryFaces){
        $objResult = New-Object -TypeName PSObject
        $NameText = $delimiter + $node + "1" + $delimiter
        Add-Member -InputObject $objResult -MemberType 'NoteProperty' -Name $NameText -Value $value
        $script:aryResults += $objResult
    }

    #Step through each node after the last
    for ($i = 2; $i -le $NodeCount; $i++) {
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
    $script:aryTemp = @()

    #get size of initial result array
    [int]$intialResultSize = $($script:aryResults).count
        
    if($showDebug ) {
        write-host "Adding Result Tally Properties" -ForegroundColor Green
    }

    #step through each result
    
    [single]$resultCount = 0
    foreach($result in $script:aryResults){

        #status bar
        $resultCount = $resultCount + 1
        $percentComplete = ($resultCount / $intialResultSize)*100
        Write-Progress -Activity "Extending Tables (Step 2/4)" -Status "Working..." -PercentComplete ($percentComplete)

        
        #create a clone of the current result
        $TempEntry = New-Object -TypeName PSObject
        $result.psobject.properties | ForEach-Object {
            $TempEntry | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value
        }

        #add metadata about the result
        Add-Member -InputObject $TempEntry -MemberType 'NoteProperty' -Name $($delimiter + "ResultID" + $delimiter) -Value $resultCount
        Add-Member -InputObject $TempEntry -MemberType 'NoteProperty' -Name $($delimiter + "HighFace" + $delimiter) -Value "Undefined"
        Add-Member -InputObject $TempEntry -MemberType 'NoteProperty' -Name $($delimiter + "LowFace" + $delimiter) -Value "Undefined"

        #add metadata to each outcome for each item listed in the summary table
        foreach($line in $arySummary) {
            $faceName = $line.face
            $faceName = $faceName.replace($delimiter,"")
            $lineName = $delimiter + $faceName + $count + $delimiter
            Add-Member -InputObject $TempEntry -MemberType 'NoteProperty' -Name $lineName -Value 0
            $lineName = $delimiter + $faceName + $orBetterCount + $delimiter
            Add-Member -InputObject $TempEntry -MemberType 'NoteProperty' -Name $lineName -Value 0
        }
        #Add the new result to the new result table
        $script:aryTemp += $TempEntry
    }
    #replace the old result table with the new result table
    $script:aryResults = $script:aryTemp
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


    #Create an empty array to hold the new results.
    $script:aryTemp = @()

    #get size of initial result array
    [int]$intialResultSize = $($script:aryResults).count
    $resultCount = 0
    
    #step through each result
    foreach($result in $script:aryResults){
        #Progress Bar
        $resultCount = $resultCount +1
        $percentComplete = ($resultCount / $intialResultSize)*100
        Write-Progress -Activity "Generating Outcomes (Multi-part Step 1/4)" -Status "Processing Node $nodeNum" -PercentComplete ($percentComplete)


        #step through each possible outcome of the current node
        foreach($value in $script:aryFaces){

            #create a copy of the current result
            $TempEntry = New-Object -TypeName PSObject
            $result.psobject.properties | ForEach-Object {
                $TempEntry | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value
            }
            
            #add outcome for this itteration of the node to the result
            $name = $delimiter + $node + $nodeNum + $delimiter
            Add-Member -InputObject $TempEntry -MemberType 'NoteProperty' -Name $name -Value $value

            #Add the new result to the new result table
            $script:aryTemp += $TempEntry
        }
    }
    #replace the old result table with the new result table
    $script:aryResults = $script:aryTemp
}








######################################################################
## Build Summary Array
######################################################################
function New-SummaryTable{


    #step through each value in the side array
    foreach ($face in $aryFaces) {
        
        #check to see if the value of the face is already in the summary array
        $match = $false

        foreach ($line in $script:arySummary) {
            if($line.face -eq $($delimiter + $face +$delimiter)){
                $match = $true
            }
        }
    
        #if there is NO match add the value of the face to the summary array
        if(!$match) {
            $objLine = New-Object -TypeName PSObject
            Add-Member -InputObject $objLine -MemberType 'NoteProperty' -Name 'Face' -Value $($delimiter + $face +$delimiter)
            #add a property to the summary line object for each node in the result
            for($i = 1; $i -le $NodeCount; $i++){
                $name = $delimiter + [string]$i + $occurance + $delimiter
                Add-Member -InputObject $objLine -MemberType 'NoteProperty' -Name $name -Value 0
                $name = $delimiter + [string]$i + $orBetterOccurance + $delimiter
                Add-Member -InputObject $objLine -MemberType 'NoteProperty' -Name $name -Value 0
            }

            #add the line object to the summary array
            $script:arySummary += $objLine
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


    #get size of initial result array
    [int]$intialResultSize = $($script:aryResults).count
    $resultCount = 0
    

    #step through each result
    for ($i = 0; $i -le $script:aryResults.count -1; $i++) {

        #Progress Bar
        $resultCount = $resultCount +1
        $percentComplete = ($resultCount / $intialResultSize)*100
        Write-Progress -Activity "Tallying Outcomes (Step 3/4)" -Status "Working..." -PercentComplete ($percentComplete)

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
    foreach($resProp in  $script:aryResults[$i].psobject.Properties) {

        #if the property has the $node string in it, then it represents a node and needs to be tallied.  Other properties contain metadata.
        $nodeString = $delimiter + $node + "*"
        if($resProp.name -like $nodeString) {

            #use the value of the current node property to generate the name of the metadata property to be incremented.
            #then step through each property looking for the matching name and incriment it
            $tallyPropName = $delimiter + $($resProp.value) + $count + $delimiter
            foreach($tallyProp in  $script:aryResults[$i].psobject.Properties) {
                #if the name of the property matches the name of the face tally property increment it by 1
                if($tallyProp.name -eq $tallyPropName) {
                    $tallyProp.value = $tallyProp.value +1
                }
            }
            
            #Determine if their are any lesser values that should also be incremented.
            #A value is considered 'lesser' if it is earlier (a lower index number) in the faces array and has a 
            #different value. For example if die is entered into the array as 'A','2','*','*','4' then A and 2 are
            #considered lesser than * and if a '*' is on a node then 'A'  and '2' should also be incremented; 
            #'4' would not and '*' would not be incrmented a second time no.

            #find the faces index in the unique faces array.
            $index = -1
            
            #step through each unique face until a match is found and get the index of the matching unique face.
            for ($j = 0;$j -lt $($script:aryuniqueFaces).count; $j++) {
                $uniqueFace = $script:aryuniqueFaces[$j]
                if($uniqueFace -eq $resProp.value) {
                    $index = $j
                    $j = $($script:aryuniqueFaces).count
                }                
            }



            #step through the unique faces array and incriment the or better meta data properites of the result for all faces
            #from 0 to that index value.
            if ($index -ge 0) {
                #step through the unique face name array generating the names of the 'or better" properties to incriment"
                for ($k = 0;$k -le $index; $k++) {

                    $propNameToIncriment = $delimiter+ $script:aryuniqueFaces[$k] +$orBetterCount  + $delimiter
                    #step through each propery in the current result
                    foreach($orBetterProp in $script:aryResults[$i].psobject.Properties) {
                        if($propNameToIncriment -eq $($orBetterProp.name)) {
                            $orBetterProp.value = $orBetterProp.value + 1
                        }
                    }
                }
            }#End IF
        }
    }
}



######################################################################
## Tally-SummaryTable
######################################################################

function Tally-SummaryTable {


    #get size of initial result array
    [int]$intialResultSize = $($script:aryResults).count
    $resultCount = 0
    

    #step through each result in the result array
    foreach ($result in $aryResults) {

        
        #status bar
        $resultCount = $resultCount + 1
        $percentComplete = ($resultCount / $intialResultSize)*100
        Write-Progress -Activity "Summarizing Outcomes (Step 4/4)" -Status "Working..." -PercentComplete ($percentComplete)
        
        
        
        #step through each property in each result
        foreach($prop in $result.psobject.Properties) {

            #if the value of the property is greather than 0 check to see if is is a tally
            if($prop.value -gt 0) {
                #if the property name contains $count then it is the tally of a face for that result
                if($prop.name -like $("*" + $count + $delimiter + "*") ) {
                    #Tally the COUNT properties in the Summary table
                    #get the face the tally is for
                    $FaceName = [string]$($prop.name).replace($count,"")
                    #get the number of times the face occured in this result
                    $FaceCount = $prop.value
                    #get the name of the tally in the summary table to be incremented
                    $TallyName = $delimiter + [string]$FaceCount + $occurance + $delimiter
                    Increment-SummaryTable $FaceName $TallyName
                } #END of if($prop.value -gt 0)

                if($prop.name -like $("*" + $orBetterCount + $delimiter + "*") ) {
                    #Tally the OR_BETTER properties in the Summary table
                    #get the face the tally is for
                    $FaceName = [string]$($prop.name).replace($orBetterCount,"")
                    #get the number of times the face occured in this result
                    $FaceCount = $prop.value
                    #incriment the Or Better counter for the current face and all lesser faces
                    for($i = $FaceCount;$i -ge 1; $i--) {
                        #get the name of the tally in the summary table to be incremented
                        $TallyName = $delimiter + [string]$i + $orBetterOccurance + $delimiter
                        Increment-SummaryTable $FaceName $TallyName
                    }   
                } #END of if($prop.value -gt 0)
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
        [string]$TallyName           #The name of the tally to incriment
    )

    #the property conresponding to the number of occurances in the result
    #$PropOcc = $delimiter + [string]$occurances + $occurance + $delimiter

    #Step through each line of the summary array
    foreach ($line in $script:arySummary) {
        #check if this is the line for the matching face
        if($line.face -eq $FaceName) {
            #Step through each property in the line item
            foreach ($lineProp in $line.psobject.properties) {
                #If the Occurance count of the property matches then increment the summary count
                if($TallyName -eq $($lineProp.name)){
                    $lineProp.value = $lineProp.value +1
                }
            }
        }
    }
}


######################################################################
## Create a table containing a list of each unique face
######################################################################
function New-uniqueFacessTable {

    #step through each face in the faces array
    foreach($face in $script:aryFaces) {

        #step through each face in the unique faces array looking for a match
        $match = $false
        foreach($uniqueFace in $script:aryUniqueFaces) {
            if($face -eq $uniqueFace) {
                $match = $true
            }
        }
        #if there is no match add it to the unique faces array
        if(!$match){
            $script:aryUniqueFaces += $face
        }
    }
}




######################################################################
## Validate Input and Settings
## Checks for know issues with input and settings
######################################################################

function Validate-Settings {

    if($delimiter -eq "*") {
        $script:delimiter = "^"     
        write-host "Using * as a delimiter may cause parsing issues."     -ForegroundColor red
        write-host "Delimiter has been set to to: $script:delimiter"   

    }


    if($orBetterCount -like $("*" + $count + "*")) {
        $script:count = "Amount"     
        write-host "Having the Count string inside the orBetterCount string may cause parsing issues."   -ForegroundColor red
        write-host "Count has been set to to: $script:count"   



    }



}





######################################################################
## Display various tables to the screen for debugging purposes
######################################################################

function Display-ResultTable {
    Write-Host 
    Write-Host "Results Table" -ForegroundColor Green
    $aryResults | FT * 
}

function Display-FacesTable {
    Write-Host 
    Write-Host "Faces Table" -ForegroundColor Green
    $aryFaces | FT * 
}

function Display-UniqueFacesTable {
    Write-Host 
    Write-Host "Unique Faces Table" -ForegroundColor Green
    $aryUniqueFaces | FT * 
}

function Display-SummaryTable {
    Write-Host 
    Write-Host "Summary Table" -ForegroundColor Green
    $arySummary | FT * 

}


function Display-ScenarioData {
    Write-Host 
    Write-Host "Scenario Data" -ForegroundColor Green
    Write-Host " Nodes:   $NodeCount" 
    Write-Host " Faces:   $($($script:aryFaces).count)"
    Write-Host " Results: $($($script:aryResults).count)"
    
}



######################################################################
## Main
######################################################################


#Check for know issue with input and settings
Validate-Settings

#Creates an array listing each face once in same order as the faces array.
New-uniqueFacessTable


#Create the table to store the summarized totals for each face
New-SummaryTable

#Create the table of all possible results
New-ResultTable -NodeCount $NodeCount

#Add metadata properties to each result.  These poperties will hold sumarization data (e.g. highest face) about the result.
Add-ResultMetaProperties

#Count the occurances of each face in each result and record the totals in the metadata properties of each result object in the table.
Tally-ResultTableMetaData

#Count the occurance of each face quantitn in each result and summarize the totals in the Summary table.
Tally-SummaryTable

#Display-ResultTable
Display-ScenarioData
Display-SummaryTable
#Display-FacesTable
#Display-UniqueFacesTable






