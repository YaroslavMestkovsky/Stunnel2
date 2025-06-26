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

# Инициализация сервисов (выполняется один раз)
init_services() {
    echo "Initializing services..."

    # Копируем ключевой контейнер (если нужно)
    cp -R /keys/* /var/opt/cprocsp/keys/root/ || echo "No keys to copy or copy failed"

    # Перезапускаем cprocsp
    echo "Restarting cprocsp service..."
    service cprocsp restart || echo "Warning: cprocsp restart failed"

    # Устанавливаем сертификаты (с попытками)
    install_certificates
}

# Установка сертификатов с повторными попытками
install_certificates() {
  # CRL-файлы
#  [ -f "/etc/stunnel/crl.crl" ] && \
#      /opt/cprocsp/bin/amd64/certmgr -inst -crl -store mCA -file /etc/stunnel/crl.crl -silent || \
#      echo "Warning: Failed to install crl.crl"
#
#  [ -f "/etc/stunnel/certcrl.crl" ] && \
#      /opt/cprocsp/bin/amd64/certmgr -inst -crl -store mCA -file /etc/stunnel/certcrl.crl -silent || \
#      echo "Warning: Failed to install certcrl.crl"
#
#  [ -f "/etc/stunnel/certnew.cer" ] && \
#    /opt/cprocsp/bin/amd64/certmgr -inst -cert -store mCA -file /etc/stunnel/certnew.cer -silent || \
#    echo "Warning: Failed to install certnew.cer"
#
#  [ -f "/etc/stunnel/certnew.p7b" ] && \
#    /opt/cprocsp/bin/amd64/certmgr -inst -cert -store mCA -file /etc/stunnel/certnew.p7b -silent || \
#    echo "Warning: Failed to install certnew.p7b"
#
#  [ -f "/etc/stunnel/testroot.p7b" ] && \
#    /opt/cprocsp/bin/amd64/certmgr -inst -cert -store mCA -file /etc/stunnel/testroot.p7b -silent || \
#    echo "Warning: Failed to install testroot.p7b"

  # определение контейнера-хранилища закрытых ключей
  containerName=$(/opt/cprocsp/bin/amd64/csptest -keys -enum -verifyc -fqcn -un | grep 'HDIMAGE' | awk -F'|' '{print $2}' | head -1)
  # экспорт сертификата для stunnel
  /opt/cprocsp/bin/amd64/certmgr -export -dest /etc/stunnel/stunnel2.cer -container "${containerName}"
  # Основной сертификат
  if [ -f "/etc/stunnel/stunnel.cer" ]; then
      if yes "o" | /opt/cprocsp/bin/amd64/certmgr -inst -cert -store uRoot -file /etc/stunnel/stunnel2.cer -silent; then
          echo "Certificate installed successfully"
          cp /etc/stunnel/stunnel2.cer /root/stunnel2.cer || echo "Warning: Failed to copy certificate"
      else
          echo "Warning: Failed to install root certificate"
      fi

      if yes "o" | /opt/cprocsp/bin/amd64/certmgr -inst -cert -store uMy -file /etc/stunnel/stunnel2.cer -silent; then
          echo "Certificate installed successfully"
          cp /etc/stunnel/stunnel2.cer /root/stunnel2.cer || echo "Warning: Failed to copy certificate"
      else
          echo "Warning: Failed to install root certificate"
      fi
      # Дружим между собой ключи и открытые сертификаты
      /opt/cprocsp/bin/amd64/csptestf -absorb -certs
  else
      echo "Error: Certificate file /etc/stunnel/stunnel.cer not found"
  fi
}

# Главный бесконечный цикл
main_loop() {
    while true; do
        if $STUNNEL_RUNNING; then
            check_stunnel
        else
            start_stunnel
        fi
        sleep 5
    done
}

# Основной поток выполнения
init_services
start_stunnel
main_loop
