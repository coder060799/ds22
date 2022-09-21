# Переходим к пользователю root
su -i 

# Задаем статику на интерфейс ens8
echo 'iface ens3 auto
      iface ens3 inet static
        address 10.10.10.11
        gateway 10.10.10.1' >> /etc/network/interfaces

# Добавляем dns-сервера
echo 'nameserver 10.10.10.10' >> /etc/resolv.conf
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf

# Переименовываем хост в c-backup и добавляем запись в hosts
echo '127.0.0.1 c-backup' > /etc/hosts
echo 'c-backup' > /etc/hostname

# Добавляем репозиторий яндекса    
echo 'deb http://mirror.yandex.ru/debian bullseye main contrib' >> /etc/apt/sources.list

# Обновляем список пакетов
apt update

# Устанавливаем ssh, curl, git, net-tools, sudo, vim, wireguard,zabbix-agent и ansible
apt install -y openssh-server curl git net-tools vim zabbix-agent

# Создаем каталог repository в /opt для загрузки туда файлов с гитхаба
mkdir /opt/repository
chmod 777 -R /opt/repository
cd /opt/repository
git clone https://github.com/coder060799/TestDS22.git
cd TestDS22

# Копируем конфиг файлы sshd
cp ./sshd/sshd_config /etc/ssh/sshd_config

# Fерезапускаем sshd
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