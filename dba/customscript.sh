#!/bin/bash

USERNAME=$1
LOGFILE=/var/log/customscript.log
SCRIPTDIR=$(cd $(dirname $0); pwd)

# start
touch $LOGFILE
whoami                    >> $LOGFILE
pwd                       >> $LOGFILE
echo "USERNAME=$USERNAME" >> $LOGFILE

# Label name is different for each deployment.
lsblk -o NAME,TYPE | grep disk > ${SCRIPTDIR}/lsblk.txt
while read line || [ -n "${line}" ];
do
    array=(${line})
    if [ "`df | grep -e "${array[0]}" | grep -e "boot"`" ]; then
        echo "${array[0]} is os_disk."   >> $LOGFILE
        OSDISK="${array[0]}"
    fi
    if [ ! "`df | grep -e "${array[0]}"`" ]; then
        echo "${array[0]} is data_disk." >> $LOGFILE
        DATADISK="${array[0]}"
    fi
done < ${SCRIPTDIR}/lsblk.txt

# disck setting
sgdisk -e /dev/${OSDISK}                                               >> $LOGFILE 2>&1
lsblk                                                                  >> $LOGFILE 2>&1
parted -s /dev/${OSDISK}   -- mkpart lvmrootvg xfs 68.7GB  100%        >> $LOGFILE 2>&1
parted -s /dev/${DATADISK} -- mklabel gpt mkpart lvmrootvg xfs 0% 100% >> $LOGFILE 2>&1
lsblk                                                                  >> $LOGFILE 2>&1
pvcreate /dev/${OSDISK}3 /dev/${DATADISK}1                             >> $LOGFILE 2>&1
vgextend rootvg /dev/${OSDISK}3                                        >> $LOGFILE 2>&1
vgextend rootvg /dev/${DATADISK}1                                      >> $LOGFILE 2>&1
lvextend -L +200G /dev/rootvg/homelv                                   >> $LOGFILE 2>&1
xfs_growfs /dev/mapper/rootvg-homelv                                   >> $LOGFILE 2>&1
lsblk                                                                  >> $LOGFILE 2>&1
pvdisplay                                                              >> $LOGFILE 2>&1
vgdisplay                                                              >> $LOGFILE 2>&1

### yum update
yum update -y                                                          >> $LOGFILE 2>&1

### jst
sed -ie 's/ZONE=\"UTC\"/ZONE=\"Asia\/Tokyo\"/g' /etc/sysconfig/clock   >> $LOGFILE 2>&1
sed -ie 's/UTC=true/UTC=false/g' /etc/sysconfig/clock                  >> $LOGFILE 2>&1
ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime                   >> $LOGFILE 2>&1

### locale
sed -ie 's/en_US\.UTF-8/ja_JP\.UTF-8/g' /etc/sysconfig/i18n            >> $LOGFILE 2>&1

### mysql
yum install -y mysql                                                   >> $LOGFILE 2>&1
yum install -y mysql-server                                            >> $LOGFILE 2>&1

### psql
yum install -y postgresql postgresql-server                            >> $LOGFILE 2>&1

### sqlplus & odbc
mkdir /opt/oracle                                                      >> $LOGFILE 2>&1
curl https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-basic-linuxx64.rpm -o /opt/oracle/oracle-instantclient-basic-linuxx64.rpm      >> $LOGFILE 2>&1
curl https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-sqlplus-linuxx64.rpm -o /opt/oracle/oracle-instantclient-sqlplus-linuxx64.rpm  >> $LOGFILE 2>&1
sleep 5
yum install -y /opt/oracle/oracle-instantclient-basic-linuxx64.rpm     >> $LOGFILE 2>&1
yum install -y /opt/oracle/oracle-instantclient-sqlplus-linuxx64.rpm   >> $LOGFILE 2>&1
echo 'export NLS_LANG=Japanese_Japan.AL32UTF8' >> /home/${USERNAME}/.bash_profile           >> $LOGFILE 2>&1

### sqlcmd
curl https://packages.microsoft.com/config/rhel/8/prod.repo > /etc/yum.repos.d/msprod.repo  >> $LOGFILE 2>&1
sleep 5
ACCEPT_EULA=Y yum install -y mssql-tools                                                    >> $LOGFILE 2>&1
echo 'export PATH=$PATH:/opt/mssql-tools/bin' >> /home/${USERNAME}/.bash_profile            >> $LOGFILE 2>&1
