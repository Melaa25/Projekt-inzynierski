import { expect, test } from '@playwright/test';
import { KONTA, tekst, zalogujDoPanelu } from './pomocnicze';

test.describe('Widoczność funkcji zależnie od roli', () => {
  test('pracownik nie widzi funkcji administracyjnych', async ({ page }) => {
    await zalogujDoPanelu(page, KONTA.pracownik);

    await expect(tekst(page, 'Partie materiałów')).toBeVisible();
    await expect(tekst(page, 'Skanowanie')).toBeVisible();
    await expect(tekst(page, 'Raporty')).toBeVisible();
    await expect(tekst(page, 'Panel administratora')).toHaveCount(0);
    await expect(tekst(page, 'Katalog materiałów')).toHaveCount(0);
  });

  test('administrator widzi panel administratora i katalog materiałów', async ({ page }) => {
    await zalogujDoPanelu(page, KONTA.administrator);

    await expect(tekst(page, 'Panel administratora')).toBeVisible();
    await expect(tekst(page, 'Katalog materiałów')).toBeVisible();
  });
});
