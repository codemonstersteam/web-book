---
title: "Серверные агенты: от тикета до Pull Request — оркестратор, харнесы, скиллы"
date: 2026-10-09
authors:
  - gardener
slug: ai-server-agents
description: >-
  Архитектура серверного агента-оркестратора для доработки Java-приложений по
  стандарту организации: гибрид workflows и autonomous agents, LangGraph как
  слой оркестрации, харнесы DeepSeek Harness и OpenHands SDK как слой
  исполнения, скиллы и progressive disclosure для стандартов. Future-proofing:
  provider-agnostic адаптер, evals в пайплайне, context engineering по CAFE(S).
  В конце — чеклист внедрения и полный список источников.
categories:
  - ai
  - architecture
  - process
---

# Серверные агенты: от тикета до Pull Request

Тикет в Jira переходит в статус «в работе» — и его подхватывает не человек. Серверный агент читает
требования, задаёт уточняющие вопросы постановщику, дорабатывает кодовую базу по стандарту
организации, гонит сборку и тесты в песочнице и открывает Pull Request с отчётом. Разработчик
приходит не писать, а ревьюить готовый дифф.

Парадигма разработки смещается от генераторов кода к автономным агентным системам: агент сам
анализирует требования, планирует архитектуру, пишет код, запускает тесты и открывает PR. Разберём,
как спроектировать такого агента для автоматизации доработок Java-приложений, какие инструменты
взять для слоёв оркестрации и исполнения — и как защититься от быстрого устаревания LLM.

<!-- more -->

## Зачем нужен оркестратор

