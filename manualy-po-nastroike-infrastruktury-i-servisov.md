# Мануалы по настройке инфраструктуры и сервисов

Раздел посвящен настройке инфраструктуры и сервисов в общем виде (то есть как мануалы)

# Wireguard VPN

##### **Установка Wireguard**

apt install -y wireguard

##### **Генерация ключей**

Необходимо на каждом из роутеров сгенерировать приватный и публичный ключи.

Выполняем следующую команду:

`wg genkey | tee srvprivkey | wg pubkey | tee srvpubkey` - выполняем на сервере

`wg genkey | tee clprivkey | wg pubkey | tee ckpubkey` - выполняем на клиенте

Далее необходимо скопировать публичный ключ сервера на клиент и записать его в будущий конфиг:

`scp srvpubkey root@2.2.2.2:/root/`

После переноса публичного ключа на роутер филиала записываем последовательно в конфиг приватный ключ клиентского роутера и публичный ключ сервера:

`cat clprivkey >> /etc/wireguard/wgvpn.conf`

`cat srvpubkey >> /etc/wireguard/wgvpn.conf`

И в самом конфиге пишем:

```shell
[Interface]
Address = 192.168.1.2/24	
PrivateKey = <приватный ключ клиента>

[Peer]
PublicKey = <публичный ключ сервера>
Endpoint = 1.1.1.2:51820 # внешний адрес сервера
AllowedIPs = 10.0.0.0/8, 192.168.1.0/24 # AllowedIPs - адреса или диапазоны сетей, которые имеют право отправлять трафик в туннель
```

Далее необходимо добавить интерфейс wgvpn в автозагрузку и включить его:

`<span class="hljs-attribute">systemctl</span> enable --now wg-quick@wgvpn`

