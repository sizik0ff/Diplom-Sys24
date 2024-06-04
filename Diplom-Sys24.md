#  Дипломная работа по профессии «Системный администратор»

Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)
---------

## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible.  

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal  

Важно: используйте по-возможности **минимальные конфигурации ВМ**:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая. 

**Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.**

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Виртуальные машины не должны обладать внешним Ip-адресом, те находится во внутренней сети. Доступ к ВМ по ssh через бастион-сервер. Доступ к web-порту ВМ через балансировщик yandex cloud.

Настройка балансировщика:

1. Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

2. Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

3. Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

4. Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh.  Эта вм будет реализовывать концепцию  [bastion host]( https://cloud.yandex.ru/docs/tutorials/routing/bastion) . Синоним "bastion host" - "Jump host". Подключение  ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью  [ProxyCommand](https://docs.ansible.com/ansible/latest/network/user_guide/network_debug_troubleshooting.html#network-delegate-to-vs-proxycommand) . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

---------

## Инфраструктура

Устанавливаем Terraform и Ansible на основную машину 

Всю инфраструктуру описываем в [main.tf](https://github.com/sizik0ff/Diplom-Sys24/blob/main/Diplom/main.tf) 

Вся необходимая информация для авторизации (token_id,cloud_id,folder_id,zone_a,zone_b) вынесены в переменные  terraform.tfvars 

Отдельно создан фаил с переменными [variables.tf](https://github.com/sizik0ff/Diplom-Sys24/blob/main/Diplom/variables.tf)

Создаем:
1) Server 1 
2) Server 2 
3) Bastion
4) Zabbix-server
5) Kibana-server
6) Elasticsearch-server

![image](https://github.com/sizik0ff/Diplom-Sys24/blob/main/img/1.png)
(прерывание отключенно для проверки) 

![image](https://github.com/sizik0ff/Diplom-Sys24/blob/main/img/2.png)


Главный плейбук называется [playbook.yml](https://github.com/sizik0ff/Diplom-Sys24/blob/main/Diplom/Ansible/playbook.yml) 

При его запуске происходит установка и настройка всех необходимых утилит,программ,конфигураций и т.д 

Но далее каждый плейбук я буду описывать отдельно. 


## Сеть

Добавляем настройки [security_group.tf](https://github.com/sizik0ff/Diplom-Sys24/blob/main/Diplom/security_group.tf) - для взаимодействия vm между собой, ключевым образом через bastion host 

Для обеспечения концепции bastion host, используем фаил 
[local_files.tf](https://github.com/sizik0ff/Diplom-Sys24/blob/main/Diplom/local_files.tf) который предоставляет ip адреса для Ansible.

Ansible считывает всю необходимую информацию из [hosts.cfg](https://github.com/sizik0ff/Diplom-Sys24/blob/main/Diplom/Ansible/hosts.cfg)
Для которой используется шаблон: [hosts.tpl](https://github.com/sizik0ff/Diplom-Sys24/blob/main/Diplom/hosts.tpl) 

![image](https://github.com/sizik0ff/Diplom-Sys24/blob/main/img/3.png)

Проверка пинга всех хостов 

## Сайт 

Ранее мы создали Server 1 и Server 2 для нашего сайта, а так же создали Target Group,Backend Group,HTTP router,Application load balancer

![image](https://github.com/sizik0ff/Diplom-Sys24/blob/main/img/4.png)

Теперь установим на него Nginx, с помощью роли geerlingguy.nginx [nginx.yml](https://github.com/sizik0ff/Diplom-Sys24/blob/main/Diplom/Ansible/nginx.yml)

После активируется плейбук который установит нужную нам страницу сайта на сервера [index.yml](https://github.com/sizik0ff/Diplom-Sys24/blob/main/Diplom/Ansible/index.yml)


Перейдем по ip адресу балансировщика и увидим одностраничный сайт : [158.160.165.106](http://158.160.165.106:80)

![image](https://github.com/sizik0ff/Diplom-Sys24/blob/main/img/5.png)

Протестируем сайт: curl -v 

```
~/diplom/ansible » curl -v http://158.160.165.106:80                                                                                                                          
*   Trying 158.160.165.106:80...
* Connected to 158.160.165.106 (158.160.165.106) port 80 (#0)
> GET / HTTP/1.1
> Host: 158.160.165.106
> User-Agent: curl/7.81.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< server: ycalb
< date: Tue, 04 Jun 2024 07:35:08 GMT
< content-type: text/html
< content-length: 1186
< last-modified: Mon, 03 Jun 2024 04:01:57 GMT
< etag: "665d4035-4a2"
< accept-ranges: bytes
< 
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Визитка Системного администратора</title>
<style>
    body {
        font-family: Arial, sans-serif;
        margin: 0;
        padding: 0;
    }
    .header {
        background-color: #333;
        color: white;
        text-align: center;
        padding: 10px 0;
    }
    .content {
        text-align: center;
        margin-top: 20px;
    }
    img {
        max-width: 100%;
        height: auto;
        margin-top: 20px;
    }
    .footer {
        background-color: #333;
        color: white;
        text-align: center;
        padding: 10px 0;
    }
</style>
</head>
<body>
    <div class="header">
        <h1>Дипломная работа по профессии системный администратор</h1>
    </div>
    <div class="content">
        <p>Участник группы SYS-24 Netology</p>
        <p>Спасибо netology.ru за обучение!</p>
    </div>
    <div class="footer">
        <p>&copy; Сизиков Максим, 2024</p>
    </div>
</body>
</html>
* Connection #0 to host 158.160.165.106 left intact
```
