FROM	nginx
COPY	index.html /usr/share/nginx/html
COPY	files/ /usr/share/nginx/html/files/
EXPOSE 8080
CMD ["/bin/sh", "-c", "sed -i 's/listen  .*/listen 8080;/g' /etc/nginx/conf.d/default.conf && exec nginx -g 'daemon off;'"]