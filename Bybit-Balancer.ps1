<#

Bybit SPOT Balancer

- Connects with a Bybit Spot (sub)account en equaly spread the tokens that are found, based on USDT.
- This script will look at the USDT-based value of your tokens and auto-rebalance.

Requirements:
- Bybit API information
  - Permissions needed: SPOT - Trade
- Some USDT
- Some other tokens to balance with

Usage:
- ADD a token to the balance
  - Buy this token in a random amount, this script will rebalance automatically with the tokens that you have.
- REMOVE a token to the balance
  - Sell this token entirely for USDT or another token that you already have, this script will rebalance automatically with the tokens that are left.

#>


$global:wen_rebalance = 5.0  # procent of deviation needed before a token will rebalance


##########################################################################################################

# Enforce Enhlish style dots and commas
[cultureinfo]::currentculture = 'en-US'

# Import the CorpusCrypto module
Import-Module -Name .\Modules\CorpusCrypto -WarningAction SilentlyContinue -Force

##################
# Connect with Bybit and request the balance
#
$balances = Connect-Bybit #-Verbose

# Collect the available symbols and their price
$price = Get-BybitRest -Endpoint "/spot/v3/public/quote/ticker/price"

# Combine balance with the pair and the last price
#   In multiple loops, as we use the fields of the previous loop
#   Convert existing nummeric values to local decimals to avoid it's seen as string
$balances | ForEach-Object { 
  $_ | Add-Member -Force -MemberType NoteProperty -Name 'amount' -Value ($_.total -as [decimal])
  $_ | Add-Member -Force -MemberType NoteProperty -Name 'free' -Value ($_.free -as [decimal])
  $_ | Add-Member -Force -MemberType NoteProperty -Name 'locked' -Value ($_.locked -as [decimal])

  if ($_.coin -eq 'USDT') { $pair = '' } else { $pair = $_.coin + 'USDT' }
  $_ | Add-Member -Force -MemberType NoteProperty -Name 'pair' -Value $pair
}
$balances | ForEach-Object { 
  $_ | Add-Member -Force -MemberType NoteProperty -Name 'price_usd' -Value ((($price.list | Where-Object symbol -eq $_.pair).price) -as [decimal])
  if ( $_.coin -eq 'USDT' ) { $_.price_usd = 1 }
}
$balances | ForEach-Object { 
  $_ | Add-Member -Force -MemberType NoteProperty -Name 'value_usd' -Value ( [math]::Round(($_.amount * $_.price_usd -as [decimal]),3) )
}

# Find the average price
$measure = $balances | Measure-Object -Property value_usd -Sum -Average
$average = $measure.Average
$total = $measure.Sum

$balances | ForEach-Object {
  $deviation = [math]::Round(100 * ($_.value_usd - $average) / $average, 3)
  if ( $deviation -lt 0 ) { $deviation = - $deviation }
  $_ | Add-Member -Force -MemberType NoteProperty -Name 'deviation_pct' -Value $deviation
  if ( $deviation -gt $wen_rebalance -and $_.coin -ne 'USDT' ) { $rebalance = '  YES'} else { $rebalance = ' '}
  $_ | Add-Member -Force -MemberType NoteProperty -Name 'rebalance' -Value $rebalance
}

# Show on screen
Write-Host "Total coins: $($balances.Count)" -ForegroundColor Green -BackgroundColor Black
Write-Host "Total value: $($total.ToString('#.##')) USDT" -ForegroundColor Green -BackgroundColor Black
Write-Host "Average value: $($average.ToString('#.##')) USDT" -ForegroundColor Green -BackgroundColor Black
$balances | Select-Object coin,amount,price_usd,value_usd,deviation_pct,rebalance | Sort-Object value_usd | Format-Table -AutoSize | Out-String | Write-Host

##################
# Determine what to buy or sell and execute
#
$todo = $balances | Where-Object deviation_pct -gt $wen_rebalance | Where-Object coin -ne 'USDT'
if ( $todo.coin.Count ) {
  $todo | ForEach-Object {
    if ( $_.value_usd -lt $average ) { 
      $side = 'Buy' # so in USDT
      $quantity = ($_.value_usd * ($average / $_.value_usd - 1)).ToString('#0.##')
      Write-Host "BUY $quantity USD of $($_.coin)" -ForegroundColor Green -BackgroundColor Black -NoNewline
    } else { 
      $side = 'Sell' # so in TOKEN
      $quantity = ($_.amount * ($_.value_usd - $average) / $_.value_usd).ToString('#0.##')
      Write-Host "SELL $quantity $($_.coin)" -ForegroundColor Red -BackgroundColor Black -NoNewline
    }

    # Place active order
    $body = @{}
    $body.Add("symbol", $_.pair)
    $body.Add("orderQty", $quantity)
    $body.Add("side", $side)
    $body.Add("orderType", 'MARKET')
    $body = $body | ConvertTo-Json

    $response = ""
    $response = Post-BybitRest -Endpoint "/spot/v3/private/order" -Body $body
    if ( $response.side -eq 'BUY' ) { $token = 'USDT' } else { $token = $_.coin }
    Write-Host " ... order created:  $($response.side) | $($response.symbol) | $($response.orderQty) $token" -ForegroundColor White -BackgroundColor Black
    #$response | ConvertTo-Json
  }
} else {
  Write-Host "Nicely balanced.... nothing to do...." -ForegroundColor Green -BackgroundColor Black
}
