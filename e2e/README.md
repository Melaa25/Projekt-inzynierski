# Testy funkcjonalne panelu webowego (Playwright)

Testy uruchamiają prawdziwą przeglądarkę (Chromium) i klikają w panel webowy tak jak użytkownik. Przed testami Playwright sam uruchamia:

1. **API** na porcie 8000 z nową bazą SQLite `backend/database/e2e.sqlite`, zasiloną seederem `TestEnvironmentSeeder`. Twoja zwykła baza z pliku `.env` nie jest używana ani zmieniana.
2. **Panel webowy** na porcie 8080, czyli pliki z `frontend/build/web`.

## Wymagania

- Node.js 20 lub nowszy (`node -v`).
- PHP i Composer (`backend/vendor` zainstalowany przez `composer install`) oraz Flutter.

## Pierwsze uruchomienie

```powershell
# 1. Zbudowanie panelu webowego z adresem lokalnego API (w katalogu frontend)
cd frontend
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000/api

# 2. Instalacja Playwrighta (w katalogu e2e)
cd ..\e2e
npm install
npx playwright install chromium

# 3. Testy
npx playwright test
```

Jeśli wcześniej wykonano `php artisan config:cache`, najpierw uruchom w katalogu `backend` polecenie `php artisan config:clear`. W przeciwnym razie Laravel zignoruje ustawienia bazy testowej.

## Wyniki

- W konsoli: lista testów z wynikiem i czasem.
- Raport HTML: `npx playwright show-report wyniki/raport-html`. Przy niezaliczonych testach zawiera zrzut ekranu i ślad (trace) z każdym krokiem.
- `wyniki/junit.xml`: wyniki w formacie JUnit.

## Gdy test się nie powiedzie

- `npx playwright test --headed` pokazuje przeglądarkę podczas testu.
- `npx playwright test 03-przyjecie --debug` uruchamia test krok po kroku.
- `npx playwright show-trace wyniki/artefakty/<test>/trace.zip` otwiera nagranie z drzewem DOM w każdym kroku.

Flutter rysuje interfejs na elemencie canvas, więc testy korzystają z drzewa semantyki (elementy `flt-semantics`), które Flutter tworzy dla czytników ekranu. Funkcje w `tests/pomocnicze.ts` wyszukują przyciski po nazwie, pola po etykiecie, a teksty po treści. Jeśli po aktualizacji Fluttera któryś element nie jest znajdowany, w trace widać, jak wygląda w DOM. Poprawkę wystarczy wtedy wprowadzić w jednej funkcji pomocniczej.
