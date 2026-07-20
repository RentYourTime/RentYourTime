# Subskrypcja Pro (StoreKit 2)

## 1. Product IDs i grupa subskrypcji

```
com.rentyourtime.app.pro.monthly   — Monthly Pro, 9.99 USD / miesiąc
com.rentyourtime.app.pro.annual    — Annual Pro,  99.99 USD / rok
```

Oba w **jednej grupie subskrypcji** ("Pro") — użytkownik ma co najwyżej
jedną aktywną subskrypcję Pro naraz; upgrade/downgrade między planami jest
prorated automatycznie przez StoreKit, nie przez kod aplikacji.

## 2. Architektura entitlementu

Źródłem prawdy jest **`Transaction.currentEntitlements`**
(`RentYourTime/Services/StoreKitService.swift`), nie ręczne liczenie dat
ważności — dla auto-renewable subscriptions StoreKit sam filtruje do
aktualnie ważnych transakcji (uwzględniając odnowienia, wygaśnięcia,
zwroty). `StoreKitService.isProActive` jest przeliczane przy starcie apki,
po zakupie, po `restorePurchases()` i przy każdej transakcji z
`Transaction.updates`.

**`isProActive` jest dziś tylko wystawiane** — widoczne jako informacyjny
status w Ustawieniach ("Aktywna"/"Nieaktywna"), ale **nic w apce go nie
używa do blokowania funkcji**. To świadomy zakres tego zadania: mechanizm
zakupu ma zostać najpierw przetestowany, zanim cokolwiek zostanie za niego
zagatowane.

## 3. Obsługiwane stany (wymogi 3–7)

`StoreKitService.PurchaseState`: `.idle / .purchasing / .purchased /
.userCancelled / .pending / .verificationFailed(String) / .failed(String)`.

- **Zakup udany** → `product.purchase()` zwraca `.success(.verified(transaction))`
  → `transaction.finish()` → odświeżenie entitlementu.
- **Anulowanie przez usera** → `.userCancelled` — traktowane jako
  informacyjne, nie błąd.
- **Pending** (np. rodzicielskie „Poproś o kupno") → `.pending` — Pro
  NIE jest nadawane od razu; finalna transakcja przyjdzie później przez
  `Transaction.updates`.
- **Verification failure** → `.success(.unverified(_, error))` — apka
  **nie ufa** takiej transakcji (nie nadaje Pro), tylko pokazuje błąd.
- **Restore** → `AppStore.sync()` (`StoreKitService.restorePurchases()`,
  osobny `RestoreState`), potem odświeżenie entitlementu.

## 4. `Transaction.updates` (wymóg 8)

Długożyjący `Task` uruchamiany raz w `StoreKitService.init()` (żyje przez
cały czas życia serwisu, czyli całej apki — wstrzyknięty raz w
`RentYourTimeApp.swift`), `.cancel()`-owany w `deinit`. Obsługuje
odnowienia, zwroty i zmiany zdalne (np. zakup zsynchronizowany z innego
urządzenia) niezależnie od tego, czy paywall jest akurat otwarty.

## 5. Plik StoreKit Configuration (wymóg 10)

`RentYourTime.storekit` (root projektu) — dwa produkty (Monthly/Annual) w
jednej grupie subskrypcji, z lokalizacjami PL/EN. Podpięty do schematu
`RentYourTime` przez `project.yml` (`run.storeKitConfiguration:
RentYourTime.storekit`) — `xcodegen generate` przekłada to na
`StoreKitConfigurationFileReference` w `.xcscheme` (zweryfikowane).

Jeśli z jakiegoś powodu Xcode nie podchwyci tego automatycznie: **Product →
Scheme → Edit Scheme → Run → Options → StoreKit Configuration** → wybierz
`RentYourTime.storekit` ręcznie.

## 6. Testowanie lokalne w Xcode

1. Uruchom apkę ze schematem `RentYourTime` (StoreKit Configuration
   podpięte jak wyżej — zakupy idą przez lokalny StoreKit Testing, bez
   prawdziwego App Store Connect/Sandboxa).
2. Otwórz **Ustawienia → RentYourTime Pro → Zobacz plany Pro** — powinieneś
   zobaczyć dwie karty z cenami pobranymi z pliku `.storekit`
   (`9,99 USD miesięcznie` / `99,99 USD rocznie` — nigdzie wpisane na
   sztywno w kodzie, wymóg "nie koduj cen na stałe").
3. Kup jeden z planów — systemowy prompt StoreKit Testing (nie prawdziwe
   płatności). Sprawdź, że status w Ustawieniach zmienia się na "Aktywna".
4. W Xcode: **Debug → StoreKit → Manage Transactions** (Transaction
   Manager) — pozwala ręcznie symulować odnowienia, zwroty, „Ask to Buy"
   (pending) i błędy weryfikacji, żeby przetestować każdą gałąź
   `PurchaseState` bez czekania na realne okresy rozliczeniowe.
5. **Restore Purchases** w paywallu → `AppStore.sync()` → sprawdź, że
   status się nie zmienia (nic nie zgubione) po ponownej instalacji/
   wylogowaniu testowego konta.

## 7. Przed wysyłką do App Store — rzeczy do podmiany

- **Terms of Use / Privacy Policy** (`PaywallView.swift`) — dziś
  `https://rentyourtime.app/terms` i `/privacy` to **jawne placeholdery**,
  strony nie istnieją. Apple Review wymaga działających linków — podmienić
  przed wysyłką.
- **App Store Connect** — założyć identyczne product ID w tej samej
  grupie subskrypcji ("Pro"), z tymi samymi cenami/okresami co w
  `RentYourTime.storekit`, żeby zachowanie sandbox/produkcyjne było
  spójne z tym, co testowane lokalnie.
- Ten dokument i `PaywallView` nie wspominają jeszcze o wymaganym przez
  Apple opisie funkcji Pro (co dokładnie odblokowuje subskrypcja) — apka
  dziś niczego nie gatuje za Pro (zgodnie z zakresem tego zadania), więc
  ten opis doczeka realnego gatingu w kolejnym kroku.

## 8. Bez Stripe / Apple Pay (wymóg 13)

Zakup funkcji cyfrowych w apce idzie wyłącznie przez `StoreKit`/
`Product.purchase()` — zgodnie z zasadami App Store dla treści cyfrowych.
