# Используем базовый образ Ubuntu LTS
FROM ubuntu:20.04

# Устанавливаем переменные среды для избежания интерактивных вопросов
ENV DEBIAN_FRONTEND=noninteractive

# Устанавливаем необходимые зависимости
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    tar \
    dpkg \
    libxml2 \
    libssl1.1 \
    libpcsclite1 \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Копируем архив КриптоПро CSP в контейнер (предполагается, что архив находится в той же директории)
# Вам нужно поместить linux-amd64_deb.tgz рядом с Dockerfile перед сборкой
COPY linux-amd64_deb.tgz /tmp/linux-amd64_deb.tgz

# Распаковываем и устанавливаем КриптоПро CSP
RUN tar xvf /tmp/linux-amd64_deb.tgz -C /tmp && \
    cd /tmp/linux-amd64_deb && \
    ./install.sh kc2 && \
#    ./install.sh && \
    dpkg -i cprocsp-stunnel-64_5.0.13455-7_amd64.deb && \
    rm -rf /tmp/linux-amd64_deb /tmp/linux-amd64_deb.tgz

# Добавляем конфигурацию провайдеров
RUN echo '[Defaults\\Provider\\"Crypto-Pro HSM CSP"]\n\
"Image Path" = "/opt/cprocsp/lib/amd64/libcspr.so"\n\
"Function Table Name" = "CPSRV_GetFunctionTable"\n\
Type = 75\n\
Channel = ".clientk2"\n\
\n\
[Defaults\\Provider\\"Crypto-Pro GOST R 34.10-2012 HSM CSP"]\n\
"Image Path" = "/opt/cprocsp/lib/amd64/libcspr.so"\n\
"Function Table Name" = "CPSRV_GetFunctionTable"\n\
Type = 80\n\
Channel = ".clientk2"\n\
\n\
[Defaults\\Provider\\"Crypto-Pro GOST R 34.10-2012 Strong HSM CSP"]\n\
"Image Path" = "/opt/cprocsp/lib/amd64/libcspr.so"\n\
"Function Path" = "/opt/cprocsp/lib/amd64/libcspr.so"\n\
"Function Table Name" = "CPSRV_GetFunctionTable"\n\
Type = 81\n\
Channel = ".clientk2"' >> /etc/opt/cprocsp/config64.ini

# Копируем скрипт для запуска
COPY ../stunnel_server/docker-entrypoint.sh docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 8088

# Точка входа
ENTRYPOINT ["bash", "docker-entrypoint.sh" ]
