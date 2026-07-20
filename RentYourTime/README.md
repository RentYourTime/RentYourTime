# RentYourTime

**Every minute costs.**

RentYourTime pomaga ograniczyć uzależnienie od telefonu. Użytkownik otrzymuje
określoną liczbę darmowych godzin czasu ekranowego dziennie — po przekroczeniu
limitu aplikacja nalicza wirtualny „rent" za każdą dodatkową minutę.

## Status

Szkielet aplikacji (onboarding, dashboard, historia, ustawienia) działający na
danych demonstracyjnych. Integracja ze Screen Time / DeviceActivity API,
persystencja, płatności i backend nie są jeszcze zaimplementowane — patrz
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Wymagania

- Xcode 16+ (iOS 17 deployment target)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Uruchomienie

```sh
xcodegen generate
open RentYourTime.xcodeproj
```

Projekt jest generowany z `project.yml` — `RentYourTime.xcodeproj` nie jest
wersjonowany w git (patrz `.gitignore`). Po każdej zmianie `project.yml`
uruchom ponownie `xcodegen generate`.

## Testy

```sh
xcodebuild -project RentYourTime.xcodeproj -scheme RentYourTime \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```
