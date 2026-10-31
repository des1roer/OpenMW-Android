# memory.md — OpenMW Android со встроенным Morrowind

Этого файла достаточно, чтобы продолжить работу после полной потери локальных файлов.

## Цель и состояние

APK OpenMW для Android, в который встроена русская версия Morrowind от 1С («Расширенное издание»: Morrowind, Tribunal, Bloodmoon, официальные плагины 1С). Данные игры в репозиторий не коммитятся: проприетарный контент Bethesda/1С.

- Готовая сборка: APK release, `com.ast.openmw`, versionName `0.51.0-14`, `targetSdk 35`, arm64-v8a, ~961 МБ. На устройстве не проверялась.
- Релиз `v1.0.0` в этом репозитории опубликован вручную владельцем: `openmw-morrowind-0.51.0-14-embedded-release.apk`.
- Пре-релиз `native-payload-0.51.0-14`: нативные библиотеки, ресурсы движка и OMWFX-шейдеры (см. ниже).
- Черновик поста для Pikabu (без ссылки на APK с игрой): `C:\dev\openmw\out.txt` на машине владельца.
- Заметки на стороне движка: https://github.com/des1roer/openmw, файл `memory.md` (форк OpenMW; в нём только remote и заметки, исходники движка не менялись).

## Быстрый старт с нуля

Нужно: Linux или WSL2, Docker (без sudo), `curl`, `unzip`, `rsync`, `git` и папка с установленным Morrowind.

```bash
git clone git@github.com:des1roer/OpenMW-Android.git
cd OpenMW-Android/source
./tools/build-embedded-apk.sh "/mnt/c/games/The Elder Scrolls - Morrowind. Расширенное издание" win1251
# → app/build/outputs/apk/mainline/release/app-mainline-release.apk
```

Скрипт делает всё сам:
1. Собирает Docker-образ `omw-android-build` из `source/docker/Dockerfile` (Ubuntu 24.04, JDK 17, autotools, multilib).
2. Ставит Android SDK в `~/Android/sdk` (`ANDROID_SDK_DIR`): platform 35, build-tools 35 и 34, NDK 26.1.10909125. Кэш Gradle лежит в `~/.cache/openmw-android-gradle` (`GRADLE_HOME_DIR`).
3. `tools/fetch-native-payload.sh` скачивает нативную часть и сверяет SHA-256.
4. `tools/stage-embedded-game.sh` раскладывает игру в `app/embedded-game/` (в `.gitignore`).
5. Запускает `./gradlew :app:assembleMainlineRelease` в контейнере; подпись берётся из `signing/`.

Установка: `adb install -r app-mainline-release.apk`. Если стоит APK с другой подписью (например, официальный от Andiweli), его нужно сначала удалить.

## Ключ подписи

- `source/signing/release.jks` (PKCS12), параметры в `source/signing/release.properties`; `app/build.gradle` подхватывает их автоматически для release.
- Alias `openmw`, пароль хранилища и ключа: `vVdvk6QUEwMf6jwhTdNEHcIX`.
- SHA-256 сертификата: `D9:26:20:AA:90:FD:BA:1F:47:30:12:70:1F:E9:12:AB:4D:D7:CD:D7:43:F9:26:67:FE:38:15:9D:B8:39:AB:39`.
- Обновления ставятся поверх только с этим ключом. Ключ публичный, поэтому подписать им APK может кто угодно.

## Что изменено относительно Andiweli/OpenMW-Android 0.51.0-14

- `app/src/main/java/file/EmbeddedGame.kt` — читает `assets/morrowind.manifest` (строки `размер<TAB>путь`) и копирует `assets/morrowind/**` в `getExternalFilesDir()/Morrowind` = `Android/data/com.ast.openmw/files/Morrowind`. Файлы с совпадающим размером пропускает (докачка после обрыва), перед копированием проверяет свободное место, по завершении пишет маркер `.embedded-game-installed` (`<кол-во файлов>:<байт>`).
- `MainActivity.kt` — `unpackEmbeddedGameIfNeeded()` в начале `checkStartGame()`: прогресс-диалог, после распаковки выставляет `game_files`, сбрасывает `game_files_storage_root/id` и ставит `pref_encoding` из `assets/morrowind.encoding`. Если пользователь вручную выбрал валидную папку, она сохраняется.
- Строки `embedded_game_*` на en, ru, de, fr, pl, sv: `verifyOpenMwPayload` требует все локали.
- `app/build.gradle`:
  - assets из `embedded-game`;
  - `ignoreAssetsPattern` без `<dir>_*` (в данных есть `Sound/Cr/_OLD`);
  - `mainline` переведён с `targetSdk 29` на 35 (Play Защита блокировала установку);
  - release подписывается ключом из `signing/`.
- `tools/stage-embedded-game.sh <папка игры> [кодировка]` — копирует `Data Files` и `Morrowind.ini`, домерживает корневую `Video` в `Data Files/Video` (в издании 1С там лежат ролики базовой игры), пишет manifest и encoding.
- `tools/fetch-native-payload.sh`, `tools/build-embedded-apk.sh`, `docker/Dockerfile`.
- `buildscripts/CMakeLists.txt` — SDL2 качается с GitHub, а не с libsdl.org.
- Скриптам сборки возвращены флаги исполнения.

## Нативная часть (native payload)

`app/build.gradle` → `verifyOpenMwPayload` принимает только `libopenmw.so` с SHA-256 `a99f89d2e8de0f652de219af9acd29db48db10f55f0026cc7a911c426a7efdc0`. Это сборка OpenMW 0.51.0 (`f4bec41`) со всеми ~40 патчами из `tools/*.ps1` (тени, gl4es, туман, постобработка). Получить её можно двумя путями:

- **Основной:** архив `openmw-native-payload-0.51.0-14.zip` (SHA-256 `6a1692b9f4cc4640277e3ea52852010f122c75d4a4ba40724164cbf1ca1bdc05`) из пре-релиза `native-payload-0.51.0-14`. Внутри `jniLibs/arm64-v8a/{libopenmw,libGL,libSDL2,libcollada-dom2.5-dp,libopenal,libc++_shared}.so`, `assets/libopenmw/`, `assets/android_omwfx/*.omwfx`.
- **Запасной:** то же самое лежит внутри официального APK https://github.com/Andiweli/OpenMW-Android/releases/download/0.51.0-14/OpenMW.0.51-14.apk (`lib/arm64-v8a/*`, `assets/libopenmw/`, `assets/android_omwfx/`).

`buildscripts/build.sh --arch arm64` собирает `libopenmw.so` с нуля (около 30 минут), но без ps1-патчей, поэтому проверка хеша её отклоняет. Такую сборку стоит использовать, только если отказаться от этой проверки.

## Грабли

- Master OpenMW (0.52-dev, форк des1roer/openmw) этой обёрткой не собрать: Android-патчи привязаны к 0.51.0. Android-задача в `.gitlab-ci.yml` апстрима OpenMW мёртвая.
- `build.sh --lto`: полная LTO-линковка съедает больше 28 ГБ (в WSL было 20 ГБ ОЗУ + 8 ГБ свопа) и уходит в трешинг. Собирать без `--lto`.
- В WSL нет sudo, всё запускается в Docker с `--user $(id -u):$(id -g)`. Каталоги для монтирования создавать заранее, иначе их создаст root.
- Скрипт, переданный в `wsl.exe ... bash -s <<'EOF'` из Git Bash на Windows, теряет обратные слэши. Правки с `\` делать через редактор файлов.
- Французский апостроф в `strings.xml`: `’` или `\'`, иначе aapt2 падает с «Can not extract resource».
- Глобальная git-идентичность в WSL рабочая (`n.zuev`). Для этого репозитория коммитить с `-c user.name=des1roer -c user.email=des1roer@gmail.com`.
- В издании 1С нет BSA, ресурсы распакованы; `Morrowind.ini` ссылается на `Tribunal.bsa`/`Bloodmoon.bsa`, но конвертер ini архивы не переносит, лаунчер подключает только существующие.
- APK с игрой около 1 ГБ; после распаковки на телефоне нужно ещё около 1,3 ГБ.

## Идеи на будущее

- Проверить на устройстве: распаковку, кодировку, ролики, производительность.
- Удалять `assets/morrowind` из памяти после распаковки нельзя (assets только для чтения), поэтому место занято дважды. Альтернатива — отдельный OBB или Play Asset Delivery.
- Перенести ps1-патчи в `buildscripts/patches/openmw051-final`, чтобы `build.sh` давал эталонную `libopenmw.so` без чужого бинаря.
