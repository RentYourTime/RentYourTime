# Widget (WidgetKit)

Widget domowego ekranu (`systemSmall`/`systemMedium`) pokazujący wykorzystany
czas, pozostały darmowy czas, aktualny wirtualny rent i status
free/rentActive. Zobacz też [DEVICE_ACTIVITY_SETUP.md](DEVICE_ACTIVITY_SETUP.md)
i [NOTIFICATIONS.md](NOTIFICATIONS.md) — ten dokument zakłada znajomość
App Group i wzorca `Shared/`-owych store'ów opisanego tam.

## 1. Przepływ danych: Device Activity → główna aplikacja → App Group → Widget

```
DeviceActivityMonitor extension
  └─ eventDidReachThreshold (80/95/100%)
       └─ RentAccrualStore (App Group)     ← realny sygnał "czy dziś wystartował rent"

Główna aplikacja
  └─ DashboardView się pojawia / Ustawienia się zmieniają
       └─ RentCalculationEngine.calculate(...)      ← ten sam silnik co Dashboard
            └─ WidgetSnapshot (App Group)
                 └─ WidgetCenter.reloadTimelines(ofKind: WidgetKind.rentStatus)

RentWidgetExtension
  └─ TimelineProvider czyta WidgetSnapshot (tylko odczyt, nigdy nie liczy)
       └─ systemSmall / systemMedium
```

**Ważne zastrzeżenie:** `DeviceActivityMonitor` w tym projekcie dostarcza
dziś tylko dyskretne zdarzenia progowe (80%/95%/100%), nie ciągły licznik
"ile minut użyto" — nie ma jeszcze `DeviceActivityReport` extension.
`usedMinutes` pokazywane w widgecie pochodzi z tego samego źródła co w
Dashboardzie (`DemoDataProvider.todayUsedMinutes` policzone przez
`RentCalculationEngine`). Widget nigdy nie liczy niczego sam — tylko czyta
to, co zapisała główna apka.

**Świeżość widgetu zależy od tego, jak często otwierana jest apka** —
extension `DeviceActivityMonitor` świadomie **nie** pisze bezpośrednio do
`WidgetSnapshot` ani nie woła `WidgetCenter` (taki jest dosłowny przepływ z
wymagań: Device Activity → **główna aplikacja** → App Group → Widget). Gdy
user otworzy Dashboard po przekroczeniu progu, widget dostanie świeże dane
przy najbliższym odświeżeniu.

## 2. Co ląduje w App Group (i co świadomie NIE ląduje)

`Shared/WidgetSnapshot.swift`:

```swift
struct WidgetSnapshot: Codable, Equatable, Sendable {
    let usedMinutes: Int
    let allowanceMinutes: Int
    let remainingMinutes: Int
    let virtualRentAmount: Decimal
    let currencyCode: String
    let status: RentStatus
    let generatedAt: Date
}
```

Zapisane pod tym samym `UserDefaults(suiteName: AppGroup.identifier)`, co
`RentAccrualStore`/`NotificationPreferences`.

**Świadomie wykluczone** (bez zbędnych danych prywatnych):
`FamilyActivitySelection`/tokeny wybranych aplikacji, historia
(`DailyUsageRecord`), jakiekolwiek dane per-aplikacja, cena za minutę per se
(tylko już przeliczona kwota rentu). Sześć pól + znacznik czasu — nic, co
identyfikuje konkretne aplikacje użytkownika.

Widget nie wymaga entitlementu Family Controls — nigdy nie dotyka
FamilyControls/DeviceActivity API bezpośrednio, tylko czyta gotowe liczby z
App Group (`Extensions/RentWidget/RentWidget.entitlements` ma tylko App
Group).

## 3. Dwa stany zamiast trzech

Silnik ma trzy statusy (`free`/`warning`/`rentActive`), ale wymóg dla
widgetu mówi tylko o dwóch. `WidgetSnapshot.status` zapisuje pełną,
3-stanową wartość (zero utraty informacji), ale warstwa wizualna widgetu
(`RentWidgetEntryView.swift`, `RentStatus.widgetTint/widgetLabel`) zwija
`.warning` do wyglądu „w normie" — czerwony/„Rent aktywny" tylko dla
`.rentActive`.

## 4. Budżet odświeżeń WidgetKit (wymóg 6/7)

WidgetKit ma systemowy, nienegocjowalny budżet odświeżeń (rzędu
kilkudziesięciu dziennie, zależny też od tego, jak często user w ogóle
patrzy na widget) — nie da się i nie próbujemy wymusić odświeżania co
minutę:

- `RentWidgetProvider.getTimeline` zwraca **jeden** entry (bieżący stan) +
  `.after(+30 minut)` — nie generujemy sztucznej serii przyszłych entries
  (nie da się przewidzieć przyszłego użycia).
- `WidgetSnapshotUpdater` (główna apka) woła `WidgetCenter.reloadTimelines`
  tylko przy konkretnych zdarzeniach — pojawienie się Dashboardu
  (`DashboardView.task`) i zmiana limitu/ceny/waluty w Ustawieniach
  (`SettingsView.onChange`) — nigdy na timerze.

## 5. placeholder / snapshot / timeline

- `placeholder(in:)` — statyczne przykładowe liczby, nie czyta App Group
  (ma być natychmiastowy); WidgetKit sam nakłada redakcję w galerii wyboru
  widgetów.
- `getSnapshot(in:completion:)` — `context.isPreview` rozróżnia podgląd w
  galerii (przykładowe dane) od realnego wywołania (prawdziwy
  `WidgetSnapshot` z App Group, z fallbackiem do przykładowych danych przy
  pierwszym uruchomieniu, zanim apka cokolwiek zapisze).
- `getTimeline(in:completion:)` — jeden entry + `.after(30 min)`, jak wyżej.

## 6. Jasny / ciemny tryb (wymóg 8)

W przeciwieństwie do Dashboardu (celowo *zawsze* ciemny, `RentTheme`),
widget używa **systemowych, adaptacyjnych** kolorów (`.primary`,
`.secondary`, `.red`/`.green`) — widgety mają wyglądać naturalnie w obu
trybach systemowych, zgodnie z HIG. `.containerBackground(.background, for:
.widget)` (wymagane od iOS 17, naszego minimum) zapewnia poprawne tło w
obu trybach bez ręcznego rozgałęziania.

## 7. Jak dodać widget do testów na urządzeniu

1. Zbuduj i zainstaluj apkę (widget jest embedowany automatycznie —
   `dependencies: [{target: RentWidgetExtension, embed: true}]` w
   `project.yml`).
2. Otwórz apkę raz (żeby `WidgetSnapshotUpdater` zapisał pierwszy
   `WidgetSnapshot` — bez tego widget pokaże stan „Otwórz RentYourTime").
3. Na ekranie głównym: przytrzymaj → **+** → znajdź „RentYourTime" → wybierz
   rozmiar mały lub średni → **Dodaj widget**.
4. Zmień limit/cenę/walutę w Ustawieniach i sprawdź, czy widget się
   zaktualizuje (może to potrwać chwilę — patrz sekcja 4 o budżecie).

## 8. Bez zmian w istniejących entitlements

`RentYourTime.entitlements` już ma App Group (z poprzednich zadań) — nic
tam nie trzeba dodawać. Nowy jest tylko
`Extensions/RentWidget/RentWidget.entitlements` z tym samym App Groupem.
