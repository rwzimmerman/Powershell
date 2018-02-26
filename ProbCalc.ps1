


<#
    .SYNOPSIS
        Calculates the percentage chance of outcomes for die rolls, card draws, etc.

    .DESCRIPTION
        Scenario - The parameters of the random event being measured.
        Result - One of many possible outcomes in a scenario.  
        Node - A single randomizaion element (e.g. one die, one card, onc coin, etc.)
        Face - A single value from a node.  (e.g three on a die, or a queen on a playing card)

        The script steps through every possible result a scenario can yeild.  Each result
        is analyzed and the data summarized into tables showing how many "exact occurnace"
        and how many "or better" matches occured.
        Exact Occurance Match - This occurs when exaclty that number of the result occurs.  For example
        if two 6's occured in a result it would be an exact match for 2x6, but not for 1x6.
        Or Better Match - This occurs when the result or better occured. For example if 
        two 6's occured in a result it would be an "or better" match for 2x6, 1x6 and 2x5, 
        but not for 2x7 or 3x6.

        The script assumes faces are input in order of value with the lowest on the left
        and the highest on the right.
        Example: 3,2,1 would give 1 the highest value, followed by 2, then 3.

        If in a scenario 2 coins (nodes) were flipped, each having heads and
        tails (2 faces) the scenario would have 4 possible results: HH, HT, TH, TT.

        Or Better Summary
        Face   1    2
        Heads  4    4
        Tails  3    1

        Exact Occurnace Summary
        Face   1    2
        Heads  2    1   Meaning two of four results give exacly 1 head, one of four results give exacly 2 heads
        Tails  2    1   Meaning two of four results give exacly 1 tails, one of four results give exacly 2 tails

        
    
    .PARAMETER Nodes
    
    
    
    .EXAMPLE
        
    

    .INPUTS

    .OUTPUTS

    .NOTES 
        Author: Robert Zimmerman
        Updated: Feb 2018

        To Do:
        Add "reroll logic" allow for rerolls and caclute percentages after a reroll
        Add asymetrical dice support
        Add percentages to displays
        Add CSV Export


        Array notes
        https://powershell.org/2013/09/16/powershell-performance-the-operator-and-when-to-avoid-it/


    .LINK
        
#> 


#https://weblogs.asp.net/soever/powershell-return-values-from-a-function-through-reference-parameters




param(
    [int]$NodeCount=2,              #the number of elements in the randomization (e.g. 3 cards, 2 dice, etc.)
    #Systems
    [switch]$XWingAtt,              #True if XWing attack dice are being used 
    [switch]$XWingDef,              #True if XWing defence dice are being used 
    [switch]$MalifauxSuited,        #
    [switch]$MalifauxUnsuited,      #
    [switch]$d4,                    #
    [switch]$d6,                    #
    [switch]$d8,                    #
    [switch]$d10,                   #
    [switch]$d12,                   #
    [switch]$d20,                   #
    [switch]$Coin,                  #
    #Options
    [string[]]$Faces,               #    
    [switch]$ExhaustFaces,          #
    [switch]$MalifauxJokers,        #True if Malfiaux joker logic should be applied
    [switch]$ShowSums,              #
    [switch]$ShowExacts,            #
    [switch]$ShowOrBetter,          #
    [switch]$ShowHighLow,           #
    [switch]$ShowAllTables,         #Shows all tables
    #Debug
    [switch]$Test,                  #Test Data
    [switch]$ShowDebug              #if true debuging data will be displayed when the script executes.
)


#Arrays
$aryFaces = @()               #This array holds the value on each face of each node
$aryUniqueFaces = @()         #This array is a list of the unique faces on each node
$aryResult = @()              #This array is the current result
#The arrays below are created in functions with the 'script' scope.  They are listed here for reference
#$aryExactlyXTable = @()            #
#$aryExactXOrMoreTable = @()        #
#$aryOrBetterBFTable = @()          #
#$aryOrBetterCalcTable = @()        #
#$aryExactSumTable = @()            #
#$arySumOrMoreTable = @()           #
#$aryHighFaceTable = @()            #
#$aryLowFaceTable = @()             #

#Variables
$resultID = -1                  #The current result
$showProcessing = $false        #True if processing info should be displayed to the screen



#input the faces used
if($Faces.count -ne 0) {
    $aryFaces = $Faces
}


#Process System Switches
#sytems are like macros.  They contain the options, like using numeric dice or malifax jokers
#and the faces of the nodes.

