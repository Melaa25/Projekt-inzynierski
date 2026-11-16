import { expect, test } from '@playwright/test';
import { KONTA, kliknijTekst, przycisk, tekst, wpisz, zaloguj, zalogujDoPanelu } from './pomocnicze';

test.describe('Panel administratora', () => {
  test('administrator zakłada konto, a nowy użytkownik musi zmienić hasło przy pierwszym logowaniu', async ({ page, browser }) => {
    await zalogujDoPanelu(page, KONTA.administrator);
    await kliknijTekst(page, 'Panel administratora');

    await przycisk(page, 'Dodaj użytkownika').click();
    await wpisz(page, 'Imię i nazwisko', 0, 'Łukasz Żółkiewski');
    await wpisz(page, 'Email', 1, 'lukasz.zolkiewski@example.com');
    await wpisz(page, 'Hasło', 2, 'Start123!');
    // Rola domyslnie: Pracownik.
    await przycisk(page, 'Zapisz').click();

    await expect(tekst(page, 'Użytkownik został dodany.')).toBeVisible();
    // Login utworzony z imienia i nazwiska, z zamiana polskich liter.
    await expect(tekst(page, 'l.zolkiewski')).toBeVisible();

    // Pierwsze logowanie nowego uzytkownika - w osobnej sesji przegladarki.
    const nowaSesja = await browser.newContext({ baseURL: 'http://127.0.0.1:8080', serviceWorkers: 'block' });
    const strona = await nowaSesja.newPage();

    await zaloguj(strona, 'l.zolkiewski', 'Start123!');
    await expect(tekst(strona, 'Zmiana hasła')).toBeVisible();

    await wpisz(strona, 'Nowe hasło', 0, 'NoweHaslo1');
    await wpisz(strona, 'Powtórz hasło', 1, 'NoweHaslo1');
    await przycisk(strona, 'Zmień hasło').click();

    await expect(tekst(strona, 'Panel główny')).toBeVisible();
    await expect(tekst(strona, 'Panel administratora')).toHaveCount(0);

    await nowaSesja.close();
  });
});
