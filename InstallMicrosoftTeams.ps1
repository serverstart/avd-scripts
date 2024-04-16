# Set IsWVDEnvironment to 1
New-Item -Path "HKLM:\SOFTWARE\Microsoft" -Name "Teams" -Force -ErrorAction Ignore
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Name "IsWVDEnvironment" -Value 1 -force

# Allow side-loading for trusted apps
New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows" -Name "Appx" -Force -ErrorAction Ignore
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Appx" -Name "AllowAllTrustedApps" -Value 1 -force
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Appx" -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -force

# Remove Teams Machine-Wide Installer
$MachineWide = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "Teams Machine-Wide Installer"}
$MachineWide.Uninstall()

# Download and install WebView2
(New-Object System.Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/p/?LinkId=2124703", "$($env:temp)\WebView2.exe")
Start-Process -FilePath "$($env:temp)\WebView2.exe" -Wait -ArgumentList "/silent /install" -ErrorAction SilentlyContinue

# Download and install the New Teams
(New-Object System.Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2243204", "$($env:temp)\TeamsBootstrapper.exe")
$rv=Start-Process -FilePath "$($env:temp)\TeamsBootstrapper.exe" -Wait -ArgumentList "-p" -PassThru -ErrorAction SilentlyContinue
$rv.ExitCode