if($XWingAtt) {
    $systemName = "X-Wing Attack Dice"
    $aryFaces = @("Blank","Blank","Focus","Focus","Hit","Hit","Hit","Crit")
    $ShowOrBetter = $true
}elseif($XWingDef) {
    $systemName = "X-Wing Defence Dice"
    $aryFaces = @("Blank","Blank","Blank","Focus","Focus","Evade","Evade","Evade")
    $ShowOrBetter = $true
}elseif($MalifauxUnsuited) {
    $systemName = "Malifaux Unsuited Cards"
    $ExhaustFaces=$true
    $MalifauxJokers=$true
    $aryFaces = @("BJ","1","1","1","1","2","2","2","2","3","3","3","3","4","4","4","4",`
                  "5","5","5","5","6","6","6","6","7","7","7","7","8","8","8","8","9","9","9","9", `
                  "10","10","10","10","11","11","11","11","12","12","12","12","13","13","13","13","RJ")
    $ShowHighLow = $true
}elseif($MalifauxSuited) {
    $systemName = "Malifaux Sited Cards"
    $ExhaustFaces=$true
    $MalifauxJokers=$true
    $aryFaces = @()
    for($i = 1; $i -le 39; $i++) {
        $aryFaces += "NA"
    }
    $aryFaces += @("BJ","1","2","3","4","5","6","7","8","9","10","11","12","13","RJ")
    $ShowHighLow = $true
}elseif($d4) {
    $systemName = "d4"
    $aryFaces = @(1,2,3,4)
    $ShowSums=$true
}elseif($d6) {
    $systemName = "d6"
    $aryFaces = @(1,2,3,4,5,6)
    $ShowSums=$true
}elseif($d8) {
    $systemName = "d8"
    $aryFaces = @(1,2,3,4,5,6,7,8)
    $ShowSums=$true
}elseif($d10) {
    $systemName = "d10"
    $aryFaces = @(1,2,3,4,5,6,7,8,9,10)
    $ShowSums=$true
}elseif($d12) {
    $systemName = "d12"
    $aryFaces = @(1,2,3,4,5,6,7,8,9,10,11,12)
    $ShowSums=$true
}elseif($d20) {
    $systemName = "d20"
    $aryFaces = @(1,2,3,4,5,6,7,8,9,10,11,1213,14,15,16,17,18,19,20)
    $ShowSums=$true
}elseif($Test) {
    $systemName = "Test Data"
    $ExhaustFaces=$true
    $MalifauxJokers=$true
    $aryFaces += @("BJ","1","1","1","1","2","2","2","2","RJ")
    $ShowHighLow = $true
}else{  
    #default to coins
    $systemName = "Coin"
    $aryFaces = @("Heads","Tails")
    $ShowExacts = $true
}



#estimate the number of results for the statuse bar
$resultCount = 0
$estResultCount = [math]::pow($aryFaces.count,$NodeCount)





##################################################################################################
# Setup Functions
#   Initialize variables, create arrays, etc...
##################################################################################################

##################################################################################################
# Initializes the result array giving it the prober number of elements
function Create-RestultArray {
    
    if($showProcessing) {write-host "  Create-RestultArray" -ForegroundColor green }

    for($i = 1; $i -le $NodeCount; $i++) {
        $script:aryResult += "empty"
    }
}

##################################################################################################
## Create a table containing a list of each unique face
function Create-UniqueFacessTable {
    
    if($showProcessing) {write-host "  Create-UniqueFacessTable" -ForegroundColor green }

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
            #$script:aryUniqueFaces.add($face)
        }
    }
}




    
##################################################################################################
## Create summary tables for counting occurnaces.
function Create-OccuranceSummaryTables {

    if($showProcessing) {write-host "  Create-OccuranceSummaryTables" -ForegroundColor green }
    
    #creat the Exact and OrBetter summary arrays
    $faceCount = $script:aryUniqueFaces.count
    $script:aryExactlyXTable = New-Object 'object[,]' $faceCount,$([int]$NodeCount+1)
    $script:aryOrBetterBFTable = New-Object 'object[,]' $faceCount,$([int]$NodeCount+1)
    $script:aryOrBetterCalcTable = New-Object 'object[,]' $faceCount,$([int]$NodeCount+1)
    $script:aryExactXOrMoreTable = New-Object 'object[,]' $faceCount,$([int]$NodeCount+1)
    $script:aryHighFaceTable = New-Object 'object[,]' $faceCount,$([int]$NodeCount+1)
    $script:aryLowFaceTable = New-Object 'object[,]' $faceCount,$([int]$NodeCount+1)


    #get row and column sizes
    $rowCount = $($script:aryUniqueFaces).count
    $colCount = $NodeCount +1
    
    #put the face name in the 0 element in the array
    for($row = 0; $row -lt ($script:aryUniqueFaces).count; $row++) {
        $aryExactlyXTable[$row,0] = $script:aryUniqueFaces[$row]
        $aryOrBetterBFTable[$row,0] = $script:aryUniqueFaces[$row]
        $aryOrBetterCalcTable[$row,0] = $script:aryUniqueFaces[$row]
        $aryHighFaceTable[$row,0] = $script:aryUniqueFaces[$row]
        $aryLowFaceTable[$row,0] = $script:aryUniqueFaces[$row]
        #zero the rest of the values in the arrays
        for($col = 1; $col -le $([int]$NodeCount); $col++) {
            $aryExactlyXTable[$row,$col] = 0
            $aryOrBetterBFTable[$row,$col] = 0
            $aryOrBetterCalcTable[$row,$col] = 0
            $aryExactXOrMoreTable[$row,$col] = 0
            $aryHighFaceTable[$row,$col] = 0
            $aryLowFaceTable[$row,$col] = 0
        }
    }
}






