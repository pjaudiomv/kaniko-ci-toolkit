FROM nginx:alpine

RUN echo "Hello World!" > /usr/share/nginx/html/index.html

RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
