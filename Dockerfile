FROM	nginx:1.12-alpine
COPY	index.html /usr/share/nginx/html
COPY	coreos.com_files/ /usr/share/nginx/html/coreos.com_files/
