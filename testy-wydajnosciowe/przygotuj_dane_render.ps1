# Tworzy na serwerze dane testowe do pomiarow JMeter:
# sektor "TEST JMeter" z jednym regalem i 4 polkami, material "TEST JMeter" i 300 partii.
# Wszystko da sie potem usunac skryptem usun_dane_render.ps1.
#
# Uzycie (PowerShell, folder testy-wydajnosciowe):
#   powershell -ExecutionPolicy Bypass -File .\przygotuj_dane_render.ps1

$Api = "https://projekt-inzynierski-3wfv.onrender.com/api"
$LiczbaPartii = 300

$login = Read-Host "Login administratora"
$haslo = Read-Host "Haslo"

function Wyslij($metoda, $sciezka, $dane) {
    $parametry = @{ Method = $metoda; Uri = "$Api$sciezka"; Headers = $script:naglowki; ContentType = "application/json; charset=utf-8" }
    if ($dane) { $parametry.Body = [System.Text.Encoding]::UTF8.GetBytes(($dane | ConvertTo-Json)) }
    return Invoke-RestMethod @parametry
}

Write-Host "Logowanie (jesli serwer spi, potrwa to do pol minuty)..."
$script:naglowki = @{ Accept = "application/json" }
try {
    $token = (Wyslij "Post" "/auth/login" @{ login = $login; password = $haslo }).token
} catch {
    Write-Host "Nie udalo sie zalogowac: $($_.Exception.Message)"
    exit 1
}
$script:naglowki = @{ Accept = "application/json"; Authorization = "Bearer $token" }

$przed = @(Wyslij "Get" "/batches" $null).Count
Write-Host "Partii w bazie przed dodaniem danych testowych: $przed"

$sektor = Wyslij "Post" "/locations" @{ name = "TEST JMeter"; type = "sektor" }
$regal = Wyslij "Post" "/locations" @{ name = "TEST JMeter regal"; type = "regal"; parent_id = $sektor.id }
$polki = @()
foreach ($p in 1..4) {
    $polki += Wyslij "Post" "/locations" @{ name = "TEST JMeter polka $p"; type = "polka"; parent_id = $regal.id }
}
$material = Wyslij "Post" "/materials" @{ name = "TEST JMeter"; weight = 1; length = 1; thickness = 1 }

# Zapisujemy identyfikatory od razu, zeby dalo sie posprzatac nawet po przerwaniu skryptu.
@{ api = $Api; material_id = $material.id; sektor_id = $sektor.id; partii_przed = $przed } |
    ConvertTo-Json | Set-Content -Encoding UTF8 dane_testowe_render.json

Write-Host "Tworzenie $LiczbaPartii partii testowych..."
for ($i = 0; $i -lt $LiczbaPartii; $i++) {
    Wyslij "Post" "/batches/receive-material" @{ material_id = $material.id; quantity = 20; location_id = $polki[$i % 4].id; note = "TEST JMeter" } | Out-Null
    if (($i + 1) % 50 -eq 0) { Write-Host "  utworzono $($i + 1)" }
}

Write-Host ""
Write-Host "Gotowe. Partii przed: $przed, partii testowych: $LiczbaPartii."
if ($przed -eq 0) {
    Write-Host "W bazie nie bylo wczesniej partii - mozna uruchomic pelny test (-Jzapis=true)."
} else {
    Write-Host "W bazie byly juz partie - uruchom test tylko do odczytu (-Jzapis=false)."
}
