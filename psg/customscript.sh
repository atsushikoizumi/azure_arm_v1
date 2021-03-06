#!/bin/bash

USERNAME=$1
LOGFILE=/var/log/customscript.log

# start
touch $LOGFILE
whoami                    >> $LOGFILE
pwd                       >> $LOGFILE
echo "USERNAME=$USERNAME" >> $LOGFILE

## for RHEL disk setting
## Label name is different for each deployment.
#SCRIPTDIR=$(cd $(dirname $0); pwd)
#lsblk -o NAME,TYPE | grep disk > ${SCRIPTDIR}/lsblk.txt
#while read line || [ -n "${line}" ];
#do
#    array=(${line})
#    if [ "`df | grep -e "${array[0]}" | grep -e "boot"`" ]; then
#        echo "${array[0]} is os_disk."   >> $LOGFILE
#        OSDISK="${array[0]}"
#    fi
#    if [ ! "`df | grep -e "${array[0]}"`" ]; then
#        echo "${array[0]} is data_disk." >> $LOGFILE
#        DATADISK="${array[0]}"
#    fi
#done < ${SCRIPTDIR}/lsblk.txt
#
## disck setting
#sgdisk -e /dev/${OSDISK}                                               >> $LOGFILE 2>&1
#lsblk                                                                  >> $LOGFILE 2>&1
#parted -s /dev/${OSDISK}   -- mkpart lvmrootvg xfs 68.7GB  100%        >> $LOGFILE 2>&1
#parted -s /dev/${DATADISK} -- mklabel gpt mkpart lvmrootvg xfs 0% 100% >> $LOGFILE 2>&1
#lsblk                                                                  >> $LOGFILE 2>&1
#pvcreate /dev/${OSDISK}3 /dev/${DATADISK}1                             >> $LOGFILE 2>&1
#vgextend rootvg /dev/${OSDISK}3                                        >> $LOGFILE 2>&1
#vgextend rootvg /dev/${DATADISK}1                                      >> $LOGFILE 2>&1
#lvextend -L +100G /dev/rootvg/homelv                                   >> $LOGFILE 2>&1
#xfs_growfs /dev/mapper/rootvg-homelv                                   >> $LOGFILE 2>&1
#lsblk                                                                  >> $LOGFILE 2>&1
#pvdisplay                                                              >> $LOGFILE 2>&1
#vgdisplay                                                              >> $LOGFILE 2>&1

### yum update
yum update -y                                                          >> $LOGFILE 2>&1

### jst
sed -ie 's/ZONE=\"UTC\"/ZONE=\"Asia\/Tokyo\"/g' /etc/sysconfig/clock
sed -ie 's/UTC=true/UTC=false/g' /etc/sysconfig/clock
ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

### locale
sed -ie 's/en_US\.UTF-8/ja_JP\.UTF-8/g' /etc/sysconfig/i18n

### mysql
yum install -y mysql                                                   >> $LOGFILE 2>&1
yum install -y mysql-server                                            >> $LOGFILE 2>&1

### psql
#yum install -y postgresql postgresql-server                            >> $LOGFILE 2>&1
yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm  >> $LOGFILE 2>&1
dnf -qy module disable postgresql                                      >> $LOGFILE 2>&1
dnf -y install postgresql12 postgresql12-server                        >> $LOGFILE 2>&1

### sqlplus
mkdir /opt/oracle                                                      >> $LOGFILE 2>&1
curl https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-basic-linuxx64.rpm -o /opt/oracle/oracle-instantclient-basic-linuxx64.rpm
curl https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-sqlplus-linuxx64.rpm -o /opt/oracle/oracle-instantclient-sqlplus-linuxx64.rpm
yum install -y /opt/oracle/oracle-instantclient-basic-linuxx64.rpm     >> $LOGFILE 2>&1
yum install -y /opt/oracle/oracle-instantclient-sqlplus-linuxx64.rpm   >> $LOGFILE 2>&1
echo 'export NLS_LANG=Japanese_Japan.AL32UTF8' >> /home/${USERNAME}/.bash_profile

### sqlcmd
curl https://packages.microsoft.com/config/rhel/8/prod.repo -o /etc/yum.repos.d/msprod.repo 
ACCEPT_EULA=Y yum install -y mssql-tools                               >> $LOGFILE 2>&1
echo 'export PATH=$PATH:/opt/mssql-tools/bin'  >> /home/${USERNAME}/.bash_profile

### az cli
rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/azure-cli.repo
yum install -y azure-cli                                               >> $LOGFILE 2>&1

