FROM ubuntu:latest

EXPOSE 443

RUN apt-get update

# Вспомогательные пакеты для тестов
RUN apt-get update && apt-get install -y ca-certificates net-tools lsof nano

# Зависимости для OpenSSL
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential libssl-dev wget perl-modules && \
    rm -rf /var/lib/apt/lists/*

# Архив Stunnel
COPY ../tars/stunnel-5.71.tar.gz /tmp/

# OpenSSL
#RUN cd /tmp/ && \
#    tar -zxvf openssl-3.2.0.tar.gz && \
#    cd openssl-3.2.0 && \
#    ./config && \
#    make && \
#    make install && \
#    cd /tmp/ && \
#    rm -rf openssl-3.2.0.tar.gz openssl-3.2.0

# Stunnel
RUN cd /tmp/ && \
    tar -zxvf stunnel-5.71.tar.gz && \
    cd stunnel-5.71 && \
    ./configure && \
    make && \
    make install && \
    cd /tmp/ && \
    rm -rf stunnel-5.71.tar.gz stunnel-5.71

# Чистим все
RUN apt-get purge -y --auto-remove build-essential libssl-dev wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Создаем самоподписанный сертификат...
RUN openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=RU/ST=VLG/L=Volgograd/O=OBT/CN=192.168.48.3" \
    -keyout /usr/local/etc/stunnel/stunnel.pem  -out /usr/local/etc/stunnel/stunnel.pem

# ...и добавляем его в доверенные, прокидывая права
RUN cp /usr/local/etc/stunnel/stunnel.pem /etc/ssl/certs/ && update-ca-certificates \
    chown root:root /usr/local/etc/stunnel/stunnel.pem \
    chmod 400 /usr/local/etc/stunnel/stunnel.pem

# Создаем pid. Нужен для stunnel
RUN touch /usr/local/etc/stunnel/stunnel.pid

# Разрешаем работу stunnel-а
#RUN echo ENABLED=1 >> /etc/default/stunnel4 && service stunnel4 restart

# Прокидываем конфиг stunnel-а
COPY ../configs/stunnel.conf /usr/local/etc/stunnel/
COPY ../configs/stunnel.pem /usr/local/etc/stunnel/

CMD ["stunnel", "/usr/local/etc/stunnel/stunnel.conf"]