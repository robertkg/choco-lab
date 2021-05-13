ARG TAG=ltsc2019
FROM mcr.microsoft.com/windows/servercore:$TAG
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Set up WinRM for HTTPS
RUN $cert = New-SelfSignedCertificate -DnsName "winrm" -CertStoreLocation Cert:\LocalMachine\My; \
    winrm create winrm/config/Listener?Address=*+Transport=HTTPS ('@{Hostname=\"winrm\"; CertificateThumbprint=\"' + $cert.Thumbprint + '\"}'); \
    winrm set winrm/config/service/Auth '@{Basic=\"true\"}'

# Create Bolt account
RUN net user /add Bolt Passw0rd /fullname:'Puppet Bolt' ; \
    net localgroup Administrators Bolt /add

