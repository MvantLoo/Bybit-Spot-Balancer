# CorpusCrypto :: Bybit Spot Balancer
Powershell script for balancing tokens in a Bybit Spot account.

**! TIP: Use a Subaccount !**
**! Balancing is using USDT as base (quote) token !**
**! Make sure you have USDY in your account !**

- Add USDT in your ByBit spot account
- Buy some tokens that you are interested in to balance them
- Run `Bybit-Balancer.ps1` to store your API and Secret in a safely in the Settings folder
- Run `Bybit-Balancer.ps1` whenever you want to balance
- Run `Run Bybit-Balancer.ps1` to balance every x minutes (default: 60)

## How to start one of these scripts?

- Double-Click on `Open PS here` to open the PowerShell console in this folder.
- Type the script that you want to run en press ENTER **-OR-**
- Type the first few letters of the script that you want to run and press TAB to auto-complete the name, then press ENTER when the name is correct.

- If the `Bybit-Balancer.ps1` runs without issues, you can rightclick on `Run Bybit-Balancer.ps1` and choose "Run with Powershell"

## Issues to run PowerShell scripts?
https://learn.microsoft.com/en-gb/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1
- Open Powershell as Administrator
- `Set-ExecutionPolicy RemoteSigned`

