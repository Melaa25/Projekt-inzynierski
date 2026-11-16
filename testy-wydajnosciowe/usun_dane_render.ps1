# Usuwa dane testowe utworzone skryptem przygotuj_dane_render.ps1.
# Usuniecie materialu "TEST JMeter" usuwa jego partie i ich ruchy (kaskadowo w bazie),
# a usuniecie sektora "TEST JMeter" usuwa jego regal i polki.
#
# Uzycie (PowerShell, folder testy-wydajnosciowe):
#   powershell -ExecutionPolicy Bypass -File .\usun_dane_render.ps1

if (-not (Test-Path dane_testowe_render.json)) {
    Write-Host "Brak pliku dane_testowe_render.json - nie ma czego usuwac."
    exit 1
}

$dane = Get-Content dane_testowe_render.json -Raw | ConvertFrom-Json
$Api = $dane.api

$login = Read-Host "Login administratora"
$haslo = Read-Host "Haslo"

$cialo = [System.Text.Encoding]::UTF8.GetBytes((@{ login = $login; password = $haslo } | ConvertTo-Json))
$token = (Invoke-RestMethod -Method Post -Uri "$Api/auth/login" -Headers @{ Accept = "application/json" } -ContentType "application/json; charset=utf-8" -Body $cialo).token
$naglowki = @{ Accept = "application/json"; Authorization = "Bearer $token" }

Invoke-RestMethod -Method Delete -Uri "$Api/materials/$($dane.material_id)" -Headers $naglowki | Out-Null
Write-Host "Usunieto material TEST JMeter razem z partiami i ruchami."

Invoke-RestMethod -Method Delete -Uri "$Api/locations/$($dane.sektor_id)" -Headers $naglowki | Out-Null
Write-Host "Usunieto sektor TEST JMeter razem z regalem i polkami."

$po = @(Invoke-RestMethod -Uri "$Api/batches" -Headers $naglowki).Count
Write-Host "Partii w bazie po sprzataniu: $po (przed testem bylo: $($dane.partii_przed))"

Remove-Item dane_testowe_render.json