Командной wg show необходимо посмотреть используемый порт на клиенте:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-10/scaled-1680-/iEEimage.png)](https://atomskills.space/uploads/images/gallery/2022-10/iEEimage.png)

Так как этот порт будет меняться после каждой перезагрузке Wireguard, то лучше зафиксировать порт статически. Для этого добавим в предыдущий конфиг строчку:

```
[Interface]
Address = 192.168.1.2/24	
PrivateKey = <приватный ключ клиента>
ListenPort = <указать порт>

[Peer]
PublicKey = <публичный ключ сервера>
Endpoint = 1.1.1.2:51820 # внешний адрес сервера
AllowedIPs = 10.0.0.0/8, 192.168.1.0/24 # AllowedIPs - адреса или диапазоны сетей, которые имеют право отправлять трафик в туннель
```

После этого копируем публичный ключ клиента на сервер:

`scp clpubkey root@1.1.1.2:/root/`

Копируем приватный ключ сервера и публичный ключ клиента в конфиг:

`cat srvprivkey >> /etc/wireguard/wgvpn.conf`

`cat clpubkey >> /etc/wireguard/wgvpn.conf`

В самом конфиге пишем следующее:

```shell
[Interface]
Address = 192.168.1.1/24
PrivateKey = <приватный ключ сервера>
ListenPort = 51820 # дефолтный порт для сервера

[Peer]
Endpoint = 2.2.2.2:<порт клиента> (в нашем примере 41034)
PublicKey = <публичный ключ клиента>
AllowedIPs = 192.168.1.2/32, 10.10.30.0/24,10.10.40.0/24 # в AllowedIPs указываем адрес интерфейса филиала и сеть за ним
PersistentKeepalive = 5 # проверка соединения через 25 секунд
```

Добавляем интерфейс в автозагрузку и поднимаем его:

`<span class="hljs-attribute">systemctl</span> enable --now wg-quick@wgvpn`

После этого команда `wg show` должна отобразить состояние интерфейса и показать проходит ли трафик:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-10/scaled-1680-/oj4image.png)](https://atomskills.space/uploads/images/gallery/2022-10/oj4image.png)

Пинг до подсетей должен идти в обе стороны:

С центрального офиса в филиал:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-10/scaled-1680-/oS0image.png)](https://atomskills.space/uploads/images/gallery/2022-10/oS0image.png)

Из филиала в центральный офис:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-10/scaled-1680-/UXzimage.png)](https://atomskills.space/uploads/images/gallery/2022-10/UXzimage.png)

На этом настройка Wireguard закончена.

# Центр Сертификации

 **Перед настройкой центра сертификации необходимо настроить синхронизацию времени!**

#### **Корневой ЦС**

Делается при помощи пакета `openssl-perl`

В Astra Linux пакет есть по умолчанию как и в большинстве других дистрибутивов.

Открываем файл `/etc/ssl/openssl.cnf`, находим там директиву `[ CA_default ]`, в ней находим переменную dir и меняем ее на директорию, где будет находится наш CA. Там же находим policy, её меняем на policy\_anything.

```shell
[ CA_default ]

dir = ./demoCA  		# Меняем demoCA на что-нибудь свое. Точки в начале быть не должно
policy = policy_match 	# Меняем на policy_anything
copy_extensions = copy 	# Расскомментируем
```

Дальше ищем `[ req_distinguished_name ]`. Там меняются параметры запроса по умолчанию. Если надо - меняем.

```shell
[ req_distinguished_name ]

countryName_default = AU 								# Страна по умолчанию
stateOrProvinceName_default = Some-State 				# Область или штат
0.organizationName_default = Internet Widgits Pty Ltd 	# Организация
```

Если мы хотим создать подчиненный CA, то надо так же изменить параметры в секции `[ req ]` и `[ v3_req ]`.

Потом нужно поменять всё обратно

```shell
[ req ]

# reg_extensions = v3_req 		# Раскомментировать
[ v3_req ]
basicConstraints = CA:FALSE 	# Меняем FALSE на TRUE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment, keyCertSign # добавляем keyCertSign (без него у меня не работало)
```

Дальше идем в `/usr/lib/ssl/misc` и работаем со скриптом CA.pl. Для начала надо найти там переменную `$CATOP` и поменять ее на такое же значение как у `dir` в `openssl.cnf`.

После этого можно создавать центр сертификации и выпускать сертификаты

```
./CA.pl -newca			 	# Создать центр сертификации
./CA.pl -newreq-nodes 		# Создать запрос без шифрования приватного ключа (Если выпускаем серт для веб-сервера)
./CA.pl -newreq 			# Создать запрос с шифрованием приватного ключа (Если выпускаем серт для центра сертификации)
./CA.pl -sign 				# Подписываем запрос
```

`./CA.pl -newca` - после этого в указанном ранее каталоге должны появиться все нужные файлы.

#### **Подчиненный ЦА**

Чтобы создать подчиненный центр сертификации необходимо:

1. Выписываем на него сертификат.  
    Нужно сгенерировать запрос на сертификат` /usr/lib/ssl/misc/CA.pl -newreq`и заполнить данные как просят в задании (если нету, то на свое усмотрение).
    
    После этого нужно подписать сертификат командной `/usr/lib/ssl/misc/CA.pl -signCA`. Лучше сразу добавить корневой сертификат в траст, чтобы проверить, что выпущенный сертификат является доверенным. Для добавления в доверенные копируем корневой сертификат ca.crt в `/usr/local/share/ca-certificates `и выполняем команду `update-ca-certificates.`   
    Затем проверяем, что сертификат успешно проходит проверку командной `openssl verify <имя сертификата>`
2. Настраиваем машину с подчиненным CA также, как настраивали Корневой
3. Выписанный сертификат и ключ передаем на машину и кладем в `/usr/lib/ssl/misc`
4. Идем туда, выполняем `CA.pl -newca`. Когда он предложит ввести имя файла или нажать Enter - вводим имя сертификата, который мы выписали.  
    **Почему-то иногда он криво импортирует. Если так произошло, то руками кладем приватный ключ и файл serial (можно забрать с рута)**

#### **Трасты**

1. Копируем root и sub сертификаты в директорию `/usr/local/share/ca-certificates` на каждой машине (**обязательно расширение .crt**)
2. Выполняем команду `update-ca-certificates`
3. Выполняем команду `openssl verify /usr/local/share/ca-certificates/название рута`,
4. Чиним firefox. Для этого делаем `rm -rf /usr/lib/firefox/libnssckbi.so`
5. Потом делаем `/usr/lib/x86_64-linux-gnu/pkcs11/p11-kit-trust.so` /usr/lib/firefox/libnssckbi.so

#### **Альты**  


Сначала создаем примерно такой конфиг в папке `/usr/lib/ssl/misc`. Называем его, например, `req.cnf`.

```shell
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C=AU
ST=Some-State
OU=OU
CN=mail.ht22.local	# Тут пишем реальный CN домена, для которого будет сертификат

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ] # тут обязательн прописываем какие-нибудь альты
DNS.1 = mail.ht22.local
DNS.2 = ht22.local
DNS.3 = www.ht22.local
```

Дальше генерируем запрос с помощью команды:

`openssl req -new -sha256 -nodes -out newreq.pem -newkey rsa:2048 -keyout newkey.pem -config /usr/lib/ssl/misc/req.cnf`

Названия надо соблюсти такие, чтобы CA.pl отработал.

Дальше делаем `CA.pl -sign`

После этого проверяем сертификаты командной `openssl verify <имя сертификата>`. Если всё успешно, то раскидываем сертификаты на все хосты.

# SQUID Proxy

#### **Настраиваем SQUID Proxy**

##### **База**

Конфигурацию squid можно разделить на три части:

1. Настройка самого squid;
2. Настройка ACL;
3. Настройка правил доступа

##### **Настройка Squid**

Тут мы будем подключать внешние плагины и настраивать порт, который должен слушать squid.

Порт настраивается через параметр в конфиге` http_port 0.0.0.0:3128`. Вместо нулей можно указать адрес конкретного интерфейса.

##### **Какие бывают ACL**

Формат написания примерно такой: `acl ИМЯ ТИП ПАРАМЕТРЫ`

```shell
# ACL, которая контролирует по каким портам можно или нельзя ходить
acl GoodPorts port 80 443 8080 9090
acl BadPorts port 3099 4098

# ACL, которая контролирует по каким протоколам можно или нельзя ходить
acl BadProto proto HTTP FTP

# ACL, которая контролирует, каким адресам можно или нельзя ходить
acl GoodHost src 10.10.1.10/32
acl BadHost src 10.10.1.11/32
acl GoodSubnet src 10.10.1.0/24
acl BadSubnet src 10.10.10.0/24

# ACL, которая контролирует до каких адресов можно ходить
acl GoodDest dst 8.8.8.8
acl BadDest dst 9.9.9.9

# ACL, которая контролирует по каким доменным именам можно ходить
acl GoodSites dstdomain yandex.ru google.com
acl BadSites dstdomain vk.com

# ACL, которая контролирует во сколько можно или нельзя ходить
acl WORKDAY time 06:00-18:00
```

##### **Конфигурация правил доступа**

Просто комбинация ACL:

```shell
http_access allow GoodPorts 		# Разрешаем холить по ACL GoodPorts
http_access allow BadHost BadPorts	# Разрешаем хоступ с адресом из acl BadHost ходить на порты из acl BadPorts
http_access allow GoodHost BadPorts BadProto	# Разрешаем доступ из acl GoodHost ходить на порты из acl BadPorts по протоколам из acl BadProto
http_access allow BadHost GoodPorts BadSites WORKDAY	# Разрешаем хосту BadHost ходить на сайты BadSites только во время WORKDAY и только по GoodPorts
http_access deny all
```

##### **Базовая аутентификация**

```shell
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/pass # Подключаем плагин для базовой аутентификации и указываем ему базу с юзера
auth_param basic realm squid # Имя реалма
acl auth proxy_auth REQUIRED # ACL, которая говорит, что нужна аутентификация
http_access allow auth # Пускаем только прошедших аутентификацию
```

Это что касается конфига squid. Надо добавить еще пользователей:

```shell
apt install -y apache2-utils # Ставим htpasswd
htpasswd -c /etc/squid/pass user1 # Добавляем пользователя в базу
```

##### **LDAP аутентификация**

**Сначала проверить пути через ldapsearch -x на Ldap сервере**

```shell
# Подключаем LDAP (обазательный конфиг)
auth_param basic program /usr/lib/squid/basic_ldap_auth -d -b "dc=wsr,dc=local" -D "uid=admin,cn=users,cn=compat,dc=wsr,dc=local" 
-w P@ssw0rd -f  uid=%s 10.10.1.10
auth_param basic realm squid
auth_param basic children 5

# Подклчюаем LDAP группы, если нужно
external_acl_type ldapgroup %LOGIN /usr/lib/squid/ext_ldap_group_acl -b "dc=wsr,dc=local" -D "uid=admin,cn=users,cn=compat,dc=wsr,dc=local"
-w P@ssw0rd -f (&(memberOf=cn=%g,cn=groups,cn=accounts,dc=wsr,dc=local)(uid=%u)) 10.10.1.10

# Пишем ACL
acl auth proxy_auth REQUIRED # говорим, что аутентификация нужна
acl ldapgroup-proxy external ldapgroup groupname # опционально определяем groupnme

# Пишем правила доступа
http_access allow auth # любому пользователю, прошедшему аутентификацию пользователя
http_access allow auth ldapgroup-proxy # можно только тем, кто состоит в группе groupname
```

##### **Kerberos аутентификация**

**Обязательно должен работать DNS, либо костыли через hosts. Прокси конфигурируется не по адресу, а по DNS-имени**

1. Добавляем сервер со squid в домен
2. На FreeIPA сервере добавляем принципал ipa service-add HTTP/squid.domain.name
3. На squid сервере получаем keytab ipa-getkeytab -s squid.domain.name -p HTTP/squid.domain.name -k /etc/squid/keytab
4. Назначаем на кейтаб права chown proxy:proxy /etc/squid/keytab
5. Пишем конфигурацию squid:

```shell
# подклчюаем плагин, где указываем keytab (-k) и принципал (-s)
auth_param negotiate program /usr/lib/squid/negotiate_kerberos_auth -d -k /etc/squid/keytab -s HTTP/ca-rtr.wsrs.local 
auth_param negotiate children 5
auth_param negotiate keep_alive on

acl auth proxy_auth REQUIRED # acl для аутентификации
http_access alllow auth # можно только аутентифицированным
```

##### **Пример готовой настройки**

```shell
http_port 0.0.0.0 3128

dns_nameservers 10.10.10.10 #Адрес DNS-сервера в локальной сети
#LDAP

auth_param basic program /usr/lib/squid/basic_ldap_auth -d -b "dc=ht22,dc=win" -D "uid=admin,cn=users,cn=compat,dc=ht22,dc=win" -w P@ssw0rd -f uid=%s 10.10.10.10
auth_param basic realm squid #Взято из официальной документации
auth_param basic children 5 #Взято из официальной документации

acl whitelist dstdomain .yandex.ru .ya.ru .google.com .ht22.local #Точки в начале важны. .ht22.local - локальный домен
acl http proto http
acl port_80 port 80
acl port_443 port 443
acl CONNECT method CONNECT #Необходимо для https
acl auth_users proxy_auth REQUIRED

http_access allow http port_80 whitelist
http_access allow CONNECT port_443 whitelist #Данная конструкция взята из документации

http_access allow http port_80 auth_users
http_access allow CONNECT port_443 auth_users

http_access deny all #Необходимо прописать, так как неявного deny не подразумевается
```

# Почта Postfix

##### **Подготовка сервера к установке Postfix**

Первым делом необходимо подключить репозитории **Debian 9**.

Для этого устанавливаем пакет `debian-archive-keyring`:

```shell
apt install -y debian-archive-keyring
echo "deb https://mirror.yandex.ru/debian stretch main contrib non-free" >> /etc/apt/sources.list
apt update
```

еред вводом в домен необходимо отредактировать файлы hostname, hosts и resolv.conf:

```shell
# файл hostname
hq-mail.ht22.local

# файл hosts
10.10.10.20	hq-mail.ht22.local	hq-mail

# файл resolv.conf
search ht22.local
domain ht22.local
nameserver 10.10.10.10
```

Для ввода в домен необходимо установить пакет astra-freeipa-client:

`apt install -y astra-freeipa-client`

После установки перезагружаем сервер.

##### **Ввод сервера в домен**

Вводим сервер в домен с помощью команды astra-freeipa-client (вводим пароль админа), ждем пока завершится ввод в домен и убеждаемся, что доменные пользователи могут входить на сервер (команда `login`).

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/image.png)](https://atomskills.space/uploads/images/gallery/2022-11/image.png)

##### **Postfix**

Устанавливаем пакеты `postfix и dovecot-imapd`:

```shell
apt install -y postfix dovecot-imapd
```

Во время установки postfix откроется визард - в нем можно оставить всё по умолчанию. После установки запускаем `dpkg-reconfigure postfix`. Задаем следующие значения:

1. Выбираем "Интернет сайт"
2. Системное почтовое имя ставим ваш домен (например, wsr.local)
3. Получателя почты для root и postmaster можно не указывать
4. В других адресатах обязательно должен быть домен и localhost
5. Синхронные обновления почтовой очереди - нет
6. В локальных сетях указываем наши подсети, где будет работать почта и 127.0.0.1
7. Дальше все параметры по умолчанию

Идем в `/etc/postfix/main.cf` :

```shell
# Меняем пути к сертификатам на свои
smtpd_tls_cert_file=/root/newcert.pem
smtpd_tls_key_file=/root/newkey.pem
```

##### **Dovecot**

Идем в` /etc/dovecot/conf.d/10-auth.conf` :

```shell
disable_plaintext_auth = no 	# раскомментируем и пишем no
auth_mechanism = plain login 	# дописываем в конец login
```

Далее идем в `/etc/dovecot/conf.d/10-master.conf` :

```shell
# Находим там вот это и раскомментируем
# Postfix smtp-auth
  unix_listener /var/spool/postfix/private/auth {
  	mode = 0666
    user = postfix	# дописали
    group = postfix # дописали
```

Потом идем в `/etc/dovecot/conf.d/10-mail.conf` :

`mail_location = mbox:/var/mail/mbox/%u:INBOX=/var/mail/$u # Меняем mbox на /var/mail/mbox`

**Не забываем потом создать папку` /var/mail/mbox` и дать на `/var/mail` права 777:**

`chmod 777 -R /var/mail/`

Потом идём в /etc/dovecot/conf.d/10-ssl.conf :

```shell
ssl = yes		# Раскомментировали, сделали yes

# Раскомментировали, написали пути к серту и ключу. < в начале обязательно!!!
ssl_cert = </root/newcert.pem
ssl_key = </root/newkey.pem
```

Делаем `systemctl restart postfix dovecot `и базовая почта готова.

##### **Создание DNS-записей**

Идём во FreeIPA в раздел с DNS и добавляем сначала A-запись нашего почтового сервера:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/nHnimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/nHnimage.png)

После этого нужно создать MX-запись для нашей почты. Заходим в запись @ и добавляем в MX:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/AXOimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/AXOimage.png)

