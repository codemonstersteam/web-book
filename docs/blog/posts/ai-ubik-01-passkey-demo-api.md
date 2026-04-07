---
title: Passkey Demo API — собираем сервис авторизации с ИИ-агентом | API First
date: 2026-03-23
authors:
  - gardener
slug: ai-passkey-demo-api
description: "Пошаговый разбор — как построить Go-сервис авторизации без паролей вместе с ИИ-агентом: от пустой папки до OpenAPI-спеки."
categories:
  - code
  - ai
  - go
  - webauthn
  - api
  - ubik
---

# Passkey Demo API — собираем сервис авторизации с ИИ-агентом | API First

Это разбор процесса: какие промпты писать агенту, какие решения принимать, почему именно так. Не туториал «скопируй и запусти» — а маршрут, который можно пройти самому.

Репозиторий с результатом: [passkey-demo-api](https://github.com/ubik-life/passkey-demo-api)

<!-- more -->

---

## Что нужно заранее

- **Git** — [git-scm.com](https://git-scm.com)
- **Аккаунт на GitHub**
- **Node.js 18+** — [nodejs.org](https://nodejs.org) (нужен для установки Claude Code)
- **VS Code** — [code.visualstudio.com](https://code.visualstudio.com)
- **Claude Code** — AI-агент в терминале

### Установка VS Code

1. Скачай и установи [VS Code](https://code.visualstudio.com)
2. Открой VS Code → Extensions (`Ctrl+Shift+X` / `Cmd+Shift+X`)
3. Найди **Claude Code** и установи плагин

![Claude Code extension in VS Code](https://anthropic.gallerycdn.vsassets.io/extensions/anthropic/claude-code/2.1.81/1774045589184/Microsoft.VisualStudio.Services.Icons.Default){ width=80 }

### Установка Claude Code

В терминале:

```bash
npm install -g @anthropic-ai/claude-code
```

Проверь:

```bash
claude --version
```

### Как открыть терминал в VS Code

Открой папку проекта в VS Code (`File → Open Folder`) и нажми:

| ОС | Сочетание клавиш |
|----|-----------------|
| Mac | `` Ctrl+` `` |
| Windows | `` Ctrl+` `` |

Или через меню: `Terminal → New Terminal`.

Терминал откроется внизу прямо в папке проекта. Все команды из этой инструкции выполняй там.

---

## Что получим по итогу сессии

```
my-service/
├── AGENTS.md                    ← контракт с агентом
├── CLAUDE.md                    ← живой журнал сессии
├── README.md                    ← описание сервиса
├── backlog.md                   ← план работы
├── api-specification/
│   └── openapi.yaml             ← OpenAPI 3.1 спека
└── devlog/
    ├── 00-intent.md             ← намерение
    └── 01-api-contract.md       ← лог шага 1
```

На ветке `feat/gherkin` — готово к следующей сессии (компонентные тесты).

---

## Часть 1 — Подготовка (клонируем шаблон)

Все стартовые файлы уже готовы в шаблоне — не нужно ничего копировать вручную.

### 1. Создать репозиторий на GitHub

Зайди на [github.com/new](https://github.com/new) и создай пустой репозиторий.

Назови его, например, `my-service`. После создания GitHub покажет страницу с адресом репозитория — скопируй SSH-адрес, он выглядит так:

```
git@github.com:your-username/my-service.git
```

### 2. Клонировать шаблон и подключить свой репозиторий

```bash
git clone git@github.com:ubik-life/service-template.git my-service
cd my-service
git remote set-url origin git@github.com:your-username/my-service.git
git push -u origin main
```

Замени `your-username/my-service` на адрес, который скопировал на шаге выше.

В папке уже лежат: `AGENTS.md`, `CLAUDE.md`, `backlog.md`, `devlog/00-intent.md`.

### 3. Заполнить devlog/00-intent.md

Открой файл — там TODO-комментарии. Замени их на описание своего сервиса.

<details>
<summary>Пример заполненного 00-intent.md (Passkey Demo API)</summary>

```markdown
# 00 — Намерение

## Что строим

**Passkey Demo API** — Go-сервер, реализующий полный цикл авторизации без паролей.

Стек: Go + WebAuthn + JWT (Ed25519) + SQLite.

Это первый кирпич ноды Ubik — открытой децентрализованной платформы для распространения знаний.

## Зачем этот devlog

Фиксируем весь процесс разработки: дословные промпты, решения, альтернативы.
Цель — чтобы любой студент смог повторить путь шаг за шагом, работая с ИИ-агентом так же, как это делал автор.

## Что умеет сервис

- Регистрация пользователя по handle + биометрия
- Вход по handle + биометрия
- Выход (инвалидация сессии)
- Проверка текущей сессии

## REST API

Регистрация и вход — двухфазные: первый POST создаёт challenge и возвращает ресурс с `id`, второй завершает процесс. Термины `attestation` и `assertion` взяты напрямую из WebAuthn.

| Метод | Ресурс | Действие |
|-------|--------|----------|
| POST | /registrations | Создать challenge → 201 {id, options} |
| POST | /registrations/{id}/attestation | Завершить регистрацию → JWT |
| POST | /sessions | Создать challenge → 201 {id, options} |
| POST | /sessions/{id}/assertion | Завершить вход → JWT |
| DELETE | /sessions/current | Выход — инвалидация refresh token |
| GET | /users/me | Текущий пользователь — требует валидный access token |

### Почему не PUT

PUT по семантике HTTP означает «положи ресурс по этому адресу целиком» и должен быть идемпотентным. Завершение регистрации и входа — продолжение процесса, а не замена ресурса. POST с вложенным ресурсом (`/attestation`, `/assertion`) честнее отражает природу действия.

## Как работает WebAuthn

Все бинарные данные между браузером и сервером передаются в **base64url**.

### Регистрация

**Фаза 1** — клиент → сервер:
{ "handle": "alice" }

Сервер создаёт challenge, сохраняет сессию, возвращает 201:
{
  "id": "uuid",
  "options": {
    "challenge": "base64url",
    "rp": { "name": "Passkey Demo", "id": "localhost" },
    "user": { "id": "base64url", "name": "alice", "displayName": "alice" },
    "pubKeyCredParams": [{ "type": "public-key", "alg": -7 }],
    "timeout": 60000,
    "attestation": "none"
  }
}

**Фаза 2** — браузер вызывает navigator.credentials.create(options), аутентификатор создаёт ключевую пару. Клиент → сервер:
{
  "id": "base64url",
  "rawId": "base64url",
  "type": "public-key",
  "response": {
    "clientDataJSON": "base64url",
    "attestationObject": "base64url"
  }
}

- clientDataJSON (после decode): {"type":"webauthn.create","challenge":"...","origin":"http://localhost"}
- attestationObject — CBOR: содержит публичный ключ в COSE-формате, счётчик, rpIdHash

Сервер проверяет challenge, origin, декодирует публичный ключ и сохраняет credential. Возвращает пару JWT.

### Вход

**Фаза 1** — клиент → сервер:
{ "handle": "alice" }

Сервер находит credentials пользователя, создаёт challenge, возвращает 201:
{
  "id": "uuid",
  "options": {
    "challenge": "base64url",
    "rpId": "localhost",
    "allowCredentials": [{ "type": "public-key", "id": "base64url" }],
    "userVerification": "preferred",
    "timeout": 60000
  }
}

**Фаза 2** — браузер вызывает navigator.credentials.get(options), аутентификатор подписывает данные. Клиент → сервер:
{
  "id": "base64url",
  "rawId": "base64url",
  "type": "public-key",
  "response": {
    "clientDataJSON": "base64url",
    "authenticatorData": "base64url",
    "signature": "base64url",
    "userHandle": "base64url"
  }
}

- clientDataJSON (после decode): {"type":"webauthn.get","challenge":"...","origin":"http://localhost"}
- authenticatorData: rpIdHash + flags + counter
- signature: подпись над authenticatorData + SHA256(clientDataJSON)

Сервер проверяет: challenge совпадает, origin совпадает, подпись валидна, счётчик вырос. Возвращает пару JWT.

### JWT

Сервер возвращает два токена:
{
  "access_token": "JWT (Ed25519, TTL 15 мин)",
  "refresh_token": "opaque string (TTL 30 дней)"
}

access_token содержит claims: sub (user_id), handle, exp.
refresh_token хранится в БД, инвалидируется при выходе.

## Шаги разработки

1. 01-api-contract.md — OpenAPI-спека и README
2. 02-gherkin.md — компонентные тесты
3. 03-go-server.md — TDD-цикл: Go-сервер

## Фрейм работы с агентом

См. AGENTS.md.
```

</details>

### 4. Заполнить CLAUDE.md

Открой `CLAUDE.md` — замени плейсхолдер в разделе `## Проект` на одну строку о своём сервисе.

Было:
```
## Проект
<!-- TODO: одна строка о сервисе -->
**Название** — краткое описание. Стек: ...
```

Стало (пример для Passkey Demo API):
```
## Проект
**Passkey Demo API** — Go-сервис авторизации без паролей. Стек: Go + WebAuthn + JWT + SQLite.
```

**Почему именно так:** `CLAUDE.md` — это первое, что читает агент в начале каждой сессии. Одна строка в `## Проект` даёт ему мгновенный контекст: что за сервис, какой стек. Без этого агент не знает с чем работает и будет задавать уточняющие вопросы или делать неверные предположения.

После замены `CLAUDE.md` выглядит так:

<details>
<summary>Полный CLAUDE.md после шага 4</summary>

```markdown
# CLAUDE.md — Контекст проекта для агента

## Проект

**Passkey Demo API** — Go-сервис авторизации без паролей. Стек: Go + WebAuthn + JWT + SQLite.

## Статус модулей

| Модуль | Статус |
|--------|--------|
| intent | done |
| API-контракт | todo |
| README | todo |
| Gherkin-тесты | todo |
| Go-сервер | todo |

## Следующий шаг

Шаг 1 — OpenAPI-спека и README. Ветка: `feat/api-contract`.

## Принятые решения

- ...

## Открытые вопросы

- ...

## Сценарий первой сессии

Когда разработчик загружает этот файл и AGENTS.md — выполни по порядку без ожидания дополнительных команд:

1. Проверь существует ли `backlog.md`:
   - **Нет** → предложи создать backlog по флоу из AGENTS.md §9, затем предложи перейти к шагу 1: OpenAPI-спека и README
   - **Да** → прочитай backlog, найди первую задачу со статусом `todo` и предложи её выполнить
2. Жди подтверждения перед каждым действием

## Правила работы агента

- После завершения каждого шага обновлять `backlog.md`: переносить выполненные задачи в раздел `## Done`.
- Обновлять `README.md` если изменились API, структура репо, стек, способ запуска.

### Флоу завершения шага

```
1. git checkout -b feat/<name>
2. git add <files>
3. git commit -m "type(scope): description"
4. git push -u origin feat/<name>
5. PR → merge (делает разработчик)
6. git checkout main && git pull origin main
7. git checkout -b feat/<next-name>
```

## Фрейм работы с агентом

См. `AGENTS.md`.
```

</details>

### 5. Первый коммит

```bash
git add .
git commit -m "docs: initial intent and agent context"
git push -u origin main
```

**Результат части 1:**

```
my-service/
├── AGENTS.md        ← контракт с агентом (готов)
├── CLAUDE.md        ← живой журнал (заполнен)
├── backlog.md       ← план работы (готов)
└── devlog/
    └── 00-intent.md ← намерение (заполнено)
```

---

## Часть 2 — Работаем с агентом

### Открываем Claude Code в папке проекта

1. Открой папку `my-service` в VS Code: `File → Open Folder`
2. Открой терминал: `` Ctrl+` ``
3. Запусти агента:

```bash
claude --model claude-sonnet-4-5
```

`claude-sonnet-4-5` — оптимальный выбор для разработки: быстрее и дешевле Opus, при этом справляется со всеми задачами этого курса.

Ты увидишь интерактивный терминал агента прямо в VS Code. Все следующие строки — это промпты, которые пишешь туда.

---

### Ориентируем агента

```
загрузи CLAUDE.md
```

```
загрузи AGENTS.md
```

```
смотри на devlog/00-intent.md
```

После трёх команд агент сам проверит наличие `backlog.md` и предложит следующий шаг:

- **Если backlog не создан** — предложит создать его. Ответь **да**, затем агент предложит перейти к шагу 1. Снова ответь **да**.
- **Если backlog уже есть** — прочитает его и предложит первую незакрытую задачу. Ответь **да**.

---

### Шаг 1 — OpenAPI-спека и README

Агент создаёт `api-specification/openapi.yaml` на основе эндпоинтов из `devlog/00-intent.md` и фиксирует лог в `devlog/01-api-contract.md`.

Затем агент создаст `README.md` по структуре постановки задачи из `AGENTS.md`.

Если агент не создал README автоматически — напиши:

```
создай README с описанием сервиса, укажи что это тестовое демо и учебный MVP
```

---

### Почему двухфазные POST, а не PUT

Это решение агент принимает на основе `00-intent.md` — там оно уже зафиксировано. Но полезно понимать логику:

PUT по семантике HTTP — идемпотентная операция «положи ресурс целиком». Завершение WebAuthn-регистрации — продолжение процесса, а не замена ресурса. POST с вложенным ресурсом (`/attestation`, `/assertion`) честнее отражает природу действия.

---

### Опционально — зафиксировать лог шага

Если хочешь задокументировать что было сделано на этом шаге:

```
напиши лог создания api контракта devlog/01-api-contract.md
```

Агент создаст `devlog/01-api-contract.md` — промпты сессии, принятые решения, результат.

---

### Закрываем шаг — коммит, пуш, мерж

Скажи агенту:

```
создаем ветку, коммитим, пушим, ждем мерджа
```

Агент запросит подтверждение на создание ветки (`feat/api-contract`) и создание папки (`api-specification`). На оба запроса ответь **да**.

Агент выполнит:

```bash
git checkout -b feat/api-contract
git add api-specification/openapi.yaml devlog/01-api-contract.md backlog.md README.md
git commit -m "feat(api): add OpenAPI 3.1 specification for passkey auth"
git push -u origin feat/api-contract
```

Ты создаёшь PR на GitHub и мержишь. Затем говоришь агенту:

```
смерджил
```

Агент заберёт main и создаст ветку следующего шага:

```bash
git checkout main && git pull origin main
git checkout -b feat/gherkin
```

---

## Стоп — следующая сессия: Gherkin

Сессия завершена. Что лежит в папке:

```
my-service/
├── AGENTS.md
├── CLAUDE.md
├── README.md
├── backlog.md
├── api-specification/
│   └── openapi.yaml
└── devlog/
    ├── 00-intent.md
    └── 01-api-contract.md
```

Ветка `feat/gherkin` создана и ждёт. Следующий шаг — описать сценарии на Gherkin: регистрация, вход, выход, `/users/me`.

Продолжение: [devlog/](https://github.com/ubik-life/passkey-demo-api/tree/main/devlog)
