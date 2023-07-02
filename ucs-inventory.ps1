param
(
    [string]$j,
    [switch]$force
    # $(throw "-j is required. It is the Source of Data for the Script.")
    #[string]$placeholder = "" #not a required switch allows targeting VM's based upon cluster
)

# Get script directory and set working directory
$jsonData = Get-Content -Path $j | ConvertFrom-Json
$todaysDate = (Get-Date).tostring("yyyy-MM-dd_HH-mm-ss")

$vcenters = @()
foreach ($k in $jsonData.vcenters.PSObject.Properties) {
    $vcenters += $k.value.name
}

#write-host $jsonData
#write-host "vcenter list is $($vcenters)"
#Start-Transcript -Path ".\Logs\$(get-date -f "yyyy-MM-dd_HH-mm-ss")_$($env:username).log" -Append -Confirm:$false

# Import VMware PS modules
If (Get-Module -Name VMware.PowerCLI -ListAvailable) {Install-Module -Name VMware.PowerCLI}
# User must install powerCLI: Install-Module VMware.PowerCLI -Scope CurrentUser
Set-PowerCLIConfiguration -Scope Session -WebOperationTimeoutSeconds 3600 -InvalidCertificateAction Ignore -Confirm:$false
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $true

# Obtain Username and password
If (Test-Path -Path ${HOME}\powercli.Cred) {
    $credential = Import-CliXml -Path "${HOME}\powercli.Cred"
} ELSE {
    $credential = Get-Credential
    $credential | Export-CliXml -Path "${HOME}\powercli.Cred"
}

# Set Output PowerShell Object
$Output = @()

foreach($vcenter in $vcenters) {
    Write-Host "Connect to vcenter $vcenter"
    if ($vcenter) {
        try {
            $null = Connect-viserver $vcenter -Credential $credential
        }
        catch {
            Write-Host "There was an issue with connecting to $vcenter"
            exit
        }
    }
    else {
        Write-Host "Unable to Connect to the vCenter."
        exit
    }
    # Get collection of Clusters and hosts
    Get-Cluster | ForEach-Object {
        $cluster = $_
        write-host "Cluster is $cluster"
        $cluster | Get-VMHost | Where-Object {$_.ConnectionState -eq “Connected”} | ForEach-Object {
            $vmhost = $_
            write-host "ESX host is $vmhost"
            $esxHost = Get-EsxCli -VMHost $vmhost;
            $physServer = $esxHost.hardware.platform.get().SerialNumber | select @{N='Hostname';E={$vmhost}}, @{N='Serial';E={$_}};
            $hostVibs = $esxHost.software.vib.list() | Select ID,InstallDate,Name,Vendor,Version | Where {$_.Name -match "ucs-tool-esxi"};

            # Merge Output from phyServer and hostVibs
            $OutputItem = New-Object PSObject;
            $OutputItem | Add-Member NoteProperty "Hostname" $physServer.Hostname;
            $OutputItem | Add-Member NoteProperty "Serial" $physServer.Serial;
            $OutputItem | Add-Member NoteProperty "vCenter" $vcenter
            $OutputItem | Add-Member NoteProperty "Cluster" $cluster.Name
            $OutputItem | Add-Member NoteProperty "ID" $hostVibs.ID;
            $OutputItem | Add-Member NoteProperty "InstallDate" $hostVibs.InstallDate;
            $OutputItem | Add-Member NoteProperty "Name" $hostVibs.Name;
            $OutputItem | Add-Member NoteProperty "Vendor" $hostVibs.Vendor;
            $OutputItem | Add-Member NoteProperty "Version" $hostVibs.Version;

            # Add OutputItem to Output Object
            $Output += $OutputItem;
        }
    }
    Disconnect-VIServer $vcenter -Confirm:$false
    write-host "Disconnecting from vCenter $vcenter"
}
# Save the Output to a JSON File
$Output | ConvertTo-Json -depth 100 | Out-File "$todaysDate.json"

#Stop-Transcript
Exit