# Решение Digital Skills 2022

### Ссылки на ресурсы

[https://github.com/coder060799/TestDS22.git](https://github.com/coder060799/TestDS22.git) - репозиторий с полезностями

### Текущая инфраструктура

#### Развернутые инфраструктурные службы

Ниже перечислены основные настроенные инфраструктурные решения предприятия и сценарии их применения

- DHCP-сервер. развернут на Сервер-2, пакет ISC DHCP. Используется для автоматической конфигурации хостов офиса. Раздаются параметры: адрес, адрес локального DNS-сервера, маршрут по умолчанию.
- DNS-сервер, развернут на Сервер-2, пакет BIND. Используется для разрешения и кэширования DNS-запросов офиса, обслуживает зону test.company.
- Файловый сервер, развернут на Сервер-1, роль «Файловые службы Windows». Используется для оперативного обмена файлами, раздается каталог Share на диске D:\\. Предоставлен доступ всем ПК из сети офиса, используется  
    пользователь Administrator.
- VPN-сервер, развернут на VDS, пакет OpenVPN. Реализует TLS VPN сервер. ключевая информация генерируется локально. Подключенные клиенты используют типовую конфигурацию и единую клиентскую ключевую информацию. Присвоение адресов происходит автоматически средствами OpenVPN.
- Интернет-шлюз, развернут на Сервер-2, пакеты Firewalld и NetworkManager. Осуществляет подключение к сети провайдера с применением протокола PPPoE. Выполняется трансляция исходящего трафика в адрес внешнего интерфейса.

#### Развернутые службы сопровождения разработки

Ниже перечислены службы сопровождения бизнес-процессов разработки приложений:

- Веб-сервер NGINX. Развернут на Сервер-2, обслуживается тестовые варианты приложений, разрабатываемых в компании. Прослушивает внутренние адреса, осуществляет перенаправление запросов по доменному  
    имени.
- СУБД Postgresql. Развернута на Сервер-2, обслуживает тестовые варианты приложений, разрабатываемых в компании. Прослушивает внутренние адреса, предоставляет доступ всем пользователям локальной сети предприятия. Осуществляет обслуживание баз данных тестовых приложений.
- Microsoft Team Foundation Server(выводится из эксплуатации). Развернут на Сервер-1. Централизованная система контроля версий и распределения задач, используется программистами для планирования работ и хранения исходников разрабатываемых проектов.

### Развертывание инфраструктуры

Перечень серверов и используемых на них пакетов:

- В качестве интернет-шлюза и VPN-сервера будут выступать маршрутизаторы на базе Linux (встроенный форвординг трафика, wireguard для VPN);
- В качестве сервера разграничения прав доступа, DNS, DHCP и файлового хранилища будет использоваться сервер на базе Astra Linux (пакеты FreeIPA для домена и DNS, isc-dhcp-server-ldap для интеграции с FreeIPA, NextCloud - для хранения данных);
- В качестве сервера бэкапа будет использоваться ВМ с пакетом Duplicati;
- В качестве сервера мониторинга и БД будет использоваться ВМ, на которой будут контейнеры с Zabbix, Postgresql;
- В качестве сервера GIT и CI/CD будет использоваться ВМ с Gitlab

#### Выделяемые ресурсы

Лабораторная демонстрация выполняется в окружении вложенной виртуализации на базе KVM + QEMU. В качестве ОС используется Centos 8 с доступом к virtmanager (только графически). Дистрибутивы ОС для ВМ можно использовать свои. Характеристики полигона составляют:

- vCPU - 8 -12 шт.
- ОЗУ - 16 Гб
- хранилище - SSD + HDD - 450 Гб

#### Именование хостов и ip-адресация

**&lt;C|L&gt;-&lt;ИмяВМ&gt;**

C-RTR - внешний роутер в облаке (debian 11)

C-DC - домен-контроллер на Astra Linux (FreeIPA, isc-dhcp)

C-GIT - GitLab CI/CD (debian 11)

C-TEST - ВМ для развертывания приложения для тестов (debian 11)

C-PROD - ВМ для готового веб-приложения (debian 11)

C-BACKUP - ВМ для бэкапов (debian 11)

C-MONITOR - ВМ для мониторинга (debian 11)

L-RTR - роутер в офисе (Debian 11)

PC-1 - ПК директора в офисе (Windows)

PC-X - ПК постоянного сотрудника (windows)

RC-W - ПК внешнего сотрудника (windows)

<address id="bkmrk-rc-u---%D0%9F%D0%9A-%D0%B2%D0%BD%D0%B5%D1%88%D0%BD%D0%B5%D0%B3%D0%BE-%D1%81">RC-U - ПК внешнего сотрудника на Ubuntu</address><address id="bkmrk-">  
</address><address id="bkmrk-%D0%A5%D0%BE%D1%81%D1%82-ip-%D0%98%D0%BD%D1%82%D0%B5%D1%80%D1%84%D0%B5%D0%B9%D1%81-c-"><table border="1" style="border-collapse: collapse; width: 100%;"><colgroup><col style="width: 33.3333%;"></col><col style="width: 33.3333%;"></col><col style="width: 33.3333%;"></col></colgroup><tbody><tr><td class="align-center">**Хост**</td><td class="align-center">**IP**</td><td class="align-center">**Интерфейс**</td></tr><tr><td>C-RTR</td><td>белый ip</td><td>eth1</td></tr><tr><td>C-RTR</td><td>10.10.10.1</td><td>eth0</td></tr><tr><td>L-RTR</td><td>белый ip</td><td>eth1</td></tr><tr><td>L-RTR</td><td>10.10.20.1</td><td>eth0</td></tr><tr><td>C-DC</td><td>10.10.10.10</td><td>eth0</td></tr><tr><td>C-BACKUP</td><td>10.10.10.11</td><td>eth0</td></tr><tr><td>C-MONITOR</td><td>10.10.10.12</td><td>eth0</td></tr><tr><td>C-GIT</td><td>10.10.10.13</td><td>eth0</td></tr><tr><td>C-TEST</td><td>10.10.10.14</td><td>eth0</td></tr><tr><td>C-PROD</td><td>10.10.10.15</td><td>eth0</td></tr></tbody></table>

</address>#### Схема инфраструктуры

[![digital.drawio.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/digital-drawio.png)](https://atomskills.space/uploads/images/gallery/2022-09/digital-drawio.png)

#### Установка Docker и Docker Compose

<address id="bkmrk-%D0%97%D0%B0%D0%B3%D1%80%D1%83%D0%B7%D0%B8%D0%BC-%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BE%D1%87%D0%BD%D1%8B">Загрузим установочный скрипт Docker Engine и Docker Compose с помощью команды:

<figure class="highlight">```shell
curl -fsSL https://get.docker.com -o get-docker.sh
```

</figure></address><address id="bkmrk-%D0%A2%D0%B5%D0%BF%D0%B5%D1%80%D1%8C-%D0%B7%D0%B0%D0%BF%D1%83%D1%81%D1%82%D0%B8%D0%BC-%D1%83%D1%81%D1%82%D0%B0">Теперь запустим установку Docker Engine и Docker Compose с помощью команды:</address><address id="bkmrk-sh-get-docker.sh-%D0%A2%D0%B5%D0%BF">```shell
sh get-docker.sh
```

Теперь нужно убедиться, что Docker Engine установлен корректно. Для этого необходимо выполнить команду:

<figure class="highlight">```docker
docker version
```

Далее нужно убедиться, что Docker Compose установлен корректно. Для этого необходимо выполнить команду:

<figure class="highlight">```docker
docker compose version
```

Далее можно добавить пользователя в группу “docker”, чтобы запускать Docker Engine без необходимости использовать “sudo”.

Добавим пользователя “debian” в группу “docker” с помощью команды:

<figure class="highlight">```shell
sudo usermod -aG docker $USER
```

Чтобы применить изменения, вам нужно выйти из системы и снова войти в систему, что приведет к тому, что ваш новый сеанс будет иметь правильную группу.

#### Настройка маршрутизаторов (C-RTR и L-RTR)

Используем дистрибутив Debian 11.

##### Базовая настройка и NAT

1. Включаем на обоих устройствах ip forwarding в /etc/sysctl.conf:  
    ```
    ```shell
    # Uncomment the next line to enable packet forwarding for IPv4
    net.ipv4.ip_forward=1
    ```<br></br>
    ```
2. Создаем правило для NAT в nftables /etc/nftables.conf:  
    ```
    ```shell
    table ip nat {
    		chain postrouting {
            type nat hook postrouting priority 0;
            ip saddr 0.0.0.0/0 oifname eth0  masquerade;
            }
    }
    ```<br></br><br></br>
    ```
3. Проверяем, что таблица не пустая, затем включаем службу nftables и проверяем, что всё работает:

```shell
nft list ruleset

systemctl enable --now nftables
systemctl status nftables
```



##### Установка и настройка VPN Wireguard (сервер)  


Добавляем репозиторий, выполняем обновление списка и устанавливаем Wireguard:

```shell
echo 'deb http://ftp.debian.org/debian buster-backports main' | sudo tee /etc/apt/sources.list.d/buster-backports.list
sudo apt update
sudo apt install wireguard
```

WireGurad VPN настраивается и управляется с помощью команд wg и wg-quick. Все устройства в сети WireGuard должны иметь как открытый, так и закрытый ключи. Генерируем пару ключей с помощью команды:

```shell
wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey
```

Сгенерированные ключи хранятся в каталоге ***/etc/wireguard.***

Настроим туннельное устройство, которое будет использоваться для маршрутизации VPN-трафика. Создаем новый файл с именем wgvpn.conf

```shell
[Interface]
Address = 10.0.0.1/24
SaveConfig = true
ListenPort = 51820
PrivateKey = GENERATED_SERVER_PRIVATE_KEY
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```

Сохраняем и закрываем файл. Затем делаем конфиг и приватный ключ нечитаемыми для пользователей.

```bash
sudo chmod 600 /etc/wireguard/{privatekey,wgvpn.conf}
```

Запускаем wgvpn интерфейс:

```bash
sudo wg-quick up wgvpn
```

Вывод будет такой:

```
[#] ip link add wgvpn type wireguard
[#] wg setconf wgvpn /dev/fd/63
[#] ip -4 address add 10.0.0.1/24 dev wgvpn
[#] ip link set mtu 1420 up dev wgvpn
[#] iptables -A FORWARD -i wgvpn -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

Проверяем, что интерфейс поднялся:

```
ip a show wgvpn
37: wgvpn: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420 qdisc noqueue state UNKNOWN group default qlen 1000
    link/none
    inet 10.0.0.1/24 scope global wgvpn
       valid_lft forever preferred_lft forever
```

Поскольку WireGuard управляется с помощью службы systemd, включаем его при загрузке с помощью команды:

```bash
sudo systemctl enable wg-quick@wgvpn
```

На устройстве должен быть включен ip forwarding:

```bash
nano /etc/sysctl.conf
net.ipv4.ip_forward=1

sudo sysctl -p
```

Разрешаем на МСЭ порт 51820 (на примере ufw):

```
sudo ufw allow 51820/udp
```

##### Установка и настройка VPN Wireguard на клиентах

Добавляем репозиторий, выполняем обновление списка и устанавливаем Wireguard:

```shell
echo 'deb http://ftp.debian.org/debian buster-backports main' | sudo tee /etc/apt/sources.list.d/buster-backports.list
sudo apt update
sudo apt install wireguard
```

Генерируем пару ключей (приватный и публичный):

```
wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey
```

Создаем /etc/wireguard/wgvpn.conf файл и добавляем следующую конфигурацию:

```
[Interface]
#This client private key
PrivateKey = CLIENT_PRIVATE_KEY
#Client IP address
Address = clientipaddress

[Peer]
#Wireguard server public key
PublicKey = SERVER_PUBLIC_KEY
# Wireguard server public IPv4/IPv6 address and port
Endpoint = SERVER_PUBLIC_IP_ADDRESS:51820
#Set ACL
AllowedIPs = networkcidr
```

***SERVER\_PUBLIC\_KEY*** - на сервере cat /etc/wireguard/publickey

***CLIENT\_PRIVATE\_KEY*** - на клиенте cat /etc/wireguard/privatekey

***SERVER\_PUBLIC\_IP\_ADDRESS:51820*** - внешний ip адрес сервера

Пример заполненного конфига:

```
[Interface]
#This client private key
PrivateKey = uKK1bKzw+lGGNDZbR6SFp8Z5x6p1b+IJwn4x94x6oHM=
#Client IP address
Address = 10.0.0.2/24

[Peer]
#Wireguard server public key
PublicKey = DzbeULxxuj3WsYY1FkE85+gesqGwGOBIbD3a5R1ZDx8=
# Wireguard server public IPv4/IPv6 address and port
Endpoint = 109.120.191.81:51820
#Set ACL
AllowedIPs = 10.0.0.0/8
```

После настройки хоста необходимо добавить его на сервер.

```
sudo wg set wgvpn peer <strong>CLIENT_PUBLIC_KEY</strong> allowed-ips 10.0.0.2
```

После этого запускаем везде vpn:

```bash
sudo wg-quick up wgvpn
```

Далее выполняем команду sudo wg и убеждаемся, что трафик проходит:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/TScimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/TScimage.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/wqvimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/wqvimage.png)

##### Установка Wireguard Web-Portal

Копируем файл wireguard-web-docker-run.sh в любую директорию. Добавляем права на запуск:

```bash
chmod +x wireguard-web-docker-run.sh
```

Содержимое файла ниже:

```bash
docker run -it --cap-add NET_ADMIN -d --name wireguard-portal \
-v /etc/wireguard/:/etc/wireguard/ \
-v /app/wireguard-portal/data:/app/data \
-p 8123:8123 \
--network=host \
--env MYVAR2=foo \
--env WG_DEVICES=wgvpn \
--env "WG_CONFIG_PATH=/etc/wireguard" \
--env EXTERNAL_URL=http://wgvpn.dig-skills.ga \
--env "WEBSITE_TITLE=WireGuard VPN" \
--env "COMPANY_NAME=Test" \
--env ADMIN_USER=admin@dig-skills.ga \
--env ADMIN_PASS=P@ssw0rd \
--env "MAIL_FROM=WireGuard PVN <noreply+wireguard@company.com>" \
--env "EMAIL_HOST=10.10.10.10" \
--env EMAIL_PORT=25 \
--env LDAP_ENABLED=true \
--env "LDAP_URL=ldap://10.10.10.10:389" \
--env "LDAP_BASEDN=DC=dig-skills,DC=ga" \
--env "LDAP_USER=admin@dig-skills.ga" \
--env "LDAP_PASSWORD=P@ssw0rd" \
--env "LDAP_ADMIN_GROUP=cn=admins,cn=groups,cn=accounts,dc=dig-skills,dc=ga" \
--restart unless-stopped \
h44z/wg-portal:latest
```

Скрипт отвечает за запуск контейнера с веб-порталом wireguard. Конфигурацию wireguard он берет из папки /etc/wireguard, поэтому wireguard должен быть настроен. Запускаем:

```
sudo sh wireguard-web-docker-run.sh
```

После пары минут заходим на веб-портал по адресу [http://10.10.10.1:8123, ](http://10.10.10.1:8123)либо по [http://wgvpn.dig-skills.ga:8123](http://wgvpn.dig-skills.ga:8123) и нажимаем Login:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/T7Rimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/T7Rimage.png)

Логинимся под администратором:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/sBDimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/sBDimage.png)

Переходим в настройки администрирования:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/ivqimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/ivqimage.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/EGsimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/EGsimage.png)

Меняем название стандартной конфигурации и проверяем, что все поля со звездочкой заполнены:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/qkAimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/qkAimage.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/W7ximage.png)](https://atomskills.space/uploads/images/gallery/2022-09/W7ximage.png)

Для добавления пиров нажимаем сюда:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/bV0image.png)](https://atomskills.space/uploads/images/gallery/2022-09/bV0image.png)

</figure></figure></figure></address>#### Развертывание ВМ с FreeIPA (DNS, DHCP, NextCloud)

Дистрибутив Astra Linux.

Раскомментировать в /etc/apt/sources.list строку с зеркалом яндекса и заменить orel на текущую версию ОС:

```
http://mirror.yandex.ru/astra/stable/2.12_x86-64/release
```

Выполнить sudo apt update для обновления списка пакетов.

##### Установка и настройка FreeIPA

Выполнить установку Astra Freeipa Server, затем выполнить настройку домен-контроллера:

```shell
sudo apt install -y astra-freeipa-server
astra-freeipa-server -d cloudig.local -n clouddc -ip 10.10.10.10
```

Пароль для УЗ администратора будет стандартный.

Заходим по адресу [https://c-dc.dig-skills.ga](https://c-dc.dig-skills.ga) или [https://10.10.10.10](https://10.10.10.10), откроется страница входа в FreeIPA, где нужно ввести учетку admin и пароль P@ssw0rd:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/owVimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/owVimage.png)

Далее сразу создадим все DNS-записи для наших серверов:

- c-rtr.dig-skills.ga - 10.10.10.1
- wgvpn.dig-skills.ga - 10.10.10.1
- c-backup.dig-skills.ga - 10.10.10.11
- zabbix.dig-skills.ga - 10.10.10.12
- c-monitor.dig-skills.ga - 10.10.10.12
- gitlab.dig-skills.ga - 10.10.10.13
- c-git.dig-skillgs.ga - 10.10.10.13
- test.dig-skills.ga - 10.10.10.14
- c-test.dig-skills.ga - 10.10.10.14
- prod.dig-skills.ga - 10.10.10.15
- c-prod.dig-skills.ga - 10.10.10.15

Для настройки необходимо перейти в Сетевые службы -&gt; DNS -&gt; Зоны DNS:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/ecgimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/ecgimage.png)

Нажимаем на нашу DNS зону:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/ZwPimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/ZwPimage.png)

И нажимаем Добавить:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/f0vimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/f0vimage.png)

Заполняем имя, тип записи выбираем A, вводим IP-адрес хоста и нажимаем Добавить и добавить ещё:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/Gamimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/Gamimage.png)

После добавления всех записей должна получиться примерно такая картина:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/V9Eimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/V9Eimage.png)

##### Установка isc-dhcp-server и плагина для FreeIPA

Устанавливаем isc-dchp-server с поддержкой ldap:

```shell
sudo apt install -y isc-dhcp-server-ldap
```

Устанавливаем git для возможности клонирования к себе репозиториев:

```shell
sudo apt install -y git
```

Клонируем репозиторий с плагином DHCP для FreeIPA:

```
git clone https://github.com/Turgon37/freeipa-plugin-dhcp.git
```

Меняем в файле freeipa-plugin-dhcp/install.sh путь IPALIB\_DEST=/usr/lib/python&lt;версия&gt;/**site**-packages/ipaserver/plugins на

IPALIB\_DEST=/usr/lib/python&lt;версия&gt;/**dist**-packages/ipaserver/plugins

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/4CHimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/4CHimage.png)

После этого выполняем скрипт:

```shell
sudo freeipa-plugin-dhcp/install.sh
```

В результате в меню должна появиться кнопка DHCP.

В конфигурационном файле /etc/default/isc-dhcp-server указать сетевые интерфейсы, с которыми будет работать сервер:

```
INTERFACESv4="eth0"
#INTERFACESv6=""
```

Далее настраиваем dhcpd.conf. Конфиг оставляем такой:

```
# dhcpd.conf
# Sample configuration file for ISC dhcpd
# option definitions common to all supported networks...
option domain-name "ipadomain.ru";
option domain-name-servers 10.10.10.10;
default-lease-time 600;
max-lease-time 7200;
ldap-server "10.10.10.10";
ldap-port 389;
ldap-username "cn=Directory Manager"; ldap-password "12345678";
ldap-base-dn "dc=ipadomain,dc=ru";
ldap-method dynamic;
ldap-debug-file "/var/log/dhcp-ldap-startup.log";
# The ddns-updates-style parameter controls whether or not the server will attempt to do a DNS update when a lease is confirmed. We default to the behavior of the version 2 packages ('none', since DHCP v2 didn't # have support for DDNS.)
ddns-update-style none;
# If this DHCP server is the official DHCP server for the local network, the authoritative directive should be uncommented.
authoritative;
```

Возвращаемся в FreeIPA, обновляем страницу (необходимо после установки плагина) и идём на вкладку Сетевые службы -&gt; DHCP -&gt; Servers и жмём Добавить:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/pppimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/pppimage.png)

Выбираем из списка узлов наш домен-контроллер и жмем Добавить:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/fQlimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/fQlimage.png)

Далее необходимо добавить подсеть:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/DN3image.png)](https://atomskills.space/uploads/images/gallery/2022-09/DN3image.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/bSJimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/bSJimage.png)

После этого настраиваем конфигурацию DHCP:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/RS0image.png)](https://atomskills.space/uploads/images/gallery/2022-09/RS0image.png)

Теперь можно запускать службу isc-dhcp-server:

```bash
sudo systemctl start isc-dhcp-server
```

Если служба запустилась, то никаких ошибок не выдастся. В противном случае необходимо внимательно изучить журнал:

```bash
sudo journalctl -xe
```

##### Установка и настройка NextCloud

Создаем каталог docker и в нём docker-compose.yml со следующим содержимым:

```yaml
version: '3.8'

services:
  db:
    image: mariadb
    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
    restart: always
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=P@ssw0rd
      - MYSQL_PASSWORD=P@ssw0rd
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
    networks: 
      - nextcloud

  app:
    image: nextcloud:fpm
    links:
      - db
    volumes:
      - nextcloud:/var/www/html:z
    depends_on:
      - db
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - NEXTCLOUD_ADMIN_USER=nextcloud
      - NEXTCLOUD_ADMIN_PASSWORD=P@ssw0rd
      - NEXTCLOUD_TRUSTED_DOMAINS=192.168.152.143
      - NEXTCLOUD_DATA_DIR=/var/www/html/data
      - MYSQL_HOST=192.168.152.143
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=P@ssw0rd
      - MYSQL_DATABASE=nextcloud
    restart: always
    networks: 
      - nextcloud
  web:
    image: nginx
    ports:
      - 80:80
    links:
      - app
    volumes:
      - nextcloud:/var/www/html:z
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - app
    restart: always
    networks: 
      - nextcloud 
networks:
  nextcloud:
volumes:
  nextcloud:
  db:
```

Также необходим файл nginx.conf со следующим содержимым:

```nginx
worker_processes auto;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    upstream php-handler {
        server app:9000;
    }

    server {
        listen 80;
        
        add_header Referrer-Policy "no-referrer" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Download-Options "noopen" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Permitted-Cross-Domain-Policies "none" always;
        add_header X-Robots-Tag "none" always;
        add_header X-XSS-Protection "1; mode=block" always;

        # Remove X-Powered-By, which is an information leak
        fastcgi_hide_header X-Powered-By;

        # Path to the root of your installation
        root /var/www/html;

        location = /robots.txt {
            allow all;
            log_not_found off;
            access_log off;
        }

        location = /.well-known/carddav {
            return 301 $scheme://$host:$server_port/remote.php/dav;
        }

        location = /.well-known/caldav {
            return 301 $scheme://$host:$server_port/remote.php/dav;
        }

        # set max upload size
        client_max_body_size 10G;
        fastcgi_buffers 64 4K;

        # Enable gzip but do not remove ETag headers
        gzip on;
        gzip_vary on;
        gzip_comp_level 4;
        gzip_min_length 256;
        gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
        gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

        # Uncomment if your server is build with the ngx_pagespeed module
        # This module is currently not supported.
        #pagespeed off;

        location / {
            rewrite ^ /index.php;
        }

        location ~ ^\/(?:build|tests|config|lib|3rdparty|templates|data)\/ {
            deny all;
        }
        location ~ ^\/(?:\.|autotest|occ|issue|indie|db_|console) {
            deny all;
        }

        location ~ ^\/(?:index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+)\.php(?:$|\/) {
            fastcgi_split_path_info ^(.+?\.php)(\/.*|)$;
            set $path_info $fastcgi_path_info;
            try_files $fastcgi_script_name =404;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param PATH_INFO $path_info;
            # fastcgi_param HTTPS on;

            # Avoid sending the security headers twice
            fastcgi_param modHeadersAvailable true;

            # Enable pretty urls
            fastcgi_param front_controller_active true;
            fastcgi_pass php-handler;
            fastcgi_intercept_errors on;
            fastcgi_request_buffering off;
        }

        location ~ ^\/(?:updater|oc[ms]-provider)(?:$|\/) {
            try_files $uri/ =404;
            index index.php;
        }

        # Adding the cache control header for js, css and map files
        # Make sure it is BELOW the PHP block
        location ~ \.(?:css|js|woff2?|svg|gif|map)$ {
            try_files $uri /index.php$request_uri;
            add_header Cache-Control "public, max-age=15778463";
            add_header Referrer-Policy "no-referrer" always;
            add_header X-Content-Type-Options "nosniff" always;
            add_header X-Download-Options "noopen" always;
            add_header X-Frame-Options "SAMEORIGIN" always;
            add_header X-Permitted-Cross-Domain-Policies "none" always;
            add_header X-Robots-Tag "none" always;
            add_header X-XSS-Protection "1; mode=block" always;

            # Optional: Don't log access to assets
            access_log off;
        }

        location ~ \.(?:png|html|ttf|ico|jpg|jpeg|bcmap|mp4|webm)$ {
            try_files $uri /index.php$request_uri;
            # Optional: Don't log access to other assets
            access_log off;
        }
    }
}
```

После этого запускаем контейнер через docker compose:

```bash
docker compose up -d
```

Открываем сайт по ip (лучше по доменному имени) и вводим УЗ для nextcloud (nextcloud и [P@ssw0rd](mailto:P@ssw0rd)):

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/cK1image.png)](https://atomskills.space/uploads/images/gallery/2022-09/cK1image.png)

По итогу откроется стартовая страница Nextcloud:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/NN8image.png)](https://atomskills.space/uploads/images/gallery/2022-09/NN8image.png)

Переходим к настройке аутентификации по протоколу LDAP. Для этого нажимаем на значок пользователя в правом верхнем углу и выбираем Приложения -&gt; Отключенные приложения :

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/Oh0image.png)](https://atomskills.space/uploads/images/gallery/2022-09/Oh0image.png)

Нажимаем на значок трех полосок для скрытия бокового меню. Включаем компоненты логирования, внешнего хранилища и LDAP аутентификации:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/oUpimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/oUpimage.png)

После включения поддержки LDAP нажимаем на значок пользователя, выбираем Настройки и в боковом меню находим LDAP/AD интеграция:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/fFTimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/fFTimage.png)

Настраиваем параметры LDAP как на скриншоте:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/zj6image.png)](https://atomskills.space/uploads/images/gallery/2022-09/zj6image.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/Wa3image.png)](https://atomskills.space/uploads/images/gallery/2022-09/Wa3image.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/xbjimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/xbjimage.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/jehimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/jehimage.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/PU8image.png)](https://atomskills.space/uploads/images/gallery/2022-09/PU8image.png)

Далее сбоку нажимаем Дополнительно и заполняем следующие поля:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/STmimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/STmimage.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/fJoimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/fJoimage.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/CYoimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/CYoimage.png)

В завершении проверяем конфигурацию:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/eawimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/eawimage.png)

Далее можно зайти под каким-нибудь доменным пользователем:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/yxdimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/yxdimage.png)

Как видим, вход по LDAP работает:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/b7Dimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/b7Dimage.png)

#### Развертывание ВМ с Duplicati (бэкапы)

Дистрибутив Debian 11.

```shell
wget https://updates.duplicati.com/beta/duplicati_2.0.6.3-1_all.deb

sudo apt install -y duplicati_2.0.6.3-1_all.deb

sudo apt install mono-complete -y
```

По умолчанию, Duplicati доступен только с localhost, это исправляем в файле /etc/default/duplicati:

```
DAEMON_OPTS="--webservice-port=80 --webservice-interface=any"
```

Теперь остается запустить приложение и сделать автозагрузку

```
systemctl enable duplicati
systemctl start duplicati
```

Оповещение на почту о выполненных бекапах в системе. Нужно зайти в веб-интерфейс, в Настройках найти Параметры по умолчанию и нажать ссылку Редактировать как текст. Вот пример настроек для отправки через Yandex почту:

```
--send-mail-username=your_USERNAME
--send-mail-password=your_PASSWORD
--send-mail-url=smtps://smtp.yandex.ru:465
--send-mail-any-operation=true
--send-mail-subject=Duplicati [%PARSEDRESULT% - %OPERATIONNAME%] - {%backup-name%}
--send-mail-to=destination_EMAIL
--send-mail-body=%RESULT%
--send-mail-level=all
--send-http-result-output-format=Duplicati
--send-mail-from=your_EMAIL
```

Переходим в веб-интерфейс управления резервным копированием. Нажимаем добавить резервную копию, выбираем настройка новой резервной копии и жмем Далее:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/V7Bimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/V7Bimage.png)

Далее заполняем имя задачи, добавляем описание, задаем пароль и нажимаем Далее:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/TfDimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/TfDimage.png)

Далее необходимо настроить место хранения резервных копий. Выбираем SFTP, так как удобнее всего будет передавать копии по данному протоколу. Заранее настраиваем SSH. На сервере необходимо создать каталог /opt/backups. После ввода необходимых данных нажимаем тест для проверки доступа:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/T3Pimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/T3Pimage.png)

В открывшемся диалоге нажимаем Да:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/jAyimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/jAyimage.png)

При наличии доступа появится сообщение об успехе. Жмем ОК, а затем Далее:

На следующем этапе необходимо выбрать данные для резервирования. Выберем самое необходимое, можно добавить фильтры и исключить какие-то файлы. После выбора нажимаем Далее:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/APoimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/APoimage.png)

Предпоследним этапом является настройка задач выполнения резервного копирования. Ставим флаг напротив автоматического резервного копирования. Остальные опции необходимо настроить в зависимости от критичности данных. Жмем Далее:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/ltyimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/ltyimage.png)

На последнем этапе указываем ограничения по размеру бэкапа, название копии, а также ограничения по времени хранения:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/VLQimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/VLQimage.png)

После настройки откроется главная страница, где можно развернуть нашу копию и посмотреть указанные настройки:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/Mi8image.png)](https://atomskills.space/uploads/images/gallery/2022-09/Mi8image.png)

После выполнения задачи резервного копирования можно увидеть информацию об последнем бэкапе, а также посмотреть, когда будет запущена следующая задача:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/uxEimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/uxEimage.png)

Для удобства дальнейшего развертывания необходимо сделать экспорт конфигурации. В разделе Настройки нажимаем Export:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/eN6image.png)](https://atomskills.space/uploads/images/gallery/2022-09/eN6image.png)

Выбираем экспорт в файл и экспорт паролей. Жмем экспорт:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/g05image.png)](https://atomskills.space/uploads/images/gallery/2022-09/g05image.png)

#### Развертывание ВМ с Zabbix + Telegram Бот

Дистрибутив Debian 11. Развернуть в Docker.

##### Установка и настройка Zabbix

Первым делом выписываем сертификаты для работы с Https. Генерируем запрос:

```bash
openssl req -out zabbix.csr -new -newkey rsa:2048 -nodes -keyout zabbix.key
# убираем пароль из ключа
openssl rsa -int zabbix.key -out zabbix.key
```

Далее копируем содержимое zabbix.csr и переходим во FreeIPA. Создаем там новый узел и указываем параметры нашего хоста:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/gcZimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/gcZimage.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/33Fimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/33Fimage.png)

После этого проваливаемся в только что созданный узел и нажимаем Действия -&gt; Выдать сертификат:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/vxTimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/vxTimage.png)

Заполняем информацию и вставляем запрос, который ранее скопировали из csr файла:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/8aeimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/8aeimage.png)

Далее переходим в Аутентификацию -&gt; Сертификаты и проваливаемся в наш выданный сертификат:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/ex1image.png)](https://atomskills.space/uploads/images/gallery/2022-09/ex1image.png)

Нажимаем Действия -&gt; Загрузить:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/0lRimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/0lRimage.png)

После этого копируем через ssh скачанный сертификат, ключ к нему и корневой сертификат из /etc/ipa/ca.crt на сервер заббикса. Создаем цепочку сертификатов:

```bash
cert.pem CA.crt > zabbix.crt
# выдаем права на ключ
chmod 755 zabbix.key 
```

Создаем zabbix-compose.yml

```yaml
version: '3.5'
services:
  server:
    image: zabbix/zabbix-server-pgsql:alpine-latest
    ports:
      - "10051:10051"
    volumes:
      - ./localtime:/etc/localtime:ro
      - ./timezone:/etc/timezone:ro 
      - ./zabbix/alertscripts:/usr/lib/zabbix/alertscripts:ro
      - ./zabbix/externalscripts:/usr/lib/zabbix/externalscripts:ro
      - ./zabbix/export:/var/lib/zabbix/export:rw
      - ./zabbix/modules:/var/lib/zabbix/modules:ro
      - ./zabbix/enc:/var/lib/zabbix/enc:ro
      - ./zabbix/ssh_keys:/var/lib/zabbix/ssh_keys:ro
      - ./zabbix/mibs:/var/lib/zabbix/mibs:ro
      - ./zabbix/snmptraps:/var/lib/zabbix/snmptraps:ro
    restart: always
    depends_on:
      - postgres-server
    environment:
      - POSTGRES_USER=zabbix
      - POSTGRES_PASSWORD=zabbix
      - POSTGRES_DB=zabbix
      - ZBX_HISTORYSTORAGETYPES=log,text
      - ZBX_DEBUGLEVEL=1
      - ZBX_HOUSEKEEPINGFREQUENCY=1
      - ZBX_MAXHOUSEKEEPERDELETE=5000
      - ZBX_PROXYCONFIGFREQUENCY=3600
  web-nginx-pgsql:
    image: zabbix/zabbix-web-nginx-pgsql:alpine-latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./localtime:/etc/localtime:ro
      - ./timezone:/etc/timezone:ro
      - ./ssl/nginx:/etc/ssl/nginx:ro
      - ./zabbix/modules/:/usr/share/zabbix/modules/:ro
    healthcheck:
      test: ["CMD", "curl", "-f", "https://localhost:443/"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 30s
    sysctls:
      - net.core.somaxconn=65535
    restart: always
    depends_on:
      - server
      - postgres-server
    environment:
      - POSTGRES_USER=zabbix
      - POSTGRES_PASSWORD=zabbix
      - POSTGRES_DB=zabbix
      - ZBX_SERVER_HOST=server
      - ZBX_POSTMAXSIZE=64M
      - PHP_TZ=Europe/Moscow
      - ZBX_MAXEXECUTIONTIME=500
  agent:
    image: zabbix/zabbix-agent:alpine-latest
    ports:
      - "10050:10050"
    volumes:
      - ./localtime:/etc/localtime:ro
      - ./timezone:/etc/timezone:ro
      - /proc:/proc
      - /sys:/sys
      - /dev:/dev
      - /var/run/docker.sock:/var/run/docker.sock
    privileged: true
    pid: "host"
    restart: always
    depends_on:
      - server
    environment:
      - ZBX_SERVER_HOST=server
  snmptraps:
    image: zabbix/zabbix-snmptraps:alpine-latest
    ports:
      - "162:1162/udp"
    volumes:
      - ./zabbix/snmptraps:/var/lib/zabbix/snmptraps:rw
    restart: always
    depends_on:
      - server
    environment:
      - ZBX_SERVER_HOST=server
  postgres-server:
    image: postgres:latest
    restart: always
    volumes:
      - ./postgresql/data:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD=zabbix
      - POSTGRES_USER=zabbix
      - POSTGRES_DB=zabbix
    healthcheck:
      test: ["CMD-SHELL", "pg_isready"]
      interval: 10s
      timeout: 5s
      retries: 5
```

Запускаем контейнеры:

```shell
docker compose -f zabbix-compose.yml up -d
```

При успешном создании страница zabbix будет доступна по адресу [https://zabbix.digital-skills.ga](https://zabbix.digital-skills.ga):

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/Wcoimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/Wcoimage.png)

Аутентификация по LDAP

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/Nnoimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/Nnoimage.png)

##### Создание бота для Zabbix

Создадим бота, через которого Zabbix будет отправлять сообщения. Для управления ботами есть специальный бот **@BotFather**, добавляем его себе в контакты и пишем ему:

```bash
/start
```

Выводится справка по командам. Для создания бота пишем:

```bash
/newbot
```

Нам предлагают указать для бота **name** (имя), пишем:

```bash
zabbix digital 2022
```

Нам предлагают указать для бота **username** (логин), он должен оканчиваться на "bot" или "Bot". Пишем:

```bash
zabbix_digital_2022_bot
```

5735095085:AAFBC\_PywK26f9mxQh0aAMFrxj62uFwk4hU - **токен бота**

t.me/zabbix\_digital\_2022\_bot - **ссылка на бота**

Бот создан, получаем токен "Use this token to access the HTTP API". Копируем его и вставляем в Zabbix в разделе Administration → Media types → Telegram → Parameters → Token.

Для проверки можно выполнить тест.

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/lsVimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/lsVimage.png)

В указанный чат (по id) придёт сообщение:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/qrEimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/qrEimage.png)

Создаем группу в telegram и добавляем туда ботов zabbix\_digital\_2022\_bot и IDbot.

В Zabbix настраиваем действия по уведомлениям о событиях:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/KIDimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/KIDimage.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/4XHimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/4XHimage.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/oARimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/oARimage.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/5jvimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/5jvimage.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/k0Nimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/k0Nimage.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/Rvvimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/Rvvimage.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/zaBimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/zaBimage.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/image.png)](https://atomskills.space/uploads/images/gallery/2022-09/image.png)

#### Развертывание ВМ с GitLab (CI/CD, netbox)

Первым делом выписываем сертификаты из FreeIPA для gitlab и container registry. Для этого необходимо добавить Узлы во FreeIPA:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/DgNimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/DgNimage.png)

Указываем имя хоста, его Ip-адрес и нажимаем добавить:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/pyVimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/pyVimage.png)

После этого необходимо зайти в созданный хост и добавить еще одну запись к нему:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/ocFimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/ocFimage.png)

После этого делаем два запроса на выдачу сертификатов:

```bash
openssl req -out gitlab.digital-skills.ga.csr -new -newkey rsa:2048 -nodes -keyout gitlab.digital-skills.ga.key
# Обязательно заполняем поле Common Name gitlab.digital-skills.ga (то есть FQDN)
openssl req -out cr.digital-skills.ga.csr -new -newkey rsa:2048 -nodes -keyout cr.digital-skills.ga.key
# Обязательно заполняем поле Common Name cr.digital-skills.ga (то есть FQDN)
```

Далее необходимо убрать пароль с ключей:

```bash
openssl rsa -in gitlab.digital-skills.ga.key -out gitlab.digital-skills.ga.key
openssl rsa -in cr.digital-skills.ga.key -out cr.digital-skills.ga.key
```

После этого необходимо посмотреть с помощью cat содержимое первого запроса gitlab.digital-skills.ga.csr и перейти во FreeIPA для выдачи сертификата:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/A8Bimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/A8Bimage.png)

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/lIRimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/lIRimage.png)

Аналогично выдаем второй сертификат. Далее переходим в раздел Аутентификация и копируем проваливаемся в нужный нам сертификат:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/2ucimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/2ucimage.png)

Нажимаем Действия -&gt; Загрузить:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/jn6image.png)](https://atomskills.space/uploads/images/gallery/2022-09/jn6image.png)

Аналогично для второго сертификата.

После этого копируем файлы на хост с гитлабом через SSH. А также копируем туда рутовый сертификат, который хранится в /etc/ipa/ca.crt.

На хосте гитлаба переносим все файлы в каталог, где хранится docker-compose.yml гитлаба в каталог ssl.

Далее необходимо выстроить цепочку доверия для каждого сертификата с корневым и выдаем права на ключи:

```bash
gitlab.digital-skills.ga.pem ca.crt > gitlab.digital.skills.ga.crt
cr.digital-skills.ga.pem ca.crt > cr.digital-skills.ga.crt

# и выдаем права для ключей
chmod 755 gitlab.digital-skills.ga.key 
chmod 755 cr.digital-skills.ga.key 
```

Также необходимо добавить корневой сертификат в систему. Для этого выполняем следующие команды:

```bash
# копируем сертификат в каталог с сертификатами
cp ./ca.crt /usr/local/share/ca-certificates/
# выполняем обновление CA store
update-ca-certificates
```

После этого скачиваем с репозитория docker-compose файл для развертывания гитлаба, либо создаем файл вручную:

```yaml
version: '3'
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    hostname: gitlab
    restart: always
    volumes:
      - ./config:/etc/gitlab
      - ./log:/var/log/gitlab
      - ./data:/var/opt/gitlab
      - ./ssl:/etc/gitlab/ssl
      - ./registry:/var/opt/registry
      - ./CA.pem:/etc/CA.pem
    ports:
      - "443:443"
      - "80:80"
      - "2222:22"
    environment:
     GITLAB_OMNIBUS_CONFIG: |
      letsencrypt['enable'] = false
      gitlab_rails['backup_keep_time'] = 604800
      gitlab_rails['gitlab_shell_ssh_port'] = 2222
      gitlab_rails['registry_path'] = "/var/opt/registry"
      gitlab_rails['packages_enabled'] = true
      gitlab_rails['time_zone'] = 'Europe/Moscow'
      nginx['redirect_http_to_https'] = true
      external_url "https://gitlab.digital-skills.ga"
      registry_external_url 'https://cr.digital-skills.ga'
      gitlab_rails['ldap_enabled'] = true
      gitlab_rails['ldap_servers'] = YAML.load <<-'EOS'
        main:
          label: 'ldap'
          host: 'c-dc.digital-skills.ga'
          port: 389
          uid: 'uid'
          encryption: 'plain'
          bind_dn: 'uid=admin,cn=users,cn=compat,dc=digital-skills,dc=ga'
          password: 'P@ssw0rd'
          active_directory: false
          base: 'OU=sdasdasd'
          user_filter: '(&(objectClass=*)(uid=%uid))'
      EOS
```

Запускаем наш контейнер с gitlab и ждем примерно 5 минут (столько времени нужно для его полной загрузки):

```bash
docker compose up -d
```

После поднятия гитлаба переходим в браузере по ссылке [https://gitlab.digital-skills.ga ](https://gitlab.digital-skills.ga) Откроется страница входа на gitlab:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/X8Nimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/X8Nimage.png)

Для просмотра пароля можно перейти в контейнер и найти файл **/etc/gitlab/init\_root\_password.**

Сразу меняем пароль от root:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/UgLimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/UgLimage.png)

Можно поменять и логин на gitadmin:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/cKmimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/cKmimage.png)

После смены данных нас перебросит на стартовую страницу входа. Нужно залогиниться.

Далее необходимо создать новый проект:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/Ndhimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/Ndhimage.png)

Выбираем пустой проект:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/EgQimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/EgQimage.png)

Задаем следующие параметры:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/Ao1image.png)](https://atomskills.space/uploads/images/gallery/2022-09/Ao1image.png)

После нажатия Create project проект создастся и откроется:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/Fgzimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/Fgzimage.png)

Далее идём в Settings -&gt; CI/CD:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/ZG3image.png)](https://atomskills.space/uploads/images/gallery/2022-09/ZG3image.png)

Находим Runners и нажимаем Expand:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/0qUimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/0qUimage.png)

##### Настройка Container Registry

<address id="bkmrk-%D0%9F%D0%B5%D1%80%D0%B5%D1%85%D0%BE%D0%B4%D0%B8%D0%BC-%D0%B2-packages">Переходим в **Packages and registries -&gt; Container Registry**:</address><address id="bkmrk-%D0%9E%D1%82%D0%BA%D1%80%D0%BE%D0%B5%D1%82%D1%81%D1%8F-%D1%81%D1%82%D1%80%D0%B0%D0%BD%D0%B8%D1%86%D0%B0-c">[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/6Tmimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/6Tmimage.png)

Откроется страница c Container Registry:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/oCeimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/oCeimage.png)

Возвращаемся в терминал и логинимся в наш container registry (нужно будет ввести логин и пароль):

```bash
docker login cr.digital-skills.ga
```

Создадим тестовый Dockerfile, попробуем его собрать и загрузить в наш Registry:

```
# Dockerfile
FROM scratch
COPY ./test.txt /test.txt

# Выполняем сборку нашего проекта
docker build -t cr.digital-skills.ga/gitlab-instance-3c32bf0e/developing .

# Заливаем его в docker registry
docker push cr.digital-skills.ga/gitlab-instance-3c32bf0e/developing
```

При успешной загрузке образа в хранилище его можно будет увидеть:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-09/scaled-1680-/RFTimage.png)](https://atomskills.space/uploads/images/gallery/2022-09/RFTimage.png)

</address>