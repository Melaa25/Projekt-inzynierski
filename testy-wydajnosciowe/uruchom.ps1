# Seria testow obciazeniowych JMeter: 1, 5, 10 i 20 jednoczesnych pracownikow.
# Uruchom w PowerShell z katalogu testy-wydajnosciowe (backend musi dzialac na porcie 8000).
#   .\uruchom.ps1
# Wyniki: wyniki\u<liczba>\raport\index.html oraz wyniki\u<liczba>\raport\statistics.json

$czas = 120      # czas jednego pomiaru w sekundach
$uzytkownicy = @(1, 5, 10, 20)

foreach ($u in $uzytkownicy) {
    $katalog = "wyniki\u$u"
    if (Test-Path $katalog) { Remove-Item -Recurse -Force $katalog }
    New-Item -ItemType Directory -Force $katalog | Out-Null

    Write-Host "=== Pomiar dla $u uzytkownikow ($czas s) ==="
    jmeter -n -t wms_obciazenie.jmx `
        "-Jusers=$u" "-Jrampup=10" "-Jduration=$czas" `
        -l "$katalog\wyniki.jtl" -j "$katalog\jmeter.log" `
        -e -o "$katalog\raport"

    Start-Sleep -Seconds 10
}

Write-Host "Gotowe. Przeslij pliki wyniki\u*\raport\statistics.json"
