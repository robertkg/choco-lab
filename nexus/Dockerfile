# Dockerfile for Puppet Bolt managed Core 2019 server
ARG TAG=windowsservercore-ltsc2019
FROM mcr.microsoft.com/windows/servercore/iis:${TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install Nexus 3 OSS
RUN mkdir C:\nexus 1>$null; \
    mkdir C:\temp 1>$null; \
    $ProgressPreference = 'SilentlyContinue'; \
    # Latest version can be grabbed from https://download.sonatype.com/nexus/3/latest-win64.zip
    Invoke-WebRequest -Uri https://download.sonatype.com/nexus/3/nexus-3.34.1-01-win64.zip -OutFile C:\temp\nexus.zip; \
    Expand-Archive C:\temp\nexus.zip C:\nexus; \
    Remove-Item C:\temp\nexus.zip;
ADD nexus.properties C:/Nexus/sonatype-work/nexus3/etc/nexus.properties
RUN & C:\nexus\nexus-*\bin\nexus.exe /install nexus; \
    & C:\nexus\nexus-*\bin\nexus.exe /start; \ 
    Set-Service nexus -StartupType Automatic;

# https://chocolatey.org/install
# Chocolatey prompts on the first plan, doing first time install in dockerfile instead
# Network mode inherit host DNS server. Set DNS servers explicit during install
RUN Set-DnsClientServerAddress -InterfaceIndex 4 -ServerAddresses 8.8.8.8, 8.8.4.4; \
    Set-ExecutionPolicy Bypass -Scope Process -Force; \
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; \
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'));

# Configure IIS management
RUN Install-WindowsFeature Web-Mgmt-Service, Web-Scripting-Tools 1>$null;  \ 
    New-ItemProperty -Path HKLM:\software\microsoft\WebManagement\Server -Name EnableRemoteManagement -Value 1 -Force 1>$null; \
    Set-Service -Name wmsvc -StartupType automatic; \
    Start-Service wmsvc; \
    net user iisadmin Passw0rd /ADD; \
    net localgroup administrators iisadmin /add;

# Setup site
ADD site c:/inetpub/chocolab.local/
ADD cert c:/temp
RUN $pw = Get-Content C:\temp\chocolab.local.pfx.password | ConvertTo-SecureString -AsPlainText -Force; \
    $cert = Import-PfxCertificate -Password $pw -CertStoreLocation Cert:\LocalMachine\Root\ -FilePath C:\temp\chocolab.local.pfx; \
    New-IISSite -Name chocolab.local -PhysicalPath "$env:systemdrive\inetpub\chocolab.local" -BindingInformation "*:443:" -CertificateThumbPrint $cert.Thumbprint -CertStoreLocation "Cert:\LocalMachine\My" -Protocol https 1>$null; \
    Remove-Item C:\temp\chocolab.local.pfx*;

# Configure IIS reverse proxy
RUN choco install urlrewrite, iis-arr -y; \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/proxy" -name "enabled" -value "True"; \
    Add-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST" -filter "system.webServer/rewrite/allowedServerVariables" -name "." -value @{name='HTTP_X_FORWARDED_HOST'}; \
    Add-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST" -filter "system.webServer/rewrite/allowedServerVariables" -name "." -value @{name='HTTP_X_FORWARDED_PROTO'};

# Set up WinRM for HTTPS
RUN $cert = New-SelfSignedCertificate -DnsName "winrm" -CertStoreLocation Cert:\LocalMachine\My; \
    winrm create winrm/config/Listener?Address=*+Transport=HTTPS ('@{Hostname=\"winrm\"; CertificateThumbprint=\"' + $cert.Thumbprint + '\"}'); \
    winrm set winrm/config/service/Auth '@{Basic=\"true\"}'

# Create Bolt account
RUN net user /add Bolt Passw0rd! /fullname:'Puppet Bolt' ; \
    net localgroup Administrators Bolt /add

RUN mkdir c:/script 1>$null
ADD setup.ps1 c:/script
