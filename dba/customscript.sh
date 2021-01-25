#!/bin/bash

USERNAME=$1

touch /tmp/sample.txt
whoami >> /tmp/sample.txt
pwd >> /tmp/sample.txt
echo "USERNAME=$USERNAME" >> /tmp/sample.txt

parted /dev/sdb --script mklabel gpt mkpart lvmrootvg xfs 68.7GB  100%
parted /dev/sdc --script mklabel gpt mkpart lvmrootvg xfs 0% 100%
pvcreate /dev/sdb3 /dev/sdc1
pvdisplay
vgextend rootvg /dev/sdb3
vgextend rootvg /dev/sdc1
vgdisplay
lvextend -L +200G /dev/rootvg/homelv
xfs_growfs /dev/mapper/rootvg-homelv
lsblk

### yum update
yum update -y

### jst
sed -ie 's/ZONE=\"UTC\"/ZONE=\"Asia\/Tokyo\"/g' /etc/sysconfig/clock
sed -ie 's/UTC=true/UTC=false/g' /etc/sysconfig/clock
ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

### locale
sed -ie 's/en_US\.UTF-8/ja_JP\.UTF-8/g' /etc/sysconfig/i18n

### mysql
yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm
yum install -y yum-utils
yum-config-manager --disable mysql80-community
yum-config-manager --enable mysql57-community
yum install -y mysql-community-client

### psql
rpm -ivh --nodeps https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sed -i "s/\$releasever/7/g" "/etc/yum.repos.d/pgdg-redhat-all.repo"
yum install -y postgresql12

### sqlplus & odbc
mkdir /opt/oracle
curl https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-basic-linuxx64.rpm -o /opt/oracle/oracle-instantclient-basic-linuxx64.rpm
curl https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-sqlplus-linuxx64.rpm -o /opt/oracle/oracle-instantclient-sqlplus-linuxx64.rpm
curl https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-odbc-linuxx64.rpm -o /opt/oracle/oracle-instantclient-odbc-linuxx64.rpm
yum install -y /opt/oracle/oracle-instantclient-basic-linuxx64.rpm
yum install -y /opt/oracle/oracle-instantclient-sqlplus-linuxx64.rpm
yum install -y /opt/oracle/oracle-instantclient-odbc-linuxx64.rpm
touch /etc/odbc.ini
/usr/lib/oracle/19.9/client64/bin/odbc_update_ini.sh "/"  "/usr/lib/oracle/19.9/client64/lib" "ORACLEODBCDRIVER" RDSORCL /etc/odbc.ini
odbcinst -i -d -f /etc/odbcinst.ini
echo 'export NLS_LANG=Japanese_Japan.AL32UTF8' >> /home/${USERNAME}/.bash_profile

### sqlcmd
curl https://packages.microsoft.com/config/rhel/8/prod.repo > /etc/yum.repos.d/msprod.repo
echo 'export PATH=$PATH:/opt/mssql-tools/bin' >> /home/${USERNAME}/.bash_profile
ACCEPT_EULA=Y yum install -y mssql-tools
