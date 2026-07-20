# Architektura

Lekka architektura feature-based. Widoki bez nietrywialnej logiki (Onboarding,
Settings) wiążą się bezpośrednio z `AppState` przez `@Environment`/`@Bindable`.
Widoki z realną logiką (Dashboard, History) mają obok siebie mały,
`@MainActor`-owy struct-ViewModel, który tłumaczy `AppState` + dane
demonstracyjne na gotowe do wyświetlenia wartości.

## Struktura

```
RentYourTime/
├── App/            – punkt wejścia (@main), wstrzyknięcie AppState
├── Core/           – AppState, RootView (onboarding vs. tab bar), MainTabView
├── Features/       – jeden folder na ekran/flow (Onboarding, Dashboard, History, Settings)
├── Services/       – DemoDataProvider (dane demonstracyjne)
├── Models/         – Currency, UsageEntry
├── Components/     – reużywalne widoki (StatCard, ProgressRing)
├── Extensions/     – rozszerzenia Swift (obecnie puste)
└── Resources/      – Assets.xcassets
```

## AppState

`Core/AppState.swift` — pojedyncza klasa `@Observable`, `@MainActor`,
wstrzykiwana przez `.environment()` w `RentYourTimeApp`. Trzymana tylko w
pamięci (brak persystencji — to celowe uproszczenie na etapie szkieletu).

Pola: `hasCompletedOnboarding`, `dailyFreeLimitMinutes`,
`pricePerExtraMinute`, `currency`. Logika naliczania „rentu" (`rentCost`,
`overLimitMinutes`) żyje w `AppState`, żeby była w jednym miejscu i testowalna
(`RentYourTimeTests/AppStateTests.swift`).

## Dane demonstracyjne

`Services/DemoDataProvider.swift` dostarcza dzisiejsze zużycie oraz 7-dniową
historię jako stałe wartości. Realna integracja ze Screen Time /
DeviceActivity API (foldery `Features/ScreenTime`, `Extensions/`) jest
świadomie poza zakresem tego etapu.

## Poza zakresem

Screen Time API, persystencja (UserDefaults/SwiftData), backend,
Stripe/Apple Pay/StoreKit, Apple Watch.
