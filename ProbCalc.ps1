


<#
    .SYNOPSIS
        Calculates the percentage chance of outcomes for die rolls, card draws, etc.

    .DESCRIPTION
        Terms
        Restult - All of the values, faces, etc. of a single instance of the scenario. (e.g. flipping three cards and getting 2 
            'threes' and 1 'queen'; or rolling a die and getting a '6')
        Face - Each of the possible results of a node.  (e.g a 'three' on a die, or a 'queen' on a playing card)
        Value - The unit of a restult.  (e.g. if a result had 3 'hits' and 2 'crits' the values would be 'hit' and 'crit')
        Occurnace - How many times a Face or Value is present in a Restult.  (e.g. if a Result gives: 'Crit', 'Hit' and 'Hit&Hit' the
            Face Tallies would be 1 'Crit', 1 'Hit' and 1 'Hit&Hit'.  The Value Tallies would be 1 'Crit', 3 'Hit').  Sometimes
            the script will refer to 'an occurance', this refers to a face or value occurring X times. (e.g. Tally the number of times
            an occurnace (3 Aces) occured in the Restult.)
        Tally - How many times a Face or Value/Occuance combo happens in a secnario.  (e.g. when rolling 2d6 there two different possible
            outcomes (5+6 and 6+5) where there is an occurnace of 11.  To that Tally would be 2.)
        Node - A single randomizaion element (e.g. one die, one card, onc coin, etc.)
        Scenario - The parameters to be tested, including every possible restult/  (e.g. the odds of rolling 2,3,4...11,12 on 2 six-sided dice)



        
        
    
    .PARAMETER Nodes
    
    
    
    .EXAMPLE
        
    

    .INPUTS

    .OUTPUTS

    .NOTES 
        Author: Robert Zimmerman
        Updated: Feb 2018

        To Do:
            Add Calcualted restuls for Exhausing faces, "Or Better", Sums, Highest/Lowest
            Add Rolling differing dice (e.g. Fallout colored dice)
            Add Compound faces (e.g. dice with 1 hit and 2 hit faces)
            Add Rerolls
            Add CSV Export




    .LINK
        
#> 




param(
    #Nodes
    [int]$XWingAtt,              #Use XWing attack dice are being used 
    [int]$XWingDef,              #Use XWing defence dice are being used 
    [int]$SWLDefWhite,             #Use Star Wars Legion White 6 Sided die
    [int]$SWLDefRed,               #Use Star Wars Legion Red 6 Sided die
    [int]$SWLAttWhite,             #Use Star Wars Legion White 8 Sided die
    [int]$SWLAttRed,               #Use Star Wars Legion Red 8 Sided die
    [int]$SWLAttBlack,             #Use Star Wars Legion Black 8 Sided die
    [int]$d4,                    #Use a d4 (1,2,3,4)
    [int]$d6,                    #Use a d4 (1,2,3,4,5,6)
    [int]$d8,                    #Use a d4 (1,2,3,4,5,6,7,8)
    [int]$d10,                   #Use a d4 (1,2,3,4,5,6,7,8,9,10)
    [int]$d12,                   #Use a d4 (1,2,3,4,5,6,7,8,9,10,11,12)
    [int]$d20,                   #Use a d4 (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20)
    [int]$dx,                    #Use a test die
    [int]$Coin,                  #Use a coin (Heads,Tails)
    [int]$MalifauxSuited,        #Use an exhausting deck of cards and malifaux joker logic
    [int]$MalifauxUnsuited,      #Use an exhausting deck of cards, where the suits do not matter and malifaux joker logic
    #Options
    [switch]$DicePool,           #True if each node has exactly one result and is unchangable (e.g. like rolling a group of dice)
    [switch]$DrawPool,           #True if each 'node' forms a single pool the yeilds one result (e.g. like putting differcont collored rocks in a bag)
    [switch]$NoReplacement,      #True if faces are unique and cannot restult twice (e.g. removing the 3 of hearts from a deck after it is drawn)
                                 #only valid with DrawPools
    [switch]$MalifauxJokers,        #True if Malfiaux joker logic should be applied
    [switch]$ShowSums,              #Show the probability of sums occuring for numeric nodes (e.g. rolling 9 an 2d6)
    [switch]$ShowExacts,            #Show the probability of an exact value occuring (e.g. getting one 5 on 2d6)
    [switch]$ShowOrBetter,          #Show the probability of a value or better occuring (e.g. getting one 5+ on 2d6)
    [switch]$ShowHighLow,           #Show the probability of a value being the highest or lowest value (e.g. a 5 being the lowst value 2d6)
    [switch]$ShowActualFaces,       #Show the probability of a face occuring
    [switch]$ShowAllTables,         #Shows all tables
    #Debug
    [int]$Test,                     #Test Data
    [switch]$ShowDebug              #if true debuging data will be displayed when the script executes.
)


#Arrays
$aryFaces = @()               #This array holds the value on each face of each node
$aryNodes = @()               #An array of node arrays.  Each element of this array is an array of the faced on that node.
$aryUniqueFaces = @()         #This array is a list of the unique faces on each node
$aryUniqueValues = @()        #This array is a list of the unique values on all the faces of all nodes. 
                              #  A muti-value faces count as having two unique values. E.g. Hit&Crit counts as Hit and Crit, NOT as Hit&Crit
$aryResult = @()              #This array is the current result

#Below are the summary arrays.  
#They tally how many times a given result occurs in the scenario. When creating these arrays the script will how many rows and columns the
#table will need and crate a static array to hold all the tally data.
#I used static arrays because powershell handles dynamic arrays poorly. When adding #a row or column to an array, powershell copies the 
#existing array to a new array and adds the new row or column. For performance reasons I create a static array large enough for all possible 
#results.  

#This means there may be extra rows.  E.g. when rolling a die with 2,4,6 as the faces #it is impossible to roll an odd number.  The arrays 
#will have space for the impossible results. It is faster to create a wasteful array than to calculate all possible results and dynamically 
#create the array.

#Rows with 0 results will not be displayed.

#This is a list of the summary tables that will be created.  BF stands for Brute Force
#Calc stands for calculated.

#$aryBFAcutalFacesTable = @()       #Probabiilty of the acutal face (as opposed to the value of the face) of the node will appear.
#$aryBFExactlyXTable = @()          #Probability of a face or value occurning exactly X times (e.g. rolling exaclty two 5's)
#$aryBFExactXOrMoreTable = @()      #Probablyily of a face or value occurning exactly X or more times (e.g. rolling two or more 5's)
#$aryBFOrBetterTable = @()          #Probability of a face or value or a better result occurning (e.g. rolling two or more 5+'s) 

#$aryCalcExactlyXTable = @()        #These tables are exaclty the same as those above except they are calculated rather than brute force
#$aryCalcExactXOrMoreTable = @()    #
#$aryCalcOrBetterTable = @()        #

#$aryHighLowTable = @()             #Proability of a face being the highest/lowest face in a result.
#$arySumsTable = @()                #Proability of various results for numeric results like (rolling 5, 5 or more, 5 or less on 3d6)

#Variables
$resultID = -1                  #The current result
$restultSizeToReplaceNodCnt = 0                #How many faces will be in each result
$nodeCount = 0
$sumsWidth = 1                  #default value will be reset if numeric dice are used
$maxValueOccCount = 0           #The greatest number of times a value can occur (e.g. with nodes a,b,c and a,b&b,c it would be 3 since b can occure three times)
$systemNote = ""                #Note do display with secenario summary
$nodeDelimiter = "&"            #Delimits values on a a multi-value face (e.g. Hit&Hit for a face with two Hit restults)
$showProcessing = $false        #True if processing info should be displayed to the screen
$projectedResultCount = 0             #Estimate of how many possible results there will be


#Process System Switches
#sytems are like macros.  They contain the options, like using numeric dice or malifax jokers
#and the faces of the nodes.


#default to using dice pool mechanics
$DicePool = $true



#XWing
for($i = 1; $i -le $XWingAtt; $i++){
    $aryNodes += ,@("Blank","Blank","Focus","Focus","Hit","Hit","Hit","Crit")
    $ShowActualFaces = $true
}
for($i = 1; $i -le $XWingDef; $i++){
    $aryNodes += ,@("Blank","Blank","Blank","Focus","Focus","Evade","Evade","Evade")
    $ShowActualFaces = $true
}


#Star Wars Legacy
for($i = 1; $i -le $SWLDefWhite; $i++){
    $aryNodes += ,@("Blank","Blank","Blank","Blank","Surge","Block")
    $ShowActualFaces = $true
}
for($i = 1; $i -le $SWLDefRed; $i++){
    $aryNodes += ,@("Blank","Blank","Surge","Block","Block","Block")
    $ShowActualFaces = $true
}
for($i = 1; $i -le $SWLAttWhite; $i++){
    $aryNodes += ,@("Blank","Blank","Blank","Blank","Blank","Surge","Hit","Crit")
    $ShowActualFaces = $true
}
for($i = 1; $i -le $SWLAttBlack; $i++){
    $aryNodes += ,@("Blank","Blank","Blank","Surge","Hit","Hit","Hit","Crit")
    $ShowActualFaces = $true
}
for($i = 1; $i -le $SWLAttRed; $i++){
    $aryNodes += ,@("Blank","Surge","Hit","Hit","Hit","Hit","Hit","Crit")
    $ShowActualFaces = $true
}

