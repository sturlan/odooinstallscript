#!/bin/bash

#Skripta v1.4 za instalaciju odoo-a v10.0
#Change log:
#v1.4
#	Added folder and privileges setup, added curl and disk as requirement
#	Fixed break line in service file
#v1.3
#	Added nodejs-legacy to requirements
#v1.2
#	Added backup requirements
#v1.1
#	Added -y to update and upgrade section
#	Added info line for PSQL pwd creation
#	Updated systemd file creation

sudo printf 'LC_ALL=en_US.UTF-8' >> /etc/default/locale

#Postgres pwd
echo -n Create Postgres Admin password: 
read -s password

#update and upgrade
sudo apt update -y && sudo apt upgrade -y

#firewall
echo "y" | sudo ufw allow ssh
echo "y" | sudo ufw allow 8069/tcp
echo "y" | sudo ufw allow 80
echo "y" | sudo ufw allow 443
echo "y" | sudo ufw enable

#requirements
sudo apt-get install -y  git python-pip postgresql postgresql-server-dev-9.5 python-all-dev python-dev python-setuptools libxml2-dev libxslt1-dev libevent-dev libsasl2-dev libldap2-dev pkg-config libtiff5-dev libjpeg8-dev libjpeg-dev zlib1g-dev libfreetype6-dev liblcms2-dev liblcms2-utils libwebp-dev tcl8.6-dev tk8.6-dev python-tk libyaml-dev fontconfig npm unzip nodejs-legacy curl

#user and folder setup
sudo -i -u postgres psql -c "CREATE USER odoo WITH PASSWORD '$password';"
sudo -i -u postgres psql -c "ALTER ROLE odoo WITH  CREATEDB"
sudo adduser --system --home=/opt/odoo --group odoo
sudo mkdir /opt/backup
sudo mkdir /opt/odoo
sudo mkdir /opt/custom
sudo chown odoo:root /opt/odoo
sudo chown odoo:root /opt/custom
sudo chown odoo:root /opt/backup

#log
sudo mkdir /var/log/odoo

#install odoo+requirements
pip install pyOpenSSL fisk
pip install pysftp==0.2.8
sudo git clone https://www.github.com/odoo/odoo --depth 1 --branch 10.0 --single-branch /opt/odoo
sudo pip install -r /opt/odoo/doc/requirements.txt
sudo pip install -r /opt/odoo/requirements.txt
sudo curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g less less-plugin-clean-css

#wkhtmltopdf
mkdir /tmp
sudo wget https://downloads.wkhtmltopdf.org/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb -P /tmp/
sudo dpkg -i /tmp/wkhtmltox-0.12.1_linux-trusty-amd64.deb
sudo cp /usr/local/bin/wkhtmltopdf /usr/bin
sudo cp /usr/local/bin/wkhtmltoimage /usr/bin
sudo cp /opt/odoo/debian/odoo.conf /etc/odoo-server.conf

#service file
sudo touch /lib/systemd/system/odoo-server.service
sudo printf '[Unit]
Description=Odoo Open Source ERP and CRM
Requires=postgresql.service
After=network.target postgresql.service
\n
[Service]
Type=simple
PermissionsStartOnly=true
SyslogIdentifier=odoo-server
User=odoo
Group=odoo
ExecStart=/opt/odoo/odoo-bin --config=/etc/odoo-server.conf --addons-path=/opt/odoo/addons/
WorkingDirectory=/opt/odoo/
StandardOutput=journal+console
\n
[Install]
WantedBy=multi-user.target' >> /lib/systemd/system/odoo-server.service

sudo chmod 755 /lib/systemd/system/odoo-server.service
sudo chown root: /lib/systemd/system/odoo-server.service
sudo chown -R odoo: /opt/odoo/
sudo chown odoo:root /var/log/odoo
sudo chown odoo: /etc/odoo-server.conf
sudo chmod 640 /etc/odoo-server.conf
sudo systemctl start odoo-server.service
sudo systemctl enable odoo-server.service
sudo systemctl status odoo-server.service


printf -n DONE!

