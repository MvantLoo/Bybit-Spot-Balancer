<#


#>
[CmdletBinding()]
param()

function Connect-Bybit {
  [CmdletBinding()]
  param()

  Write-Verbose ". Connect-Bybit"

  $myPath = Split-Path $MyInvocation.MyCommand.Module.Path
  $fileSettings = $myPath + '\..\..\Settings\config.json'
  $fileCredentials = $myPath + '\..\..\Settings\credentials'

  # Read settings.json, this file is expected
  Write-Verbose "    Read Settings"
  $Global:Config = @{}
  $Global:Config = Get-Content $fileSettings -Raw -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue | ConvertFrom-Json -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
  if ($null -eq $Config.bybitURL) {
    Write-Host "[ERROR] Configuration file $fileSettings is missing!`n" -ForegroundColor Red -BackgroundColor Black
    Write-Error "File not found !" -ErrorAction Stop
  }

  Write-Verbose "Config:"
  $Config | ConvertTo-Json | Write-Verbose

  # Read credentials, this file is optional
  $Global:Cred = [PSCustomObject]@{
    bybitAPI = ""
    bybitSECRET = ""
  }

  # Try to read and decode the credentials
  $CredF = Get-Content $fileCredentials -Raw -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
  try {
    $CredF = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($CredF)) | ConvertFrom-Json -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
  }
  catch {
    $CredF = ""
  }

  # Use the credentials from the file or ask the user
  if ($true -eq $Config.storeCredentials -and
      ($null -eq $CredF.bybitAPI -or $null -eq $CredF.bybitSECRET))
  {
    try {
      $askUser = Get-Credential -Message "Give Bybit API and SECRET"
      $Cred.bybitAPI = $askUser.UserName
      $Cred.bybitSECRET = $askUser.GetNetworkCredential().Password
    }
    catch {
      Write-Host "[ERROR] API and/or SECRET are missing!`n" -ForegroundColor Red -BackgroundColor Black
      Write-Error "API or SECRET not found!" -ErrorAction Stop
    }
  } else {
    $Cred.bybitAPI = $CredF.bybitAPI
    $Cred.bybitSECRET = $CredF.bybitSECRET
  }

  Write-Verbose ("    API: " + $Cred.bybitAPI)
  Write-Verbose ("    SECRET: " + $Cred.bybitSECRET.Length + " characters")

  if ($Cred.bybitAPI.Length -ne 18) {
    Write-Host "[ERROR] Incorrect API or API is missing!`n" -ForegroundColor Red -BackgroundColor Black
    Write-Error "API not found!" -ErrorAction Stop
  }
  if ($Cred.bybitSECRET.Length -ne 36) {
    Write-Host "[ERROR] Incorrect SECRET or SECRET is missing!`n" -ForegroundColor Red -BackgroundColor Black
    Write-Error "SECRET not found!" -ErrorAction Stop
  }

  # Try to login
  $response = Get-BybitRest -Endpoint "/spot/v3/private/account"
  $response.balances | Format-Table | Out-String | Write-Verbose
  if ($response -eq "error") {
    $Cred.PSObject.Properties.Remove('bybitSECRET')
  }

  # If logon was okay and we are still here, then save the credentials
  if ($Config.storeCredentials) {
    $Cred = ConvertTo-Json -InputObject $Cred
    $Cred = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Cred))
    $Cred | Out-File $fileCredentials
  }

  # But if logon was not okay, then stop here !
  if ($response -eq "error") {
    Write-Error "[ERROR] Incorrect API credentals!" -ErrorAction Stop
  }
  else {
    return $response.balances
  }

}