#Numeric Dice
for($i = 1; $i -le $d4; $i++){
    $aryNodes += ,@(1,2,3,4)
    $ShowSums = $true
    $ShowOrBetter = $true
}
for($i = 1; $i -le $d6; $i++){
    $aryNodes += ,@(1,2,3,4,5,6)
    $ShowSums = $true
    $ShowOrBetter = $true
}
for($i = 1; $i -le $d8; $i++){
    $aryNodes += ,@(1,2,3,4,5,6,7,8)
    $ShowSums = $true
    $ShowOrBetter = $true
}
for($i = 1; $i -le $d10; $i++){
    $aryNodes += ,@(1,2,3,4,5,6,7,8,9,10)
    $ShowSums = $true
    $ShowOrBetter = $true
}
for($i = 1; $i -le $d12; $i++){
    $aryNodes += ,@(1,2,3,4,5,6,7,8,9,10,11,12)
    $ShowSums = $true
    $ShowOrBetter = $true
}
for($i = 1; $i -le $d20; $i++){
    $aryNodes += ,@(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20)
    $ShowSums = $true
    $ShowOrBetter = $true
}
for($i = 1; $i -le $dx; $i++){
    $aryNodes += ,@(1,3,5,7,9,10,11)
    $ShowSums = $true
    $ShowOrBetter = $true
}


#Coins
for($i = 1; $i -le $Coin; $i++){
    $aryNodes += ,@("Heads","Tails")
    $ShowExacts = $true
}

#Test 
for($i = 1; $i -le $Test; $i++){
    $aryNodes += ,@("Piggy","Blank","Blank&Blank&Blank","Focus&Blank","Focus","Other","Hit","Hit","Crit")
    $ShowActualFaces = $true
}


#Decks of Cards
if($MalifauxUnsuited -gt 0) {
    $systemName = "Malifaux Unsuited Cards"
    $NoReplacement=$true
    $MalifauxJokers=$true
    $aryFaces = @("BJ","1","1","1","1","2","2","2","2","3","3","3","3","4","4","4","4",`
                  "5","5","5","5","6","6","6","6","7","7","7","7","8","8","8","8","9","9","9","9", `
                  "10","10","10","10","11","11","11","11","12","12","12","12","13","13","13","13","RJ")
    $aryNodes = @()
    $aryNodes += ,$aryFaces
    $DicePool = $false
    $DrawPool = $true
    $ShowHighLow = $true
}elseif($MalifauxSuited -gt 0) {
    $systemName = "Malifaux Sited Cards"
    $systemNote = "WS (Wrong Suit) is any card that is not of the desired suit."
    $NoReplacement=$true
    $MalifauxJokers=$true
    $aryFaces = @()
    for($i = 1; $i -le 39; $i++) {
        $aryFaces += "WS"
    }
    $aryFaces += @("BJ","1","2","3","4","5","6","7","8","9","10","11","12","13","RJ")
    $aryNodes = @()
    $aryNodes += ,$aryFaces
    $DicePool = $false
    $DrawPool = $true
    $ShowHighLow = $true
}





foreach($Node in $aryNodes) {
    write-host $node -ForegroundColor blue
}
Write-Host "Node Count: $($aryNodes.Count)" -ForegroundColor Blue



$ShowExacts = $true
$ShowActualFaces = $true





##################################################################################################
# Setup Functions
#   Initialize variables, create arrays, etc...
##################################################################################################

##################################################################################################
# Initializes the result array giving it the proper number of elements
function Create-RestultArray {
    
    if($showProcessing) {write-host "  Create-RestultArray" -ForegroundColor green }

    for($i = 1; $i -le $script:nodeCount; $i++) {
        $script:aryResult += "empty"
    }
}