##################################################################################################
#
function Create-MathSummaryTables {


    if($showProcessing) {write-host "  Create-MathSummaryTables" -ForegroundColor green }
    
    #find highest and lowest numeric value on a face
    [int]$highestFace = $aryUniqueFaces[0]
    [int]$LowestFace = $aryUniqueFaces[0]
    foreach($face in $aryUniqueFaces) {
        if([int]$face -gt $highestFace) { $highestFace = [int]$face }
        if([int]$face -lt $LowestFace) {$LowestFace = [int]$face }
    }

    #found the highest and lowest possible sums
    [int]$highestSum = $NodeCount * $highestFace
    [int]$script:lowestTotal = $NodeCount * $LowestFace
    
    #create the tables 
    $script:aryExactSumTable = New-Object 'object[,]' $($highestSum +1),2
    $script:arySumOrMoreTable = New-Object 'object[,]' $($highestSum +1),2

    #fill arrays with initial values
    $aryCount = $($script:aryExactSumTable).count /2
    for($i = 0; $i -lt $aryCount; $i++ ) {
        #exact total array
        $script:aryExactSumTable[$i,0] = $i
        $script:aryExactSumTable[$i,1] = 0
        #total or better array
        $script:arySumOrMoreTable[$i,0] = $i
        $script:arySumOrMoreTable[$i,1] = 0
    }
}


##################################################################################################
# Calcuations functions
##################################################################################################

function Calculate-TheoreticalResults {

    write-host "Calculate" -ForegroundColor Red



    Calculate-HighLowForExhausted
    Calculate-XOrBetterNonExhausting







}





##################################################################################################
#xxx
function Calculate-XOrBetterNonExhausting {



    #step thorough each face

    for($i = $($script:aryFaces.count -1); $i -ge 0; $i--){


        #calc 1 or more  instances
        $a = [math]::pow($($i+1),$NodeCount)
        $b = [math]::pow($i,$NodeCount)
        $c = $a - $b



        Write-Host "$i $($script:aryFaces[$i]): $a - $b = $c" -ForegroundColor Yellow
        
        Incriment-SummaryArray -FaceName $($script:aryFaces[$i]) -Occurnaces 1 -Tally $c -OrBetterCalc

    }


    


}





##################################################################################################
# Calculates how many times each face will be the highest and lowest face of a result if 
#faces are exhausted (removed once drawn like a deck of cards).
#Formula: 
# n=nodeCount, f=faceCount, r=rank (1 is the highest ranked card e.g. 1 for the highest card, 2
# when looking for the next highest, etc.)  It is reversed when looking for the lowest ranked card.
# Occurances = ((f-r)^(n-1)*n
function Calculate-HighLowForExhausted {


    $faceCount = $script:aryFaces.Count
    
    if($MalifauxJokers) {
        write-host "M jokers" -ForegroundColor red

        $row = Convert-FaceToRow -FaceName "BJ"
        write-host "BJROW: $row"

        $x = 1
        $occ = ([math]::Pow($faceCount-$x,$NodeCount -1)) * $NodeCount
        Incriment-SummaryArray -FaceName "BJ" -HighFace -Calculated -Occurnaces $occ


        for($row = $faceCount -1; $row -ge 1; $row--) {
            $x = $faceCount - $row +1
            $occ = ([math]::Pow($faceCount-$x,$NodeCount -1)) * $NodeCount
            $faceName = $script:aryFaces[$row]
            Incriment-SummaryArray -FaceName $faceName -HighFace -Calculated -Occurnaces $occ
            write-host "$faceName x: $x"   -ForegroundColor red
        }
    } else {
        for($row = $faceCount -1; $row -ge 0; $row--) {
            $x = $faceCount - $row
            $occ = ([math]::Pow($faceCount-$x,$NodeCount -1)) * $NodeCount
            $faceName = $script:aryFaces[$row]
            Incriment-SummaryArray -FaceName $faceName -HighFace -Calculated -Occurnaces $occ
        }
    }








}







##################################################################################################
# Brute Force Processing functions
##################################################################################################


##################################################################################################
#Steps through each face of a node
function Generate-BruteForceResult {
    param(
        [int]$nodeNum = 1,         #the current node
        [Parameter(Mandatory=$true)]
        [string[]]$DrawPool
    )

    foreach($face in $DrawPool ) {
        $script:aryResult[$nodeNum -1] = $face
        if($NodeCount -gt $nodeNum) {
            $nextNode = $nodeNum +1

            #if exhause faces is set then remove the current face from the pool for later draws
            if($ExhaustFaces) {
                $nextDrawPool = Create-DrawPool -PoolIn $DrawPool -RemoveFace  $face
            } else {
                $nextDrawPool = Create-DrawPool -PoolIn $DrawPool
            }
            Generate-BruteForceResult -nodeNum $nextNode -DrawPool $nextDrawPool
        } else {
            $script:resultID = $script:resultID +1
            Write-Progress -Activity "Generating Results" -status "Result $script:resultID of $script:estResultCount" -percentComplete ($script:resultID / $script:estResultCount * 100)
            #Display-CurrentRestult
            Analyze-Restult 
        }
    }
}


##################################################################################################
## Creates a new draw pool from an existing pool.
## RemoveFace will remove ONE instnace of face from the pool.  So if the poll is "1,1,2,2,3,3,4,4"
## and Remove Face = "2" the new pool will be "1,1,2,3,3,4,4" it will NOT be "1,1,3,3,4,4"
function Create-DrawPool {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$PoolIn,
        [string]$RemoveFace = ""
    )

    #copy the existing array
    $aryPoolOut = @()
    foreach($face in $PoolIn) {
        #if Remove face is found don't add it, then change remove face to empty so no further matches are found
        if($face -ne $RemoveFace) {
            $aryPoolOut += $face
        } else {
            $RemoveFace = ""
        }
    }


    return $aryPoolOut

}

##################################################################################################
#Looks at the current result and writes data to the summary tables
#

function Analyze-Restult {
    if($showProcessing) {write-host ""}

    #only analyze for a result if it will be displayed
    if($ShowAllTables -or $ShowExacts)    {Analyze-RestultForExactlyX}
    if($ShowAllTables -or $ShowOrBetter)  {Analyze-RestultForOrBetter}
    if($ShowAllTables -or $ShowHighLow)   {Analyze-RestultForHighAndLowFace}
    if($ShowSums)      {Analyze-ResultForMathValues}
}


##################################################################################################
#Creates secondary summary tables
#e.g. Tallies the ExactXOrMoreTable from ExactlyXTable 
#
function Tally-SummaryTables{
    if($ShowAllTables -or $ShowExacts)    {Tally-ExactXOrMoreTable}
    if($ShowAllTables -or $ShowOrBetter)  {Tally-OrBetterTable}
    if($ShowAllTables -or $ShowHighLow)   {}
    if($ShowSums)      {Tally-SumOrMoreTable}
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
    $script:aryExactSumTable[$total,1] = $script:aryExactSumTable[$total,1] +1
    $script:arySumOrMoreTable[$total,1] = $script:arySumOrMoreTable[$total,1] +1
    
}




##################################################################################################
#Looks at the current result and writes data to the exact occurance table
#An exact occurance would be how many times do exaclty two 6' occure.
function Analyze-RestultForExactlyX {

    if($showProcessing) {write-host "  Analyze-RestultForExactlyX" -ForegroundColor green }
    
    foreach ($face in $script:aryUniqueFaces){
        $occurances = 0
        foreach ($node in $script:aryResult) {
            if($face -eq $node) {
                $occurances++
            }
        }
        if($occurances -gt 0) {
            #update the exact occurnace array
            Incriment-SummaryArray -FaceName $face -Occurnaces $occurances -ExactlyX
        }
    }
}





