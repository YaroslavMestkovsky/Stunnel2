FROM ubuntu:latest

RUN apt-get update

RUN apt-get update && apt-get install ca-certificates stunnel4 -y

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