##################################################################################################
## Create a table containing a list of each unique face on all nodes.
## This table lists each face once regardless of how many times it appears on the nodes.
## For example if the faces are: Hit, Hit, Hit&Hit, Hit&Hit, and Crit this array will contain Hit, Hit&Hit and Crit. 
function Create-UniqueFacesTable {

    
    if($showProcessing) {write-host "  Create-UniqueFacesTable" -ForegroundColor green }

    #step through each node then thorugh each face on that node
    foreach($node in $aryNodes) {
        foreach($face in $node) {

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


    #for debugging write out all the values in the unique value array
    if($showProcessing) {
        write-host "    Unique Faces Array" -ForegroundColor Yellow
        foreach ($face in $script:aryUniqueFaces) {
            write-host "      $face "
        }
    }
}


##################################################################################################
## Create a table containing a list of each unique value on all faces of all nodes.
## This table lists each value once regardless of how many times it appears on nodes and faces.
## For example if the faces are: Hit, Hit&Hit, Hit&Hit&Hit, Hit&Crit and Crit this array will contain Hit and Crit. 
function Create-UniqueValuesTable {
    

    if($showProcessing) {write-host "  `nCreate-UniqueValuesTable" -ForegroundColor green }

    #step through each face in the faces array
    if($showProcessing) {Write-Host "  Unique Faces to Process" -ForegroundColor Yellow}
    foreach($face in $script:aryUniqueFaces) {
        if($showProcessing) {Write-Host "    $face" }

        #break the face into individual values and step through each value
        if(isNumeric $face) {
            $faceValues = $face
        }else{
            $faceValues = $face.split("{$nodeDelimiter}")
        }
        foreach($value in $faceValues) {

            #step through each face in the unique faces array looking for a match
            $match = $false
            foreach($uniqueFace in $script:aryUniqueValues) {
                if($value -eq $uniqueFace) {
                    $match = $true
                }
            }
            #if there is no match add it to the unique faces array
            if(!$match){
                $script:aryUniqueValues += $value
            }
        }
    }

    #for debugging write out all the values in the unique value array
    if($showProcessing) {
        write-host "`n  Unique Values Array" -ForegroundColor Yellow
        foreach ($value in $script:aryUniqueValues) {
            write-host "    $value "
        }
    }
}



##################################################################################################
#calculates how many faces will be in each result.
#E.g. if five dice are rolled there will be five faces in each result, if four cards are drawn there will be four faces in each result
#xxxx Need to move to a script varaible insteast of $script:nodeCount
function Caclulate-NodeCount {

    if($DicePool){
        $script:nodeCount = $script:aryNodes.Count
    }elseif($DrawPool){
        $script:nodeCount = 0
    }else{
        $script:nodeCount = 0
    }

    write-host "NodeCount: $script:nodeCount" -ForegroundColor Cyan

}

##################################################################################################
# Calcluate how many 
function Caclulate-ProjectedResultCount {

    if($DicePool) {
        $script:projectedResultCount = 1
        foreach($node in $script:aryNodes){
            $faceCount = $node.Count
            $script:projectedResultCount = $script:projectedResultCount * $faceCount
        }
    }elseif($DrawPool){
        $script:projectedResultCount = 0
    }


}


##################################################################################################
#Calculates the maximum number of times any one result can appear.
#E.g. if the nodes are A,B,C and AA,A,A then A can appear up to 3 times, B and C can appear up to
#1 time each, so would return 3.

function Caclulate-HighestPossibleOccurance {

    #$showProcessing = $true
    if($showProcessing) {write-host "  `nCaclulate-HighestPossibleOccurance" -ForegroundColor green }

    #the highest number of occurnaces for any value
    $highestTotalOccCount = 0

    #step through each unique value
    if($showProcessing) {write-host "    Unique Values to process" -ForegroundColor green }
    foreach ($uniqueValue in $script:aryUniqueValues) {
        if($showProcessing) {write-host "      Matching Against: $uniqueValue " -ForegroundColor blue}
        $totalOccCount = 0

        #Step through each node
        foreach($node in $script:aryNodes) {
            $highestOccCount = 0
            foreach($face in $node) {
                $OccCount = 0

                #break the face into individual values and step through each value
                if(isNumeric $face) {
                    $values = $face
                }else{
                    $values = $face.split("{$nodeDelimiter}")
                }
                #Step through each value on the face.  If it matches incriment the value count.
                foreach($value in $values){
                    if($value -eq $uniqueValue){
                        $OccCount = $OccCount +1
                        if($showProcessing) {write-host "        $uniqueValue  = $value  Occ Count = $OccCount   [Face: $face]    Node: $node" -ForegroundColor green}
                    } else {
                        if($showProcessing) {write-host "        $uniqueValue != $value  Occ Count = $OccCount   [Face: $face]    Node: $node" -ForegroundColor Red}
                    }
                }
                #if this is the face with the greatest count for the current value then track it.
                if($OccCount -gt $highestOccCount) {
                    $highestOccCount = $OccCount
                }
            }#end Face foreach

            #Add the highest possible occ count for this face to the highest occ count for this node.
            $totalOccCount = $totalOccCount + $highestOccCount 
            if($showProcessing) {write-host "        Most $uniqueValue/Face on this node = $highestOccCount  " -ForegroundColor yellow}

            #if this value has more possible occurnaces than any other then use its value
            if($totalOccCount -gt $highestTotalOccCount){
                $highestTotalOccCount = $totalOccCount
            }
        } #end node Foreach


        if($showProcessing) {write-host "          Highest Possible Number of $uniqueValue = $totalOccCount" }

    }#end uniqueValue foreach
    $script:maxValueOccCount = $highestTotalOccCount
    if($showProcessing) {write-host "            Highest Possible Number of any value = $highestTotalOccCount" }
}



##################################################################################################
#Calculates the maximum number of times any one result can appear.
#E.g. if the nodes are A,B,C and AA,A,A then A can appear up to 3 times, B and C can appear up to
#1 time each, so would return 3.

function OLDCaclulate-HighestPossibleOccurance {

    $showProcessing = $true
    if($showProcessing) {write-host "  `nCaclulate-HighestPossibleOccurance" -ForegroundColor green }
    $totalOccCount = 0

    #step through each unique value
    if($showProcessing) {write-host "    Unique Values to process" -ForegroundColor green }
    foreach ($uniqueValue in $script:aryUniqueValues) {
        if($showProcessing) {write-host "      Matching Against: $uniqueValue " -ForegroundColor blue}
        $occCount = 0

        #Step through each node
        foreach($node in $script:aryNodes) {
            $highestOccCountPerFace = 0
            foreach($face in $node) {

                #break the face into individual values and step through each value
                if(isNumeric $face) {
                    $values = $face
                }else{
                    $values = $face.split("{$nodeDelimiter}")
                }
                foreach($value in $values){
                    if($value -eq $uniqueValue){
                        $occCount ++
                        if($showProcessing) {write-host "        $uniqueValue  = $value  Occ Count = $occCount   [Face: $face]    Node: $node" -ForegroundColor green}
                    } else {
                        if($showProcessing) {write-host "        $uniqueValue != $value  Occ Count = $occCount   [Face: $face]    Node: $node" -ForegroundColor Red}

                    }

                    if($occCount -gt $highestOccCountPerFace) {
                        $highestOccCountPerFace =  $occCount
                    }
    
                }



            }#end Face foreach
            #Add the occ count for the face on this node with the most occurnaces
            $totalOccCount = $occCount
            if($showProcessing) {write-host "          $uniqueValue count: $occCount / highest count: $totalOccCount" }

        } #end node Foreach

    }#end uniqueValue foreach
    $script:maxValueOccCount = $totalOccCount
}




    
##################################################################################################
# Create summary tables for tallying results by the number of occurances.  (e.g. how many times 
# do 3 aces appear in the result set.)
# Vetted 1.0
function Create-OccuranceSummaryTables {

    if($showProcessing) {write-host "  Create-OccuranceSummaryTables" -ForegroundColor green }
    
    #Create one row for each unique value in the node pool.
    $rowCount = $script:aryUniqueValues.count

    #Create a column for the value name, and for each value from 0 to the highest possible occurance of any value.
    $colCount = $script:maxValueOccCount + 2

    #Create the Brute Force arrays.
    $script:aryBFExactlyXTable = New-Object 'object[,]' $rowCount,$colCount
    $script:aryBFOrBetterTable = New-Object 'object[,]' $rowCount,$colCount
    $script:aryBFExactXOrMoreTable = New-Object 'object[,]' $rowCount,$colCount

    #Create the Calcuated arrays.
    $script:aryCalcExactlyXTable = New-Object 'object[,]' $rowCount,$colCount
    $script:aryCalcExactXOrMoreTable = New-Object 'object[,]' $rowCount,$colCount
    $script:aryCalcOrBetterTable = New-Object 'object[,]' $rowCount,$colCount

    #put the face name in the 0 element in the array
    for($row = 0; $row -lt ($script:aryUniqueValues).count; $row++) {
        $aryBFExactlyXTable[$row,0] = $script:aryUniqueValues[$row]
        $aryCalcExactlyXTable[$row,0] = $script:aryUniqueValues[$row]
        $aryCalcExactXOrMoreTable[$row,0] = $script:aryUniqueValues[$row]
        $aryBFOrBetterTable[$row,0] = $script:aryUniqueValues[$row]
        $aryCalcOrBetterTable[$row,0] = $script:aryUniqueValues[$row]
        $aryBFExactXOrMoreTable[$row,0] = $script:aryUniqueValues[$row]
        #zero the rest of the values in the arrays
        for($col = 1; $col -lt $colCount; $col++) {
            $aryBFExactlyXTable[$row,$col] = 0
            $aryCalcExactlyXTable[$row,$col] = 0
            $aryCalcExactXOrMoreTable[$row,$col] = 0
            $aryBFOrBetterTable[$row,$col] = 0
            $aryCalcOrBetterTable[$row,$col] = 0
            $aryBFExactXOrMoreTable[$row,$col] = 0
        }
    }
}



    
##################################################################################################
# Create summary tables for tallying how many times a face appears in a result.  (e.g. If rolling 
# a die with faces: 'Blank', 'Hit', 'Hit&Hit', 'Crit' this table would show how many results had
# 1 "Blank"; 2 'Blank's; 1 'Hit'; 2 'Hit's; 1 'Hit&Hit', etc...).  Note a 'Hit&Hit' is not two 
# 'Hit's, they are seperate for the purposes of this table.
# Vetted 1.0
function Create-AcutalFacesSummaryTables {

    if($showProcessing) {write-host "  Create-AcutalFacesSummaryTables" -ForegroundColor green }

    #Create one row for each unique Face in the node pool.
    $rowCount = $script:aryUniqueFaces.count

    #Create a column for the value name, for 0, and each node in the node pool.
    $colCount = $script:NodeCount + 2
        
    #creat the table
    $script:aryBFAcutalFacesTable = New-Object 'object[,]' $rowCount,$colCount

    #put the face name in the 0 element in the array
    for($row = 0; $row -lt $rowCount; $row++) {
        $aryBFAcutalFacesTable[$row,0] = $script:aryUniqueFaces[$row]
        #zero the rest of the values in the arrays
        for($col = 1; $col -lt $colCount; $col++) {
            $aryBFAcutalFacesTable[$row,$col] = 0
        }
    }
}




    
##################################################################################################
## Create summary tables for counting occurnaces.
function Create-HighLowSummaryTable {

    if($showProcessing) {write-host "  Create-HighLowSummaryTable" -ForegroundColor green }

    #get row and column sizes
    $rowCount = $($script:aryUniqueValues).count

    #the columns
    $script:highLowColName = 0
    $script:highLowColLowestBF = 1
    $script:highLowColLowestCalc = 2
    $script:highLowColHighestBF = 3
    $script:highLowColHighestCalc = 4
    $script:highLowWidth = 5
    
    #creat the Exact and OrBetter summary arrays
    $script:aryHighLowTable = New-Object 'object[,]' $rowCount,$script:highLowWidth
    
    #put the face name in the 0 element in the array
    for($row = 0; $row -lt ($script:aryUniqueValues).count; $row++) {
        $aryHighLowTable[$row,$script:highLowColName] = $script:aryUniqueValues[$row]
        $aryHighLowTable[$row,$script:highLowColLowestBF] = 0
        $aryHighLowTable[$row,$script:highLowColLowestCalc] = 0
        $aryHighLowTable[$row,$script:highLowColHighestBF] = 0
        $aryHighLowTable[$row,$script:highLowColHighestCalc] = 0
    }
}








##################################################################################################
#
function Create-MathSummaryTable {
    
    
    if($showProcessing) {write-host "  Create-MathSummaryTable" -ForegroundColor green }
    
    #find highest and lowest numeric value on a face
    [int]$highestFace = $script:aryUniqueValues[0]
    [int]$LowestFace = $script:aryUniqueValues[0]
    foreach($face in $script:aryUniqueValues) {
        if([int]$face -gt $highestFace) { $highestFace = [int]$face }
        if([int]$face -lt $LowestFace) {$LowestFace = [int]$face }
    }

    #found the highest and lowest possible sums
    [int]$highestSum = $script:nodeCount * $highestFace
    [int]$script:lowestTotal = $script:nodeCount * $LowestFace
    
    #the columns
    $script:sumsColName = 0
    $script:sumsColExactBF = 1
    $script:sumsColExactCalc = 2
    $script:sumsColOrMoreBF = 3
    $script:sumsColOrMoreCalc = 4
    $script:sumsColOrLessBF = 5
    $script:sumsColOrLessCalc = 6
    $script:sumsWidth = 7

    #create the table
    $script:arySumsTable = New-Object 'object[,]' $($highestSum +1),$script:sumsWidth
    
    #fill arrays with initial values
    $aryCount = $($script:arySumsTable).count / $script:sumsWidth
    
    for($row = 0; $row -lt $aryCount; $row++ ) {
        #column 0 is the "sum name" e.g. the total of all faces
        $script:arySumsTable[$row,$script:sumsColName] = $row
        for($col = 1; $col -lt $script:sumsWidth; $col++) {
            #The rest of the colums count occurnaces and will be set to 0
            $script:arySumsTable[$row,$col] = 0
        }
    }
}


##################################################################################################
# Calcuations functions
##################################################################################################

#Calculate the chances of each possible result using math
function Calculate-TheoreticalResults {

    Calculate-ExactlyX
}


















##################################################################################################
# Calculate exaclty the probablity that each possible result will occur exactly x times, where
# x is 0 to the maximum number of times it can occur.
function Calculate-ExactlyX {

    foreach($face in $script:aryUniqueValues) {

        #Get node and face counts
        $matchingFaceCount =  Get-EqualToFaceCount -FaceName $face          #How many faces Match the current face
        $orBetterFaceCount = Get-EqualToOrGreaterThanFaceCount -FaceName $face -aryNode $script:aryFaces   #How many faces Match or are better than the current face
        $totalFaceCount =  $script:aryFaces.Count                    #How many faces the node has

        #Step through the node count, calculating the probabilty that the node will occure n times
        #where n is 0 to the number of possible nodes.
        #e.g. if there are three 6-sided dice loop thorough calculating the odds of rolling
        # zero 6's, one 6, two 6's, and three 6's.
        for($occCount = 0; $occCount -le $script:nodeCount; $occCount++) {
            #Do a combination calcuation for distribution of times the node occures exaclty k times
            $successChance = $matchingFaceCount / $totalFaceCount


            if ($NoReplacement) {
                #if there IS NO replacment (e.g. a deck of cards use Hypergeometric Distribution to calculate chance)
                if($occCount -gt $matchingFaceCount ) {
                    #if  we are looking for more occurance than there are instances (e.g. drawing 5 aces from standard deck) than there is 0% chance of that occuring
                    $ExacltyXChance = 0
                } else {
                    #use Hypergeometric Distribution
                    $ExacltyXChance = Calculate-HypergeometricDistribution -PopulationSize $totalFaceCount -SuccessStates $matchingFaceCount -Draws $script:nodeCount -ObservedSuccesses $occCount
                }
            } else {
                #if there IS replacment (e.g. dice  use Binomial Probabiliy Mass to calculate chance)
                $ExacltyXChance = Calculate-ProbabiliyMass -n $script:nodeCount -k $occCount -p $successChance
            }

            #write-host "$face - PopSize: $totalFaceCount / SucStates: $matchingFaceCount / Draws: $script:nodeCount / ObsSuc: $occCount / Chance: $ExacltyXChance" -ForegroundColor Yellow

            #write the chance to the summary table
            $row = Convert-FaceToUniqueValuesRow -value $face
            $col = $occCount +1
            $script:aryCalcExactlyXTable[$row,$col] = $ExacltyXChance
        }
    }
}




##################################################################################################
# Brute Force Processing functions
##################################################################################################





##################################################################################################
#Generate the rusults to analyze
#xxx
function Generate-BruteForceResult {

    #if there is no replacment then a single node is used and 
    if($DicePool) {

        Generate-BruteForceResultForDicePool

    }else{


    }





}


##################################################################################################
#Steps through the faces of each node generating every possible combination.  Then that
#combination is passed onto be analyzed.
#E.g. If the nodes are A,B,C and 1,2,3 Then A1, A2, A3, B1, B2, B3, C1, C2, C3 will be generated and
#analyzed
function Generate-BruteForceResultForDicePool {
    param(
        [int]$nodeNum = 0         #the current node
    )

    if($showProcessing) {write-host "  Generate-BruteForceResultForDicePool" -ForegroundColor green }

    $Node = $script:aryNodes[$nodeNum]
    foreach($face in $Node ) {
        $script:aryResult[$nodeNum] = $face

        if($nodeNum -lt $script:nodeCount -1) {
            $nextNode = $nodeNum +1
            Generate-BruteForceResultForDicePool $nextNode
        } else {
            $script:resultID = $script:resultID +1
            if($showProcessing) {write-host "    Result: $script:aryResult   Progress: $script:resultID / $script:projectedResultCount" -ForegroundColor yellow }
            Write-Progress -Activity "Generating Results" -status "Result $script:resultID of $script:projectedResultCount" -percentComplete ($script:resultID / $script:projectedResultCount * 100)
            Analyze-Result
        }
    }
}



##################################################################################################
#Looks at the current result and writes data to the summary tables

function Analyze-Result {

    if($showProcessing) {write-host ""}


    #Display-CurrentRestult


    if($ShowAllTables -or $ShowExacts)       {Analyze-ResultForExactlyX}
    #if($ShowAllTables -or $ShowActualFaces)  {Analyze-ResultActualFaces}
    #if($ShowAllTables -or $ShowOrBetter)  {Analyze-ResultForXOrBetter}
    #if($ShowAllTables -or $ShowHighLow)   {Analyze-ResultForHighAndLowFace}
    #if($ShowSums)      {Analyze-ResultForMathValues}
}

##################################################################################################
#Creates secondary summary tables
#e.g. Tallies the ExactXOrMoreTable from ExactlyXTable 
#
function Tally-SummaryTables{
    if($ShowAllTables -or $ShowExacts)    {Tally-ExactXOrMoreTable}
    if($ShowAllTables -or $ShowOrBetter)  {Tally-OrBetterTable}
    if($ShowAllTables -or $ShowHighLow)   {}
    if($ShowSums) {
        Tally-SumOrMoreColumn
        Tally-SumOrLessColumn
    }
}





##################################################################################################
function Analyze-ResultForMathValues {

    if($showProcessing) {write-host "  Analyze-ResultForMathValues" -ForegroundColor green }

    #tally the total of all nodes
    $total = 0
    foreach ($node in $script:aryResult) {
        $total = $total + [int]$node
    }

    #incriment the Exact value array
    $script:arySumsTable[$total,$script:sumsColExactBF] = $script:arySumsTable[$total,$script:sumsColExactBF] +1
    $script:arySumsTable[$total,$script:sumsColOrMoreBF] = $script:arySumsTable[$total,$script:sumsColOrMoreBF] +1
    $script:arySumsTable[$total,$script:sumsColOrLessBF] = $script:arySumsTable[$total,$script:sumsColOrLessBF] +1
}





##################################################################################################
# Counts up the number of times each Face (not value) Occurs and writes that data to the summary tables.
# E.g. If 'Hit', 'Hit&Hit', 'Crit' and 'Crit' appeared in the restult this function would write
# 1 Hit, 1 'Hit&Hit' and 2 'Crit' results to the Actual Faces table.
#vetted 1.0

function Analyze-ResultActualFaces {

    if($showProcessing) {write-host "  Analyze-ResultActualFaces" -ForegroundColor green }
    if($showProcessing) {write-host "    $script:aryResult"  -ForegroundColor yellow }

    #Step through each face in the unique faces array
    foreach($uniqueFace in $script:aryUniqueFaces) {        
        #Initialize the Occurance counter to 0 for this Face
        $occCount = 0
        #step through each face in the result
        
        foreach($face in $script:aryResult) {
            if ($uniqueFace -eq $face) {
                #if the restult's face matches the current face incriment the counter
                $occCount++
            }
        }
        if($showProcessing) {write-host "    $uniqueFace : $occCount" }
        Incriment-SummaryArray -Face $uniqueFace -OccCount $occCount -ActualFaces
    }
}





##################################################################################################
#Looks at the current result and incriments the occurance table by 1 for the exaclt number
#of times each value occurs (including 0). For example if the result is (Hit, Hit&Hit and Crit)
#The Exacty value table will be incremented by 1 for: 0 Blanks, 3 Hits and 1 Crit.

function Analyze-ResultForExactlyX {

    if($showProcessing) {write-host "  Analyze-ResultForExactlyX" -ForegroundColor green }
    
    #Step through each possible value
    foreach ($value in $script:aryUniqueValues){
        if($showProcessing) {
            write-host "" 
            Display-CurrentRestult
        }
        $tally = 0
        #step through each node of the result
        foreach ($node in $script:aryResult) {
            #step through each value on the face of the node
            $faceValueList = $node.split("{$nodeDelimiter}")
            foreach($faceValue in $faceValueList) {
                if($faceValue -eq $value) {
                    #if there is a match incriment the count for that value
                    $tally++
                    if($showProcessing) {write-host "    Incriment:  $faceValue = $value" -ForegroundColor green}
                }else{
                    if($showProcessing) {write-host "    No Match:   $faceValue != $value" -ForegroundColor red}
                }
            }
        }
        #update the exact occurnace array
        #This is run for every value.  Even if there are 0 instances of that value present that is counted in the exact occurnaces array.
        if($showProcessing) {
            write-host "    $value occ: $tally" -ForegroundColor green 
        }

        Incriment-SummaryArray -Value $value -OccCount $tally -ExactlyX
    }
}





##################################################################################################
#Looks at the current result and writes data to the 'X or better' table
#This is the first step in the table the coumns need to be summed for
#that data to be meaniningful
function Analyze-ResultForHighAndLowFace {

    if($showProcessing) {write-host "  Analyze-ResultForXOrBetter" -ForegroundColor green }



    #Create a copy of the current result and convert the faces to numbers
    $aryResultAsRows = @()
    for($i = 0; $i -lt $script:aryResult.count; $i++) {
        $row = Convert-FaceToUniqueValuesRow -value $script:aryResult[$i]
        $aryResultAsRows += $row
    }

    #sort the array so lowest result is first
    $aryResultAsRowsSorted = $aryResultAsRows | Sort-Object 
    #the number of columns in the result
    $colCount = $aryResultAsRowsSorted.count

    #If Malifaux Jokers are in effect then proccess
    if($MalifauxJokers) {
        #check to see if there are any black jokers
        #if so both highest and lowest result is a black joker
        for($i = 0; $i -lt $script:aryResult.count; $i++) {
            #write-host "$($script:aryResult[$i])" -ForegroundColor red
            if($($script:aryResult[$i]) -eq "BJ") {
                Incriment-SummaryArray -Value "BJ"  -LowFace -BruteForce
                Incriment-SummaryArray -Value "BJ"  -HighFace -BruteForce
                return
                #return both high and lowest cards are BJ so no need to continue
            }
        }
        #if there are no black jokers then 
        #check to see if there are any red jokers
        #if so both highest and lowest result is a red joker
        for($i = 0; $i -lt $script:aryResult.count; $i++) {
            #write-host "$($script:aryResult[$i])" -ForegroundColor red
            if($($script:aryResult[$i]) -eq "RJ") {
                Incriment-SummaryArray -Value "RJ" -LowFace -BruteForce
                Incriment-SummaryArray -Value "RJ" -HighFace -BruteForce
                return
                #return both high and lowest cards are RJ so no need to continue
            }
        }
    }

    #write the lowest faces to the lowface table
    #$lowFace = $aryResultAsRowsSorted[0] 

    write-host "aryResultAsRowsSorted[0]: $($aryResultAsRowsSorted[0])" -ForegroundColor green

    $faceName = Convert-RowToUniqueValue -Row $aryResultAsRowsSorted[0]
    Incriment-SummaryArray -Value $faceName -LowFace -BruteForce

    #write the highest faces to the hightface table
    #$highFace = $aryResultAsRowsSorted[$colCount -1] 
    $faceName = Convert-RowToUniqueValue -Row $aryResultAsRowsSorted[$colCount -1]
    Incriment-SummaryArray -Value $faceName -HighFace -BruteForce
}


##################################################################################################
#Looks at the current result and writes data to the 'X or better' table
#This is the first step in the table the coumns need to be summed for
#that data to be meaniningful
function Analyze-ResultForXOrBetter {

    if($showProcessing) {write-host "  Analyze-ResultForXOrBetter" -ForegroundColor green }

    #Create a copy of the current result and convert the faces to numbers
    $aryResultAsRows = @()
    for($i = 0; $i -lt $script:aryResult.count; $i++) {
        $row = Convert-FaceToUniqueValuesRow -value $script:aryResult[$i]
        $aryResultAsRows += $row 
    }

    #sort the array so lowest result is first
    $aryResultAsRowsSorted = $aryResultAsRows | Sort-Object 
    #the number of columns in the result
    $colCount = $aryResultAsRowsSorted.count
    #step throuch each column
    for($col = 0; $col -lt $colCount; $col++) {
        #the number of nodes that have this value or better are the currnt node
        #plus any nodes left to evaluate, since the result has been sorted in
        #ascending order any values left must be of an equal or higher value.
        $quant = ($colCount) - $col
        $faceName = Convert-RowToUniqueValue -Row $aryResultAsRowsSorted[$col]
        Incriment-SummaryArray -Value $faceName -OccCount $quant -OrBetter -BruteForce
    }
}


##################################################################################################
# Uses the raw data in the table to tally the complete "or better" vlaues in the table
function Tally-OrBetterTable {

    if($showProcessing) {write-host "  Tally-OrBetterTable" -ForegroundColor green }

    #step through each colum
    for($col = 1; $col -le $script:nodeCount; $col++) {
        #Step through each row in the column from lowest value to highest
        for($row = 0; $row -le $script:aryUniqueValues.count; $row++) {
            #add the values of all the higher value results to this result
            for($shortRow = $row +1; $shortRow -le $script:aryUniqueValues.count; $shortRow++) {
                $script:aryBFOrBetterTable[$Row,$col] = $script:aryBFOrBetterTable[$Row,$col] + $($script:aryBFOrBetterTable[$shortRow,$col])
            }
        }
    }
}



##################################################################################################
#Tally how many times a sum or more resulted via the BF method.
#Durring processing the exact number of times a result was present is written to this table. This
#function steps through each column (from bottom to top) and updates the tally for each row
#to be the tally for that row and every row above it, since those rows are 'more' than that row.
function Tally-SumOrMoreColumn {
    
        if($showProcessing) {write-host "  Tally-SumOrMoreColumn" -ForegroundColor green }
    
        $col = $script:sumsColOrMoreBF        #This column contains the Tallies for if a sum or better was rolled.
    
        #get the number of rows to process
        $rowCount = $($script:arySumsTable).count / $script:sumsWidth
        
        #Step through each row
        for($row = 0; $row -le $rowCount; $row++) {
            #Step through each row after the current row
            for($shortRow = $row +1; $shortRow -le $rowCount; $shortRow++) {
                #If the row's tally is more than 0, add all higher result tallies to this row, since their value is more.
                #If the row's tally is 0 then it is not a possible result (e.g. 1 on 2d6) and should be left at 0 tally.
                if ($script:arySumsTable[$row,$col] -gt 0) {
                   $script:arySumsTable[$row,$col] = $script:arySumsTable[$row,$col] + $($script:arySumsTable[$shortRow,$col])
                }
            }
        }
    }
    
    
##################################################################################################
#Tally how many times a sum or less resulted via the BF method.
#Durring processing the exact number of times a result was present is written to this table. This
#function steps through each column (from top to bottom) and updates the tally for each row
#to be the tally for that row and every row below it, since those rows are 'less' than that row.
function Tally-SumOrLessColumn {
    
        if($showProcessing) {write-host "  Tally-SumOrLessColumn" -ForegroundColor green }
    
        $col = $script:sumsColOrLessBF          #This column contains the Tallies for if a sum or less was rolled.
    
        #get the number of rows to process
        $rowCount = $($script:arySumsTable).count / $script:sumsWidth
        
        #Step through each row
        #for($row = 0; $row -le $rowCount; $row++) {
        for($row = $rowCount; $row -ge 0; $row--) {
                #Step through each row after the current row
            for($shortRow = $row -1; $shortRow -ge 0; $shortRow--) {
                #If the row's tally is more than 0, add all lower result tallies to this row, since their value is less.
                #If the row's tally is 0 then it is not a possible result (e.g. 1 on 2d6) and should be left at 0 tally.
                if ($script:arySumsTable[$row,$col] -gt 0) {
                   $script:arySumsTable[$row,$col] = $script:arySumsTable[$row,$col] + $($script:arySumsTable[$shortRow,$col])
                }
            }
        }
    }
    
    
        



##################################################################################################
#Count up the number of times a restult or any value greater than that result happens in the
#math summary table.
function Tally-ExactXOrMoreTable{

    if($showProcessing) {write-host "  Tally-ExactXOrMoreTable" -ForegroundColor green }

    #step through each row
    for($row=0; $row -lt $($script:aryUniqueValues.count); $row++) {
        #step through each node count in that row
        for($col=1; $col -le $script:nodeCount+1; $col++) {
            [int]$BFSum = 0
            [single]$CalcSum = 0
            #total the node value for the current column and the columns to the right of that cloumn
            for($shortCol=$col; $shortCol -le $script:nodeCount+1; $shortCol++) {
                $BFSum = $BFSum + $aryBFExactlyXTable[$row,$shortCol]
                $CalcSum = $CalcSum + $aryCalcExactlyXTable[$row,$shortCol]
            }
            #save the total to the Exact or more table
            $aryBFExactXOrMoreTable[$row,$col] = $BFSum
            $aryCalcExactXOrMoreTable[$row,$col] = $CalcSum
        }
    }
}



##################################################################################################
#Summary arrays keep track of how many times an outcome occurs.  This functions adds the proper
#value to the proper summary array.


function Incriment-SummaryArray {
    param(
        [string]$Face,           #the name of the face to incriment
        [string]$Value,           #the name of the face to incriment
        [int]$OccCount,               #the number of times the face occured
        [int]$Tally,                  #the number of times the face/occurance combo occured
        [switch]$OrBetter,            #
        [switch]$ActualFaces,         #true if the Actaul Faces array shoud be updated
        [switch]$ExactlyX,            #true if the Exact Occurnaces array shoud be updated
        [switch]$HighFace,            #true if the HighFace array shoud be updated
        [switch]$LowFace,             #true if the LowFce array shoud be updated
        [switch]$Calculated,          #
        [switch]$BruteForce           #
    )

    #Update Actual Faces tables
    if ($ActualFaces) {
        if($showProcessing) {write-host "    $Face"  -ForegroundColor blue}
        $row = Convert-FaceToUniqueFaceRow -Face $Face
        $col = $OccCount +1
        $script:aryBFAcutalFacesTable[$row,$col] = $script:aryBFAcutalFacesTable[$row,$col] +1
        if($showProcessing) {write-host "    $Face / $OccCount : $($script:aryBFAcutalFacesTable[$row,$col])"  -ForegroundColor blue}

        
    }
    
    #update Exaclty X tables
    if ($ExactlyX) {
        $row = Convert-FaceToUniqueValuesRow -value $Value
        $col = $OccCount +1
        $script:aryBFExactlyXTable[$row,$col] = $script:aryBFExactlyXTable[$row,$col] +1
    
    #update X Or Better tables
    } elseif ($OrBetter) {
        $row = Convert-FaceToUniqueValuesRow -value $Value
        if($BruteForce) {
            $col = $OccCount +1
            $script:aryBFOrBetterTable[$row,$col] = $script:aryBFOrBetterTable[$row,$col] +1
        } elseif($Calculated) {
            $col = $OccCount +1
            $script:aryCalcOrBetterTable[$row,$col] = $script:aryCalcOrBetterTable[$row,$col] + $Tally
        }

    #udpate High Face    
    } elseif ($HighFace -or $LowFace) {
        $row = Convert-FaceToUniqueValuesRow -value $Value
        if       ($HighFace -and $BruteForce) {
            $col = $script:highLowColHighestBF
        } elseif ($HighFace -and $Calculated) {
            $col = $script:highLowColHighestCalc
        } elseif ($LowFace  -and $BruteForce) {
            $col = $script:highLowColLowestBF
        } elseif ($LowFace  -and $Calculated) {
            $col = $script:highLowColLowestCalc
        }
        $script:aryHighLowTable[$row,$col] = $script:aryHighLowTable[$row,$col] + 1
    } 




    




}









##################################################################################################
# Display functions
##################################################################################################


##################################################################################################
#Displays the value of each node in the current scenario
function Display-CurrentRestult {
    
        [string]$output = "    ID: $script:resultID"
        foreach($result in $script:aryResult) {
            $output = $output + "   " + $result
        }
        Write-host $output -ForegroundColor Yellow
    }
    



##################################################################################################
#Displays summary table for Math values
function Display-MathSummaryTable {

    #the total number of possible outcomes a given scenario can produce
    $possibleOutcomes = $script:resultID +1

    #the spacing for the rows to output
    $outFormat = "{0,-1} {1,-6} {2,17} / {3,-17} {4,17} / {5,-17} {6,17} / {7,-17}"
    
    #Header info
    write-host
    write-host "------------------------------------------------------------------------------" -ForegroundColor green
    write-host "Sums Table ($possibleOutcomes) Possible Outcomes)" -ForegroundColor green
    write-host "Diplays information on the sum of all dice in the pool"   -ForegroundColor green
    write-host "  Equal To: How often the sum exactly equals the value."  -ForegroundColor green
    write-host "  Or More : How often the sum equals the value or more."  -ForegroundColor green
    write-host "  Or Less : How often the sum equals the value or less."  -ForegroundColor green
    write-host "  C       : Values are calculated with math."  -ForegroundColor green
    write-host "  BF      : Values are counted using brute force methods."  -ForegroundColor green
    write-host "------------------------------------------------------------------------------" -ForegroundColor green
    write-host ($outFormat -f "", "Sum", "Equal To BF", "Equal To C", "Or More BF", "Or More C", "Or Less BF", "Or Less C" ) 
    
    #the number of rows in the array. .count gives rows * colums so won't work here
    $aryRowCount = $($script:arySumsTable).count / $script:sumsWidth
    
    #step through each row
    for($row = 0; $row -lt $aryRowCount; $row++ ) {

        #get the data fromthe row and format it for output
        $name = $script:arySumsTable[$row,$script:sumsColName]
        $exactBF = Format-PercentageOutputFromCount -Numerator $script:arySumsTable[$row,$script:sumsColExactBF] -Denominator $possibleOutcomes
        $exactCalc = Format-PercentageOutputFromCount -Numerator $script:arySumsTable[$row,$script:sumsColExactCalc] -Denominator $possibleOutcomes
        $orMoreBF = Format-PercentageOutputFromCount -Numerator $script:arySumsTable[$row,$script:sumsColOrMoreBF] -Denominator $possibleOutcomes
        $orMoreCalc = Format-PercentageOutputFromCount -Numerator $script:arySumsTable[$row,$script:sumsColOrMoreCalc] -Denominator $possibleOutcomes
        $orLessBF = Format-PercentageOutputFromCount -Numerator $script:arySumsTable[$row,$script:sumsColOrLessBF] -Denominator $possibleOutcomes
        $orLessCalc = Format-PercentageOutputFromCount -Numerator $script:arySumsTable[$row,$script:sumsColOrLessCalc] -Denominator $possibleOutcomes
        
        #tally all values in the row. If all are 0 then the row won't be displayed
        #this is because the array may contain rows for impossisble results like 5 if rolling two dice with these faces 2,4,6,8
        $colTally = 0
        for($col = 1; $col -lt $script:sumsWidth; $col++) {
            $colTally = $colTally + $script:arySumsTable[$row,$col]
        }

        #if the row has any non 0 values then display the row
        if($colTally -gt 0){
            write-host ($outFormat -f "", $name, $exactBF, $exactCalc, $orMoreBF, $orMoreCalc, $orLessBF, $orLessCalc) 
        }
    }
}





##################################################################################################
#Displays summary table for Highest and Lowest value probabilities
function Display-HighLowTable {

    #the total number of possible outcomes a given scenario can produce
    $possibleOutcomes = $script:resultID +1

    #the spacing for the rows to output
    $outFormat = "{0,-1} {1,-6} {2,17} / {3,-17} {4,17} / {5,-17}"
    
    #Header info
    write-host
    write-host "------------------------------------------------------------------------------" -ForegroundColor green
    write-host "Highest/Lowest Table ($possibleOutcomes) Possible Outcomes)" -ForegroundColor green
    write-host "  Highest : How likely the face is to be the highest face in the result."  -ForegroundColor green
    write-host "  Lowest  : How likely the face is to be the lowest face in the result."  -ForegroundColor green
    write-host "  C       : Values are calculated with math."  -ForegroundColor green
    write-host "  BF      : Values are counted using brute force methods."  -ForegroundColor green
    write-host "------------------------------------------------------------------------------" -ForegroundColor green
    write-host ($outFormat -f "", "Sum", "Lowest BF", "Lowest C", "Highest BF", "Highest C") 
    
    #the number of rows in the array. .count gives rows * colums so won't work here
    $aryRowCount = $($script:aryHighLowTable).count / $script:highLowWidth
    
    #step through each row
    for($row = 0; $row -lt $aryRowCount; $row++ ) {

        #get the data fromthe row and format it for output
        $name = $script:aryHighLowTable[$row,$script:sumsColName]
        $exactBF = Format-PercentageOutputFromCount -Numerator $script:aryHighLowTable[$row,$script:highLowColLowestBF] -Denominator $possibleOutcomes
        $exactCalc = Format-AsPercentage $script:aryHighLowTable[$row,$script:highLowColLowestCalc] 
        $orMoreBF = Format-PercentageOutputFromCount -Numerator $script:aryHighLowTable[$row,$script:highLowColHighestBF] -Denominator $possibleOutcomes
        $orMoreCalc = Format-AsPercentage $script:aryHighLowTable[$row,$script:highLowColHighestCalc] 
        

        write-host ($outFormat -f "", $name, $exactBF, $exactCalc, $orMoreBF, $orMoreCalc) 
    }
}








##################################################################################################
#Displays summary table for Occurnace type tables
function Display-OccurnaceSummaryTable {
    param(
        [switch]$ActualFaces,              #True if the Exact Occurnaces table should be displayed
        [switch]$ExactlyX,              #True if the Exact Occurnaces table should be displayed
        [switch]$ExactXOrMore,               #True if the ExactXOrMore table should be displayed
        [switch]$XOrBetter,             #True if the OrBetter table should be displayed
        [switch]$ShowBF,
        [switch]$ShowCalc,
        [switch]$ShowBoth
    )


    #if no switch is true display nothing
    if(!$ActualFaces -and !$ExactlyX -and !$ExactXOrMore -and !$XOrBetter) {return}

    #$rowCount = $($script:aryUniqueValues).count
    $colCount = $script:maxValueOccCount +2

    #generate output format
    #initialize the format string
    $outFormat = "{0,-1} "
    for($col=0; $col -lt $colCount;$col++) {
        $indexNum = $col +1
        if($col -eq 0) {
            $outFormat = $outFormat + "{$indexNum,-12} "
        } else {
            $outFormat = $outFormat + "{$indexNum,-15} "
        }
    }

    #output the formatted line of data
    if($ActualFaces) {
        $outTableTitle = "Actual Faces"
        $outDescritption = "How many times a face occurs exactly X times (e.g. exacly two Hit & Hit faces vs. two hit values restults)."
        $outDescritption2 = "Mostly good for debugging and confirming the algorythms are functioning properly."
    } elseif($ExactlyX) {
        $outTableTitle = "Exactly X"
        $outDescritption = "How many times a value occurs exactly X times (e.g. exacly two 3's)."
        $outDescritption2 = "Mostly good for debugging and confirming the algorythms are functioning properly."
    } elseif($ExactXOrMore) {
        $outTableTitle = "Exactly X Or More"
        $outDescritption = "How many times a value occurs X times or more (e.g. two or more 3's)."
        $outDescritption2 = "Good for coin flips and game like Yahtee, where the exact value of the node is important."
    } elseif($XOrBetter) {
        $outTableTitle = "X Or Better"
        $outDescritption = "How many times a value or better occurs X times or more (e.g. 2 or more 3+'s )."
        $outDescritption2 = "Good for dice pools like X-Wing where Hits and Crits (and maybe Focuses) damage ships."
    }




    write-host
    write-host "------------------------------------------------------------------------------" -ForegroundColor green
    write-host "$outTableTitle ($($script:resultID +1) Possible Outcomes)" -ForegroundColor green
    write-host "$outDescritption"   -ForegroundColor green
    write-host "$outDescritption2"   -ForegroundColor green
    write-host "------------------------------------------------------------------------------" -ForegroundColor green

    #Brute Force
    if($ShowBF -or $ShowBoth) {
        Display-OccurnaceSummaryTableHeader -BruteForce
        Display-OccurnaceSummaryTableRows -BruteForce

    }

    #Calculated 
    if($ShowCalc -or $ShowBoth) {
        Display-OccurnaceSummaryTableHeader -Calculated
        Display-OccurnaceSummaryTableRows -Calculated
    }
}
    

##################################################################################################
#displays the header row of an Occurance Summary Table
function  Display-OccurnaceSummaryTableHeader {
    param(
        [switch]$Calculated,
        [switch]$BruteForce
    )

    #output header rows
    $outData = @()     #initialize the data array to output the data
    $outData += ""
    for($col=0; $col -lt $colCount; $col++) {
        if($col -eq 0) {
            $outData += "Face"
        } else {
            $outData += $col -1
        }
    }
    write-host 
    if($Calculated) {
        write-host ("               Occurnaces Calculated") -ForegroundColor green
        write-host ($outFormat -f $outData) -ForegroundColor green
    }elseif($BruteForce){
        write-host ("               Occurnaces Brute Force") -ForegroundColor yellow
        write-host ($outFormat -f $outData) -ForegroundColor Yellow
    }
}




##################################################################################################
#Displays the rows of an Occurance Summary Table
function Display-OccurnaceSummaryTableRows {
    param(
        [switch]$Calculated,
        [switch]$BruteForce
    )


    if($ActualFaces) {
        $rowCount = $($script:aryUniqueFaces).count
    }else{
        $rowCount = $($script:aryUniqueValues).count
    }


    
    for($row=0; $row -lt $rowCount;$row++) {
        $outData = @()     #initialize the data array to output the data
        $outData += ""
        for($col=0; $col -lt $colCount;$col++) {
            $valueType = "count"  #assume the value in the array is the 'count' of how many times the face occurs
                                  #change this value to 'percentage' if the array contains a percentage instead
                                  #change this value to 'string' for string output
            
                if($ActualFaces) {
                    if($Calculated){
                        #do nothing
                    } elseif($BruteForce) {
                        $value = $script:aryBFAcutalFacesTable[$row,$col]
                    } else {
                        $value = "-"
                        $valueType = "string"
                    }

                }elseif($ExactlyX) {
                    if($Calculated){
                        $value = $script:aryCalcExactlyXTable[$row,$col]
                        $valueType = "percentage" 
                    } elseif($BruteForce) {
                        $value = $script:aryBFExactlyXTable[$row,$col]
                    } else {
                        $value = "-"
                        $valueType = "string" 
                    }
    
                } elseif($ExactXOrMore) {
                if($Calculated){
                    $value = $script:aryCalcExactXOrMoreTable[$row,$col]
                    $valueType = "percentage" 
                } elseif($BruteForce) {
                    $value = $script:aryBFExactXOrMoreTable[$row,$col]
                } else {
                    $value = "-"
                    $valueType = "string" 
                }

            } elseif($XOrBetter) {
                if($Calculated){
                    $value = $script:aryCalcOrBetterTable[$row,$col]
                    $valueType = "percentage" 
                } elseif($BruteForce) {
                    $value = $script:aryBFOrBetterTable[$row,$col]
                } else {
                    $value = "-"
                    $valueType = "string" 
                }
            }


            #process the value



            if($col -eq 0){
                #the 0 element in each array in the face name
                $outPut = $value
            }elseif($value -eq "string") {
                #if the value is a string output it as is
                $outPut = $value
            }elseif($valueType -eq "count") {
                #if the value is a numerator, get the denominator and covert to a percentage for display
                $percentage = Format-AsPercentage -Numerator $value -Denominator $($script:resultID +1) 
                $outPut = "$percentage ($value)"
            }elseif($valueType -eq "percentage") {
                #if the value is in percent form then out put it
                $value = Format-AsPercentage -Decimal $value
                $outPut = $value
            }else{
                #default
                $outPut = $value
            }

            #put the output int he output display array
            $outData += $outPut

        }
        #output the formatted line of data
        write-host ($outFormat -f $outData) 
    }
}


##################################################################################################
#Displays a summary of the scenario
function Display-ScenarioData {


    $outFormat = "{0,-1} {1,-14} {2,-20}"

    Write-Host 
    write-host "------------------------------------------------------------------------------" -ForegroundColor green
    Write-Host "Scenario Data" -ForegroundColor Green
    write-host "------------------------------------------------------------------------------" -ForegroundColor green


    if($systemName -ne "") {
        Write-Host ($outFormat -f "","System:",$systemName)  
    }

    if($systemNote -ne "") {
        Write-Host ($outFormat -f "","Note:",$systemNote)  
    }

    Write-Host ($outFormat -f "","Nodes:",$script:nodeCount)  

    $faceList = ""
    foreach($face in $script:aryFaces) {
        $faceList = $faceList + $face + " "
    }
    Write-Host ($outFormat -f "","Faces:",$faceList)  

    Write-Host ($outFormat -f "","Face Count:",$($($script:aryFaces).count)) 
    Write-Host ($outFormat -f "","Max Occ Count:",$script:maxValueOccCount)
    Write-Host ($outFormat -f "","Result Count:",$($script:resultID +1))  

    $runTime = $(Get-Date) - $startTime
    Write-Host ($outFormat -f "","Run Time:",$runTime)  


}
#
##################################################################################################
#Displays tables based on the type of data that is likely to be interesting.
function Display-Tables {

    Display-ScenarioData

    if($ShowAllTables -or $ShowExacts) {
        Display-OccurnaceSummaryTable -ActualFaces -ShowBF
        Display-OccurnaceSummaryTable -ExactlyX -ShowBoth
        Display-OccurnaceSummaryTable -ExactXOrMore -ShowBoth
    }

    if($ShowAllTables -or $ShowOrBetter) {
        Display-OccurnaceSummaryTable -XOrBetter -ShowBoth
    }

    if($ShowAllTables -or $ShowHighLow) {
        Display-HighLowTable
    }

    if($ShowAllTables -or $ShowSums) {
        Display-MathSummaryTable
    }
}



##################################################################################################
# Helper Functions
##################################################################################################

##################################################################################################
#Formats percentages from deicimal or fraction input
function Format-AsPercentage {

    param (
        [single]$Decimal,       #Enter are decimal number to be formatted OR
        [int]$Numerator,        #Enter a fraction to be formatted
        [int]$Denominator,
        [int]$Digits=2          #How many digits to leave after the decimal place
        )

    if($Denominator -gt 0) {
        $decimal = $Numerator / $Denominator
    }
    
    #string Formating
    $Decimal = $Decimal * 100
    $Decimal = [math]::round($Decimal,$Digits)
    [string]$DecimalString = [string]$Decimal

    #pad with 0's or spaces
    if($DecimalString -eq "0"){
        $percentString = "    0"
    }elseif($DecimalString -eq "100"){
        $percentString = "  100"
    }else{
        $x = $DecimalString.Split(".")
        if     ($x[0].Length -eq 0) { $x[0] = "  " }
        elseif ($x[0].Length -eq 1) { $x[0] = " " + $x[0] }

        if     ($x[1].Length -eq 0) { $x += "00" }
        elseif ($x[1].Length -eq 1) { $x[1] = $x[1] + "0" }

        $percentString = $x[0] + "." + $x[1] 
    }

    #add the percent sign
    if($percentString.IndexOf("%") -eq -1) {
        $percentString = $percentString + "%"

    }

    #return the string
    return $percentString 
}

##################################################################################################
#Formats a percentage value into a string with this format " xxx.xx% (y)" where xxx.xx is the
#percent likelyhood of the result and y is the total number of occurances for the result
function Format-PercentageOutputFromCount {
    param (
        [int]$Numerator,
        [int]$Denominator
    )

    $asPercent = Format-AsPercentage -Numerator $Numerator -Denominator $Denominator
    [string]$output = "$asPercent ($Numerator)"
    return $output
}




##################################################################################################
#Displays data about a face on a node.  Used for troubleshooting
#
function Display-Node {
    param(
        [string]$FaceName,          #The name of the face to count
        $aryNode                    #An array of all the faces on the node to examine
    )


    
    $faceCount = $aryNode.Count

    $Faces = ""
    for ($i = 0; $i -lt $aryNode.Count; $i++) {
        $Faces = $Faces + " " + $aryNode[$i]
    }

    write-host "`n`n`n=========================================================="
    write-host "Display:    $FaceName" 
    write-host "Faces:     $Faces" 
    write-host "Face Count: $faceCount" 
    write-host "Faces <:    $(Get-LessThanFaceCount -facename $FaceName $arynode)" 
    write-host "Faces <=:   $(Get-EqualToOrLessThanFaceCount -facename $FaceName $arynode)" 
    write-host "Faces =:    $(Get-EqualToFaceCount -facename $FaceName $arynode)" 
    write-host "Faces >=:   $(Get-EqualToOrGreaterThanFaceCount -facename $FaceName $arynode)" 
    write-host "Faces >:    $(Get-GreaterThanFaceCount -facename $FaceName $arynode)" 
    write-host "==========================================================`n`n"

}




##################################################################################################
#Returns the number of times a face, an equivalent, or LOWER occurs on a node.
#
function Get-EqualToOrLessThanFaceCount {
    param(
        [string]$FaceName,          #The name of the face to count
        $aryNode                    #An array of all the faces on the node to examine
    )

    $faceCount = 0
    $faceMatch = $false

    #incriment the OrLesserFaceCount if the face matches or this face is prior to a match.
    #step through each face in the array.  I'm using a for loop instead of a foreach because
    #I want to ensure the array is processed from the lowest value to the highest.
    for($i = 0;$i -lt $aryNode.Count;$i++){
        if($($aryNode[$i] -eq $FaceName)) {
            #If there is a match then incriment the counter and set the match flag to true
            $faceMatch = $true
            $faceCount = $faceCount +1
        }elseif(!$faceMatch){
            $faceCount = $faceCount +1
        }elseif($faceMatch){
            break
        }
    }

    #return the count
    return $faceCount
}
    




##################################################################################################
#Return the number faces where a value LOWER THAN the current face occurs.
#
function Get-LessThanFaceCount {
    param(
        [string]$FaceName,          #The name of the face to count
        $aryNode                    #An array of all the faces on the node to examine
    )

    $faceCount = 0
    for($i = 0; $i -lt $aryNode.Count; $i++){
        if($($aryNode[$i] -eq $FaceName)) {
            #If there is a match then stop counting and return the current count
            return $faceCount
        }else{
            #otherwise incriment the count and keep looping
            $faceCount = $faceCount +1
        }
    }
}
    

##################################################################################################
#Return the number faces where a value BETTER THAN the current face occurs.
#
function Get-GreaterThanFaceCount {
    param(
        [string]$FaceName,          #The name of the face to count
        $aryNode                    #An array of all the faces on the node to examine
    )

    $faceCount = 0
    for($i = $aryNode.Count -1; $i -ge 0; $i--){
        if($($aryNode[$i] -eq $FaceName)) {
            #If there is a match then stop counting and return the current count
            return $faceCount
        }else{
            #otherwise incriment the count and keep looping
            $faceCount = $faceCount +1
        }
    }
}
    




##################################################################################################
#Returns the number of times a face, an equivalent, or BETTER occurs on a node.
function Get-EqualToOrGreaterThanFaceCount {
    param(
        [string]$FaceName,          #The name of the face to count
        $aryNode                    #An array of all the faces on the node to examine
    )

    $faceCount = 0
    $faceMatch = $false
    #incriment the OrBetterFaceCount if the current or a previous face matched
    for($i = 0;$i -lt $aryNode.Count;$i++){
        if($($aryNode[$i] -eq $FaceName) -or $faceMatch) {
            $faceMatch = $true
            $faceCount = $faceCount +1
        }
    }
    return $faceCount
}



##################################################################################################
#Returns the number of times a face occurs in the face array.
function Get-EqualToFaceCount {
    param (
        [string]$FaceName,          #The name of the face to count
        $aryNode                    #An array of all the faces on the node to examine
    )

    $faceCount = 0
    foreach($face in $aryNode) {
        if($face -eq $FaceName) {
            $faceCount = $faceCount +1
        }
    }
    return $faceCount
}



##################################################################################################
#Returns the row number of a value name in the unique values table
function Convert-UniqueValueToRow {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ValueName            #the name of the face to find
    )

    for($i = 0; $i -lt $script:aryUniqueValues.count; $i++){
        if($ValueName -eq $script:aryUniqueValues[$i]) {
            write-host "match $ValueName $i" -ForegroundColor blue
            return $i
        }
    }
    

}



##################################################################################################
#Returns the row number of a face in the Unique Faces table
#vetted 1.0
function Convert-FaceToUniqueFaceRow {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Face            #the name of the face to find
    )

    #step through each face in the Unique Faces array until a match is found
    $rowCount = $script:aryUniqueFaces.Count
    for($row = 0; $row -lt $rowCount; $row++) {
        if($Face -eq $script:aryUniqueFaces[$row]){
            return $row
        }
    }
}


