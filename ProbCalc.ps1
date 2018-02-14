


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




#Arrays
$aryFaces = @()               #This array holds the value on each face of each node
$aryUniqueFaces = @()         #This array is a list of the unique faces on each node
$aryResult = @()              #This array is the current result
$arySumExactOcc = @()         #
$arySumOrBetter = @()         #

#Variables
$resultID = -1                #The current result



#Faces
#if a faces array is input then use it.
#if one of the 'system' (e.g. Xwing Attack Dice) switches is used then use the faces for that system.
if($Faces.count -ne 0) {
    $aryFaces = $Faces
}elseif($XWingAtt) {
    $aryFaces = @("Blank","Blank","Focus","Focus","Hit","Hit","Hit","Crit")
}elseif($XWingDef) {
    $aryFaces = @("Blank","Blank","Blank","Focus","Focus","Evade","Evade","Evade")
}elseif($PlayingCards) {
    $aryFaces = @("BJ","1H","1D","1C","1S","2H","2D","2C","2S","3H","3D","3C","3S","4H","4D","4C","4S",`
                         "5H","5D","5C","5S","6H","6D","6C","6S","7H","7D","7C","7S","8H","8D","8C","8S","9H","9D","9C","9S", `
                         "10H","10D","10C","10S","11H","11D","11C","11S","12H","12D","12C","12S","13H","13D","13C","13S","RJ")
}elseif($Malifaux) {
    $aryFaces = @("0-","1R","1M","1T","1C","2R","2M","2T","2C","3R","3M","3T","3C","4R","4M","4T","4C",`
                         "5R","5M","5T","5C","6R","6M","6T","6C","7R","7M","7T","7C","8R","8M","8T","8C","9R","9M","9T","9C", `
                         "10R","10M","10T","10C","11R","11M","11T","11C","12R","12M","12T","12C","13R","13M","13T","13C","14*")
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
## Create a table containing totals for exact results
function Create-SummaryTables {

    #creat the Exact and OrBetter summary arrays
    $faceCount = $script:aryUniqueFaces.count
    $script:arySumExactOcc = New-Object 'object[,]' $faceCount,$([int]$NodeCount+1)
    $script:arySumOrBetter = New-Object 'object[,]' $faceCount,$([int]$NodeCount+1)


    #get row and column sizes
    $rowCount = $($script:aryUniqueFaces).count
    $colCount = $NodeCount +1
    
    #put the face name in the 0 element in the array
    for($row = 0; $row -lt ($script:aryUniqueFaces).count; $row++) {
        $arySumExactOcc[$row,0] = $script:aryUniqueFaces[$row]
        $arySumOrBetter[$row,0] = $script:aryUniqueFaces[$row]
        #zero the rest of the values in the arrays
        for($col = 1; $col -le $([int]$NodeCount); $col++) {
            $arySumExactOcc[$row,$col] = 0
            $arySumOrBetter[$row,$col] = 0
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
        [int]$nodeNum = 1         #the current node
    )

    foreach($face in $script:aryFaces) {
        $script:aryResult[$nodeNum -1] = $face

        if($NodeCount -gt $nodeNum) {
            $nextNode = $nodeNum +1
            Generate-Result -nodeNum $nextNode
        } else {
            $script:resultID = $script:resultID +1
            Write-Progress -Activity "Generating Results" -status "Result $script:resultID of $script:estResultCount" -percentComplete ($script:resultID / $script:estResultCount * 100)
            #Display-CurrentRestult
            Analyze-Restult 
        }
    }
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
        }
    }
}


##################################################################################################
#Looks at the current result and writes data to the 'or better' table
#An 'or better' occurance would be how manyt times would you draws two sixes or better.
function Analyze-RestultForOrBetter {


    #Create a copy of the current result as row numbers
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
        [switch]$OrBetter             #true if the Or Better array shoud be updated
    )

    #the row and column to update
    $row = Convert-FaceToRow -FaceName $FaceName
    $col = $Occurnaces

    #update arrays
    if ($ExactOcc) {
        $script:arySumExactOcc[$row,$col] = $script:arySumExactOcc[$row,$col] +1
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
function Display-SummaryOrBetter {
    
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
function Display-SummaryExactOcc {
    
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
        [switch]$ExactOcc              #True if the Exact Occurnaces table should be displayed
    )


    #if neither switch is true display nothing
    if(!$OrBetter -and !$ExactOcc) {
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
        $outTableTitle = "Or Better Summary Table"
    } elseif($ExactOcc) {
        $outTableTitle = "Exact Occurance Summary Table"
    }


    write-host
    write-host "------------------------------------------------------------------------------" -ForegroundColor green
    write-host $outTableTitle -ForegroundColor green
    write-host "------------------------------------------------------------------------------" -ForegroundColor green
    write-host ($outFormat -f $outData) -ForegroundColor green

    #generate and out put one row of data for each row
    for($row=0; $row -lt $rowCount;$row++) {
        $outData = @()     #initialize the data array to output the data
        $outData += ""
        for($col=0; $col -lt $colCount;$col++) {
            if($OrBetter) {
                $outData += $script:arySumOrBetter[$row,$col]
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
    
    if($XWingAtt) {
        Write-Host ($outFormat -f "","System:","XWing Attack Dice")  
    } elseif($XWingDef) {
        Write-Host ($outFormat -f "","System:","xWing Defence Dice")  
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
Generate-Result

######################################
# Restuls
Display-ScenarioData
Display-SummaryTable -OrBetter
Display-SummaryTable -ExactOcc






