<#


#>
[CmdletBinding()]
param()

function Get-BybitRest {
  [CmdletBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [string]$endpoint
  )

  Write-Verbose ". Get-BybitRest"

  # Get the current serverTime
  try {
    $response = ""
    $response = Invoke-RestMethod -Uri ($Config.bybitURL + "/spot/v3/public/server-time")
    $serverTime = $response.result.serverTime
    Write-Verbose "serverTime: $serverTime"
    Write-Verbose ($response | ConvertTo-Json -Compress)
  }
  catch {
    Write-Error "Connection error!" -ErrorAction Stop
  }
  if ($response.retCode -ne 0) {
    Write-Error "API Connection error!" -ErrorAction Stop
  }

  # Do the request
  # https://bybit-exchange.github.io/docs/spot/v3/#t-constructingtherequest

  <#   curl --location --request GET 'https://api-testnet.bybit.com/spot/v3/private/account' 
            --header 'X-BAPI-SIGN: 6f5c1a9543ea9033013b4ec0a6d05a74e2d05d109c60ad464ab7f9c6e86ad0d4' \
            --header 'X-BAPI-API-KEY: {api key}' \
            --header 'X-BAPI-TIMESTAMP: 1659346886605' \
            --header 'X-BAPI-RECV-WINDOW: 5000' 
  #>

  try {
    $param_str = $serverTime + $Cred.bybitAPI + "5000"

    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Text.Encoding]::ASCII.GetBytes($Cred.bybitSECRET)
    $signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($param_str))
    $signature = [System.BitConverter]::ToString($signature).Replace('-','').ToLower()

    $header = @{}
    $header.Add("X-BAPI-SIGN-TYPE", 2)
    $header.Add("X-BAPI-SIGN", $signature)
    $header.Add("X-BAPI-API-KEY", $Cred.bybitAPI)
    $header.Add("X-BAPI-TIMESTAMP", $serverTime)
    $header.Add("X-BAPI-RECV-WINDOW", 5000)

    Write-Verbose ($header | ConvertTo-Json -Compress)
  }
  catch {
    Write-Error "[ERROR] Rest-Get error!" -ErrorAction Stop
  }

  try {
    $response = "error"
    $response = Invoke-RestMethod -Uri ($Config.bybitURL + $endpoint) -Method Get -Headers $header
    $response | ConvertTo-Json | Write-Verbose
    if ($response.retCode -ne 0) { 
      Write-Error "[ERROR] API Request error!" -ErrorAction Stop 
    }
    $response = $response.result
  }
  catch {
    Write-Host "[ERROR] Rest-Get error!" -ForegroundColor Red -BackgroundColor Black
    return "error"
  }

  return $response
}