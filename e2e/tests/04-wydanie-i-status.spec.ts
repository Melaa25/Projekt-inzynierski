import { expect, test } from '@playwright/test';
import { KONTA, kliknijTekst, partiaZApi, przycisk, przyjmijPrzezApi, tekst, wpisz, wybierz, zalogujDoPanelu } from './pomocnicze';

test.describe('Wydanie materiału i zmiana statusu', () => {
  test('wyszukanie partii, wydanie części ilości, blokada wydania ponad stan i zmiana statusu', async ({ page, request }) => {
    // Dane testowe przygotowane przez API: partia 15 szt.
    const partia = await przyjmijPrzezApi(request, 'Kątownik', 'Półka S1-R2-P1', 15);

    await zalogujDoPanelu(page, KONTA.pracownik);
    await kliknijTekst(page, 'Partie materiałów');

    // Wyszukiwarka filtruje liste po kodzie partii.
    const wyszukiwarka = page.getByRole('textbox').first();
    await wyszukiwarka.click();
    await wyszukiwarka.fill(partia.batch_code);
    await expect(page.getByText(/Kod partii: /)).toHaveCount(1);

    await kliknijTekst(page, `Kod partii: ${partia.batch_code}`);
    await expect(tekst(page, 'Szczegóły partii')).toBeVisible();

    // Wydanie 5 z 15 sztuk.
    await przycisk(page, 'Wydaj').click();
    await wpisz(page, 'Ilość (dostępne', 0, '5');
    await wpisz(page, 'Cel wydania', 1, 'Hala produkcyjna');
    await przycisk(page, 'Wydaj').click();
    await expect(tekst(page, 'Wydano 5 szt.')).toBeVisible();
    await expect(tekst(page, '10 szt.')).toBeVisible();

    // Proba wydania wiecej niz jest w partii - walidacja formularza.
    await przycisk(page, 'Wydaj').click();
    await wpisz(page, 'Ilość (dostępne', 0, '50');
    await przycisk(page, 'Wydaj').click();
    await expect(tekst(page, 'Przekracza dostępną ilość')).toBeVisible();
    await przycisk(page, 'Anuluj').click();

    // Zmiana statusu na "Uszkodzony".
    await przycisk(page, 'Zmień status').click();
    await wybierz(page, 'Status', 'Uszkodzony');
    await przycisk(page, 'Zapisz').click();
    await expect(tekst(page, 'Status zaktualizowany.')).toBeVisible();

    // Kontrola stanu w bazie przez API.
    const poOperacjach = await partiaZApi(request, partia.batch_code);
    expect(poOperacjach.quantity).toBe(10);
    expect(poOperacjach.status).toBe('damaged');
    expect(poOperacjach.movements.map((r: { type: string }) => r.type).sort()).toEqual(['issued', 'received', 'status_change']);
  });
});
