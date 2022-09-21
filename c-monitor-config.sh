# Переходим к пользователю root
su -i 

# Задаем статику на интерфейс ens8
echo 'iface ens3 auto
      iface ens3 inet static
        address 10.10.10.12/24
        gateway 10.10.10.1' >> /etc/network/interfaces

# Добавляем dns-сервера
echo 'nameserver 10.10.10.10' >> /etc/resolv.conf
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf

# Переименовываем хост в c-monitoring и добавляем запись в hosts
echo '127.0.0.1 c-monitoring' > /etc/hosts
echo 'c-monitoring' > /etc/hostname

# Добавляем репозиторий яндекса    
echo 'deb http://mirror.yandex.ru/debian bullseye main contrib' >> /etc/apt/sources.list

# Обновляем список пакетов
apt update

# Устанавливаем ssh, curl, git, net-tools, sudo, vim, wireguard,zabbix-agent и ansible
apt install -y openssh-server curl git net-tools vim

# Создаем каталог repository в /opt для загрузки туда файлов с гитхаба
mkdir /opt/repository
chmod 777 -R /opt/repository
cd /opt/repository
git clone https://github.com/coder060799/TestDS22.git
cd TestDS22

# Копируем конфиг файлы sshd
cp ./sshd/sshd_config /etc/ssh/sshd_config

# Перезапускаем sshd
systemctl restart sshd

# Получаем скрипт docker
curl -fsSL https://get.docker.com -o get-docker.sh
# Запускаем скрипт
sh get-docker.sh

# Создаем пользователя cloudadmin
useradd cloudadmin
P@ssw0rd
P@ssw0rd

# Добавляем пользователя в sudo и в docker группы
usermod -aG sudo cloudadmin
usermod -aG docker cloudadmin

# Перезагружаемся
reboot

# логинимся под cloudadmin и переходим в каталог zabbix
cd /opt/repository/zabbix
# Запускаем docker-compose.yml для запуска zabbix
docker compose up -d

# Запускаем docker-compose.yml для Duplicati
cd /opt/repository/duplicati
docker compose up -d

на домен-контроллере 
kinit admin
ipa host-add zabbix.digital-skills.ga

ipa service-add HTTP/zabbix.digital-skills.ga

openssl req -out zabbix.csr -new -newkey rsa:2048 -nodes -keyout zabbix.key

cat cert.pem CA.crt > zabbix.crt - создаем цепочку сертификатов
chmod 755 /etc/ssl/nginx/zabbix.key - выдаем права на ключ



в Zabbix-agent 
server = 10.10.10.12
serveractive = 10.10.10.12
hostname = zabbix

systemctl enable --now zabbix-agent 
systemctl restart zabbix-agent


настроить haproxy на C-RTR 
будет перенаправлять на nextcloud по http


разобраться с гитлаб, докер регистри и с haproxy
разобраться с мониторингом контейнеров и критических узлов (просто выбрать, что мониторить)
настроить второй контроллер домена на 