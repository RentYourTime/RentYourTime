# Lokalne powiadomienia

Cztery typy powiadomień w RentYourTime, ich źródło i architektura. Zobacz
też [DEVICE_ACTIVITY_SETUP.md](DEVICE_ACTIVITY_SETUP.md) — powiadomienia
80%/95%/start rentu są nadbudowane bezpośrednio na mechanizmie opisanym tam.

## 1. Które powiadomienia wyzwala `DeviceActivityMonitor`, a które apka

| Powiadomienie | Wyzwalacz | Gdzie |
|---|---|---|
| 80% dziennego limitu | `DeviceActivityEvent` (próg czasu) | `Extensions/DeviceActivityMonitor/RentDeviceActivityMonitor.swift`, `eventDidReachThreshold` |
| 95% dziennego limitu | `DeviceActivityEvent` (próg czasu) | jw. |
| Start naliczania rentu | `DeviceActivityEvent` (próg czasu = 100% limitu) | jw. |
| Wieczorne podsumowanie dnia | `UNCalendarNotificationTrigger` (stała godzina, `repeats: true`) | `RentYourTime/Services/NotificationService.swift`, zaplanowane raz przez główną apkę |

Pierwsze trzy to zdarzenia „przekroczono próg czasu ekranowego" — dokładnie
to, co wykrywa `DeviceActivityMonitor`. Czwarte jest czysto czasowe i **nie
ma nic wspólnego z DeviceActivity** — to zwykły, powtarzający się lokalny
trigger zaplanowany przez główną apkę (domyślnie 21:00), niezależny od
tego, czy user w ogóle korzystał z telefonu.

## 2. Ograniczenia `DeviceActivityMonitor` i jak sobie z nimi radzimy

Extension działa w osobnym, krótkotrwałym procesie, odpalanym przez system
tylko w konkretnych momentach (start/koniec interwału, przekroczenie
zarejestrowanego progu) — bez ciągłego działania w tle, z ograniczonym
budżetem czasu/pamięci. Z tego wynika:

- **Extension nie zna bieżącego % w czasie rzeczywistym** — tylko trzy
  konkretne, wcześniej zarejestrowane progi (80%/95%/100% dziennego limitu,
  liczone w minutach) faktycznie wywołują `eventDidReachThreshold`. Między
  nimi extension nic nie wie i niczego nie sprawdza.
- **Extension nie ma dostępu do `AppState` głównej apki** (osobny proces) —
  nie wie, czy dany typ powiadomienia jest włączony w Ustawieniach, ani czy
  już coś wysłano dziś. Dlatego wszystko, czego potrzebuje, żyje w
  `UserDefaults(suiteName: AppGroup.identifier)`:
  `Shared/NotificationPreferences.swift` (włączone/wyłączone typy) i
  `Shared/NotificationDispatchStore.swift` (co już wysłano dziś).
- **Extension MOŻE bezpośrednio wysyłać lokalne powiadomienia** —
  `UNUserNotificationCenter.current().add(request:)` działa z poziomu
  `DeviceActivityMonitor` bez dodatkowego UI czy osobnej zgody (autoryzacja
  powiadomień jest per-aplikacja, współdzielona z rozszerzeniami). To
  oficjalny, udokumentowany przez Apple sposób reagowania na
  `eventDidReachThreshold`.

## 3. Progi (80%/95%/100%)

Liczone w `DeviceActivityService.startDailyMonitoring(selection:allowanceMinutes:)`
od **rzeczywistego** dziennego limitu użytkownika
(`AppState.dailyFreeLimitMinutes`), zaokrąglone do pełnej minuty (min. 1):

```
80%  → DeviceActivityEvent(threshold: 0.8 × allowanceMinutes)
95%  → DeviceActivityEvent(threshold: 0.95 × allowanceMinutes)
100% → DeviceActivityEvent(threshold: allowanceMinutes)  ← start rentu
```

Nazwa każdego `DeviceActivityEvent` = `NotificationKind.rawValue` (jedno
źródło prawdy dla identyfikatorów, `Shared/NotificationKind.swift`) — dzięki
temu extension w `eventDidReachThreshold` mapuje nazwę eventu z powrotem na
`NotificationKind` bez osobnego słownika.

## 4. Deduplikacja — brak wielokrotnego wysłania tego samego dnia

`NotificationDispatchStore.markSent(_:dayIdentifier:userDefaults:)` zwraca
`true` i zapisuje tylko przy **pierwszym** wysłaniu danego identyfikatora
danego dnia (dzień liczony przez `RentAccrualStore.dayIdentifier(for:)` —
ten sam format co przy naliczaniu rentu). Kolejne wywołania dla tego samego
dnia zwracają `false` bez zapisu — extension wtedy nic nie wysyła. Pokryte
testami w `RentYourTimeTests/NotificationDispatchStoreTests.swift`.

## 5. Zgoda systemowa — dopiero po wyjaśnieniu

Zgodnie z wymogiem, `UNUserNotificationCenter.requestAuthorization` jest
wołane **wyłącznie** z `NotificationService.requestAuthorization()`, a to z
kolei wyłącznie z przycisku „Włącz powiadomienia" w
`NotificationPermissionExplainerView` — ekran ten pokazuje się automatycznie
przy pierwszym włączeniu dowolnego przełącznika w Ustawieniach (sekcja
„Powiadomienia"), zanim jakikolwiek systemowy prompt się pojawi. Jeśli
status jest już określony (`authorized`/`denied` z wcześniejszej sesji),
przełącznik działa od razu, bez ponownego pytania.

## 6. Treść powiadomień

Krótka, spokojna, bez wykrzykników i bez zawstydzania — patrz
`Shared/NotificationContentBuilder.swift`. Każdy typ da się wyłączyć osobno
w Ustawieniach (sekcja „Powiadomienia", cztery przełączniki).

## 7. Testowanie na prawdziwym urządzeniu

Wymaga entitlementu Family Controls (patrz `DEVICE_ACTIVITY_SETUP.md`,
sekcja 2 — bez niego `DeviceActivityCenter.startMonitoring` się nie uda, więc
progi 80/95/100% nigdy nie odpalą, tak jak dziś w ogóle nie startuje
monitoring). Żeby przetestować szybko:

1. W Ustawieniach ustaw mały dzienny limit (np. 15 minut — minimum
   wspierane przez suwak).
2. Włącz interesujące Cię typy powiadomień (przejdziesz przez ekran
   wyjaśnienia + systemowy prompt przy pierwszym włączeniu).
3. Zapisz wybór aplikacji w „Choose what to track" / Ustawieniach — to
   uruchamia monitoring z nowo ustawionym limitem.
4. Korzystaj z wybranej aplikacji: powiadomienie o 80% powinno przyjść po
   ok. 12 minutach, 95% po ok. 14, start rentu po 15.
5. Podsumowanie wieczorne: włącz przełącznik, poczekaj do 21:00 (albo
   tymczasowo zmień godzinę w `scheduleEveningSummary(hour:minute:)` na
   potrzeby testu).