##################################################################################################
#Returns the row number of a face in the Unique Values table
#vetted 1.0
function Convert-FaceToUniqueValuesRow {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Value            #the name of the face to find
    )

    #step through each face in the Unique Faces array until a match is found
    $rowCount = $script:aryUniqueValues.Count
    for($row = 0; $row -lt $rowCount; $row++) {
        if($Value -eq $script:aryUniqueValues[$row]){
            return $row
        }
    }
}





##################################################################################################
#Returns the row number of a given face value
function DELETE-Convert-FaceToRow {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FaceName            #the name of the face to find
    )

    $rowCount = $($script:aryUniqueValues).count -1
    for($row = $rowCount; $row -ge 0;$row--) {
        $colFace = $script:aryBFOrBetterTable[$row,0]
        if ($FaceName -eq $colFace) {
            $returnRow = $row
            #write-host "    Convert-FaceToRow                   $FaceName Row: $returnRow"
            return $returnRow
            break
        }
    }
}

##################################################################################################
#Returns the value name of a give row in the Unique Values table
#Vetted 1.0
function Convert-RowToUniqueValue {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Row            #the number of the row to find
    )
    return $script:aryUniqueValues[$Row]
}



##################################################################################################
# Returns the row matching a value name in the Unique Values table
function Get-UniqueValueRow {
    param (
        [string]$ValueName
    )

    for($i = 0; $i -lt $script:aryUniqueValues.count; $i++) {
        if($script:aryUniqueValues[$i] -eq $ValueName) {
            return $i
        }
    }
}


