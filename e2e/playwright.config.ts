import { defineConfig, devices } from '@playwright/test';
import path from 'path';

// Testowa baza SQLite - tworzona od nowa przy kazdym uruchomieniu testow.
const bazaTestowa = path.resolve(__dirname, '../backend/database/e2e.sqlite');

export default defineConfig({
  testDir: './tests',
  // Testy dziela jedna baze danych, wiec uruchamiamy je po kolei.
  workers: 1,
  fullyParallel: false,
  retries: 0,
  timeout: 120_000,
  expect: { timeout: 15_000 },
  reporter: [
    ['list'],
    ['html', { outputFolder: 'wyniki/raport-html', open: 'never' }],
    ['junit', { outputFile: 'wyniki/junit.xml' }],
  ],
  outputDir: 'wyniki/artefakty',
  use: {
    baseURL: 'http://127.0.0.1:8080',
    locale: 'pl-PL',
    viewport: { width: 1280, height: 800 },
    serviceWorkers: 'block',
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
    acceptDownloads: true,
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'], viewport: { width: 1280, height: 800 } } }],
  webServer: [
    {
      // API: nowa baza testowa, dane startowe i serwer na porcie 8000.
      command:
        'node -e "require(\'fs\').writeFileSync(process.env.DB_DATABASE, \'\')" && ' +
        'php artisan migrate:fresh --force --seed --seeder=TestEnvironmentSeeder && ' +
        'php artisan serve --host=127.0.0.1 --port=8000',
      cwd: '../backend',
      url: 'http://127.0.0.1:8000/api/ping',
      reuseExistingServer: false,
      timeout: 180_000,
      env: {
        DB_CONNECTION: 'sqlite',
        DB_DATABASE: bazaTestowa,
        TEST_BATCH_COUNT: '0',
      },
    },
    {
      // Panel webowy zbudowany poleceniem:
      // flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
      command: 'npx http-server ../frontend/build/web -p 8080 -a 127.0.0.1 -s -c-1',
      url: 'http://127.0.0.1:8080',
      reuseExistingServer: false,
      timeout: 60_000,
    },
  ],
});
