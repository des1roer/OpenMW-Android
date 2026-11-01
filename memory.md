# memory.md — OpenMW Android со встроенным Morrowind

Этого файла достаточно, чтобы продолжить работу после полной потери локальных файлов.

## Цель и состояние

APK OpenMW для Android, в который встроена русская версия Morrowind от 1С («Расширенное издание»: Morrowind, Tribunal, Bloodmoon, официальные плагины 1С). Данные игры в репозиторий не коммитятся: проприетарный контент Bethesda/1С.

- Готовая сборка: APK release, `com.ast.openmw`, versionName `0.51.0-14`, `targetSdk 35`, arm64-v8a. Полная версия с игрой ~961 МБ, установлена и проверена владельцем на устройстве — работает, включая чит на золото. Лёгкая версия без игры ~44 МБ (см. ниже), на устройстве не проверялась.
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

## Чит на золото (Settings > Cheats > Gold)

Рабочий, проверен пользователем на устройстве. Код: `app/src/main/assets/cheats/scripts/cheats/{settings,player,global}.lua`, l10n en/ru, Kotlin-обвязка `app/src/main/java/ui/activity/CheatsController.kt` + хук в `MainActivity.generateOpenmwCfg()` (всегда ставится, отдельным content-каталогом `filesDir/cheats`, без переключателя в Android-настройках — включается/выключается самим действием в игровом меню). В APK попадает сам по себе: он лежит в `app/src/main/assets/cheats/`, исключение из `.gitignore` уже сделано (см. ниже).

Механика: в игровом меню Settings > Scripts > Cheats есть поле `Amount` и чекбокс `Give gold`. Включение чекбокса → `player.lua` шлёт `core.sendGlobalEvent('OMWCheatsAddGold', {actor=self.object, amount=N})` → `global.lua` делает `world.createObject('gold_001', N):moveInto(types.Actor.inventory(actor))` и отвечает `actor:sendEvent('OMWCheatsGoldResult', {ok, amount, error})` → `player.lua` по этому ответу сбрасывает чекбокс и показывает сообщение. `gold_001` — канонический id золота в OpenMW (`MWWorld::ContainerStore::sGoldId`, `apps/openmw/mwworld/containerstore.cpp:159` в движке), N единиц этого предмета = N монет.

Три реальных бага, на которые наступили по пути (все исправлены, коммиты `1f9934c`, `cc60623`, `398553d`):
1. **`self` вместо `self.object`** в `core.sendGlobalEvent(...)`. `openmw.self` — локальная обёртка, через события передавать нужно `self.object` (ровно так делает сам движок в `scripts/omw/console/player.lua`). Без этого глобальный скрипт получал невалидный `actor`, `isValid()` падал, и обработчик тихо выходил — визуально «чекбокс залипает на Да», золото не добавляется.
2. **`permanentStorage = false`** в группе настроек, зарегистрированной как `MENU,PLAYER` (скрипт исполняется в двух контекстах одновременно). Движок (`scripts/omw/settings/menu.lua:517`) разрешает MENU-скриптам регистрировать только `permanentStorage = true`-группы; нарушение рушит регистрацию в MENU-контексте с необработанной Lua-ошибкой, а `registerPage` (без такой защиты) всё равно отрабатывает в обоих контекстах → в меню дублируется пункт «Cheats». Фикс: `settings.lua` переведён на `PLAYER`-only контекст (регистрировать страницу до загрузки сохранения не нужно), `permanentStorage = true` оставлен для надёжности.
3. **Сброс чекбокса изнутри его же `subscribe`-колбэка.** `settings:set('giveGold', false)` вызывался синхронно прямо в обработчике изменения этого же ключа — паттерн без прецедента в движке, на практике полностью глушил цепочку (ни золота, ни сообщения, даже об ошибке). Фикс: сброс и показ сообщения перенесены в обработчик ответного события `OMWCheatsGoldResult` (следующий тик), а не в сам `subscribe`.

Если чит перестанет работать после будущих правок — сначала проверить эти три места, это самые нетривиальные грабли Lua-API движка, на которые легко наступить повторно.

## Лёгкая сборка без игровых данных

`tools/build-light-apk.sh` — то же самое, что `build-embedded-apk.sh`, но без `stage-embedded-game.sh`: `app/embedded-game/` не создаётся, APK получается ~44 МБ вместо ~961 МБ, без строки Bethesda-контента внутри. Лаунчер при отсутствии `assets/morrowind.manifest` сам откатывается на штатное поведение апстрима — просит выбрать папку с игрой вручную (`EmbeddedGame.readManifest()` возвращает null, `MainActivity.unpackEmbeddedGameIfNeeded()` просто ничего не делает). Эту сборку можно безопасно показывать/распространять публично — проприетарных файлов внутри нет.

## Диагностика крашей через GitHub Issue — осознанно НЕ сделано

Рассматривался перенос механизма из `C:\dev\nfsu1-recompiled` (`android/app/.../Diagnostics.java`): сбор logcat через `ProcessBuilder`, детект краша через `ApplicationExitInfo` (API 30+), упаковка в ZIP в `Download/<app>` через MediaStore, открытие `github.com/.../issues/new?title=&body=` через `ACTION_VIEW` с обрезкой тела под ~7.5 КБ — без какого-либо GitHub-токена в приложении (пользователь сам дополняет issue и прикладывает ZIP вручную браузером/файловым менеджером).

Отдельно обсуждался вариант с созданием issue через GitHub REST API — потребовал бы токен с правом `issues:write`, зашитый в публичный APK, что при декомпиляции даёт любому желающему возможность спамить issues в репозитории. Владелец репозитория отменил эту затею целиком: **токен заводить не нужно, функция диагностики не нужна**, пока явно не попросят снова. Если попросят — вариант без токена (как у NFSU1, через `ACTION_VIEW`) безопаснее, чем REST API с токеном.

## Идеи на будущее

- Проверить на устройстве: распаковку, кодировку, ролики, производительность.
- Удалять `assets/morrowind` из памяти после распаковки нельзя (assets только для чтения), поэтому место занято дважды. Альтернатива — отдельный OBB или Play Asset Delivery.
- Перенести ps1-патчи в `buildscripts/patches/openmw051-final`, чтобы `build.sh` давал эталонную `libopenmw.so` без чужого бинаря.
