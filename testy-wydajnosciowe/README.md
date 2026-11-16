# Testy wydajnościowe (Apache JMeter)

Plan testu `wms_obciazenie.jmx` symuluje pracę magazynu:

- **Pracownicy magazynu** (liczba ustawiana parametrem `users`): w pętli sprawdzenie połączenia (`/ping`), lista partii, szczegóły partii (jak po zeskanowaniu etykiety), przyjęcie 2 szt. do partii i wydanie 1 szt. Między zapytaniami jest losowa przerwa 1–2 s, czyli czas namysłu użytkownika. Każdy wątek pracuje na innej partii.
- **Kierownik**: co 5 s pobiera raport stanu magazynowego i raport historii ruchów (CSV).

Przed startem wątek przygotowawczy (setUp) loguje się jako `test.kierownik` i przekazuje token wszystkim wątkom.

## Wymagania

1. Java 17 lub nowsza (`java -version`).
2. Apache JMeter 5.6.3 z https://jmeter.apache.org/download_jmeter.cgi. Rozpakuj go i dodaj katalog `apache-jmeter-5.6.3/bin` do zmiennej PATH. Sprawdź poleceniem `jmeter -v`.

## Przygotowanie bazy testowej

**Uwaga:** `migrate:fresh` kasuje wszystkie dane w bazie, którą wskaże. Uruchamiaj go tylko na bazie testowej, nigdy na produkcyjnej.

Zalecana jest baza PostgreSQL, taka sama jak na serwerze. Najprościej uruchomić ją w Dockerze:

```powershell
docker run -d --name wms-perf -e POSTGRES_USER=wms -e POSTGRES_PASSWORD=wms -e POSTGRES_DB=wms_perf -p 5433:5432 postgres:16
```

Następnie w katalogu `backend` (PowerShell):

```powershell
$env:DB_CONNECTION="pgsql"; $env:DB_HOST="127.0.0.1"; $env:DB_PORT="5433"
$env:DB_DATABASE="wms_perf"; $env:DB_USERNAME="wms"; $env:DB_PASSWORD="wms"
$env:APP_ENV="production"; $env:APP_DEBUG="false"; $env:TEST_BATCH_COUNT="300"
php artisan config:clear
php artisan migrate:fresh --force --seed --seeder=TestEnvironmentSeeder
php artisan serve --host=127.0.0.1 --port=8000
```

Seeder tworzy konta testowe, 84 półki (3 sektory × 7 regałów × 4 półki), 10 materiałów i 300 partii. Serwer zostaw uruchomiony w tym oknie.

## Uruchomienie

W drugim oknie, w katalogu `testy-wydajnosciowe`:

```powershell
.\uruchom.ps1          # Windows (PowerShell)
bash uruchom.sh        # Linux / macOS / Git Bash
```

Skrypt wykonuje cztery pomiary po 120 s dla 1, 5, 10 i 20 pracowników. Całość trwa około 9 minut. Komputer nie powinien w tym czasie wykonywać innych ciężkich zadań.

Pojedynczy pomiar można uruchomić ręcznie:

```powershell
jmeter -n -t wms_obciazenie.jmx -Jusers=10 -Jduration=120 -l wyniki\wyniki.jtl -e -o wyniki\raport
```

Dostępne parametry `-J`: `host`, `port`, `protocol`, `users`, `rampup`, `duration`, `think` (ms), `managers`, `login`, `password`.

## Wyniki

Dla każdego pomiaru powstaje raport HTML `wyniki\u<N>\raport\index.html`. Tabela *Statistics* zawiera medianę, percentyle 90/95/99, przepustowość i procent błędów. Do pracy potrzebne są pliki `wyniki\u1\raport\statistics.json`, `u5`, `u10` i `u20`.

Otwarcie planu w trybie graficznym (`jmeter`, a potem *File → Open*) służy tylko do podglądu i edycji. Pomiary wykonuj zawsze w trybie konsolowym (`-n`), bo tryb graficzny zaburza wyniki.
