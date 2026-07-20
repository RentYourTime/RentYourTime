# DeviceActivity — konfiguracja extension, App Groups, entitlements

Ten dokument opisuje konfigurację potrzebną do działania monitoringu
`DeviceActivity` (`RentYourTime/Services/DeviceActivityService.swift` w
głównej apce + `Extensions/DeviceActivityMonitor/RentDeviceActivityMonitor.swift`
w rozszerzeniu). Zobacz też [SCREEN_TIME_SETUP.md](SCREEN_TIME_SETUP.md) —
ten dokument zakłada, że wiesz już, czym jest Family Controls i dlaczego
obecnie nie jest włączony w projekcie.

## 1. Co już jest skonfigurowane w repo

- **Target `DeviceActivityMonitorExtension`** (`app-extension`) —
  zdefiniowany w `project.yml`, embedowany w głównej apce
  (`dependencies: [{ target: DeviceActivityMonitorExtension, embed: true }]`).
  Bundle ID: `com.rentyourtime.app.DeviceActivityMonitor` (nowy identyfikator,
  nie zmienialiśmy `com.rentyourtime.app` ani `com.rentyourtime.app.tests`).
- **App Group** `group.com.rentyourtime.app` — w entitlements obu targetów
  (`RentYourTime/RentYourTime.entitlements` i
  `Extensions/DeviceActivityMonitor/DeviceActivityMonitor.entitlements`).
  Służy wyłącznie do współdzielenia stanu „przekroczono próg" między apką a
  extension (`Shared/RentAccrualStore.swift`, zapisywane przez
  `UserDefaults(suiteName: AppGroup.identifier)`). **Nie** jest używany do
  współdzielenia samej `FamilyActivitySelection` — tę zna tylko główna apka
  (`ScreenTimeSelectionStore`, `UserDefaults.standard`) i to wystarczy, bo to
  apka buduje `DeviceActivityEvent` przy starcie monitoringu; extension
  dostaje tylko nazwę eventu, który przekroczył próg, nie same tokeny.
- **Folder `Shared/`** — kompilowany do OBU targetów (`RentYourTime` i
  `DeviceActivityMonitorExtension` w `project.yml`). Trzyma
  `AppGroup.swift` (identyfikator grupy) i `RentAccrualStore.swift`
  (bezpieczny, deduplikowany zapis stanu — patrz sekcja 4).

## 2. Czego BRAKUJE, żeby to naprawdę zadziałało

**Family Controls entitlement nie jest włączony w żadnym z dwóch targetów**
(główna apka ani extension) — świadomie, bo wymaga płatnego Apple Developer
Program, a użytkownik projektu obecnie ma darmowe konto. Bez niego:

- Kod się kompiluje i apka normalnie się uruchamia,
- ale `DeviceActivityCenter.startMonitoring(...)` w
  `DeviceActivityService.swift` będzie rzucał błąd (podobnie jak wcześniej
  `AuthorizationCenter` — patrz `SCREEN_TIME_SETUP.md`), więc harmonogram
  monitoringu **nigdy się nie uruchomi naprawdę**,
- a `RentDeviceActivityMonitor` w extension nigdy nie dostanie żadnego
  callbacku od systemu, bo monitoring nigdy nie wystartował.

Żeby to uruchomić naprawdę, gdy będzie płatne konto:

1. W Apple Developer Portal dodaj capability **Family Controls** do OBU App
   ID: `com.rentyourtime.app` i `com.rentyourtime.app.DeviceActivityMonitor`
   (patrz `SCREEN_TIME_SETUP.md`, sekcja 2 — ten sam proces/wniosek).
2. W obu plikach `.entitlements` dopisz z powrotem:
   ```xml
   <key>com.apple.developer.family-controls</key>
   <true/>
   ```
   (obok już istniejącego `com.apple.security.application-groups`).
3. `xcodegen generate` i build — App Group nie wymaga żadnej dodatkowej
   zmiany w `project.yml`, jest już podpięty.

## 3. App Group w Developer Portal (kiedy będzie płatne konto)

App Groups, w przeciwieństwie do Family Controls, działają też na darmowym
koncie deweloperskim lokalnie (Xcode automatycznie tworzy identyfikator
grupy przy automatycznym podpisywaniu) — ale do dystrybucji (TestFlight/App
Store) grupa musi być jawnie zarejestrowana:

1. developer.apple.com → **Certificates, Identifiers & Profiles** →
   **App Groups** → **+** → identyfikator `group.com.rentyourtime.app`.
2. Przypisz tę grupę do obu App ID (`com.rentyourtime.app` i
   `com.rentyourtime.app.DeviceActivityMonitor`) w sekcji **App Groups**
   każdego z nich.
