FROM ubuntu:latest

ENV STUNNEL_VERSION=5.72b3
ENV OPENSSL_VERSION=3.2.0

EXPOSE 443

RUN apt-get update

RUN apt-get update && apt-get install -y ca-certificates net-tools lsof nano build-essential wget #stunnel4

# OpenSSL 3.2.0
RUN wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
    && tar -zxvf openssl-${OPENSSL_VERSION}.tar.gz

# Ставим
RUN cd openssl-${OPENSSL_VERSION} \
    && ./config \
    && make \
    && make install \
    && ldconfig

# Stunnel 5.72b3
RUN wget https://www.stunnel.org/downloads/stunnel-${STUNNEL_VERSION}.tar.gz \
    && tar -zxvf stunnel-${STUNNEL_VERSION}.tar.gz

# Ставим
RUN cd stunnel-${STUNNEL_VERSION} \
    && ./configure --with-ssl=/usr/local/ssl \
    && make \
    && make install

# Чистим
RUN rm -rf /openssl-${OPENSSL_VERSION} \
    && rm -rf /stunnel-${STUNNEL_VERSION} \
    && rm -f /stunnel-${STUNNEL_VERSION}.tar.gz \
    && apt-get remove -y build-essential wget \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=RU/ST=VLG/L=Volgograd/O=OBT/CN=192.168.48.3" \
    -keyout /etc/stunnel/stunnel.pem  -out /etc/stunnel/stunnel.pem

RUN cp /etc/stunnel/stunnel.pem /etc/ssl/certs/ && update-ca-certificates \
    chown root:root /etc/stunnel/stunnel.pem \
    chmod 400 /etc/stunnel/stunnel.pem

RUN touch /etc/stunnel/stunnel.pid

RUN echo ENABLED=1 >> /etc/default/stunnel4 && service stunnel4 restart

COPY ../configs/stunnel.conf /etc/stunnel/

CMD ["stunnel", "/etc/stunnel/stunnel.conf"]