##################################################################################################
#Looks at the current result and writes data to the 'X or better' table
#This is the first step in the table the coumns need to be summed for
#that data to be meaniningful
function Analyze-RestultForHighAndLowFace {

    if($showProcessing) {write-host "  Analyze-RestultForOrBetter" -ForegroundColor green }

    #Create a copy of the current result and convert the faces to numbers
    $aryResultAsRows = @()
    for($i = 0; $i -lt $script:aryResult.count; $i++) {
        $row = Convert-FaceToRow -FaceName $script:aryResult[$i]
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
                Incriment-SummaryArray -FaceName "BJ"  -LowFace -BruteForce
                Incriment-SummaryArray -FaceName "BJ"  -HighFace -BruteForce
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
                Incriment-SummaryArray -FaceName "RJ" -LowFace -BruteForce
                Incriment-SummaryArray -FaceName "RJ" -HighFace -BruteForce
                return
                #return both high and lowest cards are RJ so no need to continue
            }
        }
    }


    #write the lowest faces to the lowface table
    #$lowFace = $aryResultAsRowsSorted[0] 
    $faceName = Convert-RowToFace -RowNumber $aryResultAsRowsSorted[0]
    Incriment-SummaryArray -FaceName $faceName -LowFace -BruteForce


    #write the highest faces to the hightface table
    #$highFace = $aryResultAsRowsSorted[$colCount -1] 
    $faceName = Convert-RowToFace -RowNumber $aryResultAsRowsSorted[$colCount -1]
    Incriment-SummaryArray -FaceName $faceName -HighFace -BruteForce



}


##################################################################################################
#Looks at the current result and writes data to the 'X or better' table
#This is the first step in the table the coumns need to be summed for
#that data to be meaniningful
function Analyze-RestultForOrBetter {

    if($showProcessing) {write-host "  Analyze-RestultForOrBetter" -ForegroundColor green }

    #Create a copy of the current result and convert the faces to numbers
    $aryResultAsRows = @()
    for($i = 0; $i -lt $script:aryResult.count; $i++) {
        $row = Convert-FaceToRow -FaceName $script:aryResult[$i]
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
        $faceName = Convert-RowToFace -RowNumber $aryResultAsRowsSorted[$col]
        Incriment-SummaryArray -FaceName $faceName -Occurnaces $quant -OrBetterHC
    }
}


##################################################################################################
# Uses the raw data in the table to tally the complete "or better" vlaues in the table
function Tally-OrBetterTable {

    if($showProcessing) {write-host "  Tally-OrBetterTable" -ForegroundColor green }

    #step through each colum
    for($col = 1; $col -le $NodeCount; $col++) {
        #Step through each row in the column from lowest value to highest
        for($row = 0; $row -le $script:aryUniqueFaces.count; $row++) {
            #add the values of all the higher value results to this result
            for($shortRow = $row +1; $shortRow -le $script:aryUniqueFaces.count; $shortRow++) {
                $script:aryOrBetterBFTable[$Row,$col] = $script:aryOrBetterBFTable[$Row,$col] + $($script:aryOrBetterBFTable[$shortRow,$col])
            }
        }
    }
}



##################################################################################################
#
function Tally-SumOrMoreTable {


    if($showProcessing) {write-host "  Tally-SumOrMoreTable" -ForegroundColor green }

    $CountColumn = 1         #The column holding the number of matchinc occurances

    #get the number of rows to process
    $rowCount = $script:arySumOrMoreTable.Count /2

    #Step through each row
    for($row = 0; $row -le $rowCount; $row++) {
        #Step through each row after the current row
        for($shortRow = $row +1; $shortRow -le $rowCount; $shortRow++) {
            #If the current row's total is more than 0 then all higher results to this occurance total since they are "more"
            #IF the current row's total is 0 then is is not a possible result and should stay at 0 occurances
            if ($script:arySumOrMoreTable[$Row,$CountColumn] -gt 0) {
               $script:arySumOrMoreTable[$Row,$CountColumn] = $script:arySumOrMoreTable[$Row,$CountColumn] + $($script:arySumOrMoreTable[$shortRow,$CountColumn])
            }
        }
    }
}






##################################################################################################
#
function Tally-ExactXOrMoreTable{

    if($showProcessing) {write-host "  Tally-ExactXOrMoreTable" -ForegroundColor green }

    #step through each row
    for($row=0; $row -lt $($script:aryUniqueFaces.count); $row++) {
        #step through each node count in that row
        for($col=1; $col -le $NodeCount; $col++) {
            [int]$rowSum = 0
            #total the node value for the current column and the columns to the right of that cloumn
            for($shortCol=$col; $shortCol -le $NodeCount; $shortCol++) {
                $rowSum = $rowSum + $aryExactlyXTable[$row,$shortCol]
            }
            #save the total to the Exact or more table
            $aryExactXOrMoreTable[$row,$col] = $rowSum
        }
    }
}



