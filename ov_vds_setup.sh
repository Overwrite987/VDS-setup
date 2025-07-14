echo " ░█████╗░██╗░░░██╗███████╗██████╗░░██╗░░░░░░░██╗██████╗░██╗████████╗███████╗	░██████╗███████╗████████╗██╗░░░██╗██████╗░"
echo " ██╔══██╗██║░░░██║██╔════╝██╔══██╗░██║░░██╗░░██║██╔══██╗██║╚══██╔══╝██╔════╝	██╔════╝██╔════╝╚══██╔══╝██║░░░██║██╔══██╗"
echo " ██║░░██║╚██╗░██╔╝█████╗░░██████╔╝░╚██╗████╗██╔╝██████╔╝██║░░░██║░░░█████╗░░	╚█████╗░█████╗░░░░░██║░░░██║░░░██║██████╔╝"
echo " ██║░░██║░╚████╔╝░██╔══╝░░██╔══██╗░░████╔═████║░██╔══██╗██║░░░██║░░░██╔══╝░░	░╚═══██╗██╔══╝░░░░░██║░░░██║░░░██║██╔═══╝░"
echo " ╚█████╔╝░░╚██╔╝░░███████╗██║░░██║░░╚██╔╝░╚██╔╝░██║░░██║██║░░░██║░░░███████╗	██████╔╝███████╗░░░██║░░░╚██████╔╝██║░░░░░"
echo " ░╚════╝░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░░╚═╝░░░╚══════╝	╚═════╝░╚══════╝░░░╚═╝░░░░╚═════╝░╚═╝░░░░░"

sleep 1

# Обратный отсчет
i=5
while [ $i -gt 0 ]; do
    echo "Запуск скрипта через $i..."
    sleep 1
    i=$((i-1))
done

# Пояснения перед каждой командой
echo "1. Обновление списка пакетов"
apt update

echo "2. Обновление установленных пакетов"
apt upgrade -y

echo "3. Установка NTP и ntpdate"
apt install ntp ntpdate -y

echo "4. Синхронизация времени с сервером NUST"
ntpdate -u time.nust.gov

echo "5. Синхронизация аппаратных часов с системным временем"
sudo hwclock --systohc

echo "6. Установка htop"
apt install htop -y

echo "7. Установка screen"
apt install screen -y

echo "8. Установка wget"
apt install wget -y

echo "9. Установка sudo"
apt install sudo -y

echo "10. Установка UFW"
apt install ufw -y

echo "11. Базовая настройка UFW..."
ufw logging off
ufw allow ssh/tcp
ufw allow 25565/tcp
ufw enable

echo "12. Установка MariaDB"
apt install mariadb-server -y

echo "13. Установка GPG"
apt install gpg -y

echo "14. Установка wget и apt-transport-https"
apt install -y wget apt-transport-https

echo "15. Добавление ключа Adoptium"
wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor | tee /etc/apt/trusted.gpg.d/adoptium.gpg > /dev/null

echo "16. Добавление репозитория Adoptium"
echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
apt update
apt upgrade -y

echo "17. Установка Temurin JDK"
# Запрос пользователя о версии Temurin JDK
read -p "Выберите номер версии Temurin JDK (например, 11, 17 и т.д., или -1 для пропуска): " temurin_version

if [ "$temurin_version" = "-1" ]; then
  echo "Установка Temurin JDK пропущена."
else
  echo "Устанавливается Temurin JDK версии $temurin_version..."
  apt install temurin-${temurin_version}-jdk -y
fi

echo "18. Удаляем излишки..."
apt remove qemu-guest-agent -y
apt autoremove -y

# Запрос пользователя о продолжении глубокой настройки
read -p "Желаете продолжить глубокую настройку? (Введите пареметр yes или no): " continue_setup

# Проверка ответа пользователя
if [ "$continue_setup" = "yes" ]; then
    echo "1. Создаем нового пользователя"
    
    sleep 1
    
    read -p "1.1 Укажите имя нового пользователя: " new_user
    useradd -m -s /bin/bash "$new_user"
    
    echo "1.2 Создайте пароль новому пользователю"
    passwd "$new_user"
    
    echo "1.3 Задаем нужные параметры..."
    chmod 700 "/home/$new_user"
    chmod -R 700 "/home/$new_user/"
    chown -R "$new_user:$new_user" "/home/$new_user/"
    
    echo "Настройка пользователя завершена ✓"
    
    sleep 1
    
    echo "2. Настраиваем ssh"

    read -p "2.1 Укажите порт SSH (по умолчанию 22): " ssh_port
    sed -i "s|^#Port [0-9]*|Port $ssh_port|" /etc/ssh/sshd_config
    ufw allow "$ssh_port/tcp"
    
    read -p "2.2 Должны ли быть включены ssh ключи? (по умолчанию yes | если вы не используете это и не знаете что это - поставьте no): " use_key
    sed -i "s|^#PubkeyAuthentication yes*|PubkeyAuthentication $use_key|" /etc/ssh/sshd_config
    
    read -p "2.3 Должен ли быть включен root пользователь? (по умолчанию yes): " root_key
    sed -i "s|^PermitRootLogin yes*|PermitRootLogin $root_key|" /etc/ssh/sshd_config
    
    echo "Настройка SSH завершена ✓"
    echo "Перезагружаем ssh клиент..."
    systemctl restart sshd
    echo "После завершения вашей текущей SSH сессии вам будет необходимо войти с учетом указанных данных!"
    
    sleep 2
    
    echo "Глубокая настройка завершена."
else
    echo "Доп.настройка отклонена по вашему запросу."
fi

sleep 3

echo " ░█████╗░██╗░░░██╗███████╗██████╗░░██╗░░░░░░░██╗██████╗░██╗████████╗███████╗	░██████╗███████╗████████╗██╗░░░██╗██████╗░"
echo " ██╔══██╗██║░░░██║██╔════╝██╔══██╗░██║░░██╗░░██║██╔══██╗██║╚══██╔══╝██╔════╝	██╔════╝██╔════╝╚══██╔══╝██║░░░██║██╔══██╗"
echo " ██║░░██║╚██╗░██╔╝█████╗░░██████╔╝░╚██╗████╗██╔╝██████╔╝██║░░░██║░░░█████╗░░	╚█████╗░█████╗░░░░░██║░░░██║░░░██║██████╔╝"
echo " ██║░░██║░╚████╔╝░██╔══╝░░██╔══██╗░░████╔═████║░██╔══██╗██║░░░██║░░░██╔══╝░░	░╚═══██╗██╔══╝░░░░░██║░░░██║░░░██║██╔═══╝░"
echo " ╚█████╔╝░░╚██╔╝░░███████╗██║░░██║░░╚██╔╝░╚██╔╝░██║░░██║██║░░░██║░░░███████╗	██████╔╝███████╗░░░██║░░░╚██████╔╝██║░░░░░"
echo " ░╚════╝░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░░╚═╝░░░╚══════╝	╚═════╝░╚══════╝░░░╚═╝░░░░╚═════╝░╚═╝░░░░░"

echo "Сетап вашего сервера завершен ✓"