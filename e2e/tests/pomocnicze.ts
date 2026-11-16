import { APIRequestContext, Locator, Page, expect } from '@playwright/test';

/**
 * Funkcje pomocnicze do sterowania aplikacja Flutter w przegladarce.
 *
 * Flutter rysuje interfejs na elemencie canvas, wiec zwykle selektory CSS nie dzialaja.
 * Po wlaczeniu dostepnosci Flutter buduje w DOM drzewo semantyki (elementy flt-semantics)
 * z rolami (button, textbox) i tekstami - z niego korzystaja testy.
 */

export const API = 'http://127.0.0.1:8000/api';
export const HASLO = 'Test1234!';

export const KONTA = {
  administrator: 'test.admin',
  kierownik: 'test.kierownik',
  pracownik: 'test.pracownik',
};

function escapeRegExp(text: string): string {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/** Otwiera aplikacje i wlacza drzewo semantyki Fluttera. */
export async function otworzAplikacje(page: Page): Promise<void> {
  await page.goto('/');
  const przelacznik = page.locator('flt-semantics-placeholder');
  await przelacznik.waitFor({ state: 'attached', timeout: 60_000 });
  await przelacznik.evaluate((element: HTMLElement) => element.click());
  await expect(page.locator('flt-semantics').first()).toBeAttached();
}

/**
 * Tekst widoczny na ekranie (fragment albo wyrazenie regularne).
 * Flutter umieszcza tekst w DOM jako tresc elementu albo atrybut aria-label - sprawdzamy oba.
 * Parametr dokladnie = true wymaga calego tekstu (np. etykiety pola), a nie fragmentu.
 */
export function tekst(page: Page, wartosc: string | RegExp, dokladnie = false): Locator {
  return page.getByText(wartosc, { exact: dokladnie }).or(page.getByLabel(wartosc, { exact: dokladnie })).first();
}

/**
 * Flutter blokuje klikniecia w trakcie animacji przejscia miedzy ekranami (ok. 300 ms).
 * Przed kliknieciem z opcja force czekamy, az animacja sie skonczy.
 */
export async function poczekajNaAnimacje(page: Page): Promise<void> {
  await page.waitForTimeout(600);
}

/**
 * Klikniecie w tekst. Zwykle teksty w drzewie semantyki maja pointer-events: none,
 * dlatego klikamy z opcja force - zdarzenie trafia wtedy do Fluttera,
 * ktory sam sprawdza, jaki element lezy w tym miejscu (np. kafelek albo karta partii).
 */
export async function kliknijTekst(page: Page, wartosc: string | RegExp, dokladnie = false): Promise<void> {
  await expect(tekst(page, wartosc, dokladnie)).toBeVisible();
  await poczekajNaAnimacje(page);
  await tekst(page, wartosc, dokladnie).click({ force: true });
}

/** Tekst elementu - Flutter zapisuje go jako tresc albo jako atrybut aria-label. */
export async function odczytajTekst(element: Locator): Promise<string> {
  return ((await element.textContent()) || (await element.getAttribute('aria-label')) || '').trim();
}

/** Przycisk o podanej nazwie (tekst przycisku albo podpowiedz ikony). */
export function przycisk(page: Page, nazwa: string): Locator {
  return page.getByRole('button', { name: nazwa, exact: true }).last();
}

/**
 * Pole tekstowe po etykiecie (labelText). Gdyby etykieta nie trafila do drzewa
 * semantyki, pole jest wyszukiwane po kolejnosci na ekranie.
 */
export async function pole(page: Page, etykieta: string, kolejnosc: number): Promise<Locator> {
  const poEtykiecie = page.getByRole('textbox', { name: new RegExp('^' + escapeRegExp(etykieta)) });

  if ((await poEtykiecie.count()) > 0) {
    return poEtykiecie.first();
  }

  return page.getByRole('textbox').nth(kolejnosc);
}

export async function wpisz(page: Page, etykieta: string, kolejnosc: number, wartosc: string): Promise<void> {
  const element = await pole(page, etykieta, kolejnosc);
  await element.click();
  await element.fill(wartosc);
}

/** Wybor wartosci z listy rozwijanej (DropdownButtonFormField). */
export async function wybierz(page: Page, etykieta: string, opcja: string): Promise<void> {
  const jakoPrzycisk = page.getByRole('button', { name: new RegExp(escapeRegExp(etykieta)) });

  if ((await jakoPrzycisk.count()) > 0) {
    await jakoPrzycisk.last().click();
  } else {
    // Klikniecie w etykiete pola otwiera liste (dokladny tekst, zeby nie trafic w opis formularza).
    await kliknijTekst(page, etykieta, true);
  }

  // Rozwinieta lista to w drzewie semantyki menu z elementami o roli menuitem.
  const element = page.getByRole('menuitem', { name: opcja }).first();
  await expect(element).toBeVisible();
  await poczekajNaAnimacje(page);
  await element.click();
  await expect(page.getByRole('menuitem')).toHaveCount(0);
}

/** Logowanie przez formularz aplikacji. */
export async function zaloguj(page: Page, login: string, haslo = HASLO): Promise<void> {
  await otworzAplikacje(page);
  await expect(tekst(page, 'Logowanie do systemu')).toBeVisible();
  await wpisz(page, 'Login', 0, login);
  await wpisz(page, 'Hasło', 1, haslo);
  await przycisk(page, 'Zaloguj').click();
}

export async function zalogujDoPanelu(page: Page, login: string): Promise<void> {
  await zaloguj(page, login);
  await expect(tekst(page, 'Panel główny')).toBeVisible();
}

// ---------- Przygotowanie danych przez API (bez klikania w interfejs) ----------

export async function tokenApi(request: APIRequestContext, login: string): Promise<string> {
  const odpowiedz = await request.post(`${API}/auth/login`, { data: { login, password: HASLO } });
  expect(odpowiedz.status()).toBe(200);
  return (await odpowiedz.json()).token;
}

export function naglowki(token: string) {
  return { Authorization: `Bearer ${token}`, Accept: 'application/json' };
}

/** Przyjecie partii przez API - zwraca obiekt partii z odpowiedzi serwera. */
export async function przyjmijPrzezApi(
  request: APIRequestContext,
  material: string,
  polka: string,
  ilosc: number,
): Promise<{ id: number; batch_code: string; quantity: number }> {
  const token = await tokenApi(request, KONTA.kierownik);

  const materialy = await (await request.get(`${API}/materials`, { headers: naglowki(token) })).json();
  const polki = await (await request.get(`${API}/locations?type=polka`, { headers: naglowki(token) })).json();
  const materialId = materialy.find((m: { name: string }) => m.name === material).id;
  const polkaId = polki.find((l: { name: string }) => l.name === polka).id;

  const odpowiedz = await request.post(`${API}/batches/receive-material`, {
    headers: naglowki(token),
    data: { material_id: materialId, quantity: ilosc, location_id: polkaId },
  });
  expect(odpowiedz.status()).toBe(201);

  return odpowiedz.json();
}

export async function partiaZApi(request: APIRequestContext, kod: string) {
  const token = await tokenApi(request, KONTA.kierownik);
  const odpowiedz = await request.get(`${API}/batches/${kod}`, { headers: naglowki(token) });
  expect(odpowiedz.status()).toBe(200);
  return odpowiedz.json();
}
