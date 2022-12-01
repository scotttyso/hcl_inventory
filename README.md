# hcl_inventory


## Getting Started

## Install Powershell

- macOS: [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-macos?view=powershell-7.2)
- Ubuntu: [Powershell](https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu?view=powershell-7.3)

## Install VMware PowerCLI

```bash
pwsh
Install-Module -Name VMware.PowerCLI
```

## Run the Script (Windows)
```powershell
.\ucs-inventory.ps1 -j inventory.json
```

## Runt he Script (Linux)
```bash
pwsh
./ucs-inventory.ps1 -j inventory.json
```
