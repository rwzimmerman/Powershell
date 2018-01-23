






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

#returns a set of number representing cards drawn from a fresh deck.
#an array of ints will be returned, each int will be unique
# https://blogs.technet.microsoft.com/heyscriptingguy/2011/05/27/use-a-simple-powershell-technique-to-create-random-numbers/
function Draw-CardsAsInts_OLD ([int] $HandSize = 1) {
    $cards = Get-Random -Count $HandSize -InputObject (0..53)
    return $cards
}


#takes an int and returns a card value 0 through 14 (no suit is returned)
#returns value /4 rounded up
#https://msdn.microsoft.com/en-us/library/zx4t0t48%28v=vs.110%29.aspx
function Translate-IntToCard_OLD {
    Param (
        [Parameter(Mandatory=$true)]
        [int] $IntValue
    ) 

    #devides the vlue by 4 and gives the smallest integral value that is greater than or equal to the result.
    [int]$CardValue = [int][Math]::Ceiling($IntValue/4)
    write-output $CardValue
}


#generates x random unique cards from a fresh deck, where x is the input number of cards to draw.
#Cards are returned in decimal format (e.g. 1.25, 4.75, 5.00)  where the whole number represents
#the value of the card and the decimal represends the suit.
function Draw-Cards {
    param(
        [int] $HandSize = 1,
        [Parameter(Mandatory=$true)]
        $valueArray,
        [Parameter(Mandatory=$true)]
        $suitArray
    )

    $cards = Get-Random -Count $HandSize -InputObject (0..53)

    for ($i = 0; $i -le $cards.Count -1; $i++) {
        
        


        $original = $cards[$i]
        $value = [int][Math]::Ceiling($cards[$i]/4)
        $suit = ($cards[$i]/4) - [int]($cards[$i]/4)
        
        if ($value -eq 0) {
            $suit = "-"
        } elseif ($value -eq 14) {
            $suit = "*"
        } elseif ($suit -eq 0) {
            $suit = "R"
        } elseif ($suit -eq 0.25) {
            $suit = "C"
        } elseif ($suit -eq -0.25) {
            $suit = "M"
        } elseif ($suit -eq -0.50) {
            $suit = "T"
        } elseif ($suit -eq 0.50) {
            $suit = "T"
        }




        Write-Host "$original : $value / $suit  "
        



    }

    [int]$CardValue = [int][Math]::Ceiling($IntValue/4)
    

    #return $cards
}




