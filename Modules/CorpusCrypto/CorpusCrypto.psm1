<#



#>
[CmdletBinding()]
param()

# Collect the path of this module
$path = Split-Path $MyInvocation.MyCommand.Path

# Import all psm1 files, except myself and except files that start with a dot (.)
[string]$files = Get-ChildItem -Path ($path + "\*.psm1") -Recurse -Exclude CorpusCrypto.psm1, .*
$filelist = $files.Split(" ")

foreach($file in $filelist) {
  Import-Module -Name $file -Force -ErrorAction Stop -WarningAction SilentlyContinue -DisableNameChecking | Out-Null
}

# Import external modules
#Import-Module -Name ($path + "\..\folder\file.ps1") -Force -ErrorAction Stop -WarningAction SilentlyContinue -DisableNameChecking