Если сделать nslookup или host на адрес домена, то должно быть следующее:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/344image.png)](https://atomskills.space/uploads/images/gallery/2022-11/344image.png)

##### **Проверка работы почты через Thunderbird**

# Хранилище CEPH

#### **Настраиваем CEPH**

В минимальной конфигурации CEPH имеет смысл собирать на трех нодах. В примере, это будут машины CA-FS, CA-MAIL и CA-MON.

#### **Требования к стенду**

На момент создания CEPH вы должны иметь настроенную сетевую связность, настроенный SSH-сервер между всеми хостами, синхронизированное одинаковое время. Для удобства можно разблокировать пользователя root на Astra Linux и по SSH подключаться именно через него.

В инфраструктуре CEPH будет устройство-контроллер (в нашем случае CA-FS) и подчиненные устройства CA-MAIL, CA-MON.

**Имена машин должны быть только через маленькие буквы!!!**

Все работы выполняются на CA-FS, так как именно он управляющее устройство для CEPH

#### **База**

На машинах CA-FS, CA-MAIL, CA-MON, если нет DNS-сервера, проще всего настроить /etc/hosts. Формат:

```
10.10.1.11 ca-fs
10.10.1.12 ca-mon
10.10.1.13 ca-mail
```

##### **Установка ceph-deploy**

На CA-FS устанавливаем ceph-deploy:

`apt install -y ceph-deploy`

##### **Подготовка SSH-инфраструктуры**

На CA-FS из-под пользователя root:

```shell
ssh-keygen
ssh-copy-id root@ca-fs
ssh-copy-id root@ca-mon
ssh-copy id root@ca-mail
```

После этого необходимо выполнить проверку, что с CA-FS возможно попасть на все машины в кластере по SSH без указания пароля только через ssh-ключи.

##### **Установка CEPH-компонентов**

На CA-FS из-под пользователя root:

`ceph-deploy --username root install --mon --osd --mgr ca-fs ca-mail ca-mon`

##### **Сборка кластера CEPH**

`ceph-deploy --username root new ca-fs ca-mail ca-mon`

##### **Инициализация демона-мониторинга CEPH**

На CA-FS из-под пользователя root:

`ceph-deploy --username root mon create-initial`

##### **Установка менеджера кластера CEPH**

На CA-FS из-под пользователя root:

`ceph-deploy --username root mgr create ca-fs ca-mail ca-mon`

На этом этапе нужно добавить диски к виртуалкам. По 1 диску по 5 Гб.

Через команду` fdisk -l `можно узнать какое имя получил новый диск.

##### **Создание OSD (Object Storage Devices) - основное устройство хранения в CEPH**

На CA-FS из-под пользователя root:

```shell
ceph-deploy --username root osd create --data /dev/sdb ca-fs
ceph-deploy --username root osd create --data /dev/sdb ca-mail
ceph-deploy --username root osd create --data /dev/sdb ca-mon
```

##### **Установка инструментов управления CEPH-CLI**

Команда устанавливает на хосты инструменты монтирования и работы с CEPH, как клиент:

`ceph-deploy --username root install --cli ca-fs ca-mon ca-mail`

##### **Окончательная настройка CEPH, перенос конфигурационных файлов в /etc/ceph**

```shell
ceph-deploy --username root admin ca-fs
ceph-deploy --username root admin ca-mon
ceph-deploy --username root admin ca-mail
```

Проверка работы

При вводе команды `ceph -s` должен вывести отчет о собранном кластере. Если выдает ошибку, то нужно повторить команду выше на машине, где не работает.

```shell
ceph mon stat
ceph mon dump
```

##### **Создание пула хранилища**

`ceph osd pool create wsr 128`

##### **Создание пула в формате cephfs**

`ceph osd pool application enable wsr cephfs`

##### **Включение WEB-интерфейса для мониторинга**

`ceph mgr module enable dashboard`

После включения на машине, где ввели команду (вероятнее всего CA-FS), откроется порт 7000. Заходить через браузер.

##### **Установка MDS (сервера метаданных)**

`ceph-deploy --username root mds create ca-fs`

##### **Создание пула метаданных**

```shell
ceph osd pool create wsr_metadata 64
ceph fs new cephfs wsr_metadata wsr
```

**Готово!**

##### **Как примонтировать кластер к машине**

`cat ceph.client.admin.keyring | grep key > admin.secret`

Затем в файле удалите все лишнее, оставив только ключ, без опций и прочих параметров. Чисто ключ!

Передайте полученный файл на сервер, где планируете монтировать ресурс (например, на сервер NFS)

`mount -t ceph ca-fs, ca-mon, ca-mail:/ /mnt -o name=admin,secretfile=admin.secret`

Ресурс будет примонтирован! Если ресурс не монтируется:

1. Проверить, что на машине есть инструменты работы с CEPH, для монтирования нужен ceph-common. Доступен через apt;
2. Монтировать можно и по ip-адресам, не обязательно по DNS. Проверить работу DNS, если не монтируется

Для того, чтобы добавить его в автомонтирование в fstab нужно написать:

`ca-fs,ca-mon,ca-mail: /mnt ceph name=admin,secretfile=/root/admin.secret,x-systemd.automount,x-systemd.mount-timeout=10 0 0`

Далее перезагрузка (перед этим не забыть поставить пароль на root). Ресурс, вероятно, примонтируется не мгновенно. Это нормально.

# Домен на FreeIPA

##### **Подготовка сервера**

Перед установкой и настройкой Freeipa необходимо выполнить подготовку сервера. Нужно настроить файл hosts, имя сервера, отключить и замаскировать службу NetworkManager, создать и настроить файл /etc/resolv.conf

Редактируем hostname:

`hostnamectl set-hostname dc.ht22.local`

Редактируем файл hosts в такой формат:

&lt;ip сервера&gt; &lt;FQDN&gt; &lt;shortname&gt;

[![image.png](https://atomskills.space/uploads/images/gallery/2022-10/scaled-1680-/HZmimage.png)](https://atomskills.space/uploads/images/gallery/2022-10/HZmimage.png)

Также необходимо замаскировать службу NetworkManager и отключить её, иначе будут конфликты со службой networking:

`systemctl mask NetworkManager`

`systemctl disable NetworkManager`

После отключения службы создаем файл resolv.conf в /etc и пишем следующее:

```shell
search ht22.local
domain ht22.local
```

После этого перезагружаем сервер. Подготовка к установке и настройке FreeIPA успешно выполнена.

##### **Установка и настройка astra-freeipa-server**

Установка FreeIPA занимает несколько минут. В процессе нужно несколько раз подтвердить действия. Установка выполняется командой:

`apt install -y astra-freeipa-server`

После установки необходимо повысить сервер до контроллера домена. Сделать это можно, введя команду `astra-freeipa-server install` без параметров. Все нужные параметры он подберет сам. Либо можно воспользоваться командой `astra-freeipa-server install -d ht22.local -o -i 10.10.10.10 `(-d - имя домена, -o - изолированная сеть, -i - ip-адрес интерфейса).

После этого проверяем конфигурацию и вводим пароль администратора [P@ssw0rd](mailto:P@ssw0rd). После 5 минут ожиданий выйдет сообщений об успешной настройке FreeIPA.

##### **Вход в веб-интерфейс и работа с FreeIPA**

Для входа в веб-интерфейс управления FreeIPA нужно открыть Firefox и ввести [https://dc.ht22.local](https://dc.ht22.local). Вылезет окно о том, что нет доверия сертификата. Это нормально, так как Firefox по умолчанию не умеет забирать сертификаты из корневого хранилища.

[![image.png](https://atomskills.space/uploads/images/gallery/2022-10/scaled-1680-/goCimage.png)](https://atomskills.space/uploads/images/gallery/2022-10/goCimage.png)

##### **Создание пользователей**  


У FreeIPA есть особенность при создании учетных записей пользователей через веб-интерфейс. Срок действия пароля заканчивается очень быстро. Скорее всего сделано с целью безопасности, чтобы пользователь сразу же менял свой пароль при входе в домен (команда login). Чтобы не логиниться под каждым юзером для смены пароля, можно создавать учетки с помощью терминала.

Для этого вводим следующую команду:

```shell
ipa user-add anivanov--first "Anton" --last "Ivanov" --cn "Anton Ivanov" --displayname "Anton Ivanov" --password-expiration=20221130000000Z --password
```

Будет предложено ввести пароль в интерактивном режиме с подтверждением. Вводим стандартный [P@ssw0rd](mailto:P@ssw0rd). В итоге получим такую картину:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-10/scaled-1680-/7Zfimage.png)](https://atomskills.space/uploads/images/gallery/2022-10/7Zfimage.png)

После этого в веб-интерфейсе можно посмотреть свойства учетной записи, где будет указано, когда истекает пароль УЗ:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-10/scaled-1680-/tukimage.png)](https://atomskills.space/uploads/images/gallery/2022-10/tukimage.png)

##### **Список пользователей FreeIPA**

Можно вывести список пользовательских аккаунтов FreeIPA с помощью команды `ipa-user-find`.

Для вывода всех имеющихся аккаунтов можно использовать простую команду:

```
ipa user-find --all
```

Для вывода определенного аккаунта:

```shell
ipa user-find USERNAME
```

Пример:

```
ipa user-find jdoe
```

LДопонительно можно посмотреть в справке**`ipa user-find --help`**.

##### **Редактирование учетных записей FreeIPA**

Для изменения атрибутов пользователя необходимо использовать команду`ipa`` user-mod`<span class="ezoic-ad ezoic-at-0 leader-4 leader-4110 adtester-container adtester-container-110" data-ez-name="kifarunix_com-leader-4"><span class="ezoic-ad" id="bkmrk--3"></span></span>

Например, можно вот так изменить параметр shell для пользователя:

```shell
ipa user-mod USERNAME --shell=/bin/bash
```

**USERNAME** это логин пользователя.

Для просмотра остальных атрибутов необходимо ввести команду**`ipa user-mod --help`**.

Для удаления пользователя можно использовать команду **`ipa user-del`**

```shell
ipa user-del USERNAME
```

# DNS Bind9



# DHCP



# OpenConnect



# OpenVSwitch

#### **Настраиваем OpenVSwitch**

##### **Установка в Astra Linux**

```shell
apt install debian-archive-keyring # для возможности подключения старых debian репозиториев
echo "deb https://mirror.yandex.ru/debian stretch main contrib non-free" >> /etc/apt/sources.list # добавляем debian 9 репозиторий
apt update # обновляем список пакетов
apt install -y openvswitch-switch # Устанавливаем openvswitch
systemct enable openvswitch-switch # добавлявем в автозагрузку ovs
```

#### **Работаем с OpenVSwitch**

**Так как коммутация отдается openvswitch - на гипервизоре создаем отдельную порт-группу под каждый адаптер свитча (портгруппы = провода)**

##### **Работаем с интерфейсами**

```shell
ovs-vsctl add-br BR1 # добавляем в ovs новый бридж BR1
ovs-vsctl add-port BR1 eth1 # добавлявем в бридж интерфейс eth1. остальные добавляются по аналогии
ovs-vsctl set port BR1 eth1 tag = 10 # добавляем на интерфейс тегирование (порт во vlan)
ovs-vsctl set port BR1 eth1 trunks=10,20,30 # делаем порт транковым, разрешенные вланы через запятую
```

##### **Настройка STP/RSTP**

Для включения stp/rstp необходимо выполнить одну из следующих команд:

```shell
ovs-vsctl set bridge BR1 stp_enable=true # включаем stp
ovs-vsctl set bridge BR1 rstp_enable=true # включаем rstp
```

Отключается заменой true на false.

В Astra Linux OpenVSwitch слишком старый, поэтому команды `ovs-appctl stp/show` или `ovs-appctl rstp/show` нет.

Настройка LACP/Статическое аггрегирование

```shell
ovs-appctl bond/show -- проверяем, что всё работает
```

Транки настраиваются как на портах, т.е. `ovs-vsctl set port BR1 bond0 trunks=10,20,30`

##### **Роутер на палочке**

На RTR сначала делаем systemctl mask NetworkManager и перезагружаемся

Потом идем в `/etc/network/interfaces`

Пример конфига ниже:

```shell
auto eth0
iface eth0 inet manual

# VLAN 10
auto eth0.10
iface eth0.10 inet static
	address 10.10.10.1/24
    
 auto eth1
 iface eth1 inet manual
 
 # VLAN 20
 auto eth1.20
 iface eth1.20 inet static
 	address 10.10.20.1/24
```

После этого делаем `systemctl restart networking`.

##### **Команды для удаления конфигурации**

```shell
ovs-vsctl del-port eth1 # удалить порт
ovs-vsctl del-port bond0 # удалить бонд
ovs-vsctl del-br BR # удалить бридж
```

# Автоматизация с Ansible



# Автоматизация с Puppet

##### **Коррекция региональных настроек (locales) на сервере**

Проверить наличие региональной настройки **en\_US.utf8** выполнив команду:

```shell
locale -a | grep en_US.utf8
```

Если региональной настройки **en\_US.utf8** нет, то добавить её, выполнив следующие команды

```shell
echo "en_US.UTF-8 UTF-8" | tee -a /etc/locale.gen
locale-gen
```

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/SxVimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/SxVimage.png)

##### **Установка и настройка сервера Puppet**

Первым делом необходимо расширить ОЗУ на сервере хотя бы до 4гб, так как puppet требует больше 2 ГБ ОЗУ.

<p class="callout info">Расчёт памяти определяется 150 узлов = 1 ГБ</p>

Затем задать hostname и прописать в файле hosts полные доменные имена сервера.

Так же открываем порт 8140 на фаерволле:

```shell
ufw allow 8140
```

Выполняем установку пакета puppetserver. С ним автоматически подтянутся все необходимые пакеты:

```shell
apt install -y puppetserver
```

Для указания агенту puppet на сервере редактируем файл `/etc/puppetlabs/puppet/puppet.conf`. Добавляем \[main\] секцию над секцией \[master\]:

```shell
[main]
server = puppet # puppet - dns имя сервера
```

Разрешаем автоматический запуск Puppet Server и запускаем его:

```shell
systemctl enable puppetserver
systemctl start puppetserver
```

Проверить работу агента можно командой:

```shell
/opt/puppetlabs/bin/puppet agent --test
```

В результате всё должно быть зелёным:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/lgfimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/lgfimage.png)

##### **Установка и настройка агента Puppet**

Устанавливаем пакет puppet-agent:

```shell
apt install –y puppet-agent
```

 Для указания агенту puppet на сервер редактируется файл `/etc/puppetlabs/puppet/puppet.conf`. Добавляем следующие строчки:

```shell
[agent]
server = puppet	# puppet - dns имя сервера puppet
```

После этого запускаем puppet и добавляем его в автозагрузку:

```shell
systemctl start puppet
systemctl enable puppet
```

Командой `systemct status puppet` можно убедиться, что служба запущена и всё в порядке:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/zxCimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/zxCimage.png)

##### **Настройка удаленного доступа по протоколу ssh на клиентской машине**

Для настройки доступа к клиентской машине по протоколу ssh:

1. Создать отдельного пользователя с домашним каталогом:
    
    ```shell
    useradd -m <имя_пользователя>
    ```
    
    <p class="callout info">опция -m указывает на необходимость создания домашнего каталога. Далее выбранное имя пользователя должно быть указано реестре клиентских машин на сервере (файле /etc/ansible/hosts);</p>
2. Задать пароль для этого пользователя:
    
    ```shell
    passwd <имя_пользователя>
    ```
3. Разрешить пользователю выполнять команды с использованием sudo. Это можно сделать создав файл `/etc/sudoers.d/<имя_пользователя>` с указанием привилегии выполнять любые команды без запроса пароля ALL=NOPASSWD: ALL:
    
    ```shell
    echo "<имя_пользователя>   ALL=NOPASSWD:   ALL" | tee -a /etc/sudoers.d/<имя_пользователя> 
    ```
    
    <p class="callout info">Часто предлагаемый для упрощения вариант использования на клиентской машине пользователя root является нежелательным с точки зрения безопасности. При использовании этого варианта помимо задания пароля для пользователя root необходимо разрешить доступ пользователю root через ssh. Для включения доступа root через ssh в файле /etc/ssh/sshd\_config раскомментировать параметр PermitRootLogin, изменить его значение на yes и перезапустить службу SSH (команды выполняются на клиентской машине):  
    </p>

```shell
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

##### **Подписание сертификатов клиента**

При первом запуске клиентская служба Puppet Agent отправит на Puppet Server запрос на подпись сертификата. Для просмотра списка запросов на подпись сертификата выполнить на сервере следующую команду:

```shell
/opt/puppetlabs/bin/puppetserver ca list
```

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/K5oimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/K5oimage.png)

В примере выше сервер сообщает, что у него имеется один запрос на подпись сертификата от клиента с именем br-rtr-1.ht22.local.

Подписать сертификат:

```shell
/opt/puppetlabs/bin/puppetserver ca sign --certname br-rtr-1.ht22.local
```

<div class="conf-macro output-inline" data-hasbody="true" data-macro-name="command" id="bkmrk-successfully-signed-">Successfully signed certificate request for br-rtr-1.ht22.local</div>[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/ihLimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/ihLimage.png)

Для проверки правильности работы агента можно на клиентской машине после подписания сертификата выполнить следующие команды:

1. Остановить службу
    
    ```shell
    systemctl stop puppet
    ```
2. Выполнить тестирование работы службы, в процессе которого служба запросит и получит сертификат:
    
    ```shell
    /opt/puppetlabs/bin/puppet agent --test
    ```
    
    При успехе вывод будет полностью зелёным:
    
    [![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/kF5image.png)](https://atomskills.space/uploads/images/gallery/2022-11/kF5image.png)
3. Повторно запустить службу:
    
    ```shell
    systemctl start puppet
    ```

##### **Установка пакетов Ansible и Foreman**

Выполняем установку пакета ansible из репозитория:

```shell
apt install  -y ansible
```

<div class="conf-macro output-inline" data-hasbody="true" data-macro-name="command" id="bkmrk-sudo-apt-install-ans"></div>##### **Настройка /etc/ansible/hosts**

Далее нужно отредактировать файл `/etc/ansible/hosts`, добавив в файл секцию \[agents\] (т.е. добавив группу серверов, с названием этой группы agents). В этой группе пока будет один сервер с именем br-rtr-1.ht22.local и IP-адресом 10.10.30.2.

```shell
echo -e "agents:\n hosts:\n  br-rtr-1.ht22.local:\n   ansible_user: ansible" | tee -a /etc/ansible/hosts
```

<div class="conf-macro output-inline" data-hasbody="true" data-macro-name="command" id="bkmrk--4"></div>В качестве значения параметра ansible\_user вместо &lt;имя\_пользователя&gt; должно быть указано имя пользователя, созданного на клиенте для удаленного доступа.  
В результате файл `/etc/ansible/hosts` должен иметь следующий вид (пользователь для уделенного доступа - username):

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/TCdimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/TCdimage.png)

<p class="callout info">В примере используется YAML-формат файла. Отступы (количество пробелов в начале строки) должны быть соблюдены. Использование символов табуляции не допускается.</p>

Ansible использует подключение ssh без запроса пароля по ключу, поэтому нужно сгенерировать ключ:

```shell
ssh-keygen -f ~/.ssh/id_rsa -N ''
```

<div class="conf-macro output-inline" data-hasbody="true" data-macro-name="command" id="bkmrk--6"></div>Ключ должен быть сгенерирован и передан от имени пользователя, от которого будут выполняться команды ansible. Если команды ansible предполагается выполнять от sudo, то генерировать и передавать ключ следует также от sudo (можно сгенерировать и передать ключи для нескольких пользователей ).

После создания ключа передать его на нужные узлы, подключаясь к ним от имени пользователя, созданного для удаленного доступа:

```shell
ssh-copy-id -i ~/.ssh/id_rsa ansible@br-rtr-1.ht22.local
```

<div class="conf-macro output-inline" data-hasbody="true" data-macro-name="command" id="bkmrk--7"></div>Проверить работу Ansible, выполнив пинг на группу серверов agents:

```shell
ansible -m ping agents
```

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/9Lsimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/9Lsimage.png)

##### **Базовая настройка Foreman**

В случае, если ОС была установлена без графической оболочки, установить пакет shared-mime-info, командой:

```shell
apt install -y shared-mime-info
```

<div class="conf-macro output-inline" data-hasbody="true" data-macro-name="command" id="bkmrk-sudo-apt-install-sha"></div>Затем установить пакет foreman-installer:

```shell
apt install -y foreman-installer
```

<div class="conf-macro output-inline" data-hasbody="true" data-macro-name="command" id="bkmrk-sudo-apt-install-for"></div>Перед выполнением дальнейших действий следует проверить, что в файле `/etc/debian_version` указано значение 9.0, и, если там указано иное значение, заменить его на 9.0.

Запускаем установку foreman с помощью команды `foreman-installer`. В результате выполнения должно выдать следующее сообщение:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/Wijimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/Wijimage.png)

<div class="conf-macro output-inline" data-hasbody="true" data-macro-name="command" id="bkmrk-sudo-foreman-install">При такой ошибке - нужно настроить локаль.</div>[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/5lJimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/5lJimage.png)

<p class="callout info">После установки в строке "Initial credentials are admin / ...." будет указан логин admin и указан автоматически созданный пароль для входа в web-интерфейс, его рекомендуется запомнить чтобы использовать для входа в web-интерфейс.В дальнейшем пароль возможно изменить с помощью команды:</p>

Foreman-rake permissions:reset username=admin password=&lt;новый\_пароль&gt;

<div class="confluence-information-macro confluence-information-macro-warning conf-macro output-block" data-hasbody="true" data-macro-name="warning" id="bkmrk-%D0%92-%D1%81%D1%82%D1%80%D0%BE%D0%BA%D0%B5-%22initial-cr"><div class="confluence-information-macro-body">В строке "Initial credentials are admin / ...." указан логин admin и указан автоматически созданный пароль для входа в web-интерфейс, его рекомендуется запомнить чтобы использовать для входа в web-интерфейс.</div></div>  
Проверить работоспособность foreman-proxy:

```shell
curl -k -X GET -H Accept:application/json https://foreman.ht22.local:8443/features --tlsv1
```

<div class="conf-macro output-inline" data-hasbody="true" data-macro-name="command" id="bkmrk-sudo-curl--k--x-get-">["httpboot","logs","puppet","puppetca","tftp"]</div><div class="conf-macro output-inline" data-hasbody="true" data-macro-name="command" id="bkmrk-%D0%94%D0%BB%D1%8F-%D0%B2%D1%85%D0%BE%D0%B4%D0%B0-%D0%B2-%D0%B2%D0%B5%D0%B1-%D0%B8%D0%BD%D1%82%D0%B5">Для входа в веб-интерфейс Foreman вводим ссылку [https://foreman.ht22.local](https://foreman.ht22.local). Должна открыться страница входа:</div><div class="conf-macro output-inline" data-hasbody="true" data-macro-name="command" id="bkmrk--11"></div>[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/uq0image.png)](https://atomskills.space/uploads/images/gallery/2022-11/uq0image.png)

Для входа используем логин admin и пароль, который был сгенерирован и выведен в терминал на сервере с foreman:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/Lvtimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/Lvtimage.png)

Переходим в "Узлы" - "All hosts" ("Hosts" -&gt; "All Hosts" в английском варианте), где должен появится список доступных узлов:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/P3kimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/P3kimage.png)

Видим доступный узел:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/cRIimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/cRIimage.png)

<p class="callout info">Если узлы отсутствуют, то подождать, пока информация обновится, или на нужных узлах (на клиенте) выполнить команду `systemctl restart puppet`, после чего обновить страницу web-интерфейса.</p>

Убедиться, что в "Инфраструктура" - "Капсулы" ( в английском варианте "Infrastructure" -&gt; "Smart Proxies") имеется отображение созданного по умолчанию proxy.

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/oWmimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/oWmimage.png)

Если proxy не создан, то:

- Перейти в "Администратор" - "Местоположения" ("Administer" - "Locations"); 
    - Выбрать Default location;
    - Нажать кнопку "Устранить несоответствия" ("Fix mismatches");
    - Нажать кнопку "Применить" ("Submit");
- Аналогично "Администратор" - "Организации" ("Administer" - "Organizations"); 
    - Выбрать Default organization;
    - Нажать кнопку "Устранить несоответствия" ("Fix mismatches");
- Нажать кнопку "Применить" ("Submit");

После выполнения этих шагов в "Инфраструктура" - "Капсулы" ( в английском варианте "Infrastructure" -&gt; "Smart Proxies") появится отображение созданного по умолчанию proxy.

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/gU6image.png)](https://atomskills.space/uploads/images/gallery/2022-11/gU6image.png)

# Отказоустойчивая база данных PostgresPro + Patroni

[](#%D1%81%D0%BD%D0%B0%D1%87%D0%B0%D0%BB%D0%B0-%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%B0%D0%B2%D0%BB%D0%B8%D0%B2%D0%B0%D0%B5%D0%BC-etcd-%D0%BD%D0%B0-%D1%82%D1%80%D0%B8-%D0%BD%D0%BE%D0%B4%D1%8B)Сначала устанавливаем etcd на три ноды

**Нужно отсинхронить время, обязательно**

Скачиваем etcd и etcdctl

`wget https://github.com/etcd-io/etcd/releases/download/v3.5.5/etcd-v3.5.5-linux-amd64.tar.gz`

Распаковываем архив и переносим все бинари в `/usr/bin/`, даем им права на выполнение

В `/etc/systemd/system` создаем юнит `etcd.service` с содержимым

```
[Unit]
Description=etcd service

[Service]
User=root
Type=notify
ExecStart=/usr/bin/etcd \
    --name etcd01  \  #Меняем имя для каждой ноды
    --data-dir /var/lib/etcd \  #Директория должна существовать, владелец -- etcd. Если юзера нет -- добавь.
    --initial-advertise-peer-urls http://nodeip:2380 \  #Сюда вставляем адрес машины, где крутится etcd, меняем для каждой ноды
    --listen-peer-urls http://nodeip:2380 \ 
    --listen-client-urls http://nodeip:2379,http://127.0.0.1:2379  \
    --advertise-client-urls http://nodeip:2379  \
    --initial-cluster-token etcd-cluster-1 \  #одинаковый на всех нодах
    --initial-cluster etcd01=http://node1ip:2380,etcd02=http://node2ip:2380,etcd03=http://node3ip:2380 \ #Меняем адреса на свои, одинаково на всех нодах
    --initial-cluster-state new  \ 
    --enable-v2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Юнит и бинари добавляем на все три ноды, а также:

```
useradd etcd
mkdir /var/lib/etcd
chown etcd:etcd /var/lib/etcd
systemctl daemon-reload
systemctl enable --now etcd
```

Чтоб проверить, что все работает, делаем

```
export ETCDCTL_API=2
etcdctl cluster-health
```

##### [](#%D1%81%D1%82%D0%B0%D0%B2%D0%B8%D0%BC-%D0%BF%D0%BE%D1%81%D0%B3%D1%80%D0%B5%D1%81)**Ставим PostgresPro**

Для астры хорошо подходит postgres pro std, по этому ставим его

```
echo "deb http://repo.postgrespro.ru/pgpro-13/astra-orel/2.12 orel main" >> /etc/apt/sources.list   #Добавили репы
wget http://repo.postgrespro.ru/pgpro-13/keys/GPG-KEY-POSTGRESPRO -O- | apt-key add -   #Добаили ключ для репов
apt update && apt install postgrespro-std-13  #Ставим постгрес
systemctl disable --now postgrespro-std-13    #Отключаем постгрес, иначе патрони не взлетит
```

##### [](#%D1%81%D1%82%D0%B0%D0%B2%D0%B8%D0%BC-patroni)**Ставим Patroni**

```
apt install python3-pip
pip install patroni[etcd] psycopg2-binary
```

Устанавливаем сервис patroni

```
wget https://raw.githubusercontent.com/zalando/patroni/master/extras/startup-scripts/patroni.service
systemctl daemon-reload
```

Пишем конфигу для patroni `/etc/patroni.yml`

```
scope: postgres
namespace: /postgres/
name: node1    #Разное имя для каждой ноды

restapi:
#Тут айпи ноды 
  listen: 0.0.0.0:8008  
  connect_address: nodeapi:8008

#Пишем адреса всех etcd нод
etcd:
  hosts:
    - etcd01ip:2379
    - etcd02ip:2379
    - etcd03ip:2379

bootstrap:
  dcs:
    ttl: 100
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        wal_level: replica
        hot_standby: "on"
        wal_keep_segments: 5120
        max_wal_senders: 10
        max_replication_slots: 10
        checkpoint_timeout: 30
  initdb:
    - encoding: UTF8
    - data-checksums
    - locale: en_US.UTF8
  pg_hba:
    - host replication replica node1ip/32 md5
    - host replication replica node2ip/32 md5
    - host replication replica node3ip/32 md5
    - host all all 0.0.0.0 md5
  users:
    replica:
      password: P@ssw0rd
      options:
        - replication
    postgres:
      password: P@ssw0rd
      options:
        - superuser

postgresql:
  listen: 0.0.0.0:6432
  connect_address: nodeip:6432
  data_dir: /data/patroni  #Должна существовать, овнер postgres
  bin_dir: /opt/pgpro/std-13/bin
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replica
      password: P@ssw0rd
    superuser:
      username: postgres
      password: P@ssw0rd
  create_replica_methods:
    basebackup:
      checkpoint: 'fast'
  parameters:
    unix_socket_directories: '.'
    max_connections: 100
    max_locks_per_transaction: 1024

tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
  nosync: false
```

После этого можно ручками проверить, что патрони работает

```
su - postgres
patroni /etc/patroni.yml
```

Если все работает, делаем `systemctl enable --now patroni`

Проверяем, что все работает: `patronictl -c /etc/patroni.yml list`

##### [](#%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-keepalived)**Установка keepalived**

```
apt install keepalived
```

Создаем `/etc/keepalived/keepalived.conf` и пишем туда что-то типа

```
vrrp_instance cluster1 {
    state MASTER #На остальных нодах state BACKUP
    interface eth0
    virtual_router_id 10  #Одинаковый на всех нодах
    priority 100  #Самый большой на мастере, на второй ноде чуть поменьше и на третьей еще меньше
    virtual_ipaddress {
        192.168.1.200/24 #Один на все ноды, поменять на свой
    }
}
```

не забываем сделать `systemctl enable --now keepalived`

##### [](#%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%B0%D0%B2%D0%BB%D0%B8%D0%B2%D0%B0%D0%B5%D0%BC-haproxy)**Устанавливаем haproxy**

```
apt install haproxy
```

Потом идем в `/etc/haproxy/haproxy.cfg`

```
global
    mode tcp
    #Удаляем все, что связано с https

listen stats
    mode http
    bind *:8088
    stats enable
    stats uri /

frontend PG
    bind *:5432
    default_backend PG_back

backend PG_back
    option httpchk GET /master
    server pg1 node1ip:6432 check port 8008 inter 10s
    server pg2 node2ip:6432 check port 8008 inter 10s
    server pg3 node3ip:6432 check port 8008 inter 10s
```

Не забываем `systemctl enable --now haproxy`

еще можно `haproxy -c -f /etc/haproxy/haproxy.cfg` на всякий

# CI/CD

# ИНСТРУКЦИЯ

## [](#%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-gitea)Установка gitea

```
mkdir gitea
cd gitea

```

```
vim docker-compose.yml
```

```
version: "3"

networks:
  gitea:
    external: false

services:
  server:
    image: gitea/gitea:1.17.3
    container_name: gitea
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__database__DB_TYPE=postgres
      - GITEA__database__HOST=db:5432
      - GITEA__database__NAME=gitea
      - GITEA__database__USER=gitea
      - GITEA__database__PASSWD=gitea
    restart: always
    networks:
      - gitea 
    volumes:
      - ./gitea:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3000:3000"
      - "222:22"
    depends_on:
      - db

  db:
    image: postgres:14
    restart: always
    environment:
      - POSTGRES_USER=gitea
      - POSTGRES_PASSWORD=gitea
      - POSTGRES_DB=gitea
    networks:
      - gitea
    volumes:
      - ./postgres:/var/lib/postgresql/data
```

```
docker-compose pull
docker-compose up -d
```

Переходим на [http://yourip:3000](http://yourip:3000)

1. В визарде меняем URL с localhost на ваш ip и инициализируем gitea
2. Регистрируем новую УЗ
3. Создаем новый репозиторий
4. После создания репо возвращаемся в консоль

```
git clone http://x.x.x.x:3000/gitea/myapp.git  #Клонируем созданный нами репозиторий
```

```
cd myapp #Переходим в папку с репо
```

```
unzip app.zip #Разархивируем приложение
```

Теперь запушим распакованные нами файлы в репозиторий

```
git config --global user.name "Tolya"
git config --global user.email "tolya@gitea.ru"
git add .
git commit -m "uploadfiles"
git push 
```

## [](#%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-jenkins)Установка Jenkins

```
mkdir jenkins-config
mkdir ~/jenkins
```

```
vim jenkins-config/docker-compose.yml
```

```
version: '3.3'
services:
  jenkins:
    image: jenkins/jenkins:lts
    privileged: true
    user: root
    ports:
      - 8081:8080
      - 50000:50000
    container_name: jenkins
    volumes:
      - ~/jenkins:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      - /usr/local/bin/docker:/usr/local/bin/docker
      - /usr/bin/docker:/usr/bin/docker
      - /etc/docker/daemon.json:/etc/docker/daemon.json
```

```
vim /etc/docker/daemon.json
```

```
{
    "insecure-registries" : [ "x.x.x.x:5000" ]
}
```

```
docker-compose up -d
```

Переходим на [http://yourip:8081](http://yourip:8081)

```
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Выбираем "Install suggested plugins"

## [](#%D1%80%D0%B0%D0%B1%D0%BE%D1%82%D0%B0-%D0%B2-%D0%B2%D0%B5%D0%B1-%D0%B8%D0%BD%D1%82%D0%B5%D1%80%D1%84%D0%B5%D0%B9%D1%81%D0%B5)Работа в веб-интерфейсе

1. Manage Jenkins &gt; Manage Credentials &gt; Jenkins &gt; Global Credentials &gt; Add credentials

Username — пользователь Gitea

Password — пароль пользователя Gitea

2. Manage Jenkins &gt; Plugins &gt; Доступные &gt; Docker &gt; install without restart

(docker pipeline, docker-build-step, docker slaves, docker, docker api, docker commons)

3. Dashboard &gt; Создать Item &gt; Name &gt; Pipeline &gt; OK 
    1. Идем во вкладку **Pipeline**
    2. В разделе **Definition** выбираем **"Pipeline script from SCM"**
    3. В разделе **SCM** выбираем **"Git"**
    4. В разделе **Repositories** заполняем Repository URL ссылкой на раннее созданный нами реп
    5. В разделе **Credentials** выбираем созданные раннее креды от пользователя gitea
    6. В разделе Branches **Specifier** меняем master на main (в случае если при создания репозитория вы не меняли названия основной ветки)
    7. Нажимаем **"Сохранить"**

## [](#%D0%BD%D0%B0%D0%BF%D0%B8%D1%81%D0%B0%D0%BD%D0%B8%D0%B5-%D0%BF%D0%B0%D0%B9%D0%BF%D0%BB%D0%B0%D0%B9%D0%BD%D0%B0)Написание пайплайна

```
cd myapp #Переходим в папку с репозиторием
```

```
vim Jenkinsfile
```

```
node {
    def app

    stage('Clone repo') {
        checkout scm
    }

    stage('Build image'){
        app = docker.build("myapp/test")
    }

    stage('Push image') {
        docker.withRegistry('http://x.x.x.x:5000') {
            app.push("${env.BUILD_NUMBER}")
            app.push("latest")
        }
    }
}
```

```
git add Jenkinsfile
git commit -m "Add jenkinsfile"
git push
```

## [](#%D0%BC%D0%B5%D0%B6%D0%B4%D1%83-%D0%B4%D0%B5%D0%BB%D0%BE%D0%BC-%D0%BF%D0%BE%D0%B4%D0%BD%D0%B8%D0%BC%D0%B5%D0%BC-%D0%BB%D0%BE%D0%BA%D0%B0%D0%BB%D1%8C%D0%BD%D0%BE-%D1%80%D0%B5%D0%B4%D0%B6%D0%B5%D1%81%D1%82%D1%80%D0%B8-%D1%87%D1%82%D0%BE%D0%B1%D1%8B-%D0%B1%D1%8B%D0%BB%D0%BE-%D0%BA%D1%83%D0%B4%D0%B0-%D0%BF%D1%83%D1%88%D0%B8%D1%82%D1%8C)Между делом поднимем локально реджестри чтобы было куда пушить

```
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

## [](#%D0%BF%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0-%D1%80%D0%B0%D0%B1%D0%BE%D1%82%D0%BE%D1%81%D0%BF%D0%BE%D1%81%D0%BE%D0%B1%D0%BD%D0%BE%D1%81%D1%82%D0%B8-%D0%BF%D0%B0%D0%B9%D0%BF%D0%BB%D0%B0%D0%B9%D0%BD%D0%B0)Проверка работоспособности пайплайна

1. Переходим в дашборд дженкинса
2. Выбираем раннее созданный нами итем
3. Нажимаем "Собрать сейчас"
4. Ожидаем
5. В итоге мы должны видеть успешно прокатанные стейджи (Реп успешно склонирован, образ успешно собрался и успешно запушился в локальный реджестри)

*Для дебага: выбираем сборку и смотрим вывод консоли*

# Cifs + Keepalived

#### **Перед началом работы**

Перед началом работы необходимо проверить, что уже есть:

1. Развернутый домен FreeIPA;
2. Развернутый CEPH на трех нодах;
3. Настроенная DNS-инфраструктура
4. Примонтированная через FSTAB папка CEPH, по инструкции [как примонтировать кластер к машине](https://atomskills.space/link/174#bkmrk-%D0%9A%D0%B0%D0%BA-%D0%BF%D1%80%D0%B8%D0%BC%D0%BE%D0%BD%D1%82%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D1%82%D1%8C-%D0%BA)

По итогу выполнения данной инструкции мы получим отказоустойчивую Samba-сетевую папку, к которой можно будет подключать пользователей, исходя из их членства в группе. Также в случае падения одной из Samba-нод keepalived легко перенесет активных клиентов на новый хост, который подхватит клиентов. Downtime примерно 10-15 секунд.

#### **Приступаем к работе**

##### **На контроллере домена**

Получить Kerberos ключ для админа, чтобы производить работы с доменом:

`kinit admin`

Установить на сервере FreeIPA поддержку SID

`ipa-adtrust-install --add-sids --add-agents`

Получите на контроллере домена набор SID

`net getdomainsid`

В ответ команда вернет два SID. Один для локальной машины, другой доменный. Доменный нужно сохранить

`net getdomainsid > test.txt`

Потом test.txt нужно отредактировать - убрать оттуда всё, кроме самого SID вашего домена. SID начинается на символы S-1-... Далее необходимо получить диапазон ID, которые использует ваш домен:

`ipa idrange-find --raw`

В ответ придет количество диапазонов. Для FreeIPA по умолчанию ipabased равен 6240000, а ipaidrangesize - 1000000. Если значения такие же, то идем по мануалу дальше. Если нет, то решите простой арифметический пример:

`ipabaseid + ipaidrangesize - 1`

Полученное значение - это последний идентификатор пользователя в вашем домене. Далее в веб-интерфейсе добавляем новый узел. Такого хоста на самом деле не будет, но в "узлах" запись о нём должна быть. Имя узла - smb.ht22.local. Адрес - .250 адрес в твоей сети (или любой другой, этот адрес будет виртуальным общим адресом для keepalived). Обязательно проверить, что DNS-запись smbr.ht22.local отображается именно тот общий ip-адрес.

##### **На файловом сервере**

Назначить на компьютер ip-адрес и добавить его в домен через astra-freeipa-client. Далее устанавливаем:

`apt install -y libwbclient-sssd samba winbind freeipa-admintools`

После этого (данные задачи можно делать на файловом сервере, если установлен freeipa-admintools или на домен-контроллере). Получить тикет админа:

`kinit admin`

Далее регистрируем в домене новую службу:

`ipa serivce-add cifs/smb.ht22.local`

Далее на файловом сервере:

`mkdir /mnt/shared`

Получаем таблицу ключей Kerberos:

`ipa-getkeytab -s <your_DC> -p cifs/smb.ht22.local -k /etc/samba/samba.keytab`

**your-DC** - имя DNS домен-контроллера, в нашем случае:

`ipa-getkeytab -s dc.ht22.local -p cifs/smb.ht22.local -k /etc/samba/samba.keytab`

Далее настраиваем **/etc/samba/smb.conf**:

```shell
[globals]
	dedicated keytab file = /etc/samba/samba.keytab
    kerberos method = dedicated keytab
    log file = /var/log/samba/log.%m
    log level = 5
    realm = HT22.LOCAL
    security = ads
    workgroup = HT22
    idmap config HT22 : range = 624000 - 1623999
    idmap config HT22 : backend = sss
    idmap config * : range = 0 - 0
    
[shared]
	path = /mnt/shared
    create mask = 0666
    directory mask = 0777
    writable = yes
    browseable = yes
    valid users = @it
```

После этого переносим SID, сохраненный в test.txt на машину, где Samba:

`net setdomain $(cat test.txt)`

После этого перезапускаем службу:

`kinit admin`

`systemctl restart smbd winbind`

После этого первая папка готова. Как проверить? Правильнее всего в нашем случае это примонтировать сразу через pam\_mount.conf.xml. Устанавливаем на клиентской машине:

`apt install -y libpam-mount`

Файл pam\_mount\_conf.xml представлен ниже:

```xml
<?xml version="1.0" encoding="utf-8" ?>

<!--
	See pam_mount.conf(5) for a description
-->

<pam_mount>
  
 	<!-- debug should come before everythn else,
		since this file is still processed in a single pass
		from top-to-bottom -->
 <debug enable="0" />
  
 
 <volume
         	fstype="cifs"
         	server="smb.ht22.local"
         	path="shared"
         	mountpoint="~/share"
         	options="user=%(USER),cruid=%(USER),sec=krb5,uid=%(USER_,rw" />
  
  <mntoptions allow="nosuid,nodev,loop,encryption,fsck,nonempty,allow_root,allow_other" />
  
  <mntoptions require="nosuid,nodev" />
  
  <logout wait="0" hup="no" term="no" kill="no" />
  
  <mkmountpoint enable="1" remove="true" />
  
</pam_mount>
```

После настройки можно попробовать войти под учеткой из той группы, которая была прописана в smb.conf. На данном этапе Samba папка готова. Теперь необходимо реализовать механизм Keepalived.

##### **Настройка Keepalived**

Keepalived проверяет не только статус доступности по адресу, но и статус работы Samba. То есть, если сама Samba упадет, Keepalived об этом узнает и перекинет пользователей. Сделает это он через скрипт /usr/smb\_check, который представлен ниже. Склонировать его и выдать права.

```
#!/bin/bash
systemctl status smbd > /dev/null 2>&1
```

Конфигурация keepalived:

```shell
global_defs {
		enable_script_security
        script_user root
}

vrrp_instance PG {
	state MASTER
    interface eth0
    virtual_routed_id 50
    priority 100
    advert_int 1
    virtual_ipaddress {
    10.10.1.200/24
    }
}

vrrp_script smb_check {
	script "/usr/smb_check"
    interveal 2
    timeout 2
    rise 1
    fall 2
}

vrrp_instance SMB {
	state MASTER
    interface eth0
    virtual_router_id 123
    advert_int 1
    priority 10
    virtual_ipaddress {
    	10.10.1.250/24
    }
    
    track_interface {
    	eth0
    }
    
    track_script {
    	smb_check
    }
}
```

##### **Конфигурация Samba и разграничение прав доступа**

Для разграничения доступа создадим несколько групп в FreeIPA и несколько каталогов на файловом сервере:

```shell
mkdir /mnt/shared/itfolder
mkdir /mnt/shared/hrfolder
mkdir /mnt/shared/bunufolder
mkdir /mnt/shared/ahofolder
```

Идём во FreeIPA и создаем там группу fs-users, а затем все наши группы itusers,hr,bunuusers,aho:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/hU5image.png)](https://atomskills.space/uploads/images/gallery/2022-11/hU5image.png)

Затем в fs-users добавляем другие группы:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/ekQimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/ekQimage.png)

Это нужно для того, чтобы все пользователи, входящие в fs-users имели доступ к корневому каталогу /mnt/shared.

Далее делаем владельцем каждого каталога пользователя root и соответствующую группе папку:

```shell
chown root:itusers itfolder/
chown root:hrusers hrfolder/
chown root:bunuusers bunufolder/
chown root:ahousers ahofolder/
```

Далее выдаем права 2770 на каждый каталог:

```shell
chmod 2770 itfolder
chmod 2770 hrfolder
chmod 2770 bunufolder
chmod 2770 ahofolder
```

Этого достаточно для корректного разграничения прав доступа. Хотя может и костыльно работает.

# Логирование с LogAnalyzer

##### **Установка MySQL и создание базы данных**

Первым делом устанавливаем пакет mysql-rsyslog:

```shell
apt install -y mysql-rsyslog
```

При появлении визарда с предложением сконфигурировать базу данных - нажимаем No:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/GZaimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/GZaimage.png)

Затем устанавливаем пакет mysql-server:

```shell
apt install -y mysql-server
```

После установки проваливаемся в mysql под пользователем root:

```shell
mysql -u root -p
```

Далее нужно создать базу данных для Loganalyzer с помощью SQL-запроса:

```sql
create database loganalyzer;
```

Чтобы проверить имеющиеся базы данных, необходимо ввести команду `show databases;` Будет выдан список всех имеющихся баз данных:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/64cimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/64cimage.png)

Далее необходимо создать пользователя для доступа к базе данных пользователей LogAnalyzer:

```sql
mysql> GRANT ALL ON loganalyzer.* TO 'loganalyzer'@'localhost' IDENTIFIED BY 'P@ssw0rd';
mysql> FLUSH PRIVILEGES;
mysql> exit
```

Далее необходимо создать базу данных Syslog и аналогично создать пользователя для доступа к БД:

```sql
mysql> CREATE DATABASE Syslog;
mysql> GRANT ALL ON Syslog.* TO 'rsyslog'@'localhost' IDENTIFIED BY 'Password';
mysql> FLUSH PRIVILEGES;
mysql> exit
```

Импортируем схему базы данных по умолчанию, предлагаемую Rsyslog, используя приведенную ниже команду:

```shell
mysql -u rsyslog -D Syslog -p < /usr/share/dbconfig-common/data/rsyslog-mysql/install/mysql
```

Первоначальная настройка базы данных выполнена. Можно переходить к настройке Rsyslog.

##### **Настройка Rsyslog**

На всякий случай делаем копию текущего конфига rsyslog:

```
cp /etc/rsyslog.conf /etc/rsyslog.conf.org
```

Затем переходим в rsyslog.conf и раскомментируем следующие строки для прослушивания как tcp, так и udp портов:

```shell
# provides UDP syslog reception
module(load="imudp")
input(type="imudp" port="514")
[...]
# provides TCP syslog reception
module(load="imtcp")
input(type="imtcp" port="514")
```

Чтобы настроить Rsyslog для вывода журналов в базу данных, редактируем файл `/etc/rsyslog.d/mysql.conf` следующим образом:

```shell
# Load the MySQL Module
$ModLoad ommysql
#*.* :ommysql:Host,DB,DBUser,DBPassword
*.* :ommysql:127.0.0.1,Syslog,rsyslog,P@ssw0rd
```

Так же правим еще строки:

```shell
### Configuration file for rsyslog-mysql
### Changes are preserved

module (load="ommysql")
*.* action(type="ommysql" server="localhost" db="Syslog" uid="rsyslog" pwd="P@ssw0rd")
```

После этого перезапускаем rsyslog командой `systemctl restart rsyslog` и сразу же проверяем статус командой` systemctl status rsyslog`:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/y64image.png)](https://atomskills.space/uploads/images/gallery/2022-11/y64image.png)

Настройка Rsyslog выполнена и теперь можно переходить к настройке самого LogAnalyzer.

##### **Скачивание и распаковка пакета LogAnalyzer**

Создаем каталог loganalyzer в `/var/www/html`:

```shell
mkdir /var/www/html/loganalyzer
```

Скачиваем с помощью wget архив по ссылке [https://download.adiscon.com/loganalyzer/loganalyzer-4.1.13.tar.gz](https://download.adiscon.com/loganalyzer/loganalyzer-4.1.13.tar.gz). Может ругаться на сертификат, чтобы этого избежать необходимо к wget добавить опцию `--no-check-certificate`:

```shell
wget --no-check-certificate https://download.adiscon.com/loganalyzer/loganalyzer-4.1.13.tar.gz
```

После скачивания распаковываем архив с помощью команды:

```shell
tar xzvf loganalyzer-4.1.13.tar.gz
```

Переносим файлы из каталога `src` распакованного архива в`/var/www/html/loganalyzer:`

```shell
mv loganalyzer-4.1.13/src/* /var/www/html/loganalyzer
```

Переходим в каталог `/var/www/html/loganalyzer/include`:

```shell
cd /var/www/html/loganalyzer/include
```

Далее выполняем следующие команды:

```shell
cat db_template.txt | mysql -u root -p loganalyzer
cat db_updatevxx.txt | mysql -u root -p loganalyzer
```

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/CX9image.png)](https://atomskills.space/uploads/images/gallery/2022-11/CX9image.png)

Далее возвращаемся в каталог loganalyze. Cоздаем в нём пустой файл config.php, делаем владельцем этого файла www-data и присваиваем права 666:

```shell
cd /var/www/html/loganalyzer
touch config.php
chown www-data:www-data config.php
chmod 666 config.php
```

Далее делаем владельцем www-data для всего каталога loganalyzer :

```
chown www-data:www-data -R /var/www/html/loganalyzer/
```

Можно переходить к конфигурации виртуального хоста в Apache.

##### **Конфигурация виртуального хоста в Apache**

Выписываем сертификаты для сайта logs.ht22.local и копируем их в папку `/etc/apache2/certs`.

После этого создаем следующую конфигурацию виртуального хоста loganalyzer.conf в `/etc/apache2/sites-available`:

```shell
<VirtualHost *:80>
	ServerName logs.ht22.local
    Redirect / https://logs.ht22.local
</VirtualHost>

<VirtualHost *:443>
	ServerName logs.ht22.local
    DocumentRoot /var/www/html/loganalyzer
    SSLEngine on
    SSLCertificateFile /etc/apache2/certs/logs.crt
    SSLCertificateKeyFile /etc/apache2/certs/logs.key
</VirtualHost>
```

Включаем сайт и выполняем перезагрузку Apache:

```shell
a2ensite loganalyzer.conf
systemctl reload apache2.service
```

Настройка Apache успешно выполнена. Теперь необходимо создать DNS-запись во FreeIPA.

##### **Создание DNS-записи во FreeIPA**

Переходим в раздел DNS во FreeIPA и создаем A-запись logs для сервера 10.10.10.40:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/sPnimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/sPnimage.png)

Теперь можно переходить к настройке самого LogAnalyzer.

##### **Настройка LogAnalyzer**

Входим в веб-интерфейс по адресу [https://logs.ht22.local](https://logs.ht22.local). Видим ошибку, нажимаем на Click here как на скриншоте:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/GKwimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/GKwimage.png)

Включаем базу данных, проверяем имя БД , вводим учетную запись и жмем Next:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/m3Timage.png)](https://atomskills.space/uploads/images/gallery/2022-11/m3Timage.png)

Нажимаем просто Next:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/jmlimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/jmlimage.png)

И тут тоже:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/2HMimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/2HMimage.png)

Создаем учетную запись администратора admin с паролем [P@ssw0rd](mailto:P@ssw0rd) и жмем Next:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/FnOimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/FnOimage.png)

Видим, что пользователь был успешно создан, о чем говорит выданное сообщение. Заполняем данные для БД с системными логами:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/j6wimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/j6wimage.png)

Конфигурация завершена. Нажимаем Finish:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/EvWimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/EvWimage.png)

При успешном подключении будут выданы логи с сервера:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/pUqimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/pUqimage.png)

##### **Настройка Rsyslog на других хостах**

Для отправки логов на сервер всё, что необходимо это добавить одну строчку в `rsyslog.conf` и раскомментировать прослушивание tcp и udp портов:

```shell
# provides UDP syslog reception
module(load="imudp")
input(type="imudp" port="514")
[...]
# provides TCP syslog reception
module(load="imtcp")
input(type="imtcp" port="514")

# настраиваем отправку логов на сервер
*.* @@10.10.10.40 # адрес сервера логирования
```

Перезапускаем rsyslog командной `systemctl restart rsyslog` и идём в веб-интерфейс LogAnalyzer:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/VQMimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/VQMimage.png)

Как видим, теперь логи прилетают и с других устройств. На этом полная настройка логирования закончена.

# Мониторинг с Zabbix

##### **Установка и настройка Zabbix**

Выполняем установку пакетов zabbix-server-psql и zabbix-frontend-php:

`apt install -y zabbix-server-psql zabbix-frontend-php`

Далее в файле /etc/php/\*/apache2/php.ini раскомментируем и устанавливаем временную зону:

```shell
[Date]
date.timezone = Europe/Moscow
```

Затем в файл /etc/postgresql/\*/main/pg\_hba.conf в конце добавляем:

```shell
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   zabbix          zabbix                                  trust
host    zabbix          zabbix          127.0.0.1/32             trust
```

После этого перезапускаем postgresql командой `systemctl restart postgresql`

Затем нужно зайти в postgresql командой `sudo -u postgres psql` и создать там базу данных:

```sql
CREATE DATABASE ZABBIX;
CREATE USER zabbix WITH ENCRYPTED PASSWORD 'P@ssw0rd';
GRANT ALL ON DATABASE zabbix to zabbix;
\q
```

Заполняем таблицу базы данных zabbix данными:

```shell
zcat /usr/share/zabbix-server-pgsql/{schema,images,data}.sql.gz | psql -h localhost zabbix zabbix
```

Включаем конфигурацию фронтенда zabbix:  
`a2enconf zabbix-frontend-php`

Копируем шаблоны конфигов в папку с zabbixом и меняем владельца и группу:

```shell
cp /usr/share/zabbix/conf/zabbix.conf.php.example /etc/zabbix/zabbix.conf.php
chown www-data:www-data /etc/zabbix/zabbix.conf.php
```

В файле `/etc/zabbix/zabbix.conf.php` задать значения переменных TYPE   
(тип используемой СУБД) и PASSWORD (пароль пользователя zabbix СУБД)

```shell
$DB['TYPE'] = 'POSTGRESQL';
...
$DB['PASSWORD'] = 'P@ssw0rd';
```

Копируем конфиг заббикс сервера `cp /usr/share/zabbix-server-pgsql/zabbix_server.conf /etc/zabbix/`  
Внутри этого файла найти директиву DBPassword и прописать:  
[DBPassword=P@ssw0rd](mailto:DBPassword=P@ssw0rd)

Далее создаем папку certs в /etc/apache2/:

```shell
mkdir /etc/apache2/certs
```

Закидываем в нее выписанные ранее для zabbix сертификат и ключ.

После этого создаем файл zabbix.conf в `/etc/apache2/sites-available`:

```shell
<VirtualHost *:80>
    ServerName zabbix.ht22.local
    Redirect / https://zabbix.ht22.local/zabbix
</VirtualHost>

<VirtualHost *: 443>
    ServerName zabbix.ht22.local
    DocumentRoot /usr/share/zabbix
    SSLEngine on
    SSLCertificateFile /etc/apache2/certs/zabbix.crt
    SSLCertificateKeyFile /etc/apache2/certs/zabbix.key
</VirtualHost>
```

После этого включаем всё необходимое и перезапускаем apache:

```shell
a2enmod ssl	# включаем поддержку ssl
a2enconf zabbix-frontend-php # включаем конфигурацию фронтенда
a2ensite zabbix.conf # включаем конфигурацию виртуального хоста
systemctl reload apache2 # перезагружаем apache
```

##### **Добавление DNS записи во FreeIPA**

Заходим в конфигурацию DNS во FreeIPA и добавляем обычную A-запись zabbix на сервер 10.10.10.40:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/qMPimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/qMPimage.png)

