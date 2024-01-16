FROM ubuntu:latest
LABEL authors="yaroslav"

RUN apt-get update && apt-get install -y stunnel4

COPY /config/stunnel.conf /etc/stunnel/
