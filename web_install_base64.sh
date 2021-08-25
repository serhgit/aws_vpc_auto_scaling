#!/bin/bash
yum -y install httpd && systemctl enable httpd && systemctl start httpd && echo "This is WEB instance # $(hostname)" > /var/www/html/index.html && chown nobody. /var/www/html/index.html
