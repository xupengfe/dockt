#!/bin/bash

HTML_FOLDER="/var/www/html"

echo "yum install httpd -y"
yum install httpd -y

echo "mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf_backup"
mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf_backup

mkdir -p $HTML_FOLDER
echo "$(date +%Y-%m-%d_%H:%M:%S) created apache" >> ${HTML_FOLDER}/apache_record.txt

echo "systemctl restart httpd"
systemctl restart httpd

echo "systemctl enable httpd"
systemctl enable httpd