После этого можно пробовать заходить по адресу [https://zabbix.ht22.local](https://zabbix.ht22.local). Должна открыться страница входа:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/YSWimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/YSWimage.png)

**Логин - Admin, пароль - zabbix.**

##### **Устранение проблемы Zabbix server not running**

При входе в веб-интерфейс будет появляться ошибка о том, что zabbix сервер не запущен и внизу будет проблема:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/XHYimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/XHYimage.png)

При этом на сервере служба запущена и работает без проблем:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/LGkimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/LGkimage.png)

WEB интерфейс подключается к zabbix\_server TCP 10051 (Trappers) для посылки команд серверу на выполнение предварительно конфигурируемых пользовательских скриптов и возврата результата в веб-интерфейс для просмотра, таких как ping и traceroute. Поэтому должен быть запущен хотя бы один Trappers.

Идём в конфигурацию `/etc/zabbix/zabbix_server.conf` и раскомментируем одну строчку:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/QZUimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/QZUimage.png)

После этого перезапускаем сервис заббикса командой `systemctl restart zabbix-server.service`.

После проведенных манипуляций в веб-интерфейсе должно стать всё ок:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/sSkimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/sSkimage.png)

##### **Установка и настройка Zabbix Агента на хостах**

Необходимо выполнить установку пакета zabbix-agent:

`apt install -y zabbix-agent`

После установки переходим в конфигурацию `/etc/zabbix/zabbix_agentd.conf` и настроим несколько параметров:

```shell
ListenPort = 10050
Server = 10.10.10.40
ServerActive = 10.10.10.40
```

После этого перезагружаем службу zabbix агента `systemctl restart zabbix-agent` и смотрим сразу же её статус после перезапуска `systemctl status zabbix-agent`:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/uqcimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/uqcimage.png)

На этом настройка агента закончена и можно переходить к добавлению хоста в сам Zabbix.

##### **Добавление хоста в Zabbix**

В Astra Linux старый Zabbix, поэтому интерфейс от современных версий отличается, но принцип один и тот же. Переходим в раздел Configuration -&gt; Hosts и нажимаем Create host:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/YHCimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/YHCimage.png)

Заполняем имя хоста, отображаемое имя, Ip-адрес сервера и описание:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/nVvimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/nVvimage.png)

Переходим на вкладку Templates. Выбираем в поле Link new templates шаблон Template OS Linux и ниже нажимаем на Add (без нажатия именно этой кнопки Add шаблон не привяжется!). После привязки страница обновиться и можно будет нажать синюю кнопку Add:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/AV2image.png)](https://atomskills.space/uploads/images/gallery/2022-11/AV2image.png)

Как видим, хост успешно добавился:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/qQZimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/qQZimage.png)

Если через минуту обновить страницу, то видим, что хост активен:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-11/scaled-1680-/JObimage.png)](https://atomskills.space/uploads/images/gallery/2022-11/JObimage.png)

На этом добавлении хоста на мониторинг в Zabbix успешно выполнено.

# Grafana



# Rsync и Bacula

#### **Вариант бэкапа через Rsync**

Если rsync не установлен, то выполняем:

`apt install -y rsync`

На сервере CA-FS создаем каталог /backup (можно в root).

`mkdir backup`

Для копирования каталога /home/ используем следующий скрипт на bash - backup.sh:

```bash
#!/bin/bash
date=$(date +%d-%m-%y:%H-%M-%S)
# Packing home directory to archive
tar cvfj /tmp/backup-$date.tar.gz /home/ > /dev/null
# backuping file to CA-FS
rscync -av -e ssh /tmp/backup-$date.tar.gz root@10.10.1.13:/root/backup
# after copying to CA-fs delete archive from tmp directory 
rm -rf /tmp/backup-$date.tar.gz
exit 0
```

Добавляем права на выполнение на скрипт:

`chmod +x backup.sh`

Запускаем скрипт и проверяем, что всё работает:

`sh backup.sh`

В результате на CA-FS в /root/backup должен появиться архив.

##### **Добавление задачи в планировщик Cron**

Идём в `/etc/crontab` и пишем следующее:

[![image.png](https://atomskills.space/uploads/images/gallery/2022-10/scaled-1680-/x7Bimage.png)](https://atomskills.space/uploads/images/gallery/2022-10/x7Bimage.png)

 Каждые 12 часов от пользователя root будет отрабатывать скрипт бэкапа.

##### **Восстановление данных из Rsync**

На клиенте создаем каталог /restore:

`mkdir restore`

Далее пишем следующий скрипт для восстановления данных:

```bash
#!/bin/bash
echo "Select backup to restore: "
ssh root@10.10.1.13 ls /root/backup
read -p "Enter backup name: " backupname
rsync root@10.10.1.13:/root/backup/$backupname /tmp
tar xvf /tmp/$backupname -C /home/ > /dev/null
```

# Ansible базовый