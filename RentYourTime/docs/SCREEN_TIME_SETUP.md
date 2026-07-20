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

## 4. Testowanie

- Indywidualna autoryzacja (`AuthorizationCenter.shared.requestAuthorization(for:
  .individual)`) działa zarówno na urządzeniu, jak i w **Simulatorze** — nie
  jest wymagane fizyczne urządzenie ani skonfigurowana kontrola rodzicielska.
- System pokazuje natywny ekran zgody Apple — nie jest potrzebny żaden klucz
  w `Info.plist` (`NSFamilyControlsUsageDescription` nie istnieje).
- Żeby przetestować ścieżkę odmowy/ponowienia w symulatorze wielokrotnie:
  **Settings → Screen Time → (usuń/zresetuj)** albo zainstaluj appkę na
  świeżym symulatorze — status autoryzacji jest przechowywany przez system,
  nie przez naszą aplikację.

## 5. Co dalej (poza zakresem tego etapu)

Po autoryzacji indywidualnej kolejnym krokiem jest `DeviceActivity` (monitor
+ report extension, foldery `Extensions/DeviceActivityMonitor` i
`Extensions/DeviceActivityReport` już zarezerwowane w strukturze projektu)
oraz `FamilyActivityPicker` do wyboru monitorowanych aplikacji. Żadne z nich
nie jest jeszcze zaimplementowane.
