FROM	registry.access.redhat.com/rhscl/nginx-18-rhel7
COPY	index.html /usr/share/nginx/html
COPY	coreos.com_files/ /usr/share/nginx/html/coreos.com_files/