##################################################################################################
# 
function Incriment-SummaryArray {
    param(
        [string]$FaceName,            #the name of the face to incriment
        [int]$Occurnaces,             #the number of times the face occured
        [int]$Tally,                  #the number of times the face/occurance combo occured
        [switch]$ExactlyX,            #true if the Exact Occurnaces array shoud be updated
        [switch]$OrBetterHC,            #true if the Or Better array shoud be updated
        [switch]$OrBetterCalc,            #true if the Or Better array shoud be updated
        [switch]$HighFace,            #true if the HighFace array shoud be updated
        [switch]$LowFace,             #true if the LowFce array shoud be updated
        [switch]$Calculated,          #
        [switch]$BruteForce           #
    )

    #the row and column to update
    $row = Convert-FaceToRow -FaceName $FaceName

    #update arrays
    if ($ExactlyX) {
        $col = $Occurnaces
        $script:aryExactlyXTable[$row,$col] = $script:aryExactlyXTable[$row,$col] +1
    } elseif ($OrBetterHC) {
        $col = $Occurnaces
        $script:aryOrBetterBFTable[$row,$col] = $script:aryOrBetterBFTable[$row,$col] +1
    } elseif ($OrBetterCalc) {
        $col = $Occurnaces
        $script:aryOrBetterCalcTable[$row,$col] = $script:aryOrBetterCalcTable[$row,$col] +$Tally
    } elseif ($HighFace) {
        if($BruteForce) {
            $script:aryHighFaceTable[$row,1] = $script:aryHighFaceTable[$row,1] +1
        } else {
            $script:aryHighFaceTable[$row,2] = $script:aryHighFaceTable[$row,2] + $Occurnaces
        }
    } elseif ($LowFace) {
        if($BruteForce) {
            $script:aryLowFaceTable[$row,1] = $script:aryLowFaceTable[$row,1] +1
        } else {
            $script:aryLowFaceTable[$row,2] = $script:aryLowFaceTable[$row,2] + $Occurnaces
        }
    } 




}









##################################################################################################
# Display functions
##################################################################################################


##################################################################################################
#Displays the value of each node in the current event
function Display-CurrentRestult {
    
        [string]$output = "  ID: $script:resultID"
        foreach($result in $script:aryResult) {
            $output = $output + "   " + $result
        }
        Write-host 
        Write-host $output -ForegroundColor Yellow
    }
    
##################################################################################################
#Displays summary table for Math type tables
#
function Display-MathSummaryTable {
    param(
        [switch]$ExactTotal,
        [switch]$TotalOrMore
    )


    $outFormat = "{0,-1} {1,-10} {2,-10}"
    

    #output the formatted line of data
    if($ExactTotal) {
        $outTableTitle = "Exact Sum"
        $outDescritption = "How many times sum of the dice is exactly X (e.g. the dice sum to exacly 6)."
    } elseif($TotalOrMore) {
        $outTableTitle = "Sum Or Better"
        $outDescritption = "How many times sum of the dice is X or more (e.g. the dice sum to 6+)."
    }


    write-host
    write-host "------------------------------------------------------------------------------" -ForegroundColor green
    write-host "$outTableTitle ($($script:resultID +1) Possible Outcomes)" -ForegroundColor green
    write-host "$outDescritption"   -ForegroundColor green
    write-host "------------------------------------------------------------------------------" -ForegroundColor green
    write-host ($outFormat -f "","Total","Occ") 
    

    $arySize = $($script:aryExactSumTable).count /2
    if($ExactTotal){
        for($i = 0; $i -lt $arySize; $i++) {
            if(($aryExactSumTable[$i,1]) -gt 0) {
                write-host ($outFormat -f "",$($aryExactSumTable[$i,0]), $($aryExactSumTable[$i,1])) 
            }
        }
    }

    if($TotalOrMore){
        for($i = 0; $i -lt $arySize; $i++) {
            if(($arySumOrMoreTable[$i,1]) -gt 0) {
                write-host ($outFormat -f "",$($arySumOrMoreTable[$i,0]), $($arySumOrMoreTable[$i,1])) 
            }
        }
    }
}



