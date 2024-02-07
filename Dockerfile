FROM nginx:alpine
COPY nginx-default /etc/nginx/conf.d/default.conf
COPY site/ /usr/share/nginx/html
EXPOSE 80

