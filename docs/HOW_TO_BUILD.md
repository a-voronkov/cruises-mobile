# How to Build - Quick Guide

## 🚀 Запуск CI/CD сборки

CI/CD workflow запускается **только вручную** через GitHub Actions.

### Способ 1: Через GitHub UI (рекомендуется)

1. Откройте репозиторий на GitHub
2. Перейдите во вкладку **Actions**
3. Выберите workflow **"Build and Release"** в левом меню
4. Нажмите кнопку **"Run workflow"** (справа вверху)
5. В выпадающем меню выберите branch:
   - `main` - для production релиза
   - `develop` - для development релиза
   - `feature/...` - для тестирования feature branch
6. Нажмите зелёную кнопку **"Run workflow"**

### Способ 2: Через GitHub CLI

```bash
# Установите GitHub CLI (если ещё не установлен)
# https://cli.github.com/

# Запуск на main branch
gh workflow run build.yml --ref main

# Запуск на develop branch
gh workflow run build.yml --ref develop

# Запуск на feature branch
gh workflow run build.yml --ref feature/my-feature

# Посмотреть статус последнего запуска
gh run list --workflow=build.yml --limit 5

# Посмотреть логи конкретного запуска
gh run view <run-id> --log
```

### Способ 3: Через REST API

```bash
# Получите Personal Access Token на GitHub
# Settings → Developer settings → Personal access tokens

# Запуск workflow
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer YOUR_GITHUB_TOKEN" \
  https://api.github.com/repos/OWNER/REPO/actions/workflows/build.yml/dispatches \
  -d '{"ref":"main"}'
```

## 📦 Что происходит при запуске

### Первая сборка (без кешей)

```
1. Setup Job (~5 мин)
   ├─ Install Flutter SDK
   ├─ Install Pub dependencies
   ├─ Run code generation
   ├─ Run tests & analyze
   └─ Upload generated code

2. Build Android (~10 мин, параллельно с iOS)
   ├─ Restore caches
   ├─ Build llama.cpp for Android (~7 мин)
   └─ Build APK + AAB (~2 мин)

3. Build iOS (~15 мин, параллельно с Android)
   ├─ Restore caches
   ├─ Build llama.cpp for iOS (~10 мин)
   └─ Build IPA (~3 мин)

4. Create Release (~1 мин)
   ├─ Download all artifacts
   └─ Create GitHub release

Total: ~31 мин
```

### Последующие сборки (с кешами)

```
1. Setup Job (~2 мин)
   ├─ Restore all caches ✅
   ├─ Run tests & analyze
   └─ Upload generated code

2. Build Android (~3 мин, параллельно)
   ├─ Restore caches ✅
   ├─ Restore llama.cpp ✅
   └─ Build APK + AAB

3. Build iOS (~4 мин, параллельно)
   ├─ Restore caches ✅
   ├─ Restore llama.cpp ✅
   └─ Build IPA

4. Create Release (~1 мин)

Total: ~10 мин (68% экономия!)
```

## 📥 Получение артефактов

### Через GitHub UI

1. Перейдите в **Actions** → выберите завершённый workflow run
2. Прокрутите вниз до секции **"Artifacts"**
3. Скачайте нужные файлы:
   - `android-apk` - APK файл для прямой установки
   - `android-aab` - AAB файл для Google Play Store
   - `ios-build` - iOS build (требует подписи)

### Через GitHub Release

1. Перейдите в **Releases** (на главной странице репозитория)
2. Найдите нужный релиз (например, `v123`)
3. Скачайте файлы из секции **Assets**:
   - `app-release.apk`
   - `app-release.aab`

### Через GitHub CLI

```bash
# Список последних релизов
gh release list

# Скачать артефакты последнего релиза
gh release download

# Скачать конкретный релиз
gh release download v123

# Скачать только APK
gh release download v123 -p "*.apk"
```

## 🔄 Обновление llama.cpp

Если нужно обновить версию llama.cpp:

```bash
# 1. Обновите версию в файле
echo "новый_commit_hash" > scripts/llama-version.txt

# 2. Закоммитьте изменения
git add scripts/llama-version.txt
git commit -m "Update llama.cpp to новый_commit_hash"
git push

# 3. Запустите workflow вручную
gh workflow run build.yml --ref main
```

При следующей сборке:
- Кеш llama.cpp будет инвалидирован
- Библиотеки пересоберутся (~28 мин)
- Новый кеш будет создан
- Следующая сборка: ~10 мин

## ⚠️ Важно

- ✅ Workflow запускается **только вручную**
- ✅ Нет автоматических сборок на push/PR
- ✅ Вы полностью контролируете, когда собирать релиз
- ✅ Можно собрать любую ветку в любое время
- ✅ Кеши сохраняются между запусками
- ✅ Релиз создаётся автоматически после успешной сборки

## 📚 Дополнительная документация

- [CI_CD_OPTIMIZATION.md](CI_CD_OPTIMIZATION.md) - Подробное описание оптимизации
- [CI_CD.md](CI_CD.md) - Общая информация о CI/CD
- [CI_CD_LLAMA_SETUP.md](CI_CD_LLAMA_SETUP.md) - llama.cpp интеграция