##################################################################################################
#Displays summary table for Occurnace type tables
function Display-OccurnaceSummaryTable {
    param(
        [switch]$ExactlyX,              #True if the Exact Occurnaces table should be displayed
        [switch]$ExactXOrMore,               #True if the ExactXOrMore table should be displayed
        [switch]$XOrBetterBF,             #True if the OrBetter table should be displayed
        [switch]$XOrBetterCalc,             #True if the OrBetter table should be displayed
        [switch]$HighestFace,          #True if the OrBetter table should be displayed
        [switch]$LowestFace             #True if the OrBetter table should be displayed
    )


    #if no switch is true display nothing
    if(!$XOrBetterCalc -and !$XOrBetterBF -and !$ExactXOrMore -and !$ExactlyX -and !$HighestFace -and !$LowestFace) {return}

    $rowCount = $($script:aryUniqueFaces).count
    $colCount = $NodeCount +1

    #generate output format
    #initialize the format string
    $outFormat = "{0,-1} "
    for($col=0; $col -lt $colCount;$col++) {
        $indexNum = $col +1
        if($col -eq 0) {
            $outFormat = $outFormat + "{$indexNum,-12} "
        } else {
            $outFormat = $outFormat + "{$indexNum,-10} "
        }
    }

    #output the formatted line of data
    if($ExactlyX) {
        $outTableTitle = "Exactly X"
        $outDescritption = "How many times a face occurs exactly X times (e.g. exacly two 3's)."
        $outDescritption2 = "Mostly good for debugging and confirming the algorythms are functioning properly."
    } elseif($ExactXOrMore) {
        $outTableTitle = "Exactly X Or More"
        $outDescritption = "How many times a face occurs X times or more (e.g. two or more 3's)."
        $outDescritption2 = "Good for coin flips and game like Yahtee, where the exact value of the node is important."
    } elseif($XOrBetterBF) {
        $outTableTitle = "X Or Better BF"
        $outDescritption = "How many times a face or better occurs X times or more (e.g. 2 or more 3+'s )."
        $outDescritption2 = "Good for dice pools like X-Wing where Hits and Crits (and maybe Focuses) damage ships."
    } elseif($XOrBetterCalc) {
        $outTableTitle = "X Or Better Calc"
        $outDescritption = "How many times a face or better occurs X times or more (e.g. 2 or more 3+'s )."
        $outDescritption2 = "Good for dice pools like X-Wing where Hits and Crits (and maybe Focuses) damage ships."
    } elseif($HighestFace) {
        $outTableTitle = "HighestFace"
        $outDescritption = "HighestFace"
        $outDescritption2 = "HighestFace"
    } elseif($LowestFace) {
        $outTableTitle = "LowestFace"
        $outDescritption = "LowestFace"
        $outDescritption2 = "LowestFace"
    }


    write-host
    write-host "------------------------------------------------------------------------------" -ForegroundColor green
    write-host "$outTableTitle ($($script:resultID +1) Possible Outcomes)" -ForegroundColor green
    write-host "$outDescritption"   -ForegroundColor green
    write-host "$outDescritption2"   -ForegroundColor green
    write-host "------------------------------------------------------------------------------" -ForegroundColor green


    #output header rows
    $outData = @()     #initialize the data array to output the data
    $outData += ""
    for($col=0; $col -lt $colCount;$col++) {
        if($col -eq 0) {
            $outData += "Face"
        } else {
            $outData += $col
        }
    }
    write-host ("               Occurnaces") -ForegroundColor green
    write-host ($outFormat -f $outData) -ForegroundColor green

    #generate and output one row of data for each row
    for($row=0; $row -lt $rowCount;$row++) {
        $outData = @()     #initialize the data array to output the data
        $outData += ""
        for($col=0; $col -lt $colCount;$col++) {
            if($XOrBetterBF) {
                $outData += $script:aryOrBetterBFTable[$row,$col]
            } elseif($XOrBetterCalc) {
                $outData += $script:aryOrBetterCalcTable[$row,$col]
            } elseif($ExactXOrMore) {
                $outData += $script:aryExactXOrMoreTable[$row,$col]
            } elseif($ExactlyX) {
                $outData += $script:aryExactlyXTable[$row,$col]
            } elseif($LowestFace) {
                $outData += $script:aryLowFaceTable[$row,$col]
            } elseif($HighestFace) {
                $outData += $script:aryHighFaceTable[$row,$col]
            }
        }
        #output the formatted line of data
        write-host ($outFormat -f $outData)
    }
}
    
        

##################################################################################################
#Displays a summary of the event
function Display-ScenarioData {


    $outFormat = "{0,-1} {1,-14} {2,-20}"

    Write-Host 
    write-host "------------------------------------------------------------------------------" -ForegroundColor green
    Write-Host "Scenario Data" -ForegroundColor Green
    write-host "------------------------------------------------------------------------------" -ForegroundColor green


    if($systemName -ne "") {
        Write-Host ($outFormat -f "","System:",$systemName)  
    }

    Write-Host ($outFormat -f "","Nodes:",$NodeCount)  

    $faceList = ""
    foreach($face in $script:aryFaces) {
        $faceList = $faceList + $face + " "
    }
    Write-Host ($outFormat -f "","Faces:",$faceList)  

    Write-Host ($outFormat -f "","Face Count:",$($($script:aryFaces).count)) 
    Write-Host ($outFormat -f "","Result Count:",$($script:resultID +1))  
    


    $runTime = $(Get-Date) - $startTime
    Write-Host ($outFormat -f "","Run Time:",$runTime)  


}
#
##################################################################################################
#Displays tables based on the scenario type
#Scenarios:
#  MalifauxJokers
#  Coins
#  XWing

#Tables:
#  ScenarioData
#  OccurnaceSummaryTable -ExactlyX
#  OccurnaceSummaryTable -ExactXOrMore

#  OccurnaceSummaryTable -XOrBetterBF

#  OccurnaceSummaryTable -LowestFace
#  OccurnaceSummaryTable -HighestFace

#  MathSummaryTable -ExactTotal
#  MathSummaryTable -TotalOrMore



function Display-Tables {


    Display-ScenarioData

    if($ShowAllTables -or $ShowExacts) {
        Display-OccurnaceSummaryTable -ExactlyX
        Display-OccurnaceSummaryTable -ExactXOrMore
    }

    if($ShowAllTables -or $ShowOrBetter) {
        Display-OccurnaceSummaryTable -XOrBetterBF
        Display-OccurnaceSummaryTable -XOrBetterCalc
    }

    if($ShowAllTables -or $ShowHighLow) {
        Display-OccurnaceSummaryTable -LowestFace
        Display-OccurnaceSummaryTable -HighestFace
    }

    if($ShowAllTables -or $ShowSums) {
        Display-MathSummaryTable -ExactTotal
        Display-MathSummaryTable -TotalOrMore
    }


}



##################################################################################################
# Helper Functions
##################################################################################################


##################################################################################################
#Returns the row number of a given face value
function Convert-FaceToRow {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FaceName            #the name of the face to find
    )

    $rowCount = $($script:aryUniqueFaces).count -1
    for($row = $rowCount; $row -ge 0;$row--) {
        $colFace = $script:aryOrBetterBFTable[$row,0]
        if ($FaceName -eq $colFace) {
            $returnRow = $row
            #write-host "    Convert-FaceToRow                   $FaceName Row: $returnRow"
            return $returnRow
            break
        }
    }
}

##################################################################################################
#Returns the face name of a given row number
function Convert-RowToFace {
    param(
        [Parameter(Mandatory=$true)]
        [int]$RowNumber            #the number of the row to find
    )

    $returnFace = $script:aryUniqueFaces[$RowNumber]
    return $returnFace
}




##################################################################################################
## If not all faces in the face array are numberic then disable numeric processing.
function Confirm-FacesAreNumeric {


    #if any face is not numeric then change process sums to false
    foreach($face in $script:aryUniqueFaces) {
        if(isNumeric $face) {
        } else {
            $script:ShowSums = $false
            return
        }
    }
    #if no sum was not numeric the process sums
    $script:ShowSums = $true

}




######################################
# Determine if a string is numeric
function isNumeric ($x) {
    try {
        0 + $x | Out-Null
        return $true
    } catch {
        return $false
    }
}


##################################################################################################
# Main
##################################################################################################

######################################
# Setup
write-host
write-host
write-host
write-host
write-host
write-host
write-host
write-host
if($showProcessing) {write-host "" -ForegroundColor green }
if($showProcessing) {write-host "Setup Started" -ForegroundColor green }

$startTime = Get-Date
Create-RestultArray
Create-UniqueFacessTable
Create-OccuranceSummaryTables

if($ShowSums -or $ShowAllTables) {
    Confirm-FacesAreNumeric
}
if($ShowSums) {
    Create-MathSummaryTables
}




######################################
# Processing
if($showProcessing) {write-host "" -ForegroundColor green }
if($showProcessing) {write-host "Processing Started" -ForegroundColor green }
$aryDrawPool = Create-DrawPool -PoolIn $aryFaces
Generate-BruteForceResult -DrawPool $aryDrawPool
Calculate-TheoreticalResults
Tally-SummaryTables


######################################
# Restuls
if($showProcessing) {write-host "" -ForegroundColor green }
if($showProcessing) {write-host "Display Started" -ForegroundColor green }
Display-Tables
