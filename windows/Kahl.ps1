function deathStar() {
    try {
        # Disable Local Guest User
        $guest = Get-LocalUser -Name "Guest" -ErrorAction Stop
        if ($guest.Enabled) {
            Disable-LocalUser -Name "Guest"
            Write-Output "Local Guest Account has been disabled."
        }
        else {
            Write-Output "Local Guest Account is already disabled."
        }
    }
    catch {
        Write-Verbose "Error disabling local guest account: $_"
    }

    try {
        # Remove All Non Administrators from Local Groups      
        $groups = Get-LocalGroup
        foreach ($group in $groups) {
            $members = Get-LocalGroupMember -Group $group.Name -ErrorAction Stop 
            foreach ($member in $members) {
                if ($member.Name -ne "Administrator" -and $member.Name -ne "ccdcteam.com\Administrator") {
                    Remove-LocalGroupMember -Group $group.Name -Member $member.Name -ErrorAction Stop
                    Write-Output "Removed $($member.Name) from $($group.Name)"
                    $remainingMembers = Get-LocalGroupMember -Group $group.Name -ErrorAction SilentlyContinue # Print remaining members in each group
                    Write-Verbose "Remaining members in $($group.Name):"
                    foreach ($remainingMember in $remainingMembers) {
                        Write-Verbose "  $($remainingMember.Name)"
                    }
                }
            }
        }
        Write-Output "All non-administrators have been removed from local groups."
    }
    catch {
        Write-Verbose "Error removing non-administrators from local groups: $_"
    }
}

function LandOnTatooine() {
    # Prompt user for server selection
    Write-Host "Select a server type: AD (1), HTTP (2), FTP (3)" 
    
    $serverChoice = Read-Host "Enter your 1, 2, or 3"
    
        switch ($serverChoice) {
            "1" {
                try {
                    # Enable Windows Firewall for all profiles
                    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled true

                    # Set default inbound policy to Block
                    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -DefaultOutboundAction Block

                    # Enable logging for packets
                    Set-NetFirewallProfile -Profile Domain,Public,Private -LogAllowed true -LogBlocked true

                    # Disallow Configuration Changes
                    Set-NetFirewallProfile -Profile Domain,Public,Private -AllowLocalFirewallRules True -AllowLocalIPsecRules false

                    Write-Host "No Errors in 1st Stage, Continue" 
                }
                catch {
                    Write-Host "1st Stage Failed"
                }
                try {
                    # Remove Preexisting Inbound Rules
                    Get-NetFirewallRule -Direction Inbound | Set-NetFirewallRule -Enabled False
                    Enable-NetFirewallRule -DisplayGroup "Core Networking"

                    #allow inbound for AD
                    New-NetFirewallRule -DisplayName "Allow LDAP" -Direction Inbound -Protocol TCP -LocalPort 389,636 -Action Allow -Profile Domain,Public,Private -Enabled true #-remoteAddress "172.21.240.0/24,172.25.20.0-172.25.40.255"
                    New-NetFirewallRule -DisplayName "Allow Kerberos" -Direction Inbound -Protocol TCP -LocalPort 88 -Action Allow -Profile Domain,Public,Private -Enabled true #-remoteAddress "172.21.240.0/24, 172.25.20.0-172.25.40.255"
                    New-NetFirewallRule -DisplayName "Allow DNS" -Direction Inbound -Protocol UDP -LocalPort 53 -Action Allow -Profile Domain,Public,Private -Enabled true
                    New-NetFirewallRule -DisplayName "Allow Global Catalog" -Direction Inbound -Protocol TCP -LocalPort 3268,3269 -Action Allow -Profile Domain,Public,Private -Enabled true #-remoteAddress #"172.21.240.0/24,172.25.20.0-172.25.40.255"
                    New-NetFirewallRule -DisplayName "Allow SMB" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow -Profile Domain,Public,Private -Enabled true -remoteAddress "172.21.240.0/24,172.25.20.0-172.25.40.255"
                    New-NetFirewallRule -DisplayName "Allow DNS TCP" -Direction Inbound -Protocol TCP -LocalPort 53 -Action Allow -Profile Domain,Public,Private -Enabled true
                    New-NetFirewallRule -DisplayName "Allow NTP" -Direction Inbound -Protocol UDP -LocalPort 123 -Action Allow -Profile Domain,Public,Private -Enabled true -remoteAddress "172.21.240.0/24,172.25.20.0-172.25.40.255"
                  #  New-NetFirewallRule -DisplayName "Block TCP OutofScope Inbound low" -Direction Inbound -Protocol TCP -RemotePort 1-52 -Action Block -Profile Domain,Public,Private -Enabled true -RemoteAddress #"10.0.0.0/8,192.168.0.0/16,172.16.0.0-172.21.240.0,172.21.243.0-172.25.19.255,172.25.43.0-172.31.255.255"
                  #  New-NetFirewallRule -DisplayName "Block UDP OutofScope Inbound low" -Direction Inbound -Protocol UDP -RemotePort 1-52 -Action Block -Profile Domain,Public,Private -Enabled true -RemoteAddress #"10.0.0.0/8,192.168.0.0/16,172.16.0.0-172.21.240.0,172.21.243.0-172.25.19.255,172.25.43.0-172.31.255.255"
                  #  New-NetFirewallRule -DisplayName "Block TCP OutofScope Inbound High" -Direction Inbound -Protocol TCP -RemotePort 54-65535 -Action Block -Profile Domain,Public,Private -Enabled true -RemoteAddress #"10.0.0.0/8,192.168.0.0/16,172.16.0.0-172.21.240.0,172.21.243.0-172.25.19.255,172.25.43.0-172.31.255.255"
                  #  New-NetFirewallRule -DisplayName "Block UDP OutofScope Inbound High" -Direction Inbound -Protocol UDP -RemotePort 54-65535 -Action Block -Profile Domain,Public,Private -Enabled true -RemoteAddress #"10.0.0.0/8,192.168.0.0/16,172.16.0.0-172.21.240.0,172.21.243.0-172.25.19.255,172.25.43.0-172.31.255.255"
                    Write-Host "No Errors in 2nd Stage, Continue"
                }
                catch {
                    Write-Host "2nd Stage Failed"
                }
                try {
                    # Allow Communication with DNS and AD 
                    New-NetFirewallRule -DisplayName "Allow DNS" -Direction Outbound -Protocol UDP -RemotePort 53 -Action Allow -Profile Domain,Public,Private -Enabled true
                    New-NetFirewallRule -DisplayName "Allow DNS TCP" -Direction Outbound -Protocol TCP -RemotePort 53 -Action Allow -Profile Domain,Public,Private -Enabled true
                    New-NetFirewallRule -DisplayName "Allow NTP" -Direction Outbound -Protocol UDP -RemotePort 123 -Action Allow -Profile Domain,Public,Private -Enabled true
                    New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Outbound -Protocol TCP -RemotePort 80,443 -Action Allow -Profile Domain,Public,Private -Enabled true
                    New-NetFirewallRule -DisplayName "Allow Wazuh" -Direction Outbound -Protocol TCP -RemotePort 1514-1516 -Action Allow -Profile Domain,Public,Private -Enabled true
                    New-NetFirewallRule -DisplayName "Allow Wazuh" -Direction Outbound -Protocol UDP -RemotePort 1514-1516 -Action Allow -Profile Domain,Public,Private -Enabled true
                    New-NetFirewallRule -DisplayName "Block TCP OutofScope Outbound" -Direction Outbound -Protocol TCP -RemotePort 1-65535 -Action Block -Profile Domain,Public,Private -Enabled true -RemoteAddress "10.0.0.0/8,192.168.0.0/16,172.16.0.0-172.21.240.0,172.21.243.0-172.25.19.255,172.25.43.0-172.31.255.255"
                    New-NetFirewallRule -DisplayName "Block UDP OutofScope Outbound" -Direction Outbound -Protocol UDP -RemotePort 1-65535 -Action Block -Profile Domain,Public,Private -Enabled true -RemoteAddress "10.0.0.0/8,192.168.0.0/16,172.16.0.0-172.21.240.0,172.21.243.0-172.25.19.255,172.25.43.0-172.31.255.255"
                    Write-Host "No Errors in 3rd Stage, Continue"
                }  
                catch {
                    Write-Host "3rd Stage Failed"
                }
            }
            "2" {
                try {
                    # Enable Windows Firewall for all profiles
                    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled true

                    # Set default inbound policy to Block
                    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -DefaultOutboundAction Block

                    # Enable logging for packets
                    Set-NetFirewallProfile -Profile Domain,Public,Private -LogAllowed true -LogBlocked true

                    # Disallow Configuration Changes
                    Set-NetFirewallProfile -Profile Domain,Public,Private -AllowLocalFirewallRules true -AllowLocalIPsecRules false

                    Write-Host "No Errors in 1st Stage, Continue" 
                }
                catch {
                    Write-Host "1st Stage Failed"
                }
                try {

                    # Remove Preexisting Inbound Rules
                    Get-NetFirewallRule -Direction Inbound | Set-NetFirewallRule -Enabled False

                    # Begin Allowing Inbound Scoring
                    New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow -Profile Domain,Public,Private -Enabled true
                    New-NetFirewallRule -DisplayName "Allow HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow -Profile Domain,Public,Private -Enabled true


                    Write-Host "No Errors in 2nd Stage, Continue"
                }
                catch {
                    Write-Host "2nd Stage Failed"
                }
                try {
                    # Allow Communication with DNS and AD 
                    New-NetFirewallRule -DisplayName "Allow DNS" -Direction Outbound -Protocol UDP -RemotePort 53 -Action Allow -Profile Domain,Public,Private -Enabled true
                    New-NetFirewallRule -DisplayName "Allow LDAP" -Direction Outbound -Protocol TCP -RemotePort 389,636,3268,3269 -Action Allow -Profile Domain,Public,Private -Enabled true
                    New-NetFirewallRule -DisplayName "Allow Kerberos" -Direction Outbound -Protocol TCP -RemotePort 88 -Action Allow -Profile Domain,Public,Private -Enabled true
                    
                    Write-Host "No Errors in 3rd Stage, Continue"
                }  
                catch {
                    Write-Host "3rd Stage Failed"
                }
                try {
                    # Allow Necessary Connections
                    Enable-NetFirewallRule -DisplayGroup "Core Networking"
                    New-NetFirewallRule -DisplayName "Allow NTP" -Direction Outbound -Protocol UDP -RemotePort 123 -Action Allow -Profile Domain,Public,Private -Enabled true
                    New-NetFirewallRule -DisplayName "Allow SMB" -Direction Outbound -Protocol TCP -RemotePort 445 -Action Allow -Profile Domain,Public,Private -Enabled true
                }
                catch {
                    Write-Host "4th Stage Failed"
                }
            }
            "3" {
                try {
                    # Enable Windows Firewall for all profiles
                    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled true

                    # Set default inbound policy to Block
                    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -DefaultOutboundAction Block

                    # Enable logging for packets
                    Set-NetFirewallProfile -Profile Domain,Public,Private -LogAllowed true -LogBlocked true

                    # Disallow Configuration Changes
                    Set-NetFirewallProfile -Profile Domain,Public,Private -AllowLocalFirewallRules false -AllowLocalIPsecRules false

                    Write-Host "No Errors in 1st Stage, Continue" 
                }
                catch {
                    Write-Host "1st Stage Failed"
                }
                try {

                    # Remove Preexisting Inbound Rules
                    Get-NetFirewallRule -Direction Inbound | Set-NetFirewallRule -Enabled False

                    # Begin Allowing Inbound Scoring
                    New-NetFirewallRule -DisplayName "Allow FTP" -Direction Inbound -Protocol TCP -LocalPort 20,21 -Action Allow -Profile Domain,Public,Private -Enabled true
		            New-NetFirewallRule -DisplayName "Allow FTP Out" -Direction Outbound -Protocol TCP -LocalPort 20 -Action Allow -Profile Domain,Public,Private -Enabled true
		            New-NetFirewallRule -DisplayName "Allow Internet Out" -Direction Outbound -Protocol TCP -RemotePort 80,443 -Action Allow -Profile Domain,Public,Private -Enabled true
                   
		
                    Write-Host "No Errors in 2nd Stage, Continue"
                }
                catch {
                    Write-Host "2nd Stage Failed"
                }
                try { 
                    # Allow Communication with DNS and AD 
                    New-NetFirewallRule -DisplayName "Allow DNS" -Direction Outbound -Protocol UDP -RemotePort 53 -Action Allow -Profile Domain,Public,Private -Enabled true
                    New-NetFirewallRule -DisplayName "Allow LDAP" -Direction Outbound -Protocol TCP -RemotePort 389,636,3268,3269 -Action Allow -Profile Domain,Public,Private -Enabled true
                    New-NetFirewallRule -DisplayName "Allow Kerberos" -Direction Outbound -Protocol TCP -RemotePort 88 -Action Allow -Profile Domain,Public,Private -Enabled true
                    
                    Write-Host "No Errors in 3rd Stage, Continue"
                }  
                catch {
                    Write-Host "3rd Stage Failed"
                }
                try {
                    # Allow Necessary Connections
                    Enable-NetFirewallRule -DisplayGroup "Core Networking"
                    New-NetFirewallRule -DisplayName "Allow NTP" -Direction Outbound -Protocol UDP -RemotePort 123 -Action Allow -Profile Domain,Public,Private -Enabled true
                    New-NetFirewallRule -DisplayName "Allow SMB" -Direction Outbound -Protocol TCP -RemotePort 445 -Action Allow -Profile Domain,Public,Private -Enabled true
                }
                catch {
                    Write-Host "4th Stage Failed"
                }
            }
            default {
                Write-Host "Invalid selection. Please enter 1, 2, or 3."
                return
            }
        }
    
}
function CargoShip() {
    Save-Script -name winget-install -path .\ -force
    winget-install.ps1
    Stop-Process -Name explorer -Force
    winget.exe install cURL.cURL -e --accept-source-agreements --accept-package-agreements
    curl.exe -OL 'https://download.sysinternals.com/files/SysinternalsSuite.zip'
    curl.exe -OL 'https://npcap.com/dist/npcap-1.87.exe'
    Start-Process -FilePath 'npcap-1.87.exe' -Wait
    Expand-Archive -Path SysinternalsSuite.zip -DestinationPath C:\SysinternalsSuite\ -Force
    winget.exe install WiresharkFoundation.Wireshark -e --accept-source-agreements --accept-package-agreements
    winget.exe install Insecure.Nmap -e --accept-source-agreements --accept-package-agreements
    winget.exe install Microsoft.PowerShell -e --accept-source-agreements --accept-package-agreements
    winget.exe install Microsoft.VisualStudioCode -e --accept-source-agreements --accept-package-agreements
    winget.exe install Microsoft.WindowsTerminal -e --accept-source-agreements --accept-package-agreements
    winget.exe install Microsoft.etl2pcapng -e --accept-source-agreements --accept-package-agreements
    winget.exe install Git.Git -e --accept-source-agreements --accept-package-agreements
}
function Suricata() {
    curl.exe -O 'https://www.openinfosecfoundation.org/download/windows/Suricata-8.0.3-windivert-1-64bit.msi'
    Start-Process msiexec.exe -Wait -ArgumentList '/I Suricata-8.0.3-windivert-1-64bit.msi /qn'
    (Invoke-WebRequest 'https://rules.emergingthreats.net/open/suricata-8.0.3/rules/' -UseBasicParsing).Links | Where-Object -Property href -match '.rules' | ForEach-Object{
        curl.exe --output "C:\Program Files\Suricata\rules\$($_.href.substring(2))" "https://rules.emergingthreats.net/open/suricata-8.0.3/rules$($_.href.substring(1))" 
        write-host "https://rules.emergingthreats.net/open/suricata-8.0.3/rules$($_.href.substring(1))"
    }
    start-process 'C:\Program Files\Suricata\suricata.exe' -Wait -ArgumentList "-i $($(Get-NetIPAddress | Where-Object -Property ipaddress -match '172.*.*.*').ipaddress) --service-install"
}
Get-WindowsUpdate -AcceptAll -Install -Category 'Security Updates' -IgnoreReboot
CargoShip
Suricata
deathStar
LandOnTatooine
