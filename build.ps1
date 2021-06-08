$ErrorActionPreference = 'Stop'

Write-Output '----------- BEGIN DOCKER COMPOSE -----------'
docker-compose up -d --build --force-recreate

Write-Output '----------- CHOCOSERVER MANIFEST -----------'
bolt apply .\manifests\chocolateyserver.pp -t chocoserver

Write-Output '----------- PUSH PACKAGES -----------'
& .\files\Push-ChocolateyPackage.ps1

Write-Output '----------- CLIENT MANIFEST -----------'
bolt apply .\manifests\client.pp -t client