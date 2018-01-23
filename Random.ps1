






<#
    .SYNOPSIS
        Determines Malifaux averages

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



# ============================================================================================== 
# Wrapper Setup
# Load libraries
# ============================================================================================== 
param (
    
        [int]$AttStat,             #The value of the attacker's relevant stat 
        [int]$AttCards,            #The number of cards the attacker is flipping 
        [switch]$AttPos,           #True of the attacker is on a positive twist defaults to true
        [switch]$AttNeg,           #True of the attacker is on a negative twist defaults to false
        [int]$DefStat,             #The value of the defender's relevant stat 
        [int]$DefCards,            #The number of cards the defender is flipping 
        [switch]$DefPos,           #True of the defender is on a positive twist defaults to true
        [switch]$DefNeg            #True of the defender is on a negative twist defaults to false
    )



# ============================================================================================== 
# Determine if there is positive or negative twist.
if ($AttNeg) {
    $AttPos = $false
} else {
    $AttPos = $true
}

if ($DefNeg) {
    $DefPos = $false
} else {
    $DefPos = $true
}

# ============================================================================================== 
# Card Draw Functions
# ============================================================================================== 

#Constants

$freshDeck = 0,1,1,2,2,3,3,14      #array represening a fresh deck of cards


#generate all possible card draws by each side

$attResults = @()
$defResults = @()


function PopulateResults2{
    param(
        [int]$DrawSize=1,    #The number of cards to draw
        [int[]]$CardList,    #the list of cards for this element
        [switch]$Att,        #true if the attacker is be populated
        [switch]$Def         #true if the defender is be populated
    )


    if ($DrawSize -le 1) {
        Write-Output "drawsize small"
        Write-Output $CardList
        #write final array
        $attResults = $CardList
        return
    }

    if($att) {
        Write-Output "Attacker draws $drawsize"
    }elseif($def){
        Write-Output "Defender draws $drawsize"
    }else{
        write-output "No recipient (Att/Def) Specified.  Exiting."
        return
    }


    foreach ($card in $freshDeck) {
        Write-Output "ForEach Carlist"
        $CardList = $CardList + $Card
        $CardList = $CardList + $Card
        
        write $CardList
    }
    


    



}











function PopulateResults{
    $freshDeck = 0,1,1,2,2,3,3,14      #array represening a fresh deck of cards
    
    PopulateResults2 -Att -DrawSize 1 -CardList $freshDeck

    Write-Output "Results"
    write-output $attResults
}
    

