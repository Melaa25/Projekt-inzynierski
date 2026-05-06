# Model danych - krok 1

To jest punkt startowy dla dalszej pracy nad projektem magazynowym. Bazujemy na tym, co już istnieje: tabela `materials` oraz `users`, a obecne pole `location` w materiałach traktujemy jako rozwiązanie tymczasowe do zastąpienia relacją z lokalizacją magazynową.

## 1. Co już mamy

- `materials` - podstawowy katalog materiałów.
- `users` - użytkownicy systemu.
- proste API CRUD dla materiałów.

## 2. MVP modelu danych

Na pierwszy etap proponuję model obejmujący:

- katalog materiałów,
- lokalizacje magazynowe,
- historię operacji,
- użytkowników i role.

## 3. Proponowane encje

### Materials

Główna karta materiału.

Proponowane pola:

- `id`
- `name`
- `serial_number`
- `barcode` lub `qr_code` - jeśli chcemy osobny identyfikator do skanowania,
- `weight`
- `length`
- `unit`
- `current_location_id`
- `status`
- `created_at`
- `updated_at`

### Status materiału

Materiał powinien mieć jednoznaczny status, żeby było wiadomo, na jakim etapie znajduje się fizycznie w magazynie.

Proponowane statusy:

- `in_stock` - materiał jest na magazynie i dostępny,
- `cutting` - materiał jest aktualnie na cięciu,
- `reserved` - materiał jest zarezerwowany do wydania,
- `issued` - materiał został wydany,
- `damaged` - materiał uszkodzony lub wycofany z obiegu,
- `missing` - materiał chwilowo niezgodny ze stanem,
- `transit` - materiał w ruchu między lokalizacjami.

Status powinien być przechowywany w bazie jako pole typu enum albo jako słownik, jeśli później zechcemy go łatwo rozszerzać.

Najważniejsza zasada:

- lokalizacja mówi, gdzie materiał fizycznie leży,
- status mówi, w jakim jest stanie operacyjnym.

### Warehouse locations

Struktura magazynu w układzie logicznym.

Proponowane pola:

- `id`
- `code`
- `name`
- `type` - np. strefa, sektor, miejsce,
- `parent_id` - jeśli chcemy hierarchię,
- `description`

Przykład:

- strefa `A`
- sektor `A-01`
- miejsce `A-01-R03`

### Operations history

Historia wszystkich ruchów magazynowych.

Proponowane pola:

- `id`
- `user_id`
- `material_id`
- `operation_type`
- `from_location_id`
- `to_location_id`
- `quantity`
- `description`
- `status_before`
- `status_after`
- `created_at`

### Roles and permissions

Na tym etapie można przyjąć prosty model:

- `roles`
- `permissions`
- tabela łącząca użytkownika z rolą

Przykładowe role:

- administrator,
- dyspozytor,
- kierownik,
- pracownik placu.

## 4. Relacje

Najważniejsze relacje powinny wyglądać tak:

- materiał należy do jednej aktualnej lokalizacji,
- historia operacji zapisuje każdą zmianę stanu,
- użytkownik wykonuje operacje i ma przypisaną rolę.

Status materiału powinien zmieniać się razem z operacjami magazynowymi. Przykłady:

- po przyjęciu: `in_stock`,
- po przekazaniu na cięcie: `cutting`,
- po wydaniu: `issued`,
- po zarezerwowaniu: `reserved`.

## 5. Co robimy najpierw

Kolejność wdrożenia:

1. zmiana materiału z pola tekstowego `location` na prawdziwą relację do lokalizacji,
2. tabela lokalizacji magazynowych,
3. historia operacji,
4. role i uprawnienia,
5. raporty i zestawienia.

## 6. Decyzja praktyczna

Na start nie komplikujemy wszystkiego. Najpierw budujemy:

- `materials`,
- `warehouse_locations`,
- `operations_history`.

To daje nam działający fundament pod mobilkę i panel stanowiskowy.

## 7. Uproszczony kierunek projektu

W tej wersji projektu nie budujemy osobnych dokumentów przyjęć i wydań. Zamiast tego:

- każda operacja magazynowa trafia do historii,
- status materiału zmienia się po operacji,
- lokalizacja pokazuje, gdzie materiał jest fizycznie,
- raporty korzystają bezpośrednio z historii i aktualnych stanów.

To daje prostszy model, mniej ekranów i łatwiejsze wdrożenie.