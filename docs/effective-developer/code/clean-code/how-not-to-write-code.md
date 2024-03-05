---
title: "Как не стоит писать код: разбираем ошибки"
---

# Как не стоит писать код: разбираем ошибки

Вторая часть цикла статей про чистый код. В ней покажем пример некачественного кода и разберём основные ошибки.

В [прошлой части](https://tproger.ru/articles/kak-napisat-chistyj-kod-i-sdelat-zhizn-proshhe) мы рассказали, что такое чистый код и какие принципы нужно соблюдать,  чтобы его написать. В новой — поговорим про плохой код: перечислим  проблемы и покажем, как их решать.

> Эта статья —  «прожарка». Она не отвечает на все вопросы и не содержит иллюстрации ко  всей критике. В будущем мы шаг за шагом более атомарно будем всё  разгребать.


<div style="background: white; display: flex; color: black; padding: 10px 30px; border-radius: 10px; align-items:center; border: 1px solid #e6e5e3; box-shadow: 2px 5px 10px #e6e5e3;">
    <img src="https://media.tproger.ru/uploads/2023/08/image7-autoconverted.jpeg" width="100" height="100" alt="Maxim Morev" style="display: inline-block; border-radius: 100px">
    <div style="margin-left: 1rem;">
        <h1 style="padding: 0; margin: 0">Максим Морев</h1>
        <p style="padding: 0; margin: 0; font-size: 20px">Автор статьи, Software Craftsmanship энтузиаст, CTO</p>
    </div>
</div>

<div style="background: white; display: flex; color: black; padding: 10px 30px; border-radius: 10px; align-items:center; border: 1px solid #e6e5e3; box-shadow: 2px 5px 10px #e6e5e3; margin-top: 20px">
    <img src="https://media.tproger.ru/uploads/2023/08/image26-autoconverted.jpeg" width="100" height="100" alt="Maxim Morev" style="display: inline-block; border-radius: 100px">
    <div style="margin-left: 1rem;">
        <h1 style="padding: 0; margin: 0">Ваганов Вадим</h1>
        <p style="padding: 0; margin: 0; font-size: 20px">Software Engineer, Head of Profession backend-разработки</p>
    </div>
</div>

**[Ссылка на статью TProger](https://tproger.ru/articles/kak-ne-stoit-pisat-kod-razbiraem-owibki)**

## Сперва «высечем» тезисы: как нельзя писать

Всё, рассказанное ниже, база, которую мы взяли из своего опыта, и теперь хотим поделиться.

- НЕ пишите, если не нравится — круто, если код вас увлекает, и время в  компании IDE летит. Но если нет — выберите что-то кроме  программирования. В IT много интересной работы.

- НЕ пишите слепо по ТЗ аналитика — лучше прописывать требования совместно  (или хотя бы разобраться, что конкретно хочет аналитик). Потому что код — ответственность разработчика, и разгребать проблемы придется именно  ему.

- НЕ пишите, пока кратко и четко не описали проблему — её нужно  зафиксировать в README репозитория на понятном пользователю языке. В  идеале — описать поведение системы так, чтобы его можно было легко  переложить в тесты. Это поможет смотреть на систему с перспективы её  поведения.

- НЕ пишите без предварительного проектирования — можно заранее  визуализировать архитектуру приложения. Спросите себя, из каких  компонентов будет состоять приложение, почему именно из них, какие роли  будут исполнять классы на каждом уровне.

![Как не стоит писать код: разбираем ошибки 1](https://media.tproger.ru/uploads/2023/08/96cefea9-66f4-4cb3-864b-02524d0b8109-autoconverted.jpeg)

## А теперь — сам «плохой код»

Представьте, вы — разработчик. Только пришли в команду, познакомились с классными коллегами. И увидели… сервис. [Такой, как этот](https://github.com/codemonstersteam/mq-rest-sync-adapter/tree/01-dev-origin). Читать код невозможно, тестов почти нет, каждый класс «кусается» (ещё и на ChatGPT не свалишь).

> Говорить про тесты здесь не будем — это большая тема, которой лучше посвятить отдельный текст.

```kotlin
fun emerge(
  httpRequestEnvelope: Result<HttpRequestEnvelope>,
  restConfiguration: RestConfiguration
): Result<RestServiceRequest> =
httpRequestEnvelope.fold(
  onSuccess = { httpRequest ->
               val restCfg = restConfiguration.configs[httpRequest.service]
               val substitutor = StringSubstitutor(httpRequest.headers)
               val validatedRequest = validateRequest(httpRequest, restConfiguration, restCfg)

               validatedRequest.fold(
                 onSuccess = {
                   Result.success(
                     RestServiceRequest(
                       restCfg!!,
                       httpRequest,
                       substitutor.replace(restCfg.operations[httpRequest.operation]!!)
                     )
                   )
                 },
                 onFailure = { error -> Result.failure(error) }
               )
              },
  onFailure = { error -> Result.failure(error) }
)
```

Если вы читали  Роберта Мартина или, как минимум, мою предыдущую статью — появится  мысль: «Нужно срочно покинуть эту команду». Но лучше выдохнуть и  проанализировать код — его можно превратить в гармоничное приложение,  которое легко прочитать, понять и, если нужно, доработать.

### Сканируем методы, классы и структуру пакетов.

Мы постарались сделать «прожарку» максимально понятной. Но всё равно может быть тяжеловато.

#### Пакет client.RESTClient

Довольно простой REST-клиент на базе WebClient. По сигнатуре функция `sendRequest` соответствует нашему гайду. Но 82 строки для подобного класса — это  много. Так что стоит упростить: разбить код на блоки и вытащить каждый в отдельную функцию (метод класса в ООП).

Также RESTClient важно покрыть тестами.

```kotlin
class RESTClient(private val webClient: WebClient) {

  private val SERVICE = "mq-rest-sync-adapter"

  fun sendRequest(request: RestServiceRequest): Mono<Result<RestServiceResponse>> {...}

  companion object {
    val CONTENT_TYPE = "${MediaType.APPLICATION_JSON};charset=${Charsets.UTF_8}"
  }
}
```

#### Пакет configuration

`MqConfiguration` — контейнер конфигурации, который содержит класс `MqServiceCfg`. Захардкоженные значения полей `timeout`, `messagePipeline` и `type` смущают. Лучше вынести значения в конфиг-файл.

Класс WebClientConfiguration стоит проверить тестами.

```kotlin
data class MqServiceCfg(
  var REQ: String = "",
  var RES: String = "",
  var RECIEPT: String ="",
  var timeout: Long = 60000,
  var correlationID: String = "",
  var messagePipeline: PipelineType = PipelineType.StandardEnvelope,
  var createDateTime: String = "",
  var formatCreateDateTime: String = "",
  var values: Map<String, String> = mutableMapOf(),
  var type: MqServiceType = MqServiceType.ENVELOPE
) {
  fun getFormattedCreateDateTime(): String {
    val date = LocalDateTime.now().atZone(ZoneOffset.UTC)
    val formatter = DateTimeFormatter.ofPattern(formatCreateDateTime)
    return date.format(formatter)
  }
}
```

#### Пакет exceptions

`ProcessException` — класс, который нигде не используется. Просто удалить.

```kotlin
class ServiceCommunicationException (serviceName: String, msg: String):
    RuntimeException("Ошибка получения данных с сервиса '%s': %s".format(serviceName, msg))
```

#### Пакет mq

Опустим классы-контейнеры без инкапсулированной логики работы с данными. И остановлюсь на проблемах в других классах.

GetWalletBalanceRequest

Смарт-конструктор emerge может выкинуть исключение на этапе десериализации из файла.

Нужно это предусмотреть и обработать. Например. обернуть `Result.runCatching{ }`. Тогда emerge будет возвращать [Result](https://kotlinlang.org/api/latest/jvm/stdlib/kotlin/-result/), то есть однозначно говорить о том, что функция (метод) может зафэйлиться при исполнении и вернуть [Two Track Type](https://fsharpforfunandprofit.com/posts/recipe-part2/) — или результат выполнения в поле `success` или `failure`.

>  Если вы отдельно обрабатываете исключения, можно обернуть их в удобный тип.

```kotlin
data class GetWalletBalanceRequest(
  val requestType: String,
  @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss'Z'")
  val dateFrom: OffsetDateTime,
  @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss'Z'")
  val dateTo: OffsetDateTime?,
  val additionalParameters: AdditionalParameters
) {

  companion object {
    fun emerge(
      data: String
    ): GetWalletBalanceRequest {
      val request = JsonUtil.fromString(data, PsGetBalanceRequest::class.java)
      return createRequest(request)
    }

    private fun createRequest(
      request: PsGetBalanceRequest
    ): GetWalletBalanceRequest =
    GetWalletBalanceRequest(
      request.requestType,
      request.dateFrom,
      request.dateTo,
      AdditionalParameters()
    )
  }
}
```

Валидацию формата полей класса `dateFrom`, `dateTo` лучше вынести в функцию `emerge` и если на вход влетели битые данные — вернуть понятную ошибку.

```kotlin
fun emerge(
  data: String
): GetWalletBalanceRequest {
  val request = JsonUtil.fromString(data, PsGetBalanceRequest::class.java)
  return createRequest(request)
}
```

HttpRequestEnvelope

Класс — DTO, принадлежит слою представления, перегружен логикой, которой в  DTO вообще быть не должно по определению. Её нужно вынести в  соответствующие классы уровня бизнес-логики.

Поле класса `body` (31 строка) лучше сделать пустой строкой по-умолчанию — так приближаемся к Null Safety universe.

```kotlin
val body: String?
```

Функция emerge

Поля просто перекладываются из входных параметров функции в поля класса.  Умный конструктор говорит «тут возможна ошибка создания валидного  объекта, поэтому я верну `Result`», который нам не нужен. Поэтому лучше заменить его на простой of метод.

```kotlin
fun emerge(
  correlationId: String,
  httpMethod: String,
  service: String,
  operation: String,
  httpHeaders: Map<String, String>,
  httpBody: String
): Result<HttpRequestEnvelope> =
Result.success(
  HttpRequestEnvelope(
    correlationId = correlationId,
    method = httpMethod,
    service = service,
    operation = operation,
    headers = httpHeaders,
    body = httpBody
  )
)
```

Функция putPsRequestInBody

В первую очередь — что за заклинание вместо названия? Переименовать.

> Нэйминг — это важно. Но мы на данном этапе не знаем, какое имя выбрать, нужно будет погрузиться в аналитику.

Во-вторых, в 71 строке мы генерируем json-строку из класса, который собирается из тела body-запроса. И если `GetWalletBalanceRequest` зафэйлится и не сможет собраться из строки запроса, которая должна содержать JSON, мы получим необработанный `Exception`. Это плохо, так в коде преднамеренно заложена ошибка и не заложена обработка этой ошибки.￼

Лучше собрать класс в одном месте с `HttpRequestEnvelope` и `GetWalletBalanceRequest`.

В-третьих, в 63 строке вместо `fold` стоит использовать `Result.map` — он для этого и создан. Или вовсе — передавать на вход в данный метод не `Result`, а `HttpRequestEnvelope`.

```kotlin
fun putPsRequestInBody(data: Result<HttpRequestEnvelope>): Result<HttpRequestEnvelope> =
data.fold(
  onSuccess = { request ->
               emerge(
                 request.correlationId,
                 request.method,
                 request.service,
                 request.operation,
                 request.headers,
                 JsonUtil.toJson(GetWalletBalanceRequest.emerge(request.body!!))
               )
              },
  onFailure = { error -> Result.failure(error) }
)
```

Проектируйте систему так, чтобы она работала с валидными объектами — [это возможно](https://fsharpforfunandprofit.com/posts/designing-with-types-making-illegal-states-unrepresentable/) и помогает смоделировать процесс более надёжно. Так, на слое, где можно вызвать «Пут Пс Реквест Ин Боди» — что бы это ни значило — стоит  обработать возможную ошибку, а не прокидывать её в наш замечательный  метод.

Например так:

```kotlin
fun putPsRequestInBody(data: HttpRequestEnvelope): Result<HttpRequestEnvelope> =
```

Кроме того, `validatedRequest` содержит в себе validatePsRequest.

```kotlin
fun validatedRequest(data: Result<HttpRequestEnvelope>, timeout: Long): Result<HttpRequestEnvelope> =
data.fold(
  onSuccess = { success -> validatePsRequest(success, timeout) },
  onFailure = { error -> Result.failure(error) }
)
```

Но валидации для `PsGetBalanceRequest` тут не место. Она должна находиться в умном конструкторе `PsGetBalanceRequest`. Да и саму функцию `validatePsRequest` (в 24 строки) можно описать элегантней.

```kotlin
private fun validatePsRequest(data: HttpRequestEnvelope, timeout: Long): Result<HttpRequestEnvelope> =
PsGetBalanceRequest.fromJsonString(data.body!!).fold(
  onSuccess = { success ->
               if (OffsetDateTime.now().plus(Duration.ofMillis(timeout)).isAfter(success.operTime)) {
                 return Result.failure(
                   ServiceCommunicationException("validation", "Истек скорок действия запроса")
                 )
               }
               if (OperationType.OPERATION_HISTORY == getOperationType(success.requestType)
                   && success.dateFrom.isBefore(success.dateTo ?: OffsetDateTime.now())
                   && (success.dateTo == null || success.dateTo.isBefore(OffsetDateTime.now()))
                  ) {
                 return Result.success(data)
               } else {
                 return Result.failure(
                   ServiceCommunicationException("validation", "Ошибка при валидации входных данных")
                 )
               }
              },
  onFailure = {
    Result.failure(
      ServiceCommunicationException("validation", "Ошибка при валидации входных данных")
    )
  }
)
```

HttpResponseEnvelope

Вопрос к nullable-полям. Почему в запросе перекладчика могут отсутствовать:

- method;
- service;
- operation;
- body;
- headers.

Нужно чётко описать контракт в README и вместе с аналитиком прояснить, в каких случаях эти параметры могут быть `null`. Часто можно прийти к выводу, что поля класса сделаны nullable «на всякий случай» потому что лень писать качественно.

```kotlin
class HttpResponseEnvelope(

  /** Из хедера CorrelationId */
  val correlationId: String,

  /** HttpCode, 500 если ошибка перекладчика */
  val status: Int,

  /** Если была ошибка */
  val message: String?,

  /** Из HttpRequestEnvelope, null если вызова не было*/
  val method: HttpMethod?,

  /** Из HttpRequestEnvelope */
  val service: String?,

  /** Операция из HttpRequestEnvelope*/
  val operation: String?,

  /** Ответ сервиса в String */
  val body: String?,

  /** Хедеры, которые вернул сервис */
  val headers: HttpHeaders?,
)
```

toJsonString

Функция не используется — удалить.

```kotlin
fun toJsonString(): String =
JsonUtil.toJson(this)
```

47 строка, emerge

Это просто мэпер, поэтому смарт-конструктор тут не нужен. Например можно использовать `of` для такой задачи.

```kotlin
fun emerge(response: RestServiceResponse): Result<HttpResponseEnvelope> {
  return Result.success(
    HttpResponseEnvelope(
      correlationId = response.requestEnvelope.correlationId,
      status = response.httpCode.value(),
      message = response.httpCode.reasonPhrase,
      method = response.requestEnvelope.method,
      service = response.requestEnvelope.service,
      operation = response.requestEnvelope.operation,
      headers = response.headers,
      body = response.body ?: ""
    )
  )
}
```

И выглядеть это будет так:

```kotlin
fun of(response: RestServiceResponse): HttpResponseEnvelope {
  return Result.success(
    HttpResponseEnvelope(
      correlationId = response.requestEnvelope.correlationId,
      status = response.httpCode.value(),
      message = response.httpCode.reasonPhrase,
      method = response.requestEnvelope.method,
      service = response.requestEnvelope.service,
      operation = response.requestEnvelope.operation,
      headers = response.headers,
      body = response.body ?: ""
    )
  )
}
```

62 строка, emerge

В этой функции:

- не нужно создавать клон функции на 47-ой строке и передавать на вход Result — стоит удалить метод.
- нужен map вместо fold

```kotlin
fun emerge(
  data: Result<RestServiceResponse>,
): Result<HttpResponseEnvelope> =
data.fold(
  onSuccess = { restResponse ->
               Result.success(
                 HttpResponseEnvelope(
                   correlationId = restResponse.requestEnvelope.correlationId,
                   status = restResponse.httpCode.value(),
                   message = restResponse.httpCode.reasonPhrase,
                   method = restResponse.requestEnvelope.method,
                   service = restResponse.requestEnvelope.service,
                   operation = restResponse.requestEnvelope.operation,
                   headers = restResponse.headers,
                   body = restResponse.body ?: ""
                 )
               )
              },
  onFailure = { error ->
               Result.failure(error)
              })

}
```

> А ещё стоит  читать документацию к классу Result на сайте Kotlin и использовать  методы по назначению и на нужном уровне. Но с этим мы разберемся  подробнее при рефакторинге.

86 строка emerge(correlationId: String, ex: Throwable):

Дружелюбный Alt + F7 показал, что `HttpResponseEnvelope`, `MqResponseMessage`, `RestServiceRequest` и `PsGetBalanceRequest` не используются — удаляем.

Мы работаем не с библиотекой, так что IDE подсказывает, что нужно убрать,  через warning. Можно еще подключить плагины: SonarLint, SonarAnalyzer и  так далее — они хорошо помогают.

```kotlin
fun emerge(correlationId: String, ex: Throwable): HttpResponseEnvelope {

  return HttpResponseEnvelope(
    correlationId = correlationId,
    status = HttpStatus.INTERNAL_SERVER_ERROR.value(),
    message = HttpStatus.INTERNAL_SERVER_ERROR.reasonPhrase,
    method = null,
    headers = HttpHeaders.EMPTY,
    service = "",
    operation = "",
    body = "Ошибка при процессинге сообщения: ${ex.message}"
  )
}
```

> Кстати, есть  хорошая рекомендация от Марка Симана (кинга «Код, который умещается в  голове»): делайте предупреждения ошибками и не допускайте пул реквесты с warning в коде.

#### Пакет service

MqHttpService

Метод `registerJmsListener` создает слушатель на очередь, когда мы поднимаем конфигурацию в классе `MqServiceConfiguration`. Описать слушатель на конкретной задаче лучше явно. Это упростит восприятие и сократит конфигурационную обертку.

При рефакторинге мы явно создадим слушатель в так называемом Buble Context — и покажем, как просто протестировать этот код.

```kotlin
fun registerJmsListener() {

        log.debug("Registering JMS listener for queue ${mqConfig.REQ}")
        val endpoint = SimpleJmsListenerEndpoint()
        endpoint.id = "myJmsEndpoint"
        endpoint.destination = mqConfig.REQ
        endpoint.messageListener = MessageListener { message ->
            log.info("Incoming transmission: ")
            log.info("Raw message: ${message}")
            //log.info("payload: ${message.payload}")
            log.info("Selected pipeline: ${mqConfig.messagePipeline}")

            pipelineServiceSelector.choosePipelineService(mqConfig.messagePipeline).receiveMessage(
                messageConverter.fromMessage(message) as Message<Any>,
                mqPublisher,
                mqConfig,
                restConfiguration,
                restClient
            )
        }
        container = jmsFactory.createListenerContainer(endpoint)
        container!!.errorHandler = ErrorHandler {
            it.printStackTrace()
        }
        container!!.initialize()
        container!!.start()
    }
```

MqPublisher

Содержит два небезопасных метода, которые могут выкинуть исключения:

- Первый — асинхронный метод, который оборачивает отправку сообщения в очередь  на строке 22 в mono. Вызов может выкинуть исключение, как минимум, в  двух очевидных случаях: если очереди не существует или отвалилось  подключение к MQ.

```kotlin
fun publishToMq(jmsRequest: BasicJmsRequest<String>, originalMsgId: String?): Mono<MqPublishedResponce<String>> =
Mono.fromCallable {
  jmsTemplate.convertAndSend(
    jmsRequest.queue,
    jmsRequest.payload
  ) { message -> fillMessageWithHeaders(message, jmsRequest.headers, originalMsgId) }
}
.map {
  MqPublishedResponce(
    correlationId = jmsRequest.correlationId,
    status = "Success",
    jmsRequest = jmsRequest
  )
}
```

```kotlin
 Mono.fromCallable {
            jmsTemplate.convertAndSend(
                jmsRequest.queue,
                jmsRequest.payload
            ) { message -> fillMessageWithHeaders(message, jmsRequest.headers, originalMsgId) }
        }
```

* Второй — небезопасный синхронный метод отправки сообщения в очередь.

```kotlin
fun sendToMq(jmsRequest: BasicJmsRequest<String>, originalMsgId: String?) {
  jmsTemplate.convertAndSend(
    jmsRequest.queue,
    jmsRequest.payload
  ) { message -> fillMessageWithHeaders(message, jmsRequest.headers, originalMsgId) }
}
```

> Зачем нам вообще и асинхронный, и синхронный методы, когда можно завернуть IO-операцию в  асинхронный стек реактивщины и оставить только publishToMq, переименовав метод в publish.

Функция fillMessageWithHeaders

Содержит бизнес-логику обогащения запроса заголовками. Такое сложно тестировать. Так что функцию следует вытащить в доменный объект и тестировать явно  юнит-тестом.

```kotlin
private fun fillMessageWithHeaders(
  message: Message,
  headers: Map<String, String>,
  originalMsgId: String?
): Message {
  message.jmsCorrelationID = originalMsgId
  message.setIntProperty(JmsConstants.JMS_IBM_MSGTYPE, CMQC.MQMT_DATAGRAM)
  headers.forEach { (key: String, value: String) ->
                   if (StringUtils.hasLength(key) && StringUtils.hasLength(value)) {
                     message.setStringProperty(key, value)
                   }
                  }
  return message;
}
```

Интерфейс PipelineService

Функция `receiveMessage` описывает громоздкий контракт, которому должны соответствовать сервисы  обработки разных бизнес-потоков для разных слушателей. Если нужно  передать много параметров — лучше оберните параметры в класс, получится  проще и «чище».

Кроме того, большинство параметров передать инъекцией. Попробуйте написать `Rest Controller`, который описывает API URL-ресурса, и в сигнатуру метода пердеайте конфигурацию rest-сервиса, `rest client`, который понадобится под капотом на уровне `application service`, и `mq publisher` на всякий случай.

```kotlin
interface PipelineService {
    fun receiveMessage(
        message: Message<Any>,
        mqPublisher: MqPublisher,
        mqConfig: MqServiceCfg,
        restConfiguration: RestConfiguration,
        restClient: RESTClient
    )
}
```

PipelineServicePS-сервис приложения

Application — сервис, помеченный аннотацией фреймворка как компонент. Если  имплементировать интерфейс, начинаются очень странные дела в теле  функции (честно, мы ее не придумали).

Входные параметры присваиваются полям класса, потому что разработчик так  передал компоненты, конфигурацию и REST-клиент. Он логирует заголовки и  тело запроса и пробрасывает входной параметр `message` в метод process.

```kotlin
override fun receiveMessage(
  message: Message<Any>,
  mqPublisher: MqPublisher,
  mqConfig: MqServiceCfg,
  restConfiguration: RestConfiguration,
  restClient: RESTClient,
) {
  this.receivedMessage = message
  this.mqPublisher = mqPublisher
  this.mqConfig = mqConfig
  this.restConfiguration = restConfiguration
  this.restClient = restClient

  log.info("Incoming transmission")
  log.info("headers: ${message.headers}")
  log.info("payload: ${message.payload}")

  processMessage(message)
}
```

Пройдёмся по ошибкам в классе:

- `processMessage`. Метод на 30 строк, который состоит из секции настройки переменных  (больше похожей на ловушки). Разберёмся с аналитиком по контракту и  упростим.

```kotlin
fun processMessage(message: Message<Any>) {
  val correlationId = message.headers[mqConfig.correlationID] as String? ?: UUID.randomUUID().toString()
  val url = message.headers["X_Method"] as String? ?: "/somemethod"

  log.debug("msg class is: ${message.javaClass}")

  // TODO - Нужно найти способ получать msgId через стандартные методы
  val msgId = message.headers["jms_messageId"] as String?
  var httpReq: String = message.payload.toString()
```

- `сorrelationId`. 64-ая строка Устанавливается `Elvis operator` рандомно и при этом отсутствует в заголовке. На деле `correlationId` — должен передаваться в заголовке всегда, иначе система выдаст ошибку и сообщит об этом. Подробнее можно почитать тут.

- `url`. Глушим отсутствие в заголовке значения метода. Так делать нельзя. Нужно проверить контракт, и если `url` не задан — вернуть сообщение об ошибке.

- Вместо того чтобы писать комментарий ниже, лучше сразу найти способ или  создать тикет и добавить его в комментарий — задача будет реализована в  рамках 20-30% техдолга.

```kotlin
// TODO - Нужно найти способ получать msgId через стандартные методы
val msgId = message.headers["jms_messageId"] as String?
var httpReq: String = message.payload.toString()
```

* `httpReq` должна быть неизменной — `val`.

```
var httpReq: String = message.payload.toString()
```

Функция acceptedMqReceipt

Во-первых, нужно уменьшить количество входных параметров.

```kotlin
fun acceptedMqReceipt(
  correlationId: String,
  url: String,
  data: Result<HttpRequestEnvelope>,
  originalMsgId: String?,
  mqPublisher: MqPublisher,
  mqConfig: MqServiceCfg,
  httpRequestEnvelope: String
): Result<HttpRequestEnvelope> =
```

Во-вторых, в строке 106 — вместо `fold` можно применить map.

```kotlin
data.fold(
```

В третьих, прочитаем тело функции:

```kotlin
data.fold(
  onSuccess = { success ->
               createMessageForReceipt(httpRequestEnvelope, ReceiptStatus.ACCEPTED, null, null)
               .map { it ->
                     val receiptResponse = MqResponseMessage.emerge(correlationId, url, it)
                     val jmsResponse = convertToReceiptJmsResponse(receiptResponse, mqConfig)
                     mqPublisher.sendToMq(jmsResponse, originalMsgId)
                     return Result.success(success)
                    }

              },
  onFailure = { error ->
               Result.failure(error)
              }
)
```

- Строка 107. Если на вход пришел успешный запрос, вызываем функцию `createMessageForReceipt`, входных параметров в которую слишком много.
- Строка 109. Вызываем map в котором лежит бизнес-логика преобразования сообщения, созданного в функции `createMessageForReceipt`.
- Строка 112. Отправляем ответ на что-то неизвестное, судя по имени `jmsResponse`.

```
mqPublisher.sendToMq(jmsResponse, originalMsgId)
```

* Строка 100. Если приходит успешный `HttpRequestEnvelope`, который был собран из строки 75 и провалидирован, берем некое `Ps`, помещаем в `HttpRequestEnvelope` и проваливаемся в странную функцию `acceptedMqReceipt`, где создаем сообщение для квитанции, превращаем его в `jmsResponse` и отправляем в строку 112

```kotlin
Mono.just(
            HttpRequestEnvelope.fromJsonString(message.payload.toString())
        ).map {
            HttpRequestEnvelope.validatedRequest(it, mqConfig.timeout)
        }.map {
            HttpRequestEnvelope.putPsRequestInBody(it)
        }.map {
            acceptedMqReceipt(correlationId, url, it, msgId, mqPublisher, mqConfig, httpReq)
```

То есть функция должна отправить сообщение с квитанцией в очередь `mq`. Но из имени не понятно, что делается в теле. И происходящее описано  очень сложно. Решение — переименовать функцию, отправить квитанцию на  вход, подать один параметр, в теле отправить квитанцию в `mq`.

Функция fun createMessageForReceipt

Эта функция буквально говорит то же, что и предыдущая: «Я содержу много  бизнес-логики преобразований. Меня неудобно читать. Во мне много входных параметров. Во мне неверно используют `Result`».

Кроме того, не стоит кидать `fold` в `fold` через map. А `map{it}` мэпит в самого себя строка 151.

`createMessageForReceipt` после упрощения будет возвращать объект, который легко протестировать.

```kotlin
fun createMessageForReceipt(
  httpRequestEnvelope: String,
  flag: ReceiptStatus,
  errorCode: Int?,
  description: String?
): Result<String> =
fromJsonString(httpRequestEnvelope).fold(
  onSuccess = { request ->
               PsGetBalanceRequest.fromJsonString(request.body!!).fold(
                 onSuccess = { request ->
                              Result.success(
                                JsonUtil.toJson(
                                  ReceiptPs(
                                    request.requestType,
                                    request.dateFrom,
                                    request.dateTo,
                                    request.operTime,
                                    flag,
                                    errorCode,
                                    description
                                  )
                                )
                              )
                             },
                 onFailure = { error -> Result.failure(error) }
               )

              },
  onFailure = { error -> Result.failure(error) }
).map { it }
```

Функция convertToReceiptJmsResponse

Во-первых, `mqConfig` передавать не нужно, это — параметр класса, его класс получает в виде  инъекции. Во-вторых, бизнес-логику конвертации стоит выносить из сервиса в класс, так как в данном приватном методе её не протестировать  наглядно и просто.

```kotlin
private fun convertToReceiptJmsResponse(
        mqRequest: MqResponseMessage,
        mqConfig: MqServiceCfg
    ) = BasicJmsRequest(
        correlationId = mqRequest.correlationId,
        queue = mqConfig.RECEIPT,
        payload = mqRequest.payload,
        headers = prepareSipHeaders(mqRequest.correlationId, mqRequest.operation, mqConfig)
    )
```

Функция convertToBasicJmsResponse

Те же замечания что и к предыдущей функции.

```kotlin
private fun convertToBasicJmsResponse(
  mqRequest: MqResponseMessage,
  mqConfig: MqServiceCfg
) = BasicJmsRequest(
  correlationId = mqRequest.correlationId,
  queue = mqConfig.RES,
  payload = mqRequest.payload,
  headers = prepareSipHeaders(mqRequest.correlationId, mqRequest.operation, mqConfig)
)
```

Функция prepareSipHeaders

Те же замечания что и к предыдущей функции.

```kotlin
private fun prepareSipHeaders(correlationId: String, url: String, mqConfig: MqServiceCfg): Map<String, String> {
  val headers = mutableMapOf(
    mqConfig.correlationID to correlationId,
    "X_Method" to url,
    "RequestID" to UUID.randomUUID().toString(),
    mqConfig.createDateTime to mqConfig.getFormattedCreateDateTime(),
  )
  headers.putAll(mqConfig.values)
  return headers
}
```

Функция processMqResponse

В `HttpResponseEnvelope.emerge` нет умного конструктора, поэтому функцию назвать нужно было `map` и использовать просто в `of`.

```kotlin
fun processMqResponse(
  data: Result<RestServiceResponse>,
): Result<HttpResponseEnvelope> =
data.fold(
  onSuccess = { success -> HttpResponseEnvelope.emerge(success) },
  onFailure = { error ->
               log.debug(error.message)
               Result.failure(error)
              })
```

Кроме того, нужно правильно применить `Result` в классе `HttpResponseEnvelope`. Сейчас, этот метод (функция) возвращает `Result` просто потому что.

```kotlin
fun emerge(response: RestServiceResponse): Result<HttpResponseEnvelope> {
  return Result.success(
    HttpResponseEnvelope(
      correlationId = response.requestEnvelope.correlationId,
      status = response.httpCode.value(),
      message = response.httpCode.reasonPhrase,
      method = response.requestEnvelope.method,
      service = response.requestEnvelope.service,
      operation = response.requestEnvelope.operation,
      headers = response.headers,
      body = response.body ?: ""
    )
  )
}
```

Функция submitMqReceipt

Судя по развилке, функция делает несколько дел сразу.

```kotlin
fun submitMqReceipt(
  correlationId: String,
  url: String,
  mqResponse: Result<MqResponseMessage>,
  originalMessageId: String?,
  mqPublisher: MqPublisher,
  mqConfig: MqServiceCfg,
  httpRequestEnvelope: String
): Result<MqResponseMessage> =
mqResponse.fold(
  onSuccess = { success ->
               createMessageForReceipt(httpRequestEnvelope, ReceiptStatus.SUCCESS, null, null).map {
                 val receiptResponse = MqResponseMessage.emerge(correlationId, url, it)
                 val jmsResponse = convertToReceiptJmsResponse(receiptResponse, mqConfig)
                 mqPublisher.sendToMq(jmsResponse, originalMessageId)
                 return Result.success(success)
               }
              },
  onFailure = { error ->
               createMessageForReceipt(httpRequestEnvelope, ReceiptStatus.ERROR, null, error.message).map {
                 val receiptResponse = MqResponseMessage.emerge(correlationId, url, it)
                 val jmsResponse = convertToReceiptJmsResponse(receiptResponse, mqConfig)
                 mqPublisher.sendToMq(jmsResponse, originalMessageId)
                 return Result.failure(error)
               }
              }
)
```

* Если на вход залетает `mqResponse` — `Result<MqResponseMessage>` в виде `Result.success` — то функция некрасиво создает квитанцию `createMessageForReceipt`. И через две операции мэпит в JMS ответ и отправляет в MQ.

```kotlin
createMessageForReceipt(httpRequestEnvelope, ReceiptStatus.SUCCESS, null, null).map {
```

* Если на вход (строка 204) залетает `mqResponse` — `Result<MqResponseMessage> `в виде `Result.failure` — то создаётся `createMessageForReceipt` квитанции об ошибке.

```
createMessageForReceipt(httpRequestEnvelope, ReceiptStatus.ERROR, null, error.message).map {
```

К тому же функция `submitMqReceipt` принимает на вход слишком много лишних параметров.

>  Функция submitMqResponse чуть проще, но ошибки те же: выбор, конвертация, отправка.

```kotlin
fun submitMqResponse(
  correlationId: String,
  url: String,
  data: Result<MqResponseMessage>,
  originalMsgId: String?,
  mqPublisher: MqPublisher,
  mqConfig: MqServiceCfg
): Mono<MqPublishedResponce<String>> =
data.fold(
  onSuccess = { success -> mqPublisher.publishToMq(convertToBasicJmsResponse(success, mqConfig), originalMsgId) },
  onFailure = { error -> mqPublisher.publishToMq(convertToBasicJmsResponse(MqResponseMessage.emerge(correlationId,url,error), mqConfig), originalMsgId)}
)
```

После форматирования чуть проще воспринять.

```kotlin
fun submitMqResponse(
  correlationId: String,
  url: String,
  data: Result<MqResponseMessage>,
  originalMsgId: String?,
  mqPublisher: MqPublisher,
  mqConfig: MqServiceCfg
): Mono<MqPublishedResponce<String>> =
data.fold(
  onSuccess = { success ->
               mqPublisher.publishToMq(
                 convertToBasicJmsResponse(success, mqConfig),
                 originalMsgId
               )
              },
  onFailure = { error ->
               mqPublisher.publishToMq(
                 convertToBasicJmsResponse(
                   MqResponseMessage.emerge(
                     correlationId,
                     url,
                     error
                   ), mqConfig
                 ), originalMsgId
               )
              }
)
```

В следующей части начнём рефакторить код и разбирать всё подробнее.