##################################################################################################
# Returns the row matching a face name in the Unique Faces table
function Get-UniqueFaceRow {
    param (
        [string]$FaceName
    )

    for($i = 0; $i -lt $script:aryUniqueFaces.count; $i++) {
        if($script:aryUniqueFaces[$i] -eq $FaceName) {
            return $i
        }
    }
}






##################################################################################################
## If not all faces in the face array are numberic then disable numeric processing.
function Confirm-FacesAreNumeric {


    #if any face is not numeric then change process sums to false
    foreach($face in $script:aryUniqueValues) {
        if(isNumeric $face) {
        } else {
            $script:ShowSums = $false
            return
        }
    }
    #if no sum was not numeric the process sums
    $script:ShowSums = $true

}



##################################################################################################
# Math Functions
##################################################################################################


######################################
# Return true if a string is numeric
#vetted 1.0
function isNumeric ($x) {
    try {
        0 + $x | Out-Null
        return $true
    } catch {
        return $false
    }
}





######################################
# Calculates a Hypergeometric Distribution
# The probability of getting exaclty X instances of a value from a pool without replacement
# For example the proability of drawing 4 cards and having exaclty 2 Kings from a deck of cards.
# P(X=s) = C(k s) * C(n-k d-s) / C(n d)
# where
# n is the population size,
# k is the number of success states in the population,
# d is the number of draws,
# s is the number of observed successes,
# C(a b) is a binomial coefficient.
#
# https://en.wikipedia.org/wiki/Binomial_coefficient

