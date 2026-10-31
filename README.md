<div align="center">

<img width="1541" height="333" alt="image" src="https://github.com/user-attachments/assets/15a5cc0d-9210-4ce6-b8a2-09304a1b72c9" />

**OpenMW (Morrowind) для Android и ChromeOS с улучшенным управлением и шейдерами OMWFX**

![OS](https://img.shields.io/badge/up%20to-Android%2016-green)
![Architecture](https://img.shields.io/badge/architecture-64bit-orange.svg)
![ChromeOS](https://img.shields.io/badge/ChromeOS-Supported-4285F4?logo=googlechrome&logoColor=white)
![AI Assisted Coding](https://img.shields.io/badge/AI-Assisted%20Coding-white)
![Controller](https://img.shields.io/badge/Controls-Joypad/Touch/Keyb-blueviolet)

[![Join The Lair on Discord](https://img.shields.io/badge/Discord-The%20Lair-5865F2?logo=discord&logoColor=white)](https://discord.gg/AB3WVBqD5G)
[![Support via PayPal](https://img.shields.io/badge/Support%20via-PayPal-0070BA?logo=paypal&logoColor=white)](https://paypal.me/andiweli)

</div>

# OpenMW для Android и ChromeOS

## 🎮 Готовый релиз: игра уже встроена

В [релизе **v1.0.0**](https://github.com/des1roer/OpenMW-Android/releases/tag/v1.0.0) лежит APK, в который уже встроена русская версия Morrowind («Расширенное издание» от 1С: Morrowind + Tribunal + Bloodmoon). Отдельно искать и копировать игровые файлы на телефон не нужно: ставите APK, при первом запуске жмёте «Играть» — игра один раз распаковывается прямо на устройстве, и дальше лаунчер сам находит нужную папку и кодировку.

Требования: Android 5.0+, 64-битный ARM-процессор (arm64-v8a), около 2,5 ГБ свободного места (APK плюс распакованные данные).

Если вы хотите собрать такой же APK со своей копией игры сами — смотрите раздел [«Сборка со встроенной игрой»](#️-сборка-со-встроенной-игрой) и `memory.md` в корне репозитория.

## ✨ О проекте

Это **порт OpenMW для Android и ChromeOS**, позволяющий играть в The Elder Scrolls III: Morrowind. В основе лежит [проект CaveBros openmw-android](https://gitlab.com/cavebros/openmw-android/-/releases), расширенный до **OpenMW 0.51**, с дополнительными доработками под Android/ChromeOS и улучшенными шейдерами постобработки.
Это не ещё один произвольный порт, а продолжение понятного и простого интерфейса лаунчера CaveBros поверх более свежей версии движка и более современных шейдеров.

Цель — удобный, дружелюбный к геймпаду Morrowind на **Android-смартфонах, планшетах и ChromeOS**, максимально близкий к оригинальному движку OpenMW.

## ⚔️ Особенности

- ⚙️ Движок **OpenMW 0.51.0 Final**, встроенный в Android-порт
- 📱 Оптимизация под **смартфоны, планшеты, Android TV и ChromeOS**
- 🎮 Улучшенная поддержка **геймпада, сенсорного управления, клавиатуры и мыши**
- 🖥️ Расширенный лаунчер с прямым доступом к настройкам **геймплея, графики, теней, интерфейса и движка**
- 📐 Настраиваемые **разрешение, масштаб интерфейса, частота кадров и производительность**
- 🌑 Динамические **тени**, адаптированные под Android, с выбором качества и дистанции
- 🎨 Четыре набора шейдеров: **Original, Modified, Zesterer и OMWFX**
- ✨ Улучшенная постобработка **OMWFX**: WetWorld, RainLens, Godrays, Bloom и Lens Flare
- 🧩 Поддержка **модов, пользовательских файлов данных, пресетов шейдеров и флагов окружения**
- 🔧 Android-специфичные исправления **GLES2/GL4ES, постобработки и работы с глубиной**

<img width="1920" height="1080" alt="openmw0" src="https://github.com/user-attachments/assets/993327f9-ee20-466c-b1bc-ef19c0cc1d00" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/1a742936-ebb4-4199-a565-fd7ff30a30f5" />
<img width="1920" height="1080" alt="openmw1" src="https://github.com/user-attachments/assets/ace8b873-e704-45e8-b4a5-760e4994f347" />
<img width="1920" height="1080" alt="openmw2" src="https://github.com/user-attachments/assets/97bbf06b-b6d9-4fcd-8d79-bd9f36ab7db3" />
<img width="1920" height="1080" alt="openmw4" src="https://github.com/user-attachments/assets/cb9b06d6-265c-495c-ad78-f7464ac5b541" />

## 🎨 Шейдеры OMWFX

Проект включает расширенный набор шейдеров OMWFX на основе фреймворка постобработки OpenMW и коллекции [OMWFX Shaders](https://gitlab.com/vtastek/omwfx-shaders) от сообщества.

Встроенный пресет добавляет более современную картинку, оставаясь при этом опциональным, и включает собственный эффект **Lens Flare**.

## 🛠️ Сборка со встроенной игрой

Чтобы собрать APK со своей копией Morrowind (Steam, GOG или диск «Расширенного издания» от 1С), нужны только Linux или WSL2 с Docker, `curl`, `unzip`, `rsync` и `git`:

```bash
git clone git@github.com:des1roer/OpenMW-Android.git
cd OpenMW-Android/source
./tools/build-embedded-apk.sh "/путь/к/установленному/Morrowind" win1251
```

Скрипт сам соберёт Docker-образ со всеми зависимостями, поставит Android SDK, скачает нативные библиотеки движка, разложит файлы игры и соберёт подписанный release-APK в `app/build/outputs/apk/mainline/release/`.

Подробности — в файле `memory.md` в корне репозитория: откуда берутся нативные библиотеки, как устроен ключ подписи, какие грабли встречались при сборке.

## 🧩 Основа проекта

| Компонент | Источник |
|---|---|
| Android-порт | [CaveBros / openmw-android](https://gitlab.com/cavebros/openmw-android/-/releases) |
| Движок OpenMW | [OpenMW / openmw](https://github.com/OpenMW/openmw) |
| Фреймворк шейдеров | [OMWFX Shaders](https://gitlab.com/vtastek/omwfx-shaders) |

## 📦 Требования

Если вы собираете APK сами (без готового релиза с игрой), вам понадобится собственная легально приобретённая копия **The Elder Scrolls III: Morrowind**. Файлы Bethesda **не входят** в исходный код этого репозитория — только в готовую сборку релиза.

## ❤️ Поддержка

Если вам нравится проект и вы хотите поддержать автора оригинального порта, можно сделать небольшой взнос через PayPal.

Это помогает уделять больше времени поддержке существующих проектов, исправлению ошибок, улучшению совместимости и новым функциям.

[![Support via PayPal](https://img.shields.io/badge/Support%20via-PayPal-0070BA?logo=paypal\&logoColor=white)](https://paypal.me/andiweli)

[![Join The Lair on Discord](https://img.shields.io/badge/Discord-The%20Lair-5865F2?logo=discord&logoColor=white)](https://discord.gg/AB3WVBqD5G)

Спасибо за поддержку!

## 📜 Благодарности и отказ от ответственности

OpenMW — независимая реализация движка Morrowind с открытым исходным кодом. Этот Android/ChromeOS-проект построен на работе участников **OpenMW**, **CaveBros** и авторов шейдеров **OMWFX**.

Проект не аффилирован с Bethesda Softworks и не одобрен ею. **The Elder Scrolls**, **Morrowind** и связанные товарные знаки принадлежат их правообладателям.

---

<div align="center">

**OpenMW • Morrowind • Android • ChromeOS • OMWFX**

</div>
