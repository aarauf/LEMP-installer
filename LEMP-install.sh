#!/bin/bash
# This script is based on the DigitalOcean instructional "How to install LEMP stack on Ubuntu 12.04" by Etel Sverdlov. Originally published and stable on Ubuntu 14.04.
echo "This script will automatically install a functional LEMP stack unattended by the user. You must be connected to the internet for this work!"

# Comment this section out and jump down to the next section to set your own defaults for a truly unattended install...
echo "Before we begin installing, please enter a ROOT PASSWORD for MYSQL:"
read -s mp
echo "Please enter the password once more to confirm:"
read -s pq
while [ $mp != $pq ]; do
	echo "Password does not match, please try again:"
	read -s pq
done
echo "MYSQL ROOT password saved!"

echo "Please enter the domains or ip addresses you would like to use for your website (separated by spaces, using * for wildcards; use LOCALHOST for local-only server):"
read server_name
echo "Server name saved!"

# Uncomment this section and fill in the variables to create a fully automated script
# MYSQL password
# mp = ""
# NGINX server name
# server_name = ""

# The rest should be goood to go.

echo "LEMP INSTALLER: Beginning install"

debconf-set-selections <<< "mysql-server mysql-server/root_password password $mp"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $mp"

echo "LEMP INSTALLER: Adding NGINX repo to your system"
deb http://ppa.launchpad.net/nginx/stable/ubuntu $(lsb_release -sc) main | tee /etc/apt/sources.list.d/nginx-stable.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C

echo "LEMP INSTALLER: Starting with an apt-get update"
apt-get update

echo "LEMP INSTALLER: Installing mysql-server and php5-mysql"
apt-get install -y mysql-server php5-mysql

echo "LEMP INSTALLER: Activating up mysql"
mysql_install_db

echo "LEMP INSTALLER: Saving MySQL Secure Setup"
spawn /usr/local/mysql/bin/mysql_secure_installation
expect "Enter current password for root (enter for none):"
send "$mp\r"
expect "Set root password?"
send "n\r"
#expect "New password:"
#send "\r"
#expect "Re-enter new password:"
#send "password\r"
expect "Remove anonymous users?"
send "y\r"
expect "Disallow root login remotely?"
send "y\r"
expect "Remove test database and access to it?"
send "y\r"
expect "Reload privilege tables now?"
send "y\r"
echo "LEMP INSTALLER: Done saving MySQL secure setup."

echo "LEMP INSTALLER: Installing NGINX"
apt-get install -y nginx

echo "LEMP INSTALLER: Starting NGINX"
service nginx start

echo "LEMP INSTALLER: Installing php5"
apt-get install php5-fpm

echo "LEMP INSTALLER: Setting CGI.FIX_PATHINFO to 0"
sed -i 's/cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php5/fpm/php.ini

echo "LEMP INSTALLER: Adjusting php listen"
sed -i 's/listen = 127.0.0.1:9000/listen = /var/run/php5-fpm.sock/g' /etc/php5/fpm/pool.d/www.conf

echo "LEMP INSTALLER: restarting php"
service php5-fpm restart

echo "LEMP INSTALLER: Configuring NGINX"
echo "LEMP INSTALLER: Setting server_name to $server_name"
sed -i "s/server_name example.com/server_name $server_name/g" /etc/nginx/sites-available/default
sed -i 's/index index.html index.htm/index index.php index.html index.htm/g' /etc/nginx/sites-available/default
echo "LEMP INSTALLER: Creating a php-info page"
echo '<?php phpinfo(); ?>' > /usr/share/nginx/www/info.php
echo "LEMP INSTALLER: Restarting NGINX one last time..."
service nginx restart

echo "LEMP INSTALLER: Setup complete! Test your new server by entering LOCALHOST in your local browser or any of the server names you set."


exit
