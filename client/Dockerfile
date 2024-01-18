FROM ubuntu:latest

# потом убрать курл и нано
RUN apt-get update && apt-get install -y stunnel4 curl nano

EXPOSE 443

COPY configs/stunnel.conf /etc/stunnel/
COPY pems/stunnel.pem /etc/stunnel/

RUN mkdir stunnel4
RUN touch /stunnel4/stunnel.log
RUN touch /stunnel4/stunnel.pid

RUN chown root:root /etc/stunnel/stunnel.pem
RUN chmod 400 /etc/stunnel/stunnel.pem

RUN echo "ENABLED=1" | cat - /etc/default/stunnel4 > tmp_file && mv tmp_file /etc/default/stunnel4

CMD ["sh", "-c", "stunnel /etc/stunnel/stunnel.conf"]
