import { expect, test } from '@playwright/test';
import { KONTA, otworzAplikacje, przycisk, tekst, wpisz, zaloguj, zalogujDoPanelu } from './pomocnicze';

test.describe('Logowanie', () => {
  test('poprawne dane prowadzą do panelu głównego', async ({ page }) => {
    await zalogujDoPanelu(page, KONTA.kierownik);

    await expect(tekst(page, 'Partie materiałów')).toBeVisible();
    await expect(tekst(page, 'Raporty')).toBeVisible();
  });

  test('błędne hasło wyświetla komunikat i nie loguje', async ({ page }) => {
    await zaloguj(page, KONTA.kierownik, 'ZleHaslo1');

    await expect(tekst(page, 'Nieprawidlowy login lub haslo.')).toBeVisible();
    await expect(tekst(page, 'Panel główny')).toHaveCount(0);
  });

  test('puste pola są zgłaszane przez walidację formularza', async ({ page }) => {
    await otworzAplikacje(page);
    await przycisk(page, 'Zaloguj').click();

    await expect(tekst(page, 'Podaj login')).toBeVisible();
    await expect(tekst(page, 'Podaj hasło')).toBeVisible();
  });

  test('sesja zostaje odtworzona po przeładowaniu strony', async ({ page }) => {
    await zalogujDoPanelu(page, KONTA.pracownik);

    // Token zapisany w pamieci przegladarki (Hive / IndexedDB) - bez ponownego logowania.
    await otworzAplikacje(page);
    await expect(tekst(page, 'Panel główny')).toBeVisible();
    await expect(tekst(page, 'Logowanie do systemu')).toHaveCount(0);
  });

  test('niepoprawne powtórzenie nowego hasła nie zmienia hasła', async ({ page, request }) => {
    // Konto z wymuszona zmiana hasla tworzymy przez API jako administrator.
    const logowanie = await request.post('http://127.0.0.1:8000/api/auth/login', {
      data: { login: KONTA.administrator, password: 'Test1234!' },
    });
    const token = (await logowanie.json()).token;
    const nowe = await request.post('http://127.0.0.1:8000/api/users', {
      headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' },
      data: { name: 'Anna Testowa', email: 'anna.testowa@example.com', password: 'Start123!', role: 'pracownik' },
    });
    const login = (await nowe.json()).login;

    await zaloguj(page, login, 'Start123!');
    await expect(tekst(page, 'Zmiana hasła')).toBeVisible();

    await wpisz(page, 'Nowe hasło', 0, 'NoweHaslo1');
    await wpisz(page, 'Powtórz hasło', 1, 'InneHaslo2');
    await przycisk(page, 'Zmień hasło').click();

    await expect(tekst(page, 'Hasła nie są takie same')).toBeVisible();
    await expect(tekst(page, 'Panel główny')).toHaveCount(0);
  });
});
