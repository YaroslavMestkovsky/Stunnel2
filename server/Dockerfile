# Контейнер с NJINX. Отдает html-ку. Сюда можно будет попасть только через stunnel из другого докера.
FROM nginx:latest

# Ставим stunnel
#RUN apt-get update && apt-get install -y stunnel

EXPOSE 80
EXPOSE 443

# Рисуем кастомное сообщение об успехе
COPY html/index.html /usr/share/nginx/html

CMD ["nginx", "-g", "daemon off;"]