


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
        Add "Equivalent Faces" logic.  So heads is not better than tails or vice versa
        Add "reroll logic" allow for rerolls and caclute percentages after a reroll
        add "summing logic" if all faces are numeric then add them to gether (e.g. 1,1,3 = 5)
        add "malifaux logic" account for red and black jokers.
        add more built in systems like Malifaux, d4, d6, etc.


        Array notes
        https://powershell.org/2013/09/16/powershell-performance-the-operator-and-when-to-avoid-it/


    .LINK
        
#> 


#https://weblogs.asp.net/soever/powershell-return-values-from-a-function-through-reference-parameters




param(
    [int]$NodeCount=2,          #the number of elements in the randomization (e.g. 3 cards, 2 dice, etc.)
    [string[]]$Faces,           #
    [switch]$ExhaustFaces,      #
    [switch]$XWingAtt,          #True if XWing attack dice are being used 
    [switch]$XWingDef,          #True if XWing defence dice are being used 
    [switch]$PlayingCards,      #True if a deck of playing cards are being used 
    [switch]$MalifauxSuited,    #
    [switch]$MalifauxUnsuited,  #
    [switch]$Example,            #
    [switch]$Test,              #Test Data
    [switch]$ShowDebug          #if true debuging data will be displayed when the script executes.

)




#Arrays
$aryFaces = @()               #This array holds the value on each face of each node
$aryUniqueFaces = @()         #This array is a list of the unique faces on each node
$aryResult = @()              #This array is the current result
$arySumExactOcc = @()         #
$arySumOrBetter = @()         #
$arySumOrMore = @()           #

#Variables
$resultID = -1                #The current result
$systemName =""               #The name of the system used if any


#Faces
#if a faces array is input then use it.
#if one of the 'system' (e.g. Xwing Attack Dice) switches is used then use the faces for that system.
if($Faces.count -ne 0) {
    $aryFaces = $Faces
}elseif($XWingAtt) {
    $aryFaces = @("Blank","Blank","Focus","Focus","Hit","Hit","Hit","Crit")
    $systemName = "X-Wing Attack Dice"
}elseif($XWingDef) {
    $aryFaces = @("Blank","Blank","Blank","Focus","Focus","Evade","Evade","Evade")
    $systemName = "X-Wing Defence Dice"
}elseif($Test) {
    $aryFaces = @("BJ","1","2","3","4","4","5","5","6","RJ")
    $systemName = "Test Data"
}elseif($Example) {
    $aryFaces = @("1","1","2","2","3","4","5","6")
    $systemName = "Example"
}elseif($MalifauxUnsuited) {
    $aryFaces = @("BJ","1","1","1","1","2","2","2","2","3","3","3","3","4","4","4","4",`
                  "5","5","5","5","6","6","6","6","7","7","7","7","8","8","8","8","9","9","9","9", `
                  "10","10","10","10","11","11","11","11","12","12","12","12","13","13","13","13","RJ")
    $systemName = "Malifaux Unsuited Cards"
}elseif($MalifauxSuited) {
    $aryFaces = @()
    for($i = 1; $i -le 39; $i++) {
        $aryFaces += "NA"
    }
    $aryFaces += @("BJ","1","2","3","4","5","6","7","8","9","10","11","12","13","RJ")
    $systemName = "Malifaux Sited Cards"
}else{
    $aryFaces = @("Heads","Tails")
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

    for($i = 1; $i -le $NodeCount; $i++) {
        $script:aryResult += "empty"
    }
}

