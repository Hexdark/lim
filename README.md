# Fąfel Guide · Flutter

Prywatna przestrzeń dla dwóch osób: samopoczucie 1–5, ręcznie wybrana faza cyklu, notatka i zdjęcie. Flutter na Androida i jako instalowana aplikacja webowa na iPhone'a, Supabase do synchronizacji.

## Co działa

- Tryb demo bez konta i konfiguracji, przełączanie widoku nadawczyni/odbiorcy.
- Logowanie e-mail + hasło; dwie role nadawane przez właściciela bazy.
- Dodawanie i usuwanie własnych wpisów, podgląd ostatnich 100.
- Opcjonalna faza „Nie wiem / nie podaję”; brak prognoz medycznych.
- Zdjęcia z galerii/aparatu: zmniejszenie do 1280 px, JPEG, usunięcie EXIF, maks. 2 MB.
- Prywatny bucket zdjęć, pobieranie z autoryzacją, reguły RLS.
- Synchronizacja przy otwarciu aplikacji i na żywo, kiedy jest uruchomiona.
- Widget Androida z ostatnio pobranym wpisem i jego datą. Dotknięcie otwiera aplikację.
- Manifest PWA, ikona, start bez paska przeglądarki, cache statycznego interfejsu.

**Ograniczenia v0.1:** widget nie pobiera danych sam w tle. Brak Web Push, E2EE, edycji wpisu, automatycznych prognoz cyklu, odzyskiwania hasła w aplikacji i kolejki wysyłki offline. Historia i zdjęcia wymagają internetu. Demo żyje tylko w pamięci sesji. Wygenerowany projekt iOS jest do przyszłych kompilacji na macOS; na iPhonie używaj wersji webowej.

## Uruchom demo

Wymagany Flutter 3.44.7 / Dart 3.12.2.

```sh
flutter pub get
flutter run -d chrome
# Android / emulator:
flutter run
```

Na ekranie startowym kliknij **Zobacz demo**.

## Podłącz Wasze konta (Supabase Free)

1. Utwórz projekt w [Supabase](https://supabase.com/dashboard). Wybierz region blisko Was, np. UE.
2. W SQL Editor uruchom całą migrację [202609170001_initial.sql](supabase/migrations/202609170001_initial.sql) **raz**.
3. W Authentication → Users → Add user utwórz dwa konta e-mail + hasło, z potwierdzonym e-mailem. Hasła ustalcie osobno; nie wpisuj ich do repozytorium.
4. Wyłącz publiczne rejestracje w ustawieniach Auth.
5. Skopiuj UUID obu użytkowników do [create_couple.example.sql](supabase/create_couple.example.sql), uruchom skrypt w SQL Editor. `writer` wysyła i usuwa wpisy, `reader` tylko czyta.
6. Skopiuj `config/example.json` do **config/local.json**. Wpisz adres projektu oraz **publishable key** (lub starszy `anon`). Nigdy `service_role` ani secret key. Plik lokalny jest ignorowany przez git.
7. Uruchom:

```sh
flutter run -d chrome --dart-define-from-file=config/local.json
flutter run --dart-define-from-file=config/local.json
```

Publiczny klucz aplikacji jest widoczny w zbudowanym kliencie. Bezpieczeństwo zapewniają logowanie i RLS, a nie ukrycie tego klucza. Warto wykonać [test reguł](supabase/tests/rls.sql) w SQL Editor po migracji — dane testowe są wycofywane przez ROLLBACK.

## Instalacja bez sklepów

### iPhone — PWA

```sh
flutter build web --no-web-resources-cdn --dart-define-from-file=config/local.json
```

Opublikuj zawartość `build/web` na hostingu statycznym z HTTPS. Nie trzeba wystawiać bazy ani zdjęć publicznie. Nie ma automatycznego wdrożenia ani opłat za hosting w tym repo.

Otwórz otrzymany adres w Safari → Udostępnij → Dodaj do ekranu początkowego → Otwieraj jako aplikację. Logowanie działa wewnątrz aplikacji. Po aktualizacji czasem trzeba zamknąć i ponownie otworzyć PWA. Cache przechowuje tylko pliki interfejsu, nie odpowiedzi Supabase. Pierwsze uruchomienie wymaga internetu.

### Android — APK + widget

```sh
flutter build apk --debug --dart-define-from-file=config/local.json
```

Plik: `build/app/outputs/flutter-apk/app-debug.apk`. Prześlij na swój telefon, otwórz i zezwól tej aplikacji (np. menedżerowi plików) na instalację z tego źródła. Otwórz Fąfel Guide i zaloguj się. Przytrzymaj ekran główny → Widgety → Fąfel Guide.

To instalacja testowa podpisana lokalnym kluczem debug. Budowanie APK na różnych komputerach/CI może wymagać odinstalowania poprzedniej wersji. Przed stałym używaniem skonfiguruj własny release keystore i zachowaj go poza repo. Szablon release aktualnie również używa klucza debug.

Widget pokazuje dane na ekranie głównym, w tym fazę i fragment notatki; dodanie go jest świadomą decyzją użytkownika. Wylogowanie czyści jego treść.

## Prywatność i kopie danych

- Dostęp do wpisów/zdjęć mają członkowie danej pary. Role i przypisania zmienia tylko administrator bazy.
- Transport korzysta z HTTPS; **to nie jest szyfrowanie end-to-end**. Administrator projektu ma dostęp do treści.
- Zdjęcia pobieramy bezpośrednio z tokenem użytkownika. Brak publicznych URL i zewnętrznej analityki.
- Sesja jest zachowywana przez standardowy mechanizm Supabase Flutter. Nie używaj wspólnego profilu przeglądarki.
- Darmowy projekt może zostać wstrzymany przy niskiej aktywności. Wznów go w panelu Supabase.
- Zaplanuj własne kopie bazy i zdjęć; usunięcie wpisu jest trwałe z punktu widzenia aplikacji.
- Baza i Storage nie mają wspólnej transakcji: przy awarii zapisu/usuwania może pozostać osierocony plik albo wpis bez zdjęcia. Nie usuwaj plików bez sprawdzenia referencji.

## Sprawdzenie projektu

```sh
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
flutter build web --no-web-resources-cdn
flutter build apk --debug
```

GitHub Actions wykonuje te kroki i udostępnia **demo** web/APK jako artefakty. Kompilacje CI nie zawierają Waszej konfiguracji Supabase.

Struktura: `lib/models.dart` → `lib/data/repository.dart` → `lib/controller.dart` → `lib/app.dart`. Natywny widget: `android/app/src/main/kotlin/app/wetwo/we_two/BliskoWidgetProvider.kt`. Schemat i RLS: `supabase/`.

Ikony generuje `dart run tool/generate_icons.dart`. Kod używa własnego geometrycznego znaku, bez zewnętrznych zdjęć i fontów.
