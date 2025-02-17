#!/bin/bash

#sudo printf 'LC_ALL=en_US.UTF-8' >> /etc/default/locale

#password
echo Your password for connecting to PSQL DB with Odoo user: 
password=$(tr -dc 'A-Za-z0-9!?%=' < /dev/urandom | head -c 25) && echo "$password"

echo -n Enter username:
read user

echo -n Enter port:
read port

echo -n Enter Odoo branch:
read branch

# Ask the user whether to install Odoo Enterprise
read -p "Install Enterprise? (yes/no): " install_enterprise
# Convert input to lowercase for consistency
install_enterprise=${install_enterprise,,}

#apt
sudo apt update && apt upgrade && apt install -y sudo wget git python3 python3-pip postgresql postgresql-client

#user and folder setup
sudo adduser --system --home=/opt/$user --group $user
sudo -u postgres psql -c "CREATE USER '$user' WITH SUPERUSER PASSWORD '$password';"

sudo mkdir /opt/$user /opt/$user/backup /opt/$user/custom /var/log/$user
if [[ "$install_enterprise" == "yes" ]]; then
	sudo mkdir /opt/$user/enterprise
	sudo chown $user:$user /opt/$user/enterprise
	sudo git clone https://github.com/odoo/enterprise.git --depth 1 --branch $branch --single-branch /opt/$user/enterprise
fi

#install odoo+requirements
#pip install pyOpenSSL fisk pysftp
sudo git clone https://www.github.com/odoo/odoo --depth 1 --branch $branch --single-branch /opt/$user
sudo /opt/$user/setup/debinstall.sh


#wkhtmltopdf
wget -O /opt/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb
sudo dpkg -i /opt/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb

#conf file
if [[ "$install_enterprise" == "yes" ]]; then
	cat > /etc/'"$user.conf"' <<EOF
	[options]
	addons_path = /opt/'"$home"'/addons,/opt/'"$user"'/enterprise,/opt/'"$user"'/custom
	db_host = localhost
	db_port = 5432
	db_user = '"$user"'
	db_password = '"$password"'
	logfile = /var/log/'"$user"'/odoo.log
	http_port = '"$port"'
	EOF'
else
	cat > /etc/'"$user.conf"' <<EOF
	[options]
	addons_path = /opt/'"$user"'/addons,/opt/'"$user"'/custom
	db_host = localhost
	db_port = 5432
	db_user = '"$user"'
	db_password = '"$password"'
	logfile = /var/log/'"$user"'/odoo.log
	http_port = '"$port"'
	EOF'
fi


#owner
sudo chown $user:$user /etc/$user.conf && chown -R $user:$user /opt/$user && chown -R $user:$user /var/log/$user


#service file
cat > /etc/systemd/system/odoo.service <<EOF
[Unit]
Description=Odoo $user $branch $port
Documentation=http://www.odoo.com
[Service]
# Ubuntu/Debian convention:
Type=simple
User=$user
ExecStart=/opt/$user/odoo-bin -c /etc/$user.conf
[Install]
WantedBy=default.target
EOF


sudo chmod 755 /lib/systemd/system/$user-server.service
sudo chown root: /lib/systemd/system/$user-server.service

printf -n DONE!
