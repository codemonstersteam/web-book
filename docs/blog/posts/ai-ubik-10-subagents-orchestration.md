---
title: Субагенты и оркестрация. Когда команда агентов лучше одного — и чем это оплачено
date: 2026-07-12
authors:
  - gardener
slug: subagents-orchestration
description: "Исследование того, как устроены субагенты и workflow-оркестрация в агентном кодинге 2025–2026, с состязательной проверкой каждого факта. Как определить субагента тремя способами и почему изоляция контекста — его главное свойство. Когда multi-agent обходит одиночного агента (breadth-first research, +90.2% у Anthropic) и почему для кодинга он чаще вреден: токены объясняют ~80% разброса производительности, а команда агентов жжёт в 3–10 раз больше. Единственный устойчивый multi-agent паттерн для кода — отдельный агент-верификатор (Coordinator-Implementor-Verifier). И сравнение пяти вендоров в двух лагерях: у Anthropic Claude Code, Google ADK и opencode субагенты свои, а DeepSeek и z.ai/GLM своей оркестрации не имеют — они подключаются через Anthropic-совместимый эндпоинт и протокол самого Claude Code. Метод: deep-research harness, два прогона, ~200 агентов, верификация в три голоса. В конце — полный список источников."
categories:
  - code
  - ai
  - architecture
  - process
  - ubik
---

# Субагенты и оркестрация. Когда команда агентов лучше одного — и чем это оплачено

> *«Добавление людей на запаздывающий программный проект задерживает его ещё сильнее.»*
>
> — Фред Брукс, *Мифический человеко-месяц*

