# Screen Time / Family Controls — konfiguracja

Ten dokument opisuje capabilities i entitlements potrzebne do tego, żeby
`FamilyControls.AuthorizationCenter` (patrz
`RentYourTime/Services/ScreenTimeAuthorizationService.swift`) mógł prosić o
**individual authorization**.

## 1. Entitlement w kodzie

Plik `RentYourTime/RentYourTime.entitlements` zawiera:

```xml
<key>com.apple.developer.family-controls</key>
<true/>
```

i jest podpięty w `project.yml` przez:

```yaml
CODE_SIGN_ENTITLEMENTS: RentYourTime/RentYourTime.entitlements
```

Po zmianach w `project.yml` uruchom `xcodegen generate`.

## 2. Apple Developer Portal

Capability **Family Controls** nie jest dostępna do samodzielnego włączenia
dla każdego App ID — dla dystrybucji (TestFlight/App Store) Apple wymaga
złożenia osobnego wniosku:

1. Zaloguj się na [developer.apple.com](https://developer.apple.com) →
   **Certificates, Identifiers & Profiles** → wybierz App ID
   (`com.rentyourtime.app`).
2. Włącz capability **Family Controls**.
3. Jeśli capability nie jest widoczna do włączenia od razu — złóż wniosek o
   **Family Controls distribution entitlement**
   (Apple → *Request the Family Controls entitlement*, formularz dostępny w
   sekcji Developer Account). Zatwierdzenie nie jest natychmiastowe.
4. Odśwież/pobierz profil provisioningu po zatwierdzeniu.

Do lokalnego developmentu (podpisywanie automatyczne, ten sam Apple ID)
Xcode zwykle sam dopisuje capability po dodaniu jej w
**Signing & Capabilities**, ale wciąż wymaga, żeby App ID miał ją
zarejestrowaną w portalu.

## 3. Xcode — Signing & Capabilities

Jeśli wolisz dodać capability z GUI zamiast ręcznie edytować
`.entitlements`:

1. Otwórz `RentYourTime.xcodeproj` (po `xcodegen generate`).
2. Target `RentYourTime` → **Signing & Capabilities** → **+ Capability** →
   **Family Controls**.
3. Xcode doda/zaktualizuje `RentYourTime.entitlements` automatically —
   upewnij się, że wynikowy plik nadal wskazuje ścieżkę ustawioną w
   `project.yml` (`RentYourTime/RentYourTime.entitlements`), żeby zmiana nie
   zniknęła po kolejnym `xcodegen generate`.

## 4. Testowanie autoryzacji

- Indywidualna autoryzacja (`AuthorizationCenter.shared.requestAuthorization(for:
  .individual)`) działa zarówno na urządzeniu, jak i w **Simulatorze** — nie
  jest wymagane fizyczne urządzenie ani skonfigurowana kontrola rodzicielska.
- System pokazuje natywny ekran zgody Apple — nie jest potrzebny żaden klucz
  w `Info.plist` (`NSFamilyControlsUsageDescription` nie istnieje).
- Żeby przetestować ścieżkę odmowy/ponowienia w symulatorze wielokrotnie:
  **Settings → Screen Time → (usuń/zresetuj)** albo zainstaluj appkę na
  świeżym symulatorze — status autoryzacji jest przechowywany przez system,
  nie przez naszą aplikację.

## 5. Wybór aplikacji i kategorii (FamilyActivityPicker)

`ScreenTimeSelectionStore` (`RentYourTime/Services/ScreenTimeSelectionStore.swift`)
trzyma bieżący `FamilyActivitySelection` i zapisuje go lokalnie (JSON w
`UserDefaults`, klucz `screenTimeSelection`). `ScreenTimeSelectionView`
(`RentYourTime/Features/ScreenTime/ScreenTimeSelectionView.swift`) otwiera
natywny `FamilyActivityPicker` przez modyfikator
`.familyActivityPicker(isPresented:selection:)` — to system renderuje nazwy i
ikony aplikacji; aplikacja nigdy nie odczytuje zawartości opaque tokenów,
tylko liczy elementy wybranego zbioru (`applicationTokens.count` itd.).
Ekran jest używany w dwóch miejscach: jako krok onboardingu
(„Choose what to track", blokuje przejście dalej, dopóki nic nie jest
wybrane) oraz jako arkusz w **Ustawieniach** (sekcja „Śledzone aplikacje" →
„Zmień wybór" / „Wyczyść wybór").

### Testowanie na prawdziwym urządzeniu

`FamilyActivityPicker` pokazuje realnie zainstalowane aplikacje i musi być
przetestowany na fizycznym iPhonie/iPadzie:

1. Podłącz urządzenie, w Xcode wybierz je jako destination, upewnij się że
   **Signing & Capabilities → Team** jest ustawiony na Twój Apple ID/zespół
   i że App ID ma zarejestrowaną capability Family Controls (sekcja 2/3
   wyżej) — do developmentu na własnym urządzeniu wystarczy zwykłe konto
   Apple Developer (personal team), bez czekania na zatwierdzenie
   dystrybucyjnego entitlementu.
2. Uruchom aplikację (`Cmd+R`) i przejdź onboarding: krok „Dostęp do Screen
   Time" → zaakceptuj systemowy prompt → krok „Choose what to track".
3. Stuknij „Wybierz aplikacje i kategorie" — powinien pokazać się natywny
   `FamilyActivityPicker` z realną listą zainstalowanych aplikacji i
   kategorii z Twojego urządzenia (oraz zakładką stron internetowych, jeśli
   system ją udostępnia).
4. Zaznacz kilka pozycji, zamknij picker — pod przyciskiem powinno pojawić
   się podsumowanie liczbowe („X aplikacji, Y kategorii, Z domen"), a
   przycisk „Zapisz i kontynuuj" powinien się odblokować.
5. Zapisz — onboarding powinien przejść do kolejnego kroku (limit czasu).
6. Wymuś zamknięcie i ponowne uruchomienie aplikacji — po ukończonym
   onboardingu wejdź w **Ustawienia → Śledzone aplikacje**: podsumowanie
   powinno pokazywać ten sam wybór, co potwierdza, że odczyt z
   `UserDefaults` w `init(userDefaults:)` faktycznie działa (nie tylko stan
   w pamięci z bieżącej sesji).
7. W Ustawieniach stuknij „Zmień wybór", zmodyfikuj selekcję i zapisz —
   podsumowanie powinno się zaktualizować. Stuknij „Wyczyść wybór" —
   podsumowanie powinno wrócić do „Nie wybrano jeszcze...", a przy ponownym
   uruchomieniu appki wybór ma pozostać pusty (czyli `clear()` faktycznie
   usuwa wpis z `UserDefaults`, a nie tylko stan w pamięci).
8. Bez fizycznego urządzenia: Simulator technicznie otwiera
   `FamilyActivityPicker`, ale pokazuje bardzo ograniczony/pusty zestaw
   aplikacji (symulator nie ma realnie zainstalowanych aplikacji z App
   Store), więc nie nadaje się do sensownego testowania tego ekranu — do
   tego kroku wymagane jest prawdziwe urządzenie.

## 6. Co dalej (poza zakresem tego etapu)

Kolejny krok to `DeviceActivity` (monitor + report extension, foldery
`Extensions/DeviceActivityMonitor` i `Extensions/DeviceActivityReport` już
zarezerwowane w strukturze projektu) — czyli faktyczne naliczanie czasu na
podstawie wybranej selekcji. Nie jest jeszcze zaimplementowane.