function Calculate-HypergeometricDistribution{
    param(
        [int]$PopulationSize,
        [int]$SuccessStates,
        [int]$Draws,
        [int]$ObservedSuccesses
    )

    $a = Calculate-BinomialCoefficient -n $SuccessStates -k $ObservedSuccesses
    $b = Calculate-BinomialCoefficient -n $($PopulationSize - $SuccessStates) -k $($Draws - $ObservedSuccesses)
    $c = Calculate-BinomialCoefficient -n $PopulationSize -k $Draws


    $answer = $a * $b / $c

    return $answer
    



}




######################################
# Calculates a Binomial Coeffieient
# C(n,k) = n!/k!(n-k)!
#
# https://en.wikipedia.org/wiki/Binomial_coefficient

function Calculate-BinomialCoefficient{
    param(
        [int]$n,
        [int]$k
    )

    #get factorials
    $nfac = Calculate-Factorial $n
    $kfac = Calculate-Factorial $k
    $nMinusKfac = Calculate-Factorial $($n-$k)

    #get combination
    $c = $nfac / ($kfac * $nMinusKfac)
    return $c
}



######################################
#Performs the Probabilty Mass Function and returns the result
#The PMF calculates the percentage chance that a given result
#will occure exaclty k times in a give scenario.
#
# PMF = (C(n,k)) * (p^k) * ((1-p)^(n-k))
# C(n,k) = n!/k!(n-k)!
# k = the numer of exact time an element will be present
# n = the number of nodes in the scenario
# p = the probability of success (in percent)
#
#https://en.wikipedia.org/wiki/Binomial_distribution

