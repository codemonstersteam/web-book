---
title: Эссенция эффективного кода
description: Эссенция правил и лучших практик кодописи
js: [{url: 'https://dartpad.dev/inject_embed.dart.js', defer: true}]
---
## Эффективный чистый код

Источник моя статья на типичном прогере [Как написать чистый код и сделать жизнь проще](https://tproger.ru/articles/kak-napisat-chistyj-kod-i-sdelat-zhizn-proshh)

Благодарности:  

🔹 спасибо Дев Релс за поддержку  
🔹 спасибо нашему HoP Ваганову Вадиму за помощь и поддержку. Ты читаешь мои лонгриды и помогаешь сделать их лучше.  

<p>В университетах, как правило, рассказывают базовые понятия: алгоритмы и структуры данных, вычислительную математику. Но не про то, как красиво спроектировать приложение и сделать код удобочитаемым и пригодным для доработок. В итоге на практике мы часто получаем бессистемный подход и нечто, что трудно читать, сложно и страшно рефакторить. Потому что явно что-то где-то да упадёт.</p>
<div class="image-block" data-image="https://media.tproger.ru/uploads/2023/06/701350fb-d82d-4b85-ab76-64c5584234c5-autoconverted.jpeg"><a class="flex lightbox" href="https://media.tproger.ru/uploads/2023/06/701350fb-d82d-4b85-ab76-64c5584234c5-autoconverted.jpeg" data-wpel-link="external" target="_blank" rel="nofollow noopener noreferrer"><br/>
<img decoding="async" width="1024" height="1024" class="wp-image wp-image-243216 lazy entered loaded " src="https://media.tproger.ru/uploads/2023/06/701350fb-d82d-4b85-ab76-64c5584234c5-autoconverted.jpeg" srcset="https://media.tproger.ru/uploads/2023/06/701350fb-d82d-4b85-ab76-64c5584234c5-autoconverted.jpeg 1024w, https://media.tproger.ru/uploads/2023/06/701350fb-d82d-4b85-ab76-64c5584234c5-autoconverted-330x330.jpeg 330w, https://media.tproger.ru/uploads/2023/06/701350fb-d82d-4b85-ab76-64c5584234c5-autoconverted-150x150.jpeg 150w, https://media.tproger.ru/uploads/2023/06/701350fb-d82d-4b85-ab76-64c5584234c5-autoconverted-840x840.jpeg 840w, https://media.tproger.ru/uploads/2023/06/701350fb-d82d-4b85-ab76-64c5584234c5-autoconverted-970x970.jpeg 970w, https://media.tproger.ru/uploads/2023/06/701350fb-d82d-4b85-ab76-64c5584234c5-autoconverted-720x720.jpeg 720w, https://media.tproger.ru/uploads/2023/06/701350fb-d82d-4b85-ab76-64c5584234c5-autoconverted-660x660.jpeg 660w, https://media.tproger.ru/uploads/2023/06/701350fb-d82d-4b85-ab76-64c5584234c5-autoconverted-726x726.jpeg 726w, https://media.tproger.ru/uploads/2023/06/701350fb-d82d-4b85-ab76-64c5584234c5-autoconverted-90x90.jpeg 90w, https://media.tproger.ru/uploads/2023/06/701350fb-d82d-4b85-ab76-64c5584234c5-autoconverted-50x50.jpeg 50w, https://media.tproger.ru/uploads/2023/06/701350fb-d82d-4b85-ab76-64c5584234c5-autoconverted-32x32.jpeg 32w, https://media.tproger.ru/uploads/2023/06/701350fb-d82d-4b85-ab76-64c5584234c5-autoconverted-16x16.jpeg 16w" sizes="(min-width: 1700px) 768px, (min-width: 1400px) calc(100vw - 912px), (min-width: 1200px) calc(100vw - 702px), (min-width: 960px) calc(100vw - 462px), (min-width: 600px) calc(100vw - 112px), calc(100vw - 32px)"><br/>
</a></div>
<p>Чтобы не допускать такого, мы запускаем серию статей про код, где подробно расскажем, как писать красиво и чисто и получать на выходе поддерживаемый код. В первой части расскажем, что такое чистый код и зачем он нужен и опишем принципы его создания. А дальше на конкретных примерах разберём, как делать надо и не надо.</p>
<ol>
<li><a href="#part1">Да кому вообще нужен этот чистый код?</a></li>
<li><a href="#part2">Как написать чистый код?</a></li>
<li><a href="#part3">Подробное руководство</a></li>
<li><a href="#part4">Как править НЕ чистый код?</a></li>
</ol>
<h2 id="#part1">Да кому вообще нужен этот чистый код?</h2>
<p>Читаемый, легко тестируемый, легко компонуемый код, который решает бизнес-задачу и сам является документацией, сокращает ТТM (time to market). За счёт времени, которое разработчик тратит на изучение приложения, внесение изменений в код, добавление новых фич и прочее.</p>
<p>И если приложение плохо спроектировано, код спутан — продуктивность команды, которой приходится разбираться с этим примерно 70% рабочего времени, падает. Это факт. И я с ним сталкивался.</p>
<p>Так что, по сути, он нужен всем, кто работает в IT.</p>
<h3>Разработчикам</h3>
<p>В первую очередь для того, чтобы быстро анализировать и дорабатывать уже готовый код — в том числе собственный, написанный два месяца назад и благополучно за это время забытый. Так, сокращаем TTM.</p>
<p>К тому же, если мы плохо проектируем, плохо пишем, плохо автоматизируем, плохо доставляем, структура начинает тормозить, возникают ошибки. И приходят бизнес, лиды, тестировщики с претензиями, баг-репортами и доработками.</p>
<div class="tp-hint tp-hint--full-width">
<div class="tp-hint__content">Чистый и юзабельный код не ценность — а обязанность. И чем он однообразнее, скучнее и проще тем проще нам автоматизировать процессы.</div>
</div>
<h3>Лидам</h3>
<p>Лиды, как и разработчики, отвечают за качество готового продукта. И им чистый код помогает быстрее проводить ревью, переключаться между задачами и следить за соблюдением соглашений.</p>
<div class="tp-hint tp-hint--full-width">
<div class="tp-hint__content">Бегите из команды, если ваш техлид говорит: «Чистый код — это миф. А те, кто пишут про него книги, статьи и доклады, не работают, а выдумывают теорию, которая на практике неприменима».</div>
</div>
<h3>Бизнесу</h3>
<p>Бизнесу доклады про эстетику и красоту кода неинтересны. Бизнесу важна скорость появления фичей и отсутствие багов.</p>
<p>Так что чем быстрее работает команда, чем больше качественных продуктов и доработок она выпускает, тем больше бизнес может заработать.</p>
<h2 id="#part2">Хорошо, и как тогда написать чистый код?</h2>
<h3>Сперва почитать хорошие книги</h3>
<p>Да, лень — но надо. Всё хорошее и «правильное» уже придумано, и чтобы писать код грамотно, необязательно 5 лет изобретать велосипеды, как это делал я.</p>
<p>Рекомендую читать Роберта Мартина, Владимира Хорикова, Джошуа Блоха, Скота Влашина, Стива Макконнелла и стремиться к профессиональной простоте кодирования. Важно: старайтесь читать книги в оригинале.</p>
<div class="book">
<img decoding="async" importance="low" loading="lazy" title="Обложка книги Clean Code: A Handbook of Agile Software Craftsmanship" class="lazy book" data-lazy-type="image" alt="Обложка книги Clean Code: A Handbook of Agile Software Craftsmanship" src="https://media.tproger.ru/uploads/2023/06/41xShlnTZTL._SX376_BO1204203200_.jpg" width="90" height="135" srcset="https://tproger.ru/signed_image/TyJ_002vXrZOjCoPGo-r-JM6VYNvw-e4qaxQseYn-Hk/rs:fit:90:0:1/cb:vimg_1/f:webp/aHR0cHM6Ly9tZWRpYS50cHJvZ2VyLnJ1L3VwbG9hZHMvMjAyMy8wNi80MXhTaGxuVFpUTC5fU1gzNzZfQk8xMjA0MjAzMjAwXy5qcGc 90w, https://tproger.ru/signed_image/P4ICa2oKHKHlJO40Seo4UizXkx6DOgE7NeouARj2ScQ/rs:fit:180:0:1/cb:vimg_1/f:webp/aHR0cHM6Ly9tZWRpYS50cHJvZ2VyLnJ1L3VwbG9hZHMvMjAyMy8wNi80MXhTaGxuVFpUTC5fU1gzNzZfQk8xMjA0MjAzMjAwXy5qcGc 180w" sizes="90px 135px"> <div>
<h3>Clean Code: A Handbook of Agile Software Craftsmanship</h3>
<div class="book__btn-container">
</div>
</div>
</div>
<p>&nbsp;</p>
<div class="book">
<img decoding="async" importance="low" loading="lazy" title="Обложка книги Clean Architecture: A Craftsman's Guide to Software Structure and Design" class="lazy book" data-lazy-type="image" alt="Обложка книги Clean Architecture: A Craftsman's Guide to Software Structure and Design" src="https://media.tproger.ru/uploads/2023/06/411csr6Nn0L.jpg" width="90" height="135" srcset="https://tproger.ru/signed_image/6KFH7nWZqKaRew6SynBlK91_pHiPCL-vAOixaVihaMY/rs:fit:90:0:1/cb:vimg_1/f:webp/aHR0cHM6Ly9tZWRpYS50cHJvZ2VyLnJ1L3VwbG9hZHMvMjAyMy8wNi80MTFjc3I2Tm4wTC5qcGc 90w, https://tproger.ru/signed_image/MpEH3wKJ3u4rssmtLBho1XV4j0EUevSDSloNUMMbNug/rs:fit:180:0:1/cb:vimg_1/f:webp/aHR0cHM6Ly9tZWRpYS50cHJvZ2VyLnJ1L3VwbG9hZHMvMjAyMy8wNi80MTFjc3I2Tm4wTC5qcGc 180w" sizes="90px 135px"> <div>
<h3>Clean Architecture: A Craftsman's Guide to Software Structure and Design</h3>
<div class="book__btn-container">
</div>
</div>
</div>
<p>&nbsp;</p>
<div class="book">
<img decoding="async" importance="low" loading="lazy" title="Обложка книги Code Complete" class="lazy book" data-lazy-type="image" alt="Обложка книги Code Complete" src="https://media.tproger.ru/uploads/2023/06/51IM3Ywr1yL._SX397_BO1204203200_.jpg" width="90" height="135" srcset="https://tproger.ru/signed_image/BIA_RJHPagfJfQYGgzmS6OJ-0Mm5gkwQ2rboXwl89J8/rs:fit:90:0:1/cb:vimg_1/f:webp/aHR0cHM6Ly9tZWRpYS50cHJvZ2VyLnJ1L3VwbG9hZHMvMjAyMy8wNi81MUlNM1l3cjF5TC5fU1gzOTdfQk8xMjA0MjAzMjAwXy5qcGc 90w, https://tproger.ru/signed_image/2YitEdTl4_D7pBYG_IKjmVdo41uiUQTIIlVrmWfWGR0/rs:fit:180:0:1/cb:vimg_1/f:webp/aHR0cHM6Ly9tZWRpYS50cHJvZ2VyLnJ1L3VwbG9hZHMvMjAyMy8wNi81MUlNM1l3cjF5TC5fU1gzOTdfQk8xMjA0MjAzMjAwXy5qcGc 180w" sizes="90px 135px"> <div>
<h3>Code Complete</h3>
<div class="book__btn-container">
</div>
</div>
</div>
<p>&nbsp;</p>
<div class="book">
<img decoding="async" importance="low" loading="lazy" title="Обложка книги Domain Modeling Made Functional: Tackle Software Complexity with Domain-Driven Design and F#" class="lazy book" data-lazy-type="image" alt="Обложка книги Domain Modeling Made Functional: Tackle Software Complexity with Domain-Driven Design and F#" src="https://media.tproger.ru/uploads/2023/06/511O5zAOJiL.jpg" width="90" height="135" srcset="https://tproger.ru/signed_image/S_Z2G33YNZ2cnir5aPEXK5rL2ODZzbKHZcpHXy2mGFs/rs:fit:90:0:1/cb:vimg_1/f:webp/aHR0cHM6Ly9tZWRpYS50cHJvZ2VyLnJ1L3VwbG9hZHMvMjAyMy8wNi81MTFPNXpBT0ppTC5qcGc 90w, https://tproger.ru/signed_image/qI9ZdRWhq2JNR7yb9CqZxK6kwuGxQPOy_2a2GkbOtJU/rs:fit:180:0:1/cb:vimg_1/f:webp/aHR0cHM6Ly9tZWRpYS50cHJvZ2VyLnJ1L3VwbG9hZHMvMjAyMy8wNi81MTFPNXpBT0ppTC5qcGc 180w" sizes="90px 135px"> <div>
<h3>Domain Modeling Made Functional: Tackle Software Complexity with Domain-Driven Design and F#</h3>
<div class="book__btn-container">
</div>
</div>
</div>
<p>&nbsp;</p>
<div class="book">
<img decoding="async" importance="low" loading="lazy" title="Обложка книги Effective Java (2nd Edition)" class="lazy book" data-lazy-type="image" alt="Обложка книги Effective Java (2nd Edition)" src="https://media.tproger.ru/uploads/2023/06/0321356683.01._SCLZZZZZZZ_SX500_.jpg" width="90" height="135" srcset="https://tproger.ru/signed_image/eLnXVeuK90mR6AfEQiWGEFM2Q5PO9tBBYCwojDzGy9Y/rs:fit:90:0:1/cb:vimg_1/f:webp/aHR0cHM6Ly9tZWRpYS50cHJvZ2VyLnJ1L3VwbG9hZHMvMjAyMy8wNi8wMzIxMzU2NjgzLjAxLl9TQ0xaWlpaWlpaX1NYNTAwXy5qcGc 90w, https://tproger.ru/signed_image/Xibu2aU0YwER8XzdPKzXp0Gjm9PaiT1TJmDsuDpy7L4/rs:fit:180:0:1/cb:vimg_1/f:webp/aHR0cHM6Ly9tZWRpYS50cHJvZ2VyLnJ1L3VwbG9hZHMvMjAyMy8wNi8wMzIxMzU2NjgzLjAxLl9TQ0xaWlpaWlpaX1NYNTAwXy5qcGc 180w" sizes="90px 135px"> <div>
<h3>Effective Java (2nd Edition)</h3>
<div class="book__btn-container">
</div>
</div>
</div>
<p>&nbsp;</p>
<div class="book">
<img decoding="async" importance="low" loading="lazy" title="Обложка книги Принципы юнит-тестирования" class="lazy book" data-lazy-type="image" alt="Обложка книги Принципы юнит-тестирования" src="https://media.tproger.ru/uploads/2023/06/cover.jpg" width="90" height="135" srcset="https://tproger.ru/signed_image/NTwUs0ZcTm9GXM13MeREKd7Yad8ih-6oX4XjR1YfqXU/rs:fit:90:0:1/cb:vimg_1/f:webp/aHR0cHM6Ly9tZWRpYS50cHJvZ2VyLnJ1L3VwbG9hZHMvMjAyMy8wNi9jb3Zlci5qcGc 90w, https://tproger.ru/signed_image/_iloKKk_Nq4WjWBRK7-rXOLp7ZFkwWkHZCxqc1Cl0MM/rs:fit:180:0:1/cb:vimg_1/f:webp/aHR0cHM6Ly9tZWRpYS50cHJvZ2VyLnJ1L3VwbG9hZHMvMjAyMy8wNi9jb3Zlci5qcGc 180w" sizes="90px 135px"> <div>
<h3>Принципы юнит-тестирования</h3>
<div class="book__btn-container">
</div>
</div>
</div>
<div class="tp-hint tp-hint--full-width">
<div class="tp-hint__content">Важно понимать, что некоторые топики, которые тот же Мартин отстаивал в 2008, уже не актуальны. Советую отсеивать их и просто забирать полезное.</div>
</div>
<h3>Обратить внимание на принципы Unix</h3>
<ul>
<li>Write programs that do one thing and do it well — Каждая программа, класс, функция выполняет одну задачу — и выполняет хорошо.</li>
<li>Write programs to work together — Программы работают совместно, и мы можем выстроить пайплайн. Компоненты на разных уровнях работают вместе и взаимодействуют посредством классов.</li>
<li>Write programs to handle text streams, because that is a universal interface — Программы взаимодействуют, используя универсальный текстовый интерфейс, а классы — код. Тип — универсальный интерфейс взаимодействия функций и классов.</li>
</ul>
<p>Эти принципы помогают мне осознавать архитектуру в срезе сложного приложения, и проектировать программы/классы/функции.</p>
<div class="tp-hint tp-hint--full-width">
<div class="tp-hint__content">Unix-философия хорошо подходит для проектирования микросервисов (программ). Поэтому я рекомендую исследовать мир Unix и использовать Linux разработчикам.</div>
</div>
<h3>Внимательно прочитать руководство ниже</h3>
<p>Здесь я привёл основные рекомендации по написанию чистого кода, основанные на многих годах практики и книгах «Чистый код» и «Чистая архитектура: Руководство ремесленника по структуре и проектированию программного обеспечения».</p>
<div class="image-block" data-image="https://media.tproger.ru/uploads/2023/06/aa3fb774-6e89-49f4-b947-69e6160a7164-autoconverted.jpeg"><a class="flex lightbox" href="https://media.tproger.ru/uploads/2023/06/aa3fb774-6e89-49f4-b947-69e6160a7164-autoconverted.jpeg" data-wpel-link="external" target="_blank" rel="nofollow noopener noreferrer"><br/>
<img decoding="async" width="1024" height="1024" class="wp-image wp-image-243218 lazy entered loaded " src="https://media.tproger.ru/uploads/2023/06/aa3fb774-6e89-49f4-b947-69e6160a7164-autoconverted.jpeg" srcset="https://media.tproger.ru/uploads/2023/06/aa3fb774-6e89-49f4-b947-69e6160a7164-autoconverted.jpeg 1024w, https://media.tproger.ru/uploads/2023/06/aa3fb774-6e89-49f4-b947-69e6160a7164-autoconverted-330x330.jpeg 330w, https://media.tproger.ru/uploads/2023/06/aa3fb774-6e89-49f4-b947-69e6160a7164-autoconverted-150x150.jpeg 150w, https://media.tproger.ru/uploads/2023/06/aa3fb774-6e89-49f4-b947-69e6160a7164-autoconverted-840x840.jpeg 840w, https://media.tproger.ru/uploads/2023/06/aa3fb774-6e89-49f4-b947-69e6160a7164-autoconverted-970x970.jpeg 970w, https://media.tproger.ru/uploads/2023/06/aa3fb774-6e89-49f4-b947-69e6160a7164-autoconverted-720x720.jpeg 720w, https://media.tproger.ru/uploads/2023/06/aa3fb774-6e89-49f4-b947-69e6160a7164-autoconverted-660x660.jpeg 660w, https://media.tproger.ru/uploads/2023/06/aa3fb774-6e89-49f4-b947-69e6160a7164-autoconverted-726x726.jpeg 726w, https://media.tproger.ru/uploads/2023/06/aa3fb774-6e89-49f4-b947-69e6160a7164-autoconverted-90x90.jpeg 90w, https://media.tproger.ru/uploads/2023/06/aa3fb774-6e89-49f4-b947-69e6160a7164-autoconverted-50x50.jpeg 50w, https://media.tproger.ru/uploads/2023/06/aa3fb774-6e89-49f4-b947-69e6160a7164-autoconverted-32x32.jpeg 32w, https://media.tproger.ru/uploads/2023/06/aa3fb774-6e89-49f4-b947-69e6160a7164-autoconverted-16x16.jpeg 16w" sizes="(min-width: 1700px) 768px, (min-width: 1400px) calc(100vw - 912px), (min-width: 1200px) calc(100vw - 702px), (min-width: 960px) calc(100vw - 462px), (min-width: 600px) calc(100vw - 112px), calc(100vw - 32px)"><br/>
</a></div>
<h4>Всегда улучшайте код, с которым работаете</h4>
<p>Мартин использует «Правило бойскаута» и призывает улучшать кодовую базу постоянно (так же, как бойскауты оставляют кемпинг в лучшем состоянии, чем он был до визита). Это очень важная жизненная идея.</p>
<p>Поддерживайте свой код в хорошем состоянии. Исправляйте ошибки как можно раньше, удаляйте неиспользуемый код и обновляйте его, чтобы он соответствовал новым требованиям.</p>
<p>И если нашли «сомнительную, странную дичь» в старом коде — соберите команду, обсудите то, что обнаружили. Вероятно, это «нечто» именно то, что стоит улучшить — или вовсе избавиться.</p>
<h4>Think twice, code once</h4>
<p>Прежде чем приступить к разработке, доработке, рефакторингу, разберитесь в том, как функция/система работает по данному потоку. Станьте экспертом в предметной области.</p>
<h4>Используйте функциональную парадигму</h4>
<p>Она загоняет нас в рамки чистого кода и способствует следовать лучшим практикам. Кроме того, чистое ООП в программах не нужно. Серьёзно, нет.</p>
<div class="tp-hint tp-hint--full-width">
<div class="tp-hint__content">Это тема для отдельной статьи, но тут поделюсь фактом: в нескольких больших банках функциональная парадигма — стандарт де-факто при написании микросервисов. И советую почитать, что Роберт Мартин пишет в блогеAnd the future is looking very functional to me.</div>
</div>
<h4>Делите код на слои</h4>
<p>Каждый слой должен выполнять определённую функцию и быть независимым от других слоёв.</p>
<ul>
<li>Разделяйте логику и представление, чтобы упростить тестирование и обеспечить независимость компонентов.</li>
<li>Используйте Вертикальное разделение. «Переменные, функции должны быть определены близко к тому месту, где они используются» (G10 Vertical Separation Clean Code, page 292).</li>
<li>Опирайтесь на луковичную архитектуру, где внутренний слой ничего не знает о внешнем — это помогает визуализировать и проектировать структуру приложения.</li>
</ul>
<div class="image-block" data-image="https://media.tproger.ru/uploads/2023/06/9a4a3467-f6ad-4fd8-8e6b-13842056d9e0-autoconverted.jpeg"><a class="flex lightbox" href="https://media.tproger.ru/uploads/2023/06/9a4a3467-f6ad-4fd8-8e6b-13842056d9e0-autoconverted.jpeg" data-wpel-link="external" target="_blank" rel="nofollow noopener noreferrer"><br/>
<img decoding="async" width="1600" height="874" class="wp-image wp-image-243168 lazy entered loaded " src="https://media.tproger.ru/uploads/2023/06/9a4a3467-f6ad-4fd8-8e6b-13842056d9e0-autoconverted.jpeg" srcset="https://media.tproger.ru/uploads/2023/06/9a4a3467-f6ad-4fd8-8e6b-13842056d9e0-autoconverted.jpeg 1600w, https://media.tproger.ru/uploads/2023/06/9a4a3467-f6ad-4fd8-8e6b-13842056d9e0-autoconverted-330x180.jpeg 330w, https://media.tproger.ru/uploads/2023/06/9a4a3467-f6ad-4fd8-8e6b-13842056d9e0-autoconverted-840x459.jpeg 840w, https://media.tproger.ru/uploads/2023/06/9a4a3467-f6ad-4fd8-8e6b-13842056d9e0-autoconverted-970x530.jpeg 970w, https://media.tproger.ru/uploads/2023/06/9a4a3467-f6ad-4fd8-8e6b-13842056d9e0-autoconverted-720x393.jpeg 720w, https://media.tproger.ru/uploads/2023/06/9a4a3467-f6ad-4fd8-8e6b-13842056d9e0-autoconverted-1080x590.jpeg 1080w, https://media.tproger.ru/uploads/2023/06/9a4a3467-f6ad-4fd8-8e6b-13842056d9e0-autoconverted-660x361.jpeg 660w, https://media.tproger.ru/uploads/2023/06/9a4a3467-f6ad-4fd8-8e6b-13842056d9e0-autoconverted-726x397.jpeg 726w" sizes="(min-width: 1700px) 768px, (min-width: 1400px) calc(100vw - 912px), (min-width: 1200px) calc(100vw - 702px), (min-width: 960px) calc(100vw - 462px), (min-width: 600px) calc(100vw - 112px), calc(100vw - 32px)"><br/>
</a></div>
<p>Пара материалов по теме:</p>
<ul>
<li><a href="https://www.redhat.com/architect/5-essential-patterns-software-architecture#layered" data-wpel-link="external" target="_blank" rel="nofollow noopener noreferrer">https://www.redhat.com/architect/5-essential-patterns-software-architecture#layered</a></li>
</ul>
<ul>
<li><a href="https://www.redhat.com/architect/14-software-architecture-patterns" data-wpel-link="external" target="_blank" rel="nofollow noopener noreferrer">https://www.redhat.com/architect/14-software-architecture-patterns</a></li>
</ul>
<ul>
<li><a href="https://jeffreypalermo.com/2008/07/the-onion-architecture-part-1/" data-wpel-link="external" target="_blank" rel="nofollow noopener noreferrer">https://jeffreypalermo.com/2008/07/the-onion-architecture-part-1/</a></li>
</ul>
<h4>Соблюдайте принципы SOLID для проектирования сервисов, классов и функций</h4>
<p>Нам особенно важен «Принцип единственной ответственности (Single Responsibility Principle)» для классов и функций, сервисов:</p>
<div class="tp-hint tp-hint--full-width">
<div class="tp-hint__content">«Каждый класс или функция должны выполнять только одну задачу».</div>
</div>
<p>То есть пишите функции, которые делают только одну вещь — и делают её хорошо. Есть несколько способов убедиться, что выполнили это правило:</p>
<ul>
<li>функция выполняет только те действия, которые находятся на одном уровне с объявленным именем, выполняет задачу как бы замкнуто в своём теле; и если какие-то запросы пролетают наружу, как это бывает в функциях сервисов приложений, то через шлюзы;</li>
<li>функция выполняет действия, которые находятся на одном уровне абстракции;</li>
<li>из одной функции не получается выделить другие;</li>
<li>функцию не получается разделить на секции.</li>
</ul>
<h4>Избегайте наследования</h4>
<p>Сложные иерархии наследования приводят к путанице и проблемам отладки. Постарайтесь ограничить сложность класса, сохраняя связанную функциональность вместе, а не распределяя её по нескольким уровням абстракции.</p>
<h4>Предпочитайте полиморфизм операторам If/Else</h4>
<p>Приложение будет более гибким, если мы вынесем поведение в классы, убрав тем самым бизнес логику принятия решений, ветвлений в родственные доменные классы.</p>
<h4>DRY</h4>
<p>Код должен быть повторно использован только тогда, когда имеет ту же ответственность.</p>
<p>Если вы используете один и тот же код несколько раз, выносите его в отдельную функцию (класс, компонент, сервис) чтобы избежать дублирования и упростить поддержку.</p>
<div class="tp-hint tp-hint--full-width">
<div class="tp-hint__content">Не увлекайтесь DRY при написании тестов. Универсальность в них часто уменьшает читабельность, а значит, ясность. Помните, тест — это документация.</div>
</div>
<h4>Классы не должны знать о внутренней реализации других классов</h4>
<p>Не думайте о внутренней работе юнита (класса, функции) — лучше смотреть на него, как на чёрный ящик. Это поможет при проектировании и писании прекрасно тестируемого кода.</p>
<h4>G22: Make Logical Dependencies Physical</h4>
<p>Если один модуль зависит от другого, эта зависимость должна быть физической, а не только логической. Также зависимость должна быть очевидной</p>
<h4>Используйте понятные и описательные имена</h4>
<p>Для всего: переменных, функций, классов и других элементов кода. Избегайте сокращений и аббревиатур.</p>
<h4>Форматируйте код</h4>
<p>Казалось бы, очевидное правило. Но как показывает практика — нет. Поэтому:</p>
<ul>
<li>открыли класс в Idea, нажали Ctrl + Alt + L, продолжаем работу;</li>
<li>одной пустой строки в отступах между блоками в коде достаточно.</li>
</ul>
<div class="tp-hint tp-hint--full-width">
<div class="tp-hint__content">Современные IDE умеют форматировать перед коммитом или при сохранении файла. Но лучше один раз вручную установить стандарт — и потом придерживаться его средствами автоматизации.</div>
</div>
<h4>Опирайтесь на 3 закона TDD</h4>
<ul>
<li>You may not write production code until you have written a failing unit test — Мы не выпускаем в прод код, который не покрыт тестами.</li>
<li>You may not write more of a unit test than is sufﬁcient to fail, and not compiling is failing — Покрываем тестами код в достаточном количестве, чтобы убедиться, что данный слой (класс, функция) работает верно. Не дублируйте тест кейсы на разных уровнях. Если все сделали правильно: покрыли юнит-тестами бизнес-логику, не нужно дублировать проверку всех бизнес-кейсов интеграционными тестами.</li>
<li>You may not write more production code than is sufﬁcient to pass the currently failing test — Написал код — написал тесты. Или в обратном порядке.</li>
</ul>
<div class="tp-hint tp-hint--full-width">
<div class="tp-hint__content">Эти законы можно интерпретировать и использовать и тем, кто не придерживается каноничного TDD.</div>
</div>
<h4>Не используйте исключения для обработки ошибок</h4>
<p>Мартин рекомендовал в своё время использовать исключения. А я — нет. Исключения для нас — только сигналы багов. А для обработки ошибок мы используем <a href="https://fsharpforfunandprofit.com/rop/" data-wpel-link="external" target="_blank" rel="nofollow noopener noreferrer">R.O.P.</a></p>
<h4>Комментарий — признак плохого кода</h4>
<p>Пишите комментарии внутри кода только тогда, когда они объясняют, не что код делает, а почему он написан таким образом.</p>
<div class="tp-hint tp-hint--full-width">
<div class="tp-hint__content">Общее правило для большинства случаев: если вам приходится добавлять комментарии — перепишите код.</div>
</div>
<h4>Задавайте границы для внешних библиотек и систем</h4>
<p>Оборачивайте внешние библиотеки или API в API который подходит вашему дизайну — это даст запас прочности.</p>
<p>Применяйте<a href="https://learn.microsoft.com/en-us/azure/architecture/patterns/anti-corruption-layer" data-wpel-link="external" target="_blank" rel="nofollow noopener noreferrer"> Anti-corruption Layer pattern</a> в дизайне кода. И используйте юнит-тесты.</p>
<h4>Живите в парадигме Null Safety</h4>
<p>Не передавайте null</p>
<p>Не возвращайте null</p>
<p>Не используйте null</p>
<h4>Размер функции или метода — максимум пять строк</h4>
<p>Об этом пишет Кристиан Клаусен в книге «Пять строк кода» которую Роберт Мартин рекомендует.</p>
<div class="tp-hint tp-hint--full-width">
<div class="tp-hint__content">Сам Мартин указывает, что размер функции не должен превышать 20 строк по 150 символов каждый, но чем меньше — тем лучше.</div>
</div>
<h4>Идеальное количество входных параметров для функции — один</h4>
<p>Параметры усложняют функцию и запутывают её восприятие. Особенно это касается выходных — потому что мало кто ожидает, что функция в аргументах будет возвращать значения. Поэтому:</p>
<ul>
<li>функция не преобразует входной аргумент;если вы видите такую функцию или написали её только что, исправьте — результат изменения нужно передавать в возвращаемом значении — и точка;</li>
<li>некоторые аргументы стоит упаковать в отдельном классе — так советует старина Блох, отец Макконэл, советую я.</li>
</ul>
<h4>Отделите бизнес-логику предметной области от логики приложения</h4>
<p>Например, бизнес-правила, консистентное состояние объектов в системе, проверки ограничений (валидация), расчёты, используемые в решении, не следует путать с техническими деталями, такими как схема базы данных, интеграции с внешними системами, сервисами уровня приложений и уровнем DTO.</p>
<p>Наконец, помните, что написание чистого кода — это ремесло и где-то даже искусство, которое требует практики и терпения. Не бойтесь переписывать код, если это поможет улучшить его качество и поддерживаемость. А если ищете элегантное простое решение, смотрите <a href="https://habr.com/ru/companies/gazprombank/articles/722620/" data-wpel-link="external" target="_blank" rel="nofollow noopener noreferrer">кукбук</a>.</p>
<h4>А если мне попал в руки НЕ чистый код?</h4>
<p>Тогда начинаем рефакторинг. Я использую такой алгоритм:</p>
<ul>
<li>Просматриваем приложение сверху вниз, оцениваем насколько оно хорошо спроектировано и как описаны классы.</li>
<li>Узнаем у автора этого непотребства, что делает сервис.</li>
<li>Открываем Readme и в функциональном стиле описываем назначение сервиса. Нам пригодятся <a href="https://www.markdownguide.org/basic-syntax/" data-wpel-link="external" target="_blank" rel="nofollow noopener noreferrer">Markdown Best practices</a>. Лучше визуализировать процесс (например, с помощью <a href="https://excalidraw.com/" data-wpel-link="external" target="_blank" rel="nofollow noopener noreferrer">https://excalidraw.com/</a>) это поможет представить правильную картину и структуру классов.</li>
<li>Продумываем, как будем всё это тестировать. Если всё выглядит совсем монструозно, я предлагаю воспользоваться дорогими, но покрывающими максимум кода интеграционными тестами. Раз уж это творение орков работает, зафиксируем состояние и покроем крайние точки тестами. Проверенная тактика.</li>
<li>Во время рефакторинга сразу покрываем код юнит-тестами.</li>
</ul>
<p>На выходе получим простой элегантный дизайн в функциональной парадигме, которая способствует следованию хорошим принципам дизайна и рекомендациям Мартина в частности.</p>
<h4>А что дальше?</h4>
<p>В первой части я описал смысл и принципы чистого кода. В следующей мы проанализируем приложение на предмет чистоты кода. Я пройдусь по каждому классу и опишу недостатки. И расскажу, как это исправлять.</p>

## Чистый код : Заклинание чистокодца

Чистый код - побочный эффект коммуникации, который написан экспертами предметной области и представляет собой простую и понятную документацию на всех уровнях приложения.  
Чистый код - это простые документирующие юнит-тесты, количество Моков при этом минимально или сведено к нулю.  
Чистый код - это простая структура папок, пакетов сгруппированных по бизнес-смыслу, а не по архитектурному уровню типа все DTO лежат в одном вместе, а Entity в другом - если они работают вместе в сборке - пусть и лежат вместе.    
Чистый код - это сильная доменная модель в сердце Луковичной Архитектуры приложения и описанная по TDD Type Driven Development без примитивов.    
Чистый код - это KISS + YAGNI возведенные в абсолют, понятные имена (методов) чистых(pure) и честных(honest) функций с одним параметром на вход и спроектированных без использования исключений при работе с ошибками.   
Чистый код - это мой кукбук <a href="https://git.codemonsters.team/guides/ddd-code-toolkit/src/branch/dev" target="_blank">DDD в действии</a> как пример в открытом для всех доступе (Open Source) - он элегантен, эффективен, прост в прочтении, поддержке, опирается на самую важную идею кодописи - все должно быть максимально просто и к месту, чтобы уволиться одним днем или перейти на другой проект и оставить после себя документацию кодом к которой просто вернуться при необходимости.    
Чистый код - это математика Type Driven Development.  
Чистый код - это постоянный процесс совершенствования в профессии на всех уровнях от Solution Architecture до юнит-тестирования.  
Чистый код - это Null Safety проектирование.  
Если DDD не применим к тебе - YAGNI: отбрось лишнее и используй остальные идеи.   
Эти советы работают как на фронте, так и на бэке.  

## Дизайн мысли
- [Разрабатываем опираясь на лучшие практики](https://betterprogramming.pub/there-is-no-i-in-software-development-4ec478631d6b)
- [7 важных дизайн принципов на завтрак](https://betterprogramming.pub/7-software-development-principles-that-should-be-embraced-daily-c26a94ec4ecc)
- Код это не ценность - это обязанность
- YAGIN, KISS - очень-очень важные дизайн принципы
- Реализуй только то, что необходимо, просто и эффективно
- Если возникают идеи по шаблонизации бизнес-логики, значит вы делаете что-то не правильно
- Решай проблемы в коде, даже если они созданы не тобой - теперь это твоя ответственность
  Улучшай код маленькими порциями, если это не входит в поставку фичи. Вырезаем уродливые куски. Ставь задачу на улучшение - если сделать улучшение во время поставки фичи невозможно
- Если строка единожды используется, то смысла выносить ее в константу нет
- Уделяй максимум внимания и трепета бизнес-логике
- Мы все в ответе за конечный результат
- Код - побочный эффект хорошей коммуникации - не спецификации

## Наименования Типов
- Называй типы в UpperCamelCase стиле
- Используй понятные по бизнесу Лаконичные имена
- Имена типов отвечают на вопрос - какую проблему решает тип (класс)
- Имя может подсказывать какой паттерн реализует класс, например: Visitor, Strategy, ИТП

## О классах
- Класс - это сервис
- Класс решает одну бизнес задачу, но это не значит, что класс содержит один публичный метод
- Используй Reach Domain Model. Доменные классы - содержат в себе бизнес логику
- Избегай игр разума в именах

## Функциональная парадигма с поддержкой императивной
- Функциональная парадигма первична
- Императивная усиливает функциональную

## Общие рекомендации по дизайну функций (методов)
- DRY
- Один аргумент на вход - один на выход
- Функция всегда возвращает результат выполнения операции
- Предпочитай strategy вместо switch
- Честные функции
- Чистые функции
- При дизайне функций используй принцип CQS\
  Command Query Separation\
  Command - всегда возвращает информацию о выполнении команды

## Придерживайся null safety парадигме во всех слоях
- Добро пожаловать в Великое Null Safety Приключение
- Избегай Null-эбл состояний в дизайне классов
- Не передавай Null
- Не возвращай Null
- Null может жить только на границе входного контракта в DTO и все

## Обработка ошибок
- не используй Exception в качестве инструмента управления контроля потока бизнес-логики
- используй [R.O.P. (Railway Oriented Programming)](https://fsharpforfunandprofit.com/rop/) в обработке ошибок в функционально парадигме
- используй Two Track Type: **Result<Data, Error>** в качестве ответа функции, которая может "сломаться" исключением

## Помни про 

<a href="https://12factor.net/" target="_blank">https://12factor.net/</a> 