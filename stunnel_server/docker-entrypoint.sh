#!/bin/bash
set +e  # Отключаем немедленный выход при ошибках

# Глобальные переменные
STUNNEL_RUNNING=false

touch /etc/stunnel/stunnel.pid
touch /etc/stunnel/stunnel.log


# Функция для запуска stunnel
start_stunnel() {
    echo "Starting stunnel..."
    /opt/cprocsp/sbin/amd64/stunnel_fork > /var/log/stunnel.log 2>&1 &
    STUNNEL_RUNNING=true
    echo -n > /etc/stunnel/stunnel.pid
    echo -n > /etc/stunnel/stunnel.log
    echo "Stunnel started"
}

# Функция для проверки работы stunnel
check_stunnel() {
    if ! pgrep -f "stunnel_fork" > /dev/null; then
        echo "Stunnel is not running, restarting..."
        STUNNEL_RUNNING=false
        start_stunnel
    fi
}

# Инициализация сервисов
init_services() {
    echo "Initializing services..."

    # Копируем ключевые контейнеры из папки keys
    cp -R /keys/* /var/opt/cprocsp/keys/root/ || echo "No keys to copy or copy failed"

    # Перезапускаем службу cprocsp
    echo "Restarting cprocsp service..."
    service cprocsp restart || echo "Warning: cprocsp restart failed"

    # Устанавливаем сертификаты
    install_certificates
}

install_certificates() {
    local cert_dir="/etc/stunnel"

    # Создаем массив файлов, чтобы правильно обрабатывать пробелы в именах
    local cert_files=()

    while IFS= read -r -d $'\0' file; do
        cert_files+=("$file")
    done < <(find "$cert_dir" -maxdepth 1 -type f \( -name "*.cer" -o -name "*.crt" -o -name "*.pem" -o -name "*.pfx" -o -name "*.crl" -o -name "*.p7b" \) -print0)

    for cert_file in "${cert_files[@]}"; do
        local cert_name=$(basename "$cert_file")
        local cert_path="$cert_file"  # Используем полный путь

        # Определяем тип сертификата по имени файла
        if [[ "$cert_name" == client.* ]]; then
            echo "Установка КЛИЕНТСКОГО сертификата: $cert_name"

            # Установка клиентского сертификата хранилище uRoot
            if ! /opt/cprocsp/bin/amd64/certmgr -inst -cert -store uRoot -file "$cert_path" -silent; then
                echo "Ошибка установки клиентского сертификата в uRoot: $cert_name"
            else echo "Успешная установка клиентского сертификата в uRoot"
            fi

            # Установка клиентского сертификата в хранилище uMy
            if ! /opt/cprocsp/bin/amd64/certmgr -inst -cert -store uMy -file "$cert_path" -silent; then
                echo "Ошибка установки в uMy: $cert_name"
            else echo "Успешная установка клиентского сертификата в uMy"
            fi

            # Нахождение имени контейнера с закрытыми ключами
            containerName=$(/opt/cprocsp/bin/amd64/csptest -keys -enum -verifyc -fqcn -un | grep 'HDIMAGE' | awk -F'|' '{print $2}' | head -1)

            # Экспорт сертификата для stunnel
            if [ -n "$containerName" ]; then
                /opt/cprocsp/bin/amd64/certmgr -export -dest "$cert_path" -container "$containerName"
            else
                echo "Не найден контейнер ключей"
            fi
            # Дружим между собой ключи и открытые сертификаты
            /opt/cprocsp/bin/amd64/csptestf -absorb -certs

            continue
        fi

        if [[ "$cert_name" == *.p7b ]]; then
            echo "Установка цепочки сертификатов: $cert_name"
            if ! /opt/cprocsp/bin/amd64/certmgr -inst -cert -file "$cert_path" -silent; then
                echo "Ошибка установки цепочки сертификатов: $cert_name"
            else echo "Успешно установлена цепочка сертификатов: $cert_name"
            fi
            continue
        fi

        if [[ "$cert_name" == *.crl ]]; then
            echo "Установка CA сертификата: $cert_name"
            if ! /opt/cprocsp/bin/amd64/certmgr -inst -crl -store mCA -file "$cert_path" -silent; then
                echo "Ошибка установки CA сертификата: $cert_name"
            else echo "Успешно установлен CA сертификат: $cert_name"
            fi
            contunue
        else
            echo "Установка CA сертификата: $cert_name"
            if ! /opt/cprocsp/bin/amd64/certmgr -inst -cert -store mCA -file "$cert_path" -silent; then
                echo "Ошибка установки CA сертификата: $cert_name"
            else echo "Успешно установлен CA сертификат: $cert_name"
            fi
            continue
        fi
    done
}

# Главный бесконечный цикл проверяющий работу Stunnel'а
main_loop() {
    while true; do
        if $STUNNEL_RUNNING; then
            check_stunnel
        else
            start_stunnel
        fi
        sleep 60
    done
}

# Основной поток выполнения
init_services
start_stunnel
main_loop