##################################################################################################
## Create a table containing a list of each unique face
function Create-UniqueFacessTable {
    
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
## Create a summary tables.  These tables count the number of times a give combination occurs
function Create-SummaryTables {

    #creat the Exact and OrBetter summary arrays
    $faceCount = $script:aryUniqueFaces.count
    $script:arySumExactOcc = New-Object 'object[,]' $faceCount,$([int]$NodeCount+1)
    $script:arySumOrBetter = New-Object 'object[,]' $faceCount,$([int]$NodeCount+1)
    $script:arySumOrMore = New-Object 'object[,]' $faceCount,$([int]$NodeCount+1)


    #get row and column sizes
    $rowCount = $($script:aryUniqueFaces).count
    $colCount = $NodeCount +1
    
    #put the face name in the 0 element in the array
    for($row = 0; $row -lt ($script:aryUniqueFaces).count; $row++) {
        $arySumExactOcc[$row,0] = $script:aryUniqueFaces[$row]
        $arySumOrBetter[$row,0] = $script:aryUniqueFaces[$row]
        $arySumOrMore[$row,0] = $script:aryUniqueFaces[$row]
        #zero the rest of the values in the arrays
        for($col = 1; $col -le $([int]$NodeCount); $col++) {
            $arySumExactOcc[$row,$col] = 0
            $arySumOrBetter[$row,$col] = 0
            $arySumOrMOre[$row,$col] = 0
        }
    }
}




##################################################################################################
# Processing functions
##################################################################################################


##################################################################################################
#Steps through each face of a node
function Generate-Result {
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
            Generate-Result -nodeNum $nextNode -DrawPool $nextDrawPool
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

function Analyze-Restult {
    Analyze-RestultForExactOccurances
    Analyze-RestultForOrBetter

}


##################################################################################################
#Looks at the current result and writes data to the exact occurance table
#An exact occurance would be how many times do exaclty two 6' occure.
function Analyze-RestultForExactOccurances {


    foreach ($face in $script:aryUniqueFaces){
        $occurances = 0
        foreach ($node in $script:aryResult) {
            if($face -eq $node) {
                $occurances++
            }
        }
        if($occurances -gt 0) {
            #write-host "    Analyze-RestultForExactOccurances:  $occurances $face"
            #update the exact occurnace array
            Incriment-SummaryArray -FaceName $face -Occurnaces $occurances -ExactOcc
            Incriment-SummaryArray -FaceName $face -Occurnaces $occurances -OrMore
        }
    }
}


##################################################################################################
#Looks at the current result and writes data to the 'or better' table
#An 'or better' occurance would be how many times would you draws two sixes or better.
function Analyze-RestultForOrBetter {



    #Create a copy of the current result and convert the faces to numbers
    $aryResultAsRows = @()
    for($i = 0; $i -lt $script:aryResult.count; $i++) {
        $row = Convert-FaceToRow -FaceName $script:aryResult[$i]
        $aryResultAsRows += $row
    }

    #sort the array so lowest result is first
    $aryResultAsRowsSorted = $aryResultAsRows | Sort-Object -Descending

    for($i = 0; $i -lt $aryResultAsRowsSorted.count; $i++) {
        $faceName = Convert-RowToFace -RowNumber $aryResultAsRowsSorted[$i]
        $occ = $i + 1
        Incriment-SummaryArray -FaceName $faceName -Occurnaces $occ -OrBetter
    }
}






##################################################################################################
# 
function Incriment-SummaryArray {
    param(
        [string]$FaceName,            #the name of the face to incriment
        [int]$Occurnaces,             #the number of times the face occured
        [switch]$ExactOcc,            #true if the Exact Occurnaces array shoud be updated
        [switch]$OrBetter,             #true if the Or Better array shoud be updated
        [switch]$OrMore             #true if the Or Better array shoud be updated
    )

    #the row and column to update
    $row = Convert-FaceToRow -FaceName $FaceName
    $col = $Occurnaces

    #update arrays
    if ($ExactOcc) {
        $script:arySumExactOcc[$row,$col] = $script:arySumExactOcc[$row,$col] +1
    }

    if ($OrMore) {
        for($i = 1; $i -le $col; $i++) {
            $script:arySumOrMore[$row,$i] = $script:arySumOrMore[$row,$i] +1
        }
    }

    if ($OrBetter) {
        for($i = $row; $i -ge 0; $i--) {
            $script:arySumOrBetter[$i,$col] = $script:arySumOrBetter[$i,$col] +1
        }
    }
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
        $colFace = $script:arySumOrBetter[$row,0]
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
#Displays the summary table for Exact Occurnaces
function DELETE_Display-SummaryOrBetter {
    
    write-host
    write-host "Or Better Summary Table" -ForegroundColor green
    $rowCount = $($script:aryUniqueFaces).count
    $colCount = $NodeCount +1
    
    for($row=0; $row -lt $rowCount;$row++) {
        $outPut = "  "
        for($col=0; $col -lt $colCount;$col++) {
            $outPut = $outPut + [string]$script:arySumOrBetter[$row,$col] + "   "
        }
        write-host $outPut
    }
}
    
##################################################################################################
#Displays the summary table for Exact Occurnaces
function DELETE_Display-SummaryExactOcc {
    
    write-host
    write-host "Exact Occurance Summary Table" -ForegroundColor green
    $rowCount = $($script:aryUniqueFaces).count
    $colCount = $NodeCount +1
    
    for($row=0; $row -lt $rowCount;$row++) {
        $outPut = "  "
        for($col=0; $col -lt $colCount;$col++) {
            $outPut = $outPut + [string]$script:arySumExactOcc[$row,$col] + "   "
        }
        write-host $outPut
    }
}




##################################################################################################
#Displays the summary table for Exact Occurnaces
function Display-SummaryTable {
    param(
        [switch]$OrBetter,             #True if the OrBetter table should be displayed
        [switch]$OrMore,               #True if the OrMore table should be displayed
        [switch]$ExactOcc              #True if the Exact Occurnaces table should be displayed
    )


    #if neither switch is true display nothing
    if(!$OrBetter -and !$OrMore -and !$ExactOcc) {
        return
    }

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
            $outFormat = $outFormat + "{$indexNum,-6} "
        }
    }

    #output header row
    $outData = @()     #initialize the data array to output the data
    $outData += ""
    for($col=0; $col -lt $colCount;$col++) {
        if($col -eq 0) {
            $outData += "Face"
        } else {
            $outData += $col
        }
    }
    
    #output the formatted line of data

    if($OrBetter) {
        $outTableTitle = "Or Better Table"
        $outDescritption = "This table shows how many occurances have the face or a better result the given number of times or more (e.g. 2 or more three's or better). "
    } elseif($OrMore) {
        $outTableTitle = "Or More Table"
        $outDescritption = "This table shows how many occurances have the face the given number of times or more (e.g. 2 or more threes). "
    } elseif($ExactOcc) {
        $outTableTitle = "Occurances Table"
        $outDescritption = "The acutal number of times a combo (e.g. exacly 2 threes) occurs."
    }


    write-host
    write-host "------------------------------------------------------------------------------" -ForegroundColor green
    write-host "$outTableTitle           Possible restuls: $($script:resultID +1)"   -ForegroundColor green
    write-host "$outDescritption"   -ForegroundColor green
    write-host "------------------------------------------------------------------------------" -ForegroundColor green
#    Write-Host ($outFormat -f "","Result Cnt:",$($script:resultID +1))  

    write-host ($outFormat -f $outData) -ForegroundColor green

    #generate and out put one row of data for each row
    for($row=0; $row -lt $rowCount;$row++) {
        $outData = @()     #initialize the data array to output the data
        $outData += ""
        for($col=0; $col -lt $colCount;$col++) {
            if($OrBetter) {
                $outData += $script:arySumOrBetter[$row,$col]
            } elseif($OrMore) {
                $outData += $script:arySumOrMore[$row,$col]
            } elseif($ExactOcc) {
                $outData += $script:arySumExactOcc[$row,$col]
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


    Write-Host ($outFormat -f "","Nodes:",$NodeCount)  

    $faceList = ""
    foreach($face in $script:aryFaces) {
        $faceList = $faceList + $face + " "
    }
    Write-Host ($outFormat -f "","Faces:",$faceList)  

    Write-Host ($outFormat -f "","Face Cnt:",$($($script:aryFaces).count)) 
    Write-Host ($outFormat -f "","Result Cnt:",$($script:resultID +1))  
    
    if($systemName -ne "") {
        Write-Host ($outFormat -f "","System:",$systemName)  
    }


    $runTime = $(Get-Date) - $startTime
    Write-Host ($outFormat -f "","Run Time:",$runTime)  


}



##################################################################################################
# Main
##################################################################################################

######################################
# Setup
$startTime = Get-Date
Create-RestultArray
Create-UniqueFacessTable
Create-SummaryTables

######################################
# Processing
$aryDrawPool = Create-DrawPool -PoolIn $aryFaces
Generate-Result -DrawPool $aryDrawPool

######################################
# Restuls
Display-ScenarioData
Display-SummaryTable -ExactOcc
Display-SummaryTable -OrMore
Display-SummaryTable -OrBetter