function Calculate-ProbabiliyMass {
    param(
        [int]$n,
        [int]$k,
        [single]$p
    )


    #write-host "k (exact count): $k"
    #write-host "n (nodes):       $n"
    #write-host "p (success):     $p"
    
    #use a combination calculation to get the distribution of k appearing in n
    [single]$c = Calculate-BinomialCoefficient -n $n -k $k
    #the percentage chance of k nodes appearing based on a success rate of p
    $successes = [math]::pow($p,$k)
    #the percentage chance of n-k nodes NOT appearing based on a success rate of p
    $failures = [math]::pow($(1-$p),$($n-$k))
    #multiple the three expressions for the percentage chance
    $answer = $c * $successes * $failures
    return $answer

}





######################################
# Get factorial of a number n
function Calculate-Factorial {
    param(
        [int]$n
    )

    $nFac = 1
    for($i = $n; $i -gt 1; $i--){

        $nFac = $nFac * $i
   }
    return $nFac
}








##################################################################################################
# Main
##################################################################################################

######################################
# Setup
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
write-host
write-host
if($showProcessing) {write-host "" -ForegroundColor green }
if($showProcessing) {write-host "Setup Started" -ForegroundColor green }

$startTime = Get-Date


Create-UniqueFacesTable
Create-UniqueValuesTable 
Caclulate-HighestPossibleOccurance
Caclulate-NodeCount
Caclulate-ProjectedResultCount

Create-RestultArray
Create-OccuranceSummaryTables
Create-AcutalFacesSummaryTables
Create-HighLowSummaryTable

if($ShowSums -or $ShowAllTables) {
    Confirm-FacesAreNumeric
}
if($ShowSums) {
    Create-MathSummaryTable
}


######################################
# Processing
if($showProcessing) {write-host "" -ForegroundColor green }
if($showProcessing) {write-host "Processing Started" -ForegroundColor green }


Generate-BruteForceResult



#xxx
#Calculate-TheoreticalResults
#xxx
#Tally-SummaryTables


######################################
# Restuls
if($showProcessing) {write-host "" -ForegroundColor green }
if($showProcessing) {write-host "Display Started" -ForegroundColor green }
Display-Tables
