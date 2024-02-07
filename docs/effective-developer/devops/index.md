---
title: Emerge DevOps
description: Links to Dart codelabs.
toc: false
---

# Как построить песочницу разработчика

Для того, чтобы собрать и структурировать эксперименты и в качестве образовательного челенджа 
я создал эту страницу. 

По шагам я опишу создание **Песочницы разработчика** в которой и буду вести эксперименты

## Введение

Сначала я платил Digital Ocean, позже понял и посчитал: у меня большие аппетиты и много идей, для меня дорого платить ежемесячно 40$

Я не хочу ограничений  

Я уверен, что хороший инженер должен разбираться в том, как настроить Пайплайн производства, как создать песочницу для разработки, написать код и выстроить процессы.

Очен классная книга, в жизни так и происходит, я наблюдаю изменения у нас в ГПБ.
()[]


## План

Настраиваем приватный dev контур   

✔️ Настроить сервак: мой выбор [Gentoo](https://wiki.gentoo.org/wiki/Handbook:Main_Page)  
⚒️ Настроить email: [email: postman](https://wiki.gentoo.org/wiki/Complete_Virtual_Mail_Server)    
⚒️ Настроить Private DNS: bind  
⚒️ Настроить систему авторизации: [Keycloak](https://www.keycloak.org/)     
✔️️ Настроить Nginx Proxy для разрула запросов на разные ресурсы в рамках одного сервака (minikube, docker swarm)   
✔️ Настроить git: как сердце CI - gitlab  
   ✔️ Настроить gitlab: runner (CD)   
⚒️ Настроить nexus: для хранения артефактов  
✔️ Настроить minikube: сервер stateless приложений  
⚒️ Настроить istio service mesh (minikube)  
⚒️ Настроить ELK  
⚒️ Настроить мониторинг: [Zabbix](https://www.zabbix.com/documentation/5.4/ru/manual)  

### Research
main resource
https://landscape.cncf.io/

https://traefik.io/traefik/

https://nextcloud.com/about/  



### Zabbix

https://github.com/zabbix/zabbix-docker/blob/6.4/docker-compose_v3_alpine_pgsql_latest.yaml

````
curl -O https://raw.githubusercontent.com/zabbix/zabbix-docker/6.4/docker-compose_v3_alpine_pgsql_latest.yaml

````
Learn

Init
````
docker swarm init
````