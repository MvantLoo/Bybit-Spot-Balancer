<#

Keeps the Bybit-Balancer running

#>

$pause = 60 # minutes of pause between rerun

While ($true) {
  Date | Write-Host -ForegroundColor Yellow -BackgroundColor Black
  & .\Bybit-Balancer.ps1
  "Sleep for $pause minutes"
  "Press Ctrl-C to stop this script."
  Start-Sleep -Seconds ($pause * 60)
}

