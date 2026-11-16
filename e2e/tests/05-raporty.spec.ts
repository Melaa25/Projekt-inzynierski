import { expect, test } from '@playwright/test';
import fs from 'fs';
import { KONTA, kliknijTekst, przycisk, przyjmijPrzezApi, tekst, zalogujDoPanelu } from './pomocnicze';

test.describe('Raporty CSV w panelu webowym', () => {
  test('eksport stanu magazynowego pobiera plik CSV czytelny dla Excela', async ({ page, request }) => {
    const partia = await przyjmijPrzezApi(request, 'Rura stalowa', 'Półka S1-R3-P1', 8);

    await zalogujDoPanelu(page, KONTA.pracownik);
    await kliknijTekst(page, 'Raporty');
    await expect(tekst(page, 'Raporty CSV')).toBeVisible();

    const [pobieranie] = await Promise.all([
      page.waitForEvent('download'),
      przycisk(page, 'Eksportuj stan magazynowy').click(),
    ]);

    expect(pobieranie.suggestedFilename()).toBe('stan_magazynowy.csv');

    const plik = await pobieranie.path();
    const zawartosc = fs.readFileSync(plik);
    const wiersze = zawartosc.toString('utf8').trim().split(/\r?\n/);

    // Znacznik BOM, srednik jako separator i polskie znaki w naglowku.
    expect([...zawartosc.subarray(0, 3)]).toEqual([0xef, 0xbb, 0xbf]);
    expect(wiersze[0]).toContain('Kod partii');
    expect(wiersze[0]).toContain(';Materiał;');
    expect(wiersze.some((w) => w.startsWith(`${partia.batch_code};`))).toBe(true);
  });

  test('eksport historii ruchów pobiera plik CSV', async ({ page }) => {
    await zalogujDoPanelu(page, KONTA.kierownik);
    await kliknijTekst(page, 'Raporty');

    const [pobieranie] = await Promise.all([
      page.waitForEvent('download'),
      przycisk(page, 'Eksportuj historię ruchów').click(),
    ]);

    expect(pobieranie.suggestedFilename()).toBe('historia_ruchow.csv');
    const tresc = fs.readFileSync(await pobieranie.path(), 'utf8');
    expect(tresc.split(/\r?\n/)[0]).toContain(';');
  });
});
