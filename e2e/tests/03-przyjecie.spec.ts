import { expect, test } from '@playwright/test';
import { KONTA, kliknijTekst, odczytajTekst, przycisk, tekst, wpisz, wybierz, zalogujDoPanelu } from './pomocnicze';

// Testy w tym pliku tworza po kolei dane dla siebie nawzajem.
test.describe.configure({ mode: 'serial' });

test.describe('Przyjęcie materiału', () => {
  let kodPartii = '';

  test('przyjęcie na pustą półkę tworzy nową partię z kodem', async ({ page }) => {
    await zalogujDoPanelu(page, KONTA.pracownik);
    await kliknijTekst(page, 'Partie materiałów');
    await przycisk(page, 'Przyjmij materiał').click();
    await expect(tekst(page, 'Dane przyjęcia')).toBeVisible();

    await wybierz(page, 'Typ materiału', 'Blacha DC01');
    await wpisz(page, 'Ilość (szt.)', 0, '12');
    await wybierz(page, 'Półka', 'Półka S1-R1-P1');

    await przycisk(page, 'Sprawdź lokalizację').click();
    await expect(tekst(page, 'Na tej lokalizacji nie ma jeszcze tego materiału')).toBeVisible();

    await przycisk(page, 'Zapisz przyjęcie').click();

    // Okno z propozycja wydruku etykiety zawiera kod nowej partii.
    const okno = tekst(page, /Utworzono nową partię z kodem/);
    await expect(okno).toBeVisible();
    kodPartii = /([A-Z]{2,3}-\d{4})/.exec(await odczytajTekst(okno))?.[1] ?? '';
    expect(kodPartii).toMatch(/^BL-\d{4}$/);

    await przycisk(page, 'Później').click();

    await expect(tekst(page, `Kod partii: ${kodPartii}`)).toBeVisible();
    await expect(tekst(page, 'Ilość: 12 szt.')).toBeVisible();
  });

  test('przyjęcie tego samego materiału na tę samą półkę dopisuje ilość do partii', async ({ page }) => {
    await zalogujDoPanelu(page, KONTA.pracownik);
    await kliknijTekst(page, 'Partie materiałów');
    await przycisk(page, 'Przyjmij materiał').click();

    await wybierz(page, 'Typ materiału', 'Blacha DC01');
    await wpisz(page, 'Ilość (szt.)', 0, '3');
    await wybierz(page, 'Półka', 'Półka S1-R1-P1');

    await przycisk(page, 'Sprawdź lokalizację').click();
    await expect(tekst(page, `Na tej lokalizacji jest już partia ${kodPartii}`)).toBeVisible();

    await przycisk(page, 'Zapisz przyjęcie').click();
    await expect(tekst(page, `Dodano 3 szt. do partii ${kodPartii}.`)).toBeVisible();

    // Nie powstala nowa partia - jest jedna partia z iloscia 15.
    await expect(tekst(page, 'Ilość: 15 szt.')).toBeVisible();
    await expect(page.getByText(/Kod partii: BL-/)).toHaveCount(1);
  });

  test('sprawdzenie lokalizacji bez wybranych danych wyświetla komunikat', async ({ page }) => {
    await zalogujDoPanelu(page, KONTA.pracownik);
    await kliknijTekst(page, 'Partie materiałów');
    await przycisk(page, 'Przyjmij materiał').click();

    await przycisk(page, 'Sprawdź lokalizację').click();

    await expect(tekst(page, 'Wybierz materiał i lokalizację.')).toBeVisible();
  });
});
