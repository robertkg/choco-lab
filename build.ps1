$ErrorActionPreference = 'Stop'

Write-Output '----------- BEGIN DOCKER COMPOSE -----------'
docker-compose up -d --build --force-recreate
Write-Output '----------- BEGIN BOLT APPLY -----------'
bolt apply .\manifests\chocolateyserver.pp -t chocoserver
