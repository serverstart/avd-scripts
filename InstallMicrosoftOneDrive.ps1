# Vorlage: https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/virtual-desktop/install-office-on-wvd-master-image.md

# Download OneDrive Setup
(New-Object System.Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/p/?LinkId=844652", "$($env:temp)\OneDriveSetup.exe")

# Uninstall old OneDrive
Start-Process -FilePath "$($env:temp)\OneDriveSetup.exe" -Wait -ArgumentList "/silent /uninstall" -ErrorAction SilentlyContinue

# Set AllUsersInstall to 1
New-Item -Path "HKLM:\SOFTWARE\Microsoft" -Name "OneDrive" -Force -ErrorAction Ignore
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\OneDrive" -Name "AllUsersInstall" -PropertyType DWord -Value 1 -force

# Install OneDrive for all users
Start-Process -FilePath "$($env:temp)\OneDriveSetup.exe" -ArgumentList "/silent /allusers" -ErrorAction SilentlyContinue
Wait-Event -Timeout 5

# Configure OneDrive to start at sign in for all users
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -PropertyType String -Value "C:\Program Files\Microsoft OneDrive\OneDrive.exe /background" -force

# Enable Silently configure user account by running the following command.
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft" -Name "OneDrive" -Force -ErrorAction Ignore
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" -Name "SilentAccountConfig" -PropertyType DWord -Value 1 -force