#!/usr/bin/env bash
 
# BEGIN ########################################################################
echo -e "-- ---------- --\n"
echo -e "-- BEGIN ${HOSTNAME} --\n"
echo -e "-- ---------- --\n"
 
# VARIABLES ####################################################################
echo -e "-- Setting global variables\n"
APACHE_CONFIG=/etc/apache2/apache2.conf
SITES_ENABLED=/etc/apache2/sites-enabled
LOCALHOST=localhost
 
# BOX ##########################################################################
echo -e "-- Updating packages list\n"
apt-get update -y -qq
 
# APACHE #######################################################################
echo -e "-- Installing Apache web server\n"
apt-get install -y apache2 > /dev/null 2>&1
 
echo -e "-- Adding ServerName to Apache config\n"
grep -q "ServerName ${LOCALHOST}" "${APACHE_CONFIG}" || echo "ServerName ${LOCALHOST}" >> "${APACHE_CONFIG}"
 
echo -e "-- Updating vhost file\n"

cat > ${SITES_ENABLED}/000-default.conf <<EOF
<VirtualHost *:80>
	DocumentRoot /var/www/html
 
	SetEnvIf Request_Method OPTIONS do-not-log-haproxy-ping
	ErrorLog /var/log/apache2/error.log
	CustomLog /var/log/apache2/access.log combined env=!do-not-log-haproxy-ping
</VirtualHost>
EOF
 
echo -e "-- Adding a custom LogFormat to Apache config catch client's request IP\n"
grep -q 'LogFormat "%{X-Forwarded-For}i %l %u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\"" combined' ${APACHE_CONFIG} || echo 'LogFormat "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined' >> ${APACHE_CONFIG}
 
echo -e "-- Restarting Apache web server\n"
service apache2 restart
 
# TEST #########################################################################
echo -e "-- Creating a dummy index.html file\n"
cat > /var/www/html/index.html <<EOD
<html>
<head>
<title>${HOSTNAME}</title>
</head>
<body>
<h1>${HOSTNAME}</h1>
<p>Hi sir, I am going to serve you today!</p>
</body>
</html>
EOD
 
# END ##########################################################################
echo -e "-- -------- --"
echo -e "-- END ${HOSTNAME} --"
echo -e "-- -------- --"
