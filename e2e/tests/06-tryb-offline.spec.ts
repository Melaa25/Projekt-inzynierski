import { expect, test } from '@playwright/test';
import { API, KONTA, kliknijTekst, naglowki, przycisk, tekst, tokenApi, wpisz, wybierz, zalogujDoPanelu } from './pomocnicze';

test.describe('Praca bez połączenia i synchronizacja', () => {
  test('przyjęcie bez sieci trafia do kolejki i po powrocie sieci jest zapisywane na serwerze', async ({ page, context, request }) => {
    test.setTimeout(240_000);

    // 1. Praca z siecia - aplikacja zapisuje kopie list partii, materialow i polek.
    await zalogujDoPanelu(page, KONTA.pracownik);
    await kliknijTekst(page, 'Partie materiałów');
    await przycisk(page, 'Przyjmij materiał').click();
    await expect(tekst(page, 'Dane przyjęcia')).toBeVisible();
    await page.waitForTimeout(1_000);
    await przycisk(page, 'Back').click();

    // 2. Utrata sieci (jak w magazynie bez zasiegu).
    await context.setOffline(true);

    // 3. Przyjecie bez polaczenia - partia dostaje tymczasowy kod OFF-.
    await przycisk(page, 'Przyjmij materiał').click();
    await wybierz(page, 'Typ materiału', 'Ceownik');
    await wpisz(page, 'Ilość (szt.)', 0, '7');
    await wybierz(page, 'Półka', 'Półka S1-R1-P2');
    await przycisk(page, 'Sprawdź lokalizację').click();
    await expect(tekst(page, 'Na tej lokalizacji nie ma jeszcze tego materiału')).toBeVisible();
    await przycisk(page, 'Zapisz przyjęcie').click();

    await expect(tekst(page, /Utworzono nową partię z kodem OFF-/)).toBeVisible();
    await przycisk(page, 'Później').click();
    await expect(tekst(page, /Kod partii: OFF-/)).toBeVisible();

    // 4. Funkcje wymagajace polaczenia informuja o tym uzytkownika.
    await przycisk(page, 'Back').click();
    await kliknijTekst(page, 'Przyjęcia');
    await expect(tekst(page, 'Historia ruchów jest dostępna tylko z połączeniem internetowym.')).toBeVisible();
    await przycisk(page, 'Back').click();

    // Serwer jeszcze nie wie o tej operacji.
    const token = await tokenApi(request, KONTA.kierownik);
    let partie = await (await request.get(`${API}/batches`, { headers: naglowki(token) })).json();
    expect(partie.filter((p: { material?: { name: string } }) => p.material?.name === 'Ceownik')).toHaveLength(0);

    // 5. Powrot sieci - kolejka wysyla sie sama (sprawdzenie polaczenia co 15 s).
    await context.setOffline(false);
    await kliknijTekst(page, 'Partie materiałów');

    await expect(async () => {
      await przycisk(page, 'Odśwież').click();
      await expect(tekst(page, /Kod partii: CE-\d{4}/)).toBeVisible({ timeout: 3_000 });
      await expect(page.getByText(/Kod partii: OFF-/)).toHaveCount(0);
    }).toPass({ timeout: 90_000, intervals: [5_000] });

    // 6. Partia jest w bazie z poprawna iloscia i czasem wykonania z telefonu.
    partie = await (await request.get(`${API}/batches`, { headers: naglowki(token) })).json();
    const ceowniki = partie.filter((p: { material?: { name: string } }) => p.material?.name === 'Ceownik');
    expect(ceowniki).toHaveLength(1);
    expect(ceowniki[0].quantity).toBe(7);
    expect(ceowniki[0].client_uuid).toBeTruthy();

    const szczegoly = await (await request.get(`${API}/batches/${ceowniki[0].batch_code}`, { headers: naglowki(token) })).json();
    expect(szczegoly.movements).toHaveLength(1);
    expect(szczegoly.movements[0].client_operation_id).toBeTruthy();
    expect(new Date(szczegoly.movements[0].performed_at).getTime()).toBeLessThan(new Date(szczegoly.movements[0].created_at).getTime());
  });
});