В [прошлой статье](https://codemonsters.team/blog/2026/07/11/product-landing-jtbd/) мы разбирали витрину платформы — вход для потребителя concept-уровня. А сама платформа rationaldev собирается не одним агентом, а **командой ролей**: `orchestrator` планирует, `implementer` пишет, `plan-reviewer` принимает план, `fixer` чинит, `release-health` следит за релизом. Это субагенты. И интуитивно кажется: чем больше специализированных агентов, тем лучше.

Брукс сорок лет назад объяснил, почему это не так с людьми. Оказалось — и с агентами тоже. Добавить в проект ещё одного агента — это не только ещё одна пара рук, это ещё один канал координации и ещё один счёт за токены.

Поэтому я не стал угадывать, а провёл **исследование**: как индустрия строит субагентов и оркестрацию в 2025–2026, что из этого подтверждается первоисточниками, а что — маркетинг. Прогнал deep-research harness в два захода, ~200 агентов, каждый факт прошёл состязательную проверку в три голоса (чтобы отсеять — нужно два «опровергнуть» из трёх). В статье — только то, что выжило, с честными пометками там, где не выжило.

**GL HF DD!**
<!-- more -->

---

## Что нужно заранее

- Понимание, что агент-раннер (Claude Code, opencode, codex) — это цикл «модель ↔ инструменты»
- Прочитанная [«Композиция корректности»](https://codemonsters.team/blog/2026/05/12/composition-of-correctness/) — генерация и проверка это разные работы
- Знакомство с идеей роли-агента из [харнеса rationaldev](https://github.com/codemonstersteam)

В этой главе:

- [Как устроен субагент](#subagent-mechanics)
- [Когда команда лучше одного](#when-multi)
- [Пять вендоров, два лагеря](#vendors)
- [Что это значит для харнеса](#harness)
- [Что не подтвердилось](#refuted)
- [Как это исследовано](#method)
- [Источники](#sources)

---

## Как устроен субагент {#subagent-mechanics}

Возьмём самый зрелый и подробно задокументированный стек — Anthropic Claude Code и Agent SDK. Здесь субагент определяется **тремя способами**:

- **программно** — параметром `agents` в опциях `query()`;
- **файлом** — Markdown с YAML-фронтматтером (`name`, `description`, `tools`, `model`) в `.claude/agents/`; тело Markdown становится системным промптом;
- **встроенным** general-purpose агентом через Agent tool.

Ровно так устроен и харнес rationaldev: роли лежат Markdown-файлами, фронтматтер задаёт имя и инструменты, тело — это инструкция роли.

Но определение — не главное. Главное свойство субагента — **изоляция контекста**.

Каждый субагент работает в **свежем изолированном окне**. Наружу, родителю, возвращается **только финальное сообщение**. Все промежуточные вызовы инструментов, каждый прочитанный файл, каждая строка вывода тестов — остаются внутри субагента и родителя не засоряют. Единственный канал от родителя к субагенту — строка-промпт в Agent tool. Субагент **не наследует** историю диалога родителя, результаты его инструментов и его системный промпт.

Это и есть причина, по которой субагенты вообще существуют. Не «разделение труда» ради красоты — а **защита контекстного окна**. Родитель делегирует шумную работу (перелопатить сто файлов, прогнать тесты) и получает назад один чистый вывод, не утонув в промежуточном мусоре.

Дальше — **least privilege**. Каждого субагента можно ограничить:

- `tools` — это allowlist. Но осторожно: если поле **опущено**, наследуются **ВСЕ** инструменты, а не ноль. Это задокументированный footgun — «забыл ограничить» означает «дал всё».
- `disallowedTools` — вычитает из унаследованного набора.
- на уровне агента переопределяются модель, `permissionMode`, источник памяти и уровень reasoning effort.

И наконец — **параллельность**. Несколько субагентов работают одновременно, поэтому пачка независимых подзадач завершается за время **самого медленного**, а не за сумму. Классический пример из документации: одновременно запустить style-checker, security-scanner и test-coverage. Для сотен задач документация уводит на отдельный Workflow tool — но это уже другой инструмент.

Всё это — **подтверждено первоисточниками Anthropic**, единогласно (3–0 в каждом голосовании).

---

## Когда команда лучше одного {#when-multi}

Теперь архитектура. Здесь начинается самое интересное, и здесь же — Брукс.

**Рекомендованный паттерн — orchestrator-worker.** Ведущий агент анализирует запрос и порождает специализированных воркеров, работающих независимо в параллель, каждый со своим контекстным окном. Референсная система Anthropic: Opus 4 как lead, воркеры на Sonnet 4, плюс отдельный citation-агент. 3–5 субагентов параллельно.

**Когда это выигрывает.** Multi-agent обошёл одиночного Opus 4 на **90.2%** на внутреннем research-эвале Anthropic, а параллельность срезала время исследования **до 90%**. Сила — именно в **breadth-first** задачах: когда надо разойтись веером по многим независимым направлениям одновременно. Это буквально то, что делает deep-research, которым написана эта статья.

Но вот три отрезвляющих факта, и все три — 3–0:

**Факт первый: за это платят токенами, и много.** Токены объясняют **~80%** разброса производительности. Multi-agent жжёт в **3–10 раз** больше токенов, чем одиночный агент на той же задаче (у Anthropic: агенты ~×4, multi-agent ~×15 против обычного чата). Вывод самих Anthropic, дословно из раздела «в пользу того, чтобы начинать с одного агента»: **дефолт — одиночный агент**, усложняй только когда есть доказательства, что оно того стоит.

Вот он, Брукс, в цифрах. Ещё один агент — это ещё один счёт.

**Факт второй: для кодинга multi-agent чаще вреден.** Задачи с общим контекстом и сильной взаимозависимостью — а это **большинство задач кодинга** — «не подходят для multi-agent сегодня». В коде куда меньше по-настоящему параллелизуемых кусков, чем в research. И LLM-агенты пока плохо координируются между собой в реальном времени.

**Факт третий: делить надо по контексту, а не по проблеме.** Разбивать работу на субагентов стоит **только когда контекст реально изолируется**. Деление по ролям в лоб — «один пишет фичи, другой пишет тесты, третий ревьюит» — создаёт постоянные накладные на координацию. Агент, который делает фичу, должен делать и её тесты: у него уже есть контекст, передавать его — дороже, чем переиспользовать.

Казалось бы, это приговор нашему харнесу с его `implementer`/`fixer`/`plan-reviewer`. Но нет — и вот почему.

**Единственный multi-agent паттерн, который устойчиво окупается на коде** — выделенный **агент-верификатор**, отделяющий генерацию от проверки. Один агент, который и генерирует, и сам себя проверяет, заметно хуже двух независимых. Индустриальное имя — **Coordinator-Implementor-Verifier (CIV)**: результат принимается, только если проходит верификатор, иначе возвращается имплементору.

Это ровно то различение, которое мы вывели в [«Композиции корректности»](https://codemonsters.team/blog/2026/05/12/composition-of-correctness/): проверка — это не «ещё раз посмотреть своим же взглядом», это отдельная работа с отдельным контекстом. Разделять генерацию и верификацию правильно не потому, что «так чище», а потому что один агент на обеих ролях систематически хуже.

Тут честная оговорка (у этого факта уверенность средняя, не высокая): для со-обученных унифицированных моделей, где верификация встроена в саму модель (линия ReVeal), преимущество разделения размывается. То есть это свойство **сегодняшних** моделей, а не закон природы.

---

## Пять вендоров, два лагеря {#vendors}

Второй прогон исследования я заточил под сравнение: как конкретные инструменты определяют субагентов и оркестрацию. Google ADK, opencode и DeepSeek подтвердились единогласно на первоисточниках; по z.ai/GLM верифицированных фактов собрать не удалось — ниже они помечены как **не подтверждено**.

Картина разбилась на **два лагеря**.

| Вендор | Модель субагентов | Оркестрация | Гибкость моделей | Данные |
| --- | --- | --- | --- | --- |
| Anthropic Claude Code | 3 способа: программно / MD / встроенный | orchestrator-worker + Workflow tool | override модели на агента | подтверждено |
| Google ADK | иерархия через список `sub_agents` | **детерминированные** Sequential / Parallel / Loop | любые Gemini + LiteLLM | подтверждено |
| opencode | primary vs subagent | primary вызывает subagent (`@mention`/авто) | **model-agnostic** на агента | подтверждено |
| DeepSeek | нет своей — через Claude Code | нет нативной | маппинг `claude-*` → `deepseek-*` | подтверждено |
| z.ai / GLM | нет своей — через Claude Code | нет нативной | маппинг `claude-*` → `glm-*` | не подтверждено |

### Лагерь первый: у кого субагенты свои

**Google ADK — самый явный и зрелый.** Три встроенных **детерминированных** workflow-примитива, управляемых кодом, а не моделью:

- `SequentialAgent` — гоняет суб-агентов по порядку;
- `ParallelAgent` — конкурентно;
- `LoopAgent` — повторяет до `max_iterations` или события `escalate=True`.

Важнее всего — **семантика состояния**. `SequentialAgent` передаёт **один и тот же** `InvocationContext` всем — общий session state, данные легко текут от шага к шагу. А `ParallelAgent` запускает каждого в **изолированной ветке** без автоматического обмена — кросс-агентная связь только явно, через `output_key` в session state. Иерархия строится списком `sub_agents=[...]`; один экземпляр можно добавить субагентом только раз (иначе `ValueError`). Взаимодействие — тремя механизмами: общий state, LLM-делегирование через `transfer_to_agent()` (роутинг по полю `description`), и `AgentTool` (агент, обёрнутый в инструмент).

Если вам нужен **детерминированный пайплайн** с гарантиями порядка и состояния — из коробки это умеет только ADK.

**opencode — лёгкая model-agnostic таксономия.** Различает **primary** (переключаются через Tab) и **subagent** (вызываются автоматически или через `@mention`). Из коробки: primary — `Build` (все инструменты) и `Plan` (read-only, edits/bash на «спросить»); subagent — `General`, `Explore` (read-only по коду) и `Scout` (read-only по внешним докам). Конфиг — через `opencode.json` или Markdown+YAML в `~/.config/opencode/agents/`, где имя файла становится именем агента (`review.md` → агент «review»). Model-agnostic на уровне агента: субагент без явной модели наследует модель вызвавшего его primary.

### Лагерь второй: у кого субагентов нет — но они есть

Вот где неожиданно.

**DeepSeek своей оркестрации не имеет вообще.** Есть OpenAI-совместимый tool calling (модель, что важно, **не исполняет** функции — она возвращает вызов, исполняет вызывающий; с версии V3.2 — вызов инструментов даже внутри режима размышления). Но субагенты у DeepSeek появляются через **Anthropic-совместимый эндпоинт** `api.deepseek.com/anthropic`: он маппит имена моделей Claude на модели DeepSeek (`claude-opus` → `deepseek-v4-pro`, `claude-haiku/sonnet` → `deepseek-v4-flash`) и — ключевое — уважает переменную `CLAUDE_CODE_SUBAGENT_MODEL`, чтобы гнать субагентов на отдельную дешёвую модель. То есть протокол субагентов — это фича **Claude Code**, которую DeepSeek поддерживает, а не изобретение DeepSeek.

**z.ai / GLM — та же история** (не подтверждено, из первичной документации и wrapper-репозиториев): Claude Code направляется на z.ai через `ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic` плюс ключ z.ai. GLM Coding Plan по умолчанию использует `GLM-4.7`. Сторонний wrapper даёт ключ `subagentModel` (по умолчанию `GLM-4.6`). Собственного механизма субагентов документация z.ai **не описывает**.

**Вывод по лагерю два — де-факто общий протокол.** DeepSeek, GLM/Zhipu, Qwen, MiniMax, Kimi/Moonshot — все подключаются к субагентам одним и тем же приёмом: подменяют `ANTHROPIC_BASE_URL` и `ANTHROPIC_AUTH_TOKEN` на Anthropic-совместимый эндпоинт. **Протоколом субагентов владеет Claude Code.** Китайские вендоры дают только модель за совместимым API — дешёвую и часто открытую, но без своей оркестрации.

И тут же скрытая стоимость (не подтверждено, blog-оценки): дешёвые открытые модели требуют больше итераций QA — Sonnet ~×1 цикл, GLM-5 ~×3, MiniMax ещё больше. Экономия на токене частично съедается лишними циклами верификации. Что, кстати, ещё раз подсвечивает ценность отдельного агента-верификатора.

---

## Что это значит для харнеса {#harness}

Свести к четырём правилам.

- **Дефолт — одиночный агент.** Не заводи субагента, пока не докажешь, что контекст реально изолируется. Токены — не бесплатны, Брукс не отменён.
- **Верификатор — отдельным агентом.** Это единственный multi-agent паттерн, устойчиво окупающийся на коде. У нас это `plan-reviewer` и `fixer`, отделённые от `implementer`. Мы, получается, интуитивно уже стоим на правильном паттерне.
- **Дели по контексту, не по ролям в лоб.** Агент, делающий фичу, пусть делает и её тесты. Не размазывай один контекст по трём агентам, каждый из которых будет его перечитывать.
- **Нужен детерминированный пайплайн** (гарантии порядка и состояния между шагами)? — из коробки это Google ADK. Нужна свобода моделей при сохранении субагентов? — DeepSeek/GLM через совместимый эндпоинт дадут дешёвую модель, но протокол останется Claude Code.

Красивое совпадение: харнес rationaldev с его `orchestrator` + `implementer` + `fixer` + `plan-reviewer` — это и есть CIV-поток, где генерация отделена от верификации. Не потому что мы прочитали исследование, а потому что то же самое различение мы вывели из корректности по построению. Индустрия пришла к нему с другой стороны.

---

## Что не подтвердилось {#refuted}

Честность метода — в том числе в том, что он **убивает** красивые, но ложные факты. Два утверждения получили 0–3 и вылетели:

- **«Есть шесть канонических production-паттернов оркестрации»** (orchestrator-worker, pipeline, fan-out/fan-in, debate, dynamic handoff, adaptive planning). Источник — маркетинговый блог, проверку не прошёл.
- **«Одиночный агент обходит multi-agent на 64% задач при равных ресурсах, по Princeton NLP»**. Атрибуция к Princeton NLP не подтвердилась.

И крупный **пробел**: по z.ai/GLM своих, нативных агентных возможностей (сверх совместимости с Claude Code) верифицированных данных собрать не удалось. Так что по этому вендору — только «не подтверждено».

---

## Как это исследовано {#method}

Чтобы не было магии — вот метод, тот же, что для корректности кода: не угадывать, а проверять.

Deep-research harness, **два прогона**:

1. Вопрос декомпозируется на поисковые углы (3 в первом прогоне, 5 во втором).
2. По каждому углу — параллельный веб-поиск.
3. Дедупликация URL, загрузка первоисточников, извлечение **проверяемых** утверждений (falsifiable claims) с цитатой-подтверждением.
4. **Состязательная верификация**: каждое утверждение проверяют три независимых скептика, которым велено его **опровергнуть**. Чтобы факт выжил, нужно не больше одного «опровергнуть» из трёх.
5. Синтез: слияние семантических дублей, ранжирование по уверенности.

Суммарно: ~15 + 23 источника, 159 извлечённых утверждений, 50 проверенных, **48 подтверждено, 2 опровергнуто**, ~200 агентов, ~3.3M токенов. Данные — 2025–2026.

Оговорка на честность: количественные заголовочные цифры (+90.2%, ×90 время, ~×15 токенов, ~80% разброса) — это **внутренние self-reported эвалы Anthropic на research-задачах**, а не независимые бенчмарки, и на кодинг они могут не переноситься. И API-поверхности версионируются — имена моделей DeepSeek/GLM, поля `AgentDefinition`, эндпоинты меняются между релизами.

---

## Замыкание {#closing}

Брукс писал про людей, но закон оказался про координацию как таковую — неважно, из чего собрана команда. Добавить агента — значит добавить канал координации и счёт за токены. Поэтому multi-agent — не «лучше по умолчанию», а инструмент под узкий класс задач: широкий параллельный поиск, где контекст естественно распадается на независимые куски.

Для кодинга из всего зоопарка паттернов устойчиво окупается ровно один — отделить того, кто пишет, от того, кто проверяет. Ровно к этому мы пришли и со стороны корректности. Приятно, когда две дороги сходятся в одной точке.

А протоколом субагентов, как выяснилось, сегодня фактически владеет Claude Code — и половина мира, включая китайских вендоров, просто подключает к нему свои модели через совместимый эндпоинт. Это и рычаг, и предупреждение: стоя на этом протоколе, стоит понимать, чей он.

**GG!**

---

## Источники {#sources}

Полный список документов, использованных в исследовании, сгруппированный по надёжности. Помечены `[перв.]` — первоисточник (официальная документация/инженерный блог вендора), `[втор.]` — вторичный разбор, `[блог]` — сторонний блог/агрегатор, `[ненад.]` — источник признан ненадёжным (данные не использованы).

### Anthropic — субагенты, Agent SDK, оркестрация

- `[перв.]` [Subagents in the SDK — Claude Code Docs](https://code.claude.com/docs/en/agent-sdk/subagents)
- `[перв.]` [Subagents — Claude Code Docs](https://code.claude.com/docs/en/sub-agents)
- `[перв.]` [Subagents — docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code/sub-agents)
- `[перв.]` [How we built our multi-agent research system — Anthropic Engineering](https://www.anthropic.com/engineering/multi-agent-research-system)
- `[перв.]` [Building multi-agent systems: when and how to use them — Claude blog](https://claude.com/blog/building-multi-agent-systems-when-and-how-to-use-them)
- `[втор.]` [How Anthropic built a multi-agent research system — ByteByteGo](https://blog.bytebytego.com/p/how-anthropic-built-a-multi-agent)

### Google — Agent Development Kit (ADK)

- `[перв.]` [Sequential agents — ADK Docs](https://google.github.io/adk-docs/agents/workflow-agents/sequential-agents/)
- `[перв.]` [Parallel agents — ADK Docs](https://google.github.io/adk-docs/agents/workflow-agents/parallel-agents/)
- `[перв.]` [Custom agents — ADK Docs](https://google.github.io/adk-docs/agents/custom-agents/)
- `[перв.]` [Agent Development Kit: easy to build multi-agent applications — Google Developers Blog](https://developers.googleblog.com/en/agent-development-kit-easy-to-build-multi-agent-applications/)

### opencode

- `[перв.]` [Agents — opencode Docs](https://opencode.ai/docs/agents/)
- `[перв.]` [opencode agents (mirror) — mudrii/opencode-docs](https://github.com/mudrii/opencode-docs/blob/main/docs/official/agents.md)
- `[втор.]` [Agent system — DeepWiki sst/opencode](https://deepwiki.com/sst/opencode/3.2-agent-system)
- `[втор.]` [Agents — open-code.ai](https://open-code.ai/en/docs/agents)
- `[блог]` [Coding agents internals: opencode deep dive — cefboud](https://cefboud.com/posts/coding-agents-internals-opencode-deepdive/)
- `[блог]` [opencode agent orchestration and subagent-driven development — adurrr](https://adurrr.github.io/en/p/opencode-agent-orchestration-and-subagent-driven-development-a-complete-guide/)

### DeepSeek

- `[перв.]` [Tool calling — DeepSeek API Docs](https://api-docs.deepseek.com/guides/tool_calls/)
- `[перв.]` [Anthropic API compatibility — DeepSeek API Docs](https://api-docs.deepseek.com/guides/anthropic_api/)
- `[перв.]` [Claude Code integration — DeepSeek API Docs](https://api-docs.deepseek.com/quick_start/agent_integrations/claude_code/)
- `[перв.]` [Coding agents — DeepSeek API Docs](https://api-docs.deepseek.com/guides/coding_agents/)
- `[перв.]` [Release news 2025-12-01 — DeepSeek API Docs](https://api-docs.deepseek.com/news/news251201/)
- `[перв.]` [DeepSeek API Docs (index)](https://api-docs.deepseek.com/)

### z.ai / Zhipu GLM (не подтверждено верификацией)

- `[перв.]` [Develop tools · Claude — z.ai Docs](https://docs.z.ai/scenario-example/develop-tools/claude)
- `[блог]` [z.ai-powered-claude-code — geoh](https://github.com/geoh/z.ai-powered-claude-code)
- `[ненад.]` [z.ai subscribe](https://z.ai/subscribe)

### Паттерны, теория и сравнения (сторонние)

- `[блог]` [Claude Code subagents and orchestration guide — hidekazu-konishi](https://hidekazu-konishi.com/entry/claude_code_subagents_and_orchestration_guide.html)
- `[блог]` [Multi-agent orchestration patterns — Prateek Sharma](https://www.prateek-sharma.com/blog/multi-agent-orchestration-patterns/)
- `[блог]` [Orchestrate autonomous sub-agents without blowing your context window — dev.to](https://dev.to/programmingcentral/how-to-orchestrate-autonomous-sub-agents-without-blowing-your-llm-context-window-jpo)
- `[блог]` [Multi-agent orchestration patterns — glukhov.org](https://www.glukhov.org/ai-systems/architecture/multi-agent-orchestration-patterns)
- `[блог]` [cc-compatible-models — Alorse](https://github.com/Alorse/cc-compatible-models)
- `[блог]` [GLM vs Claude — codingplan.run](https://codingplan.run/compare/glm-vs-claude)
- `[блог]` [DeepSeek V4 vs GPT-5.5 vs Claude Opus vs GLM — flowtivity.ai](https://flowtivity.ai/blog/deepseek-v4-vs-gpt-5-5-vs-claude-opus-vs-glm-cost-benchmarks/)
- `[блог]` [Claude Code vs opencode: a CTO decision — inetanel](https://inetanel.com/articles/claude-code-vs-opencode-cto-decision)
- `[блог]` [GLM-5.2 vs DeepSeek V4 coding 2026 — codersera](https://codersera.com/blog/glm-5-2-vs-deepseek-v4-coding-2026/)
- `[блог]` [GLM-5.2 vs DeepSeek V4 vs Qwen3 open-weights coding showdown — developersdigest](https://www.developersdigest.tech/blog/glm-5-2-vs-deepseek-v4-vs-qwen3-open-weights-coding-showdown)
- `[ненад.]` [Multi-agent orchestration patterns in production — beam.ai](https://beam.ai/agentic-insights/multi-agent-orchestration-patterns-production) — источник двух опровергнутых утверждений
- `[ненад.]` [Best AI coding agent — morphllm](https://www.morphllm.com/ai-coding-agent)
- `[ненад.]` [AI coding costs — morphllm](https://www.morphllm.com/ai-coding-costs)
- `[ненад.]` [AI agent framework — morphllm](https://www.morphllm.com/ai-agent-framework)
