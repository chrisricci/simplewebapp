FROM	quay.io/chris_ricci/nginx-112-rhel7:1-16
COPY	index.html /usr/share/nginx/html
COPY	coreos.com_files/ /usr/share/nginx/html/coreos.com_files/
