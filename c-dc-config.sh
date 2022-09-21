# Переходим к пользователю root
sudo -i 

# Переименовываем хост в c-dc.digital-skills.ga и добавляем запись в hosts
echo '127.0.0.1 c-dc.digital-skills.ga  c-dc' > /etc/hosts
echo 'c-dc.digital-skills.ga' > /etc/hostname

# Добавляем репозиторий яндекса    
echo 'deb http://mirror.yandex.ru/astra/current/2.12_x86-64/repository main contrib' >> /etc/apt/sources.list

# Обновляем список пакетов
apt update

# Устанавливаем ssh, curl, git, net-tools, sudo, vim, zabbix-agent, astra-freeipa-server
apt install -y openssh-server curl git net-tools vim zabbix-agent astra-freeipa-server

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

# Устанавливаем docker-compose
apt install -y docker-compose

# Создаем пользователя cloudadmin
adduser cloudadmin
P@ssw0rd
P@ssw0rd

# Добавляем пользователя в sudo и в docker группы
usermod -aG sudo cloudadmin
usermod -aG docker cloudadmin

# Перезагружаемся и логинимся под пользователем cloudadmin
# Настраиваем astra-freeipa-server
astra-freeipa-server -d digital-skills.ga -ip 10.10.10.10

# Запускаем docker-compose.yml для Duplicati
cd /opt/repository/duplicati
docker-compose up -d

# Запускаем docker-compose.yml для Nextcloud
cd /opt/repository/Nextcloud
docker-compose up -d

