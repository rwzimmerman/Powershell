


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
#$aryBFExactlyXTable = @()          #
#$aryBFExactXOrMoreTable = @()      #
#$aryBFOrBetterTable = @()          #

#$aryCalcExactlyXTable = @()          #
#$aryCalcOrBetterTable = @()        #

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
    $ShowOrBetter = $true
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


$ShowExacts = $true

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
    $script:aryBFExactlyXTable = New-Object 'object[,]' $faceCount,$([int]$NodeCount+2)
    $script:aryBFOrBetterTable = New-Object 'object[,]' $faceCount,$([int]$NodeCount+2)
    $script:aryBFExactXOrMoreTable = New-Object 'object[,]' $faceCount,$([int]$NodeCount+2)

    $script:aryCalcExactlyXTable = New-Object 'object[,]' $faceCount,$([int]$NodeCount+2)
    $script:aryCalcOrBetterTable = New-Object 'object[,]' $faceCount,$([int]$NodeCount+2)

    $script:aryHighFaceTable = New-Object 'object[,]' $faceCount,$([int]$NodeCount+2)
    $script:aryLowFaceTable = New-Object 'object[,]' $faceCount,$([int]$NodeCount+2)


    #get row and column sizes
    $rowCount = $($script:aryUniqueFaces).count
    $colCount = $NodeCount +1
    
    #put the face name in the 0 element in the array
    for($row = 0; $row -lt ($script:aryUniqueFaces).count; $row++) {
        $aryBFExactlyXTable[$row,0] = $script:aryUniqueFaces[$row]
        $aryCalcExactlyXTable[$row,0] = $script:aryUniqueFaces[$row]
        $aryBFOrBetterTable[$row,0] = $script:aryUniqueFaces[$row]
        $aryCalcOrBetterTable[$row,0] = $script:aryUniqueFaces[$row]
        $aryHighFaceTable[$row,0] = $script:aryUniqueFaces[$row]
        $aryLowFaceTable[$row,0] = $script:aryUniqueFaces[$row]
        #zero the rest of the values in the arrays
        for($col = 1; $col -le $([int]$NodeCount)+1; $col++) {
            $aryBFExactlyXTable[$row,$col] = 0
            $aryCalcExactlyXTable[$row,$col] = 0
            $aryBFOrBetterTable[$row,$col] = 0
            $aryCalcOrBetterTable[$row,$col] = 0
            $aryBFExactXOrMoreTable[$row,$col] = 0
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



    Calculate-X







}




##################################################################################################
# xxxxxx
function Calculate-X {


    foreach($face in $script:aryUniqueFaces) {

        #Get how many times the current face occures on the node
        $matchingFaceCount =  Get-FaceCount -FaceName $face
        #get how many faces the current node has in total
        $totalFaceCount =  $script:aryFaces.Count 
        write-host "`n$face - FC: $matchingFaceCount / $totalFaceCount - NC : $NodeCount" -ForegroundColor Yellow
        
        #The sum of the chances so far.  Mostly for debugging.  It should sum to 100%
        $ExacltyXChanceSum = 0

        #step the number of time the face can occure (0 to the node count)
        for($occCount = 0; $occCount -le $NodeCount; $occCount++) {
            #Do a combination calcuation for distribution of times the node occures exaclty k times
            $comb = Get-Combination -n $NodeCount -k $occCount
            #Calculate the percentage of the face occurning on the node
            $successChance = $matchingFaceCount / $totalFaceCount
            #Calculate the percentage of the face NOT occurning on the node
            $failuerChance = ($totalFaceCount - $matchingFaceCount) / $totalFaceCount
            #Get the percentage chance the face will occure exactly k times.
            $ExacltyXChance = Get-Binomial -n $NodeCount -k $occCount -p $successChance
            $ExacltyXChanceSum = $ExacltyXChanceSum + $ExacltyXChance
            Write-Host "$occCount $face -  comb ($comb) - % chance ($($ExacltyXChance * 100))  % chance sum ($($ExacltyXChanceSum * 100))"
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
            Incriment-SummaryArray -FaceName $face -OccCount $occurances -ExactlyX
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
        Incriment-SummaryArray -FaceName $faceName -OccCount $quant -OrBetter -BruteForce
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
                $script:aryBFOrBetterTable[$Row,$col] = $script:aryBFOrBetterTable[$Row,$col] + $($script:aryBFOrBetterTable[$shortRow,$col])
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
        for($col=1; $col -le $NodeCount+1; $col++) {
            [int]$rowSum = 0
            #total the node value for the current column and the columns to the right of that cloumn
            for($shortCol=$col; $shortCol -le $NodeCount+1; $shortCol++) {
                $rowSum = $rowSum + $aryBFExactlyXTable[$row,$shortCol]
            }
            #save the total to the Exact or more table
            $aryBFExactXOrMoreTable[$row,$col] = $rowSum
        }
    }
}



##################################################################################################
# 
function Incriment-SummaryArray {
    param(
        [string]$FaceName,            #the name of the face to incriment
        [int]$OccCount,               #the number of times the face occured
        [int]$Tally,                  #the number of times the face/occurance combo occured
        [switch]$OrBetter,            #
        [switch]$ExactlyX,            #true if the Exact Occurnaces array shoud be updated
        [switch]$HighFace,            #true if the HighFace array shoud be updated
        [switch]$LowFace,             #true if the LowFce array shoud be updated
        [switch]$Calculated,          #
        [switch]$BruteForce           #
    )

    #the row and column to update
    $row = Convert-FaceToRow -FaceName $FaceName

    #update Exaclty X tables
    if ($ExactlyX) {
        $col = $OccCount +1
        $script:aryBFExactlyXTable[$row,$col] = $script:aryBFExactlyXTable[$row,$col] +1
    
    #update X Or Better tables
    } elseif ($OrBetter) {
        if($BruteForce) {
            $col = $OccCount +1
            $script:aryBFOrBetterTable[$row,$col] = $script:aryBFOrBetterTable[$row,$col] +1
        } elseif($Calculated) {
            $col = $OccCount +1
            $script:aryCalcOrBetterTable[$row,$col] = $script:aryCalcOrBetterTable[$row,$col] + $Tally
        }

    #udpate High Face    
    } elseif ($HighFace) {
        if($BruteForce) {
            $script:aryHighFaceTable[$row,1] = $script:aryHighFaceTable[$row,1] +1
        } elseif ($Calculated) {
            $script:aryHighFaceTable[$row,2] = $script:aryHighFaceTable[$row,2] + $OccCount
        }

    #update Low Face
    } elseif ($LowFace) {
        if($BruteForce) {
            $script:aryLowFaceTable[$row,1] = $script:aryLowFaceTable[$row,1] +1
        } elseif ($Calculated) {
            $script:aryLowFaceTable[$row,2] = $script:aryLowFaceTable[$row,2] + $OccCount
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
#yyy
function Display-OccurnaceSummaryTable {
    param(
        [switch]$ExactlyX,              #True if the Exact Occurnaces table should be displayed
        [switch]$ExactXOrMore,               #True if the ExactXOrMore table should be displayed
        [switch]$XOrBetter,             #True if the OrBetter table should be displayed
        [switch]$HighestFace,          #True if the OrBetter table should be displayed
        [switch]$LowestFace,             #True if the OrBetter table should be displayed
        [switch]$ShowBF,
        [switch]$ShowCalc,
        [switch]$ShowBoth
        
    )


    #if no switch is true display nothing
    if(!$ExactlyX -and !$ExactXOrMore -and !$XOrBetter -and !$HighestFace -and !$LowestFace) {return}

    $rowCount = $($script:aryUniqueFaces).count
    $colCount = $NodeCount +2

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
    } elseif($XOrBetter) {
        $outTableTitle = "X Or Better"
        $outDescritption = "How many times a face or better occurs X times or more (e.g. 2 or more 3+'s )."
        $outDescritption2 = "Good for dice pools like X-Wing where Hits and Crits (and maybe Focuses) damage ships."
    } elseif($HighestFace) {
        $outTableTitle = "Highest Face"
        $outDescritption = "HighestFace"
        $outDescritption2 = "HighestFace"
    } elseif($LowestFace) {
        $outTableTitle = "Lowest Face"
        $outDescritption = "LowestFace"
        $outDescritption2 = "LowestFace"
    }




    write-host
    write-host "------------------------------------------------------------------------------" -ForegroundColor green
    write-host "$outTableTitle ($($script:resultID +1) Possible Outcomes)" -ForegroundColor green
    write-host "$outDescritption"   -ForegroundColor green
    write-host "$outDescritption2"   -ForegroundColor green
    write-host "------------------------------------------------------------------------------" -ForegroundColor green





    #Brute Force
    if($ShowBF -or $ShowBoth) {
        
        #output header rows
        $outData = @()     #initialize the data array to output the data
        $outData += ""
        for($col=0; $col -lt $colCount;$col++) {
            if($col -eq 0) {
                $outData += "Face"
            } else {
                $outData += $col -1
            }
        }
        write-host 
        write-host ("               Occurnaces (Brute Force)") -ForegroundColor yellow
        write-host ($outFormat -f $outData) -ForegroundColor green

        #generate and output one row of data for each row
        for($row=0; $row -lt $rowCount;$row++) {
            $outData = @()     #initialize the data array to output the data
            $outData += ""
            for($col=0; $col -lt $colCount;$col++) {
                if($XOrBetter) {
                    $outData += $script:aryBFOrBetterTable[$row,$col]
                } elseif($ExactXOrMore) {
                    $outData += $script:aryBFExactXOrMoreTable[$row,$col]
                } elseif($ExactlyX) {
                    $outData += $script:aryBFExactlyXTable[$row,$col]
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


    #Calculated 
    if($ShowCalc -or $ShowBoth) {
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
        write-host 
        write-host ("               Occurnaces (Calculated)") -ForegroundColor green
        write-host ($outFormat -f $outData) -ForegroundColor green
        
        #generate and output one row of data for each row
        for($row=0; $row -lt $rowCount;$row++) {
            $outData = @()     #initialize the data array to output the data
            $outData += ""
            for($col=0; $col -lt $colCount;$col++) {
                if($XOrBetter) {
                    $outData += $script:aryCalcOrBetterTable[$row,$col]
                } elseif($ExactlyX) {
                    $outData += $script:aryCalcExactlyXTable[$row,$col]
                }
            }
            #output the formatted line of data
            write-host ($outFormat -f $outData)
        }
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



function Display-Tables {


    Display-ScenarioData

    if($ShowAllTables -or $ShowExacts) {
        Display-OccurnaceSummaryTable -ExactlyX -ShowBoth
        Display-OccurnaceSummaryTable -ExactXOrMore -ShowBF
    }

    if($ShowAllTables -or $ShowOrBetter) {
        Display-OccurnaceSummaryTable -XOrBetter -ShowBoth
    }

    if($ShowAllTables -or $ShowHighLow) {
        Display-OccurnaceSummaryTable -LowestFace -ShowBoth
        Display-OccurnaceSummaryTable -HighestFace  -ShowBoth
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
#Returns the number of times a face occurs in the face array.
function Get-FaceCount {
    param (
        [string]$FaceName          #The name of the face to count
    )

    $faceCount = 0
    foreach($face in $script:aryFaces) {
        if($face -eq $FaceName) {
            $faceCount = $faceCount +1
        }
    }
    return $faceCount
}




##################################################################################################
#Returns the lowest row number of a given face value in the Faces Table

function Convert-FaceToLowestRow {
    param(
        $FaceName
    )

    #step through the face array returning the row number for the first match
    for($i = 0; $i -le $script:aryFaces.count; $i++ ) {
        if($script:aryFaces[$i] -eq $FaceName) {
            #return the number of the row maching the face
            return $i
        }
    }
    #if no matches were found return -1
    return -1
}




##################################################################################################
#Returns the row number of a given face value
function Convert-FaceToRow {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FaceName            #the name of the face to find
    )

    $rowCount = $($script:aryUniqueFaces).count -1
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
# Returns the row matching he face name in the Unique Faces table
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



##################################################################################################
# Math Functions
##################################################################################################


######################################
# Return true if a string is numeric
function isNumeric ($x) {
    try {
        0 + $x | Out-Null
        return $true
    } catch {
        return $false
    }
}


######################################
# Perform Combintaion
# C(n,k) = n!/k!(n-k)!
# C = the number of times a given face will be present exaclty k times in all possible outcomes in a set of n nodes.

function Get-Combination{
    param(
        [int]$n,
        [int]$k
    )

    #get factorials
    $nfac = Get-Factorial $n
    $kfac = Get-Factorial $k
    $nMinusKfac = Get-Factorial $($n-$k)

    #get combination
    $c = $nfac / ($kfac * $nMinusKfac)
    return $c
}



######################################
# Perform a Binomial calculation that will return the precentage chance that a face
# will appear exaclty k times in n nodes when the probability of the face appearing
# on a given node is p.
# Binomial = (C(n,k)) * (p^k) * ((1-p)^(n-k))
# C(n,k) = n!/k!(n-k)!
# k = the numer of exact time an element will be present
# n = the number of nodes in the event
# p = the probability of success (in percent)

function Get-Binomial {
    param(
        [int]$n,
        [int]$k,
        [single]$p
    )


    #write-host "k (exact count): $k"
    #write-host "n (nodes):       $n"
    #write-host "p (success):     $p"
    
    #use a combination calculation to get the distribution of k appearing in n
    [single]$c = Get-Combination -n $n -k $k
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
function Get-Factorial {
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