Современные агентные системы вышли за пределы чат-ботов. По определению MIT Sloan, **Agentic AI** —
это системы, способные воспринимать среду, рассуждать и автономно выполнять многошаговые задачи для
достижения цели ([MIT Sloan](https://mitsloan.mit.edu/ideas-made-to-matter/agentic-ai-explained)).

В контексте разработки ПО это серверный агент, который берёт тикет из Jira/GitHub, анализирует его,
дорабатывает кодовую базу по стандартам организации и открывает PR. Масштаб явления показывает
исследование Microsoft Research по 3,2 млн следов GitHub Copilot: **87% вызовов LLM в production
инициируют сами агенты, а не разработчики**
([Microsoft Research](https://www.microsoft.com/en-us/research/publication/agentic-coding-in-the-wild-characterizing-github-copilot-traces-at-production-scale/)).
Когда почти весь трафик к модели порождает машина, архитектура оркестрации становится критически
важным слоем — качеством чат-интерфейса результат уже не вытянуть.

Каноническая статья Anthropic *«Building Effective Agents»* разделяет агентные системы на два типа:
**workflows** — предопределённые графы вызовов, и **agents** — автономные циклы, где модель сама
выбирает инструменты ([Anthropic](https://www.anthropic.com/engineering/building-effective-agents)).
Для задачи строгого следования стандартам организации оптимален гибрид: детерминированный workflow
для гейтов (анализ требований, ревью) и автономные агенты для фазы исполнения (написание кода).

## Архитектура: оркестратор и слой исполнения

Для Java-разработки система целесообразно делится на два слоя: **оркестратор** — контроль доменной
логики и гейтов, и **execution layer** — исполнение кода и тестов.

```
Тикет GitHub/Jira
      │ webhook
      ▼
Анализ требований ──(недостаточно)──► Запрос уточнения человеку
      │ (достаточно)
      ▼
Маршрутизация сложности
      │
      ├─(простая)──► Single-agent ──┐
      │                             ├──► Сборка Maven + JUnit в Sandbox
      └─(сложная)──► Рой агентов ───┘           │
                                     (OK) ──────► PR + Отчёт
                                     (Fail) ────► Fix-loop ──► повторная сборка
```

### Слой оркестратора: LangGraph

Для управления графом состояний и точками human-in-the-loop стандартом де-факто стал
**LangGraph**. Команда LangChain определяет его как агентный *рантайм*, дающий примитивы для
создания типизированного состояния, узлов-функций и условных переходов
([LangChain blog](https://www.langchain.com/blog/deep-agents-vs-langchain-vs-langgraph)).

В отличие от простых цепочек, LangGraph позволяет реализовать:

1. **Interrupts** — пауза выполнения для подтверждения требований человеком.
2. **Checkpointers** — сохранение состояния между шагами (полезно при долгих сборках).
3. **Subgraphs** — изоляция логики роя агентов (что такое субагенты и когда команда лучше одного —
   разбирали [в прошлой
   статье](https://codemonsters.team/blog/2026/07/12/subagents-orchestration/)).

### Слой исполнения: харнесы

Написать надёжный цикл агента (loop), context management и sandbox с нуля сложно. Здесь приходят на
помощь **харнесы** — предопределённые инфраструктурные обёртки вокруг LLM.

**DeepSeek Harness (dsh)** — open-source харнес с архитектурой «всё есть плагин»
([GitHub](https://github.com/deepseek-ai/deepseek-harness)). Предоставляет:

- `ctx.subagents` — встроенный механизм делегирования задач дочерним агентам, включая режим swarm
  «leader-follower» ([документация](https://deepseek-harness.github.io/deepseek-harness/));
- `harness-github` — плагин с 18 инструментами для работы с GitHub: PR, issue, CI;
- `LlmAdapter` — провайдер-нейтральный слой для моментальной замены DeepSeek V4 на Qwen или Claude.

**OpenHands Software Agent SDK** — production-ready SDK от академического комьюнити (MLSys 2026),
специально заточенный под Software Engineering
([GitHub](https://github.com/OpenHands/software-agent-sdk)). Включает нативный Docker/Kubernetes
sandbox, автоматизации для триггеров от GitHub/Jira и встроенную систему сжатия контекста.

## Скиллы: стандарт организации в контексте агента

Чтобы агент следовал стандартам организации, используется паттерн **Progressive Disclosure**
(прогрессивное раскрытие). Вместо того чтобы грузить весь стандарт кодирования в контекст LLM,
используются **Skills** — директории с файлами `SKILL.md`, содержащие frontmatter (метаданные) и
инструкции.

Для Java-разработки целесообразно создать следующие скиллы:

1. **Java/Spring Boot Architect** — рекомендует архитектурный паттерн (Layered, Hexagonal, Modular
   Monolith) на основе размера задачи.
2. **DB Schema Design** — генерация DDL и миграций Flyway/Liquibase по требованиям. Существуют
   специализированные фреймворки вроде **SchemaAgent**, использующие рой агентов (дизайнер,
   инспектор, рефлексор) для генерации качественных схем БД.
3. **Testing Strategy** — генерация JUnit-тестов с использованием Testcontainers.

Оркестратор LangGraph может вызывать tool `read_skill`, когда агент сталкивается с задачей
проектирования БД, загружая точечные инструкции в контекст.

## Future-proofing: как не стать заложником модели

LLM развиваются стремительно. Архитектура, привязанная к API одной модели (например, только Claude
или только GPT), устаревает за месяцы. Исследование MIT Technology Review подчёркивает, что
enterprise-среда для агентов должна включать надёжный слой управления контекстом и независимость от
моделей ([MIT Technology
Review](https://www.technologyreview.com/2026/07/27)).

Ключевые принципы защиты от устаревания:

1. **Provider-Agnostic Adapter.** Использование AI Gateway (например, LiteLLM или TrueFoundry),
   который ставится перед всеми агентами и маршрутизирует запросы на любой OpenAI-совместимый
   эндпоинт.
2. **Evals как часть пайплайна.** Перед обновлением модели агент должен прогоняться через набор
   регрессионных тестов (например, с использованием Kitaru или BenchFlow), чтобы убедиться, что
   качество кода не упало ([VentureBeat](https://venturebeat.com/orchestration/ai-coding-agents-are-blowing-through-budgets-replit-kilo-code-and-symbotic-explain-how-theyre-managing-it)).
3. **Context Engineering.** Согласно исследованию ACM Queue (фреймворк CAFE(S)), главная причина
   падения качества агентов — не «глупость» модели, а нечёткий, устаревший или неполный контекст
   ([ACM Queue](https://queue.acm.org)). Инвестиции в context engineering окупаются больше, чем
   смена LLM.

## Практический чеклист внедрения

1. **Инфраструктура.** Поднять LangGraph + LangSmith (observability). Настроить AI Gateway.
2. **Оркестратор.** Определить `TaskState`. Реализовать узел парсинга тикета и узел
   `analyze_requirements` с interrupt.
3. **Execution.** Интегрировать OpenHands SDK (для production-стабильности) или DeepSeek Harness
   (если нужен быстрый старт с плагинами). Настроить Docker-сандбокс для Maven/JUnit.
4. **Скиллы.** Создать директорию `skills/java-architect/SKILL.md`.
5. **Интеграции.** Настроить webhook GitHub → LangGraph и автоматическое создание PR через
   `harness-github` или OpenHands automation.

---

**Итог.** Серверный агент — это не «модель поумнее», а система из трёх слоёв: детерминированный
оркестратор для гейтов, зрелый харнес для цикла исполнения и скиллы, доставляющие стандарт
организации в контекст точечно. Гибрид workflows и agents даёт предсказуемость там, где она нужна, и
автономность там, где она окупается. Provider-agnostic адаптер и evals в пайплайне защищают от смены
модельного ландшафта, а context engineering определяет качество агента больше, чем выбор конкретной
LLM.

## Источники {#sources}

Полный список документов, использованных в статье, сгруппированный по типу. Помечены `[перв.]` —
первоисточник (научная публикация, официальная документация или инженерный блог вендора), `[втор.]` —
аналитика отраслевого издания, `[блог]` — сторонний блог или агрегатор.

### Научные публикации и исследования

- `[перв.]` [SWE-agent: Agent-Computer Interfaces Enable Automated Software Engineering (NeurIPS
  2024)](https://proceedings.neurips.cc/paper_files/swe-agent) — базовый референс по проектированию
  интерфейсов агентов.
- `[перв.]` [Agentic Coding in the Wild: Characterizing GitHub Copilot Traces (Microsoft Research,
  2026)](https://www.microsoft.com/en-us/research/publication/agentic-coding-in-the-wild-characterizing-github-copilot-traces-at-production-scale/) —
  масштабное исследование поведения агентов в production.
- `[перв.]` [ACM Queue: CAFE(S) Framework](https://queue.acm.org) — фреймворк из 5 измерений для
  диагностики контекста AI-агентов.
- `[перв.]` [The OpenHands Software Agent SDK (Semantic
  Scholar)](https://www.semanticscholar.org/paper/the-openhands-software-agent-sdk) — архитектура
  event-sourced агента.

### Отраслевые издания

- `[втор.]` [MIT Sloan: Agentic AI, explained
  (2026)](https://mitsloan.mit.edu/ideas-made-to-matter/agentic-ai-explained) — что такое агенты и
  чем они отличаются от LLM.
- `[втор.]` [MIT Technology Review: Building the enterprise environment for agentic AI (июль
  2026)](https://www.technologyreview.com/2026/07/27) — требования к enterprise-среде для агентов.
- `[блог]` [VentureBeat: AI coding agents are blowing through budgets (август
  2026)](https://venturebeat.com/orchestration/ai-coding-agents-are-blowing-through-budgets-replit-kilo-code-and-symbotic-explain-how-theyre-managing-it) —
  реальный опыт управления cost-эффективностью агентов.
- `[блог]` [InfoQ: Stack Overflow for Agents](https://www.infoq.com/news/2026/06/stack-overflow-for-agents) —
  создание баз знаний для агентов.
- `[блог]` [The New Stack: Choosing Your AI Orchestration Stack for
  2026](https://thenewstack.io/choosing-your-ai-orchestration-stack-for-2026) — обзор стека
  оркестрации.

### Инженерные блоги и первоисточники

- `[перв.]` [Anthropic: Building Effective AI
  Agents](https://www.anthropic.com/engineering/building-effective-agents) — каноническая статья о
  паттернах agents vs workflows.
- `[перв.]` [Anthropic: Effective Context Engineering for AI
  Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — техники
  работы с контекстом (just-in-time loading).
- `[перв.]` [LangChain: Deep Agents vs LangChain vs
  LangGraph](https://www.langchain.com/blog/deep-agents-vs-langchain-vs-langgraph) — разница между
  рантаймом, фреймворком и харнесом.
- `[перв.]` [GitHub Blog: Continuous AI in
  practice](https://github.blog/AI%20&%20ML/Generative%20AI) — концепция Continuous AI в репозитории.

### Официальные репозитории и документация

- `[перв.]` [DeepSeek Harness (GitHub)](https://github.com/deepseek-ai/deepseek-harness) — репозиторий
  харнеса.
- `[перв.]` [DeepSeek Harness
  Docs](https://deepseek-harness.github.io/deepseek-harness/) — архитектура Cordis, плагины,
  subagents.
- `[перв.]` [OpenHands Software Agent SDK
  (GitHub)](https://github.com/OpenHands/software-agent-sdk) — SDK и Agent Server.
- `[перв.]` [OpenHands Docs](https://docs.openhands.dev/) — документация по компонентам Agent Canvas,
  SDK и Sandbox.