3. Jeśli capability nie pojawia się automatycznie w Xcode → target →
   **Signing & Capabilities** → **+ Capability** → **App Groups** → zaznacz
   `group.com.rentyourtime.app` (dla obu targetów).

Jeśli po dodaniu App Groups signing znowu przestanie działać na darmowym
koncie — usuń klucz `com.apple.security.application-groups` z obu
entitlements tym samym sposobem, jakim usunęliśmy wcześniej Family Controls.

## 4. Jak działa harmonogram i deduplikacja

- `DeviceActivityService.startDailyMonitoring(selection:threshold:)` startuje
  `DeviceActivitySchedule` od `00:00` do `23:59`, `repeats: true` (codziennie
  ten sam interwał), z jednym eventem (`thresholdEventName`) zbudowanym z
  tokenów zapisanej wcześniej `FamilyActivitySelection`.
- Próg (`DeviceActivityThreshold.default`) to **5 minut w konfiguracji
  DEBUG** i **3 godziny w RELEASE** — niezależna wartość od „dziennego
  darmowego limitu" ustawianego w Ustawieniach (`AppState.dailyFreeLimitMinutes`);
  można to później spiąć, ale na etapie POC to celowo osobne ustawienia.
  Threshold można nadpisać, przekazując inną wartość do
  `startDailyMonitoring(selection:threshold:)`.
- `RentDeviceActivityMonitor.eventDidReachThreshold` woła
  `RentAccrualStore.recordThresholdExceeded(dayIdentifier:date:userDefaults:)`.
  Ta funkcja **najpierw sprawdza, czy dla danego dnia (`dayIdentifier`,
  format `yyyy-MM-dd`) już coś zapisano** — jeśli tak, nic nie nadpisuje i
  zwraca `false`. To zapobiega wielokrotnemu naliczeniu tego samego
  przekroczenia progu (np. gdyby system wywołał callback więcej niż raz).
  Pokrywa to test `RentAccrualStoreTests.testSecondRecordForSameDayIsIgnored`.
- Wszystkie trzy wymagane callbacki (`intervalDidStart`, `intervalDidEnd`,
  `eventDidReachThreshold`) są obsłużone; extension nie uruchamia żadnego
  własnego timera/pętli w tle — działa wyłącznie reaktywnie na wywołania
  systemu.
- Logi (`print`) są zawsze owinięte w `#if DEBUG` — nie trafiają do builda
  RELEASE.

## 5. Testowanie na prawdziwym urządzeniu

W przeciwieństwie do indywidualnej autoryzacji (którą dało się zamockować
przez `MockScreenTimeService` — patrz `SCREEN_TIME_SETUP.md`),
**`DeviceActivityMonitor` nie da się sensownie zamockować lokalnie** —
callbacki wywołuje system w osobnym procesie extension, w reakcji na
faktyczne korzystanie z wybranych aplikacji na prawdziwym urządzeniu. Żeby
przetestować cały łańcuch (po dodaniu Family Controls entitlementu, patrz
sekcja 2):

1. Zainstaluj apkę na fizycznym urządzeniu, przejdź onboarding, wybierz w
   „Choose what to track" jedną aplikację, którą łatwo intensywnie użyć
   (np. przeglądarkę).
2. Upewnij się, że build jest w konfiguracji **Debug** — próg wynosi wtedy
   5 minut, a nie 3 godziny.
3. Korzystaj z wybranej aplikacji łącznie >5 minut w ciągu dnia.
4. Sprawdź w Xcode → **Devices and Simulators** → **View Device Logs** (albo
   Console.app podłączonego urządzenia), filtrując po `RentDeviceActivityMonitor`
   — powinny pojawić się logi `intervalDidStart` na starcie dnia i
   `eventDidReachThreshold` po przekroczeniu progu.
5. Zweryfikuj zapisany stan: najprościej dopisać tymczasowo w Ustawieniach
   (lub w debugerze) odczyt `RentAccrualStore.load(userDefaults:
   UserDefaults(suiteName: AppGroup.identifier))` — powinien zwrócić
   `dayIdentifier` odpowiadający dzisiejszej dacie i `hasStartedRent == true`.
   (Nie dodaliśmy do tego UI — to celowo poza zakresem tego kroku, patrz
   „Poza zakresem" w planie.)
6. Odczekaj do 23:59 (albo zmień czas systemowy urządzenia, jeśli to
   dopuszczalne w Twoim scenariuszu testowym) i sprawdź, czy pojawił się log
   `intervalDidEnd`.

## 6. Poza zakresem tego kroku

Wyświetlanie zarejestrowanego rentu w Dashboard/History, realne naliczanie
kosztu na podstawie `RentAccrualStore`, jakiekolwiek UI do podglądu stanu
poza logami DEBUG.
