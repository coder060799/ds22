# Переходим к пользователю root
su -i 

# Задаем статику на интерфейс ens8
echo 'iface ens8 auto
      iface ens8 inet static
        address 10.10.20.1/24' >> /etc/network/interfaces

# Переименовываем хост в c-rtr и добавляем запись в hosts
echo '127.0.0.1 l-rtr' > /etc/hosts
echo 'l-rtr' > /etc/hostname

# Добавляем репозиторий яндекса    
echo 'deb http://mirror.yandex.ru/debian bullseye main contrib' >> /etc/apt/sources.list

# Обновляем список пакетов
apt update

# Устанавливаем ssh, curl, git, net-tools, sudo, vim, wireguard,zabbix-agent и ansible
apt install -y openssh-server curl git net-tools vim wireguard zabbix-agent

# Создаем каталог repository в /opt для загрузки туда файлов с гитхаба
mkdir /opt/repository
chmod 777 -R /opt/repository
cd /opt/repository
git clone https://github.com/coder060799/TestDS22.git
cd TestDS22

# Включаем Ip forwarding
echo 'net.ip.forwarding=1' >> /etc/sysctl.conf
sysctl -p

# Копируем конфиг файлы sshd, wireguard и nftables
cp ./sshd/sshd_config /etc/ssh/sshd_config
cp ./wireguard/* /etc/wireguard/
cp ./nftables/nftables.conf /etc/nftables.conf

# Запускаем nftables и перезапускаем sshd
systemctl enable --now nftables
systemctl restart nftables
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

# Запускаем docker-compose.yml для Duplicati
cd /opt/repository/duplicati
docker compose up -d