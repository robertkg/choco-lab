# Dockerfile for Puppet Bolt managed Core 2019 server
ARG TAG=ltsc2019
FROM mcr.microsoft.com/windows/servercore:$TAG
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# https://chocolatey.org/install
# Chocolatey prompts on the first plan, doing first time install in dockerfile instead
# Network mode inherit host DNS server. Set DNS servers explicit during install
RUN Set-DnsClientServerAddress -InterfaceIndex 4 -ServerAddresses 8.8.8.8, 8.8.4.4; \
    Set-ExecutionPolicy Bypass -Scope Process -Force; \
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; \
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'));

# Install Nexus 3 OSS
RUN mkdir C:\Nexus; \
    mkdir C:\Temp; \
    $ProgressPreference = 'SilentlyContinue'; \
    Invoke-WebRequest -Uri https://download.sonatype.com/nexus/3/latest-win64.zip -OutFile C:\Temp\nexus.zip; \
    Expand-Archive C:\Temp\nexus.zip C:\Nexus; \
    Remove-Item C:\Temp\nexus.zip;

ADD nexus.properties C:/Nexus/sonatype-work/nexus3/etc/nexus.properties

RUN & C:\Nexus\nexus-3.34.0-01\bin\nexus.exe /install Nexus; \
    Start-Service Nexus