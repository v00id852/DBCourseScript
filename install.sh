#!/bin/bash

# packages name which need to install
packages=('binutils' 'compat-libstdc++-33' 'elfutils-libelf' 'elfutils-libelf-devel' 'elfutils-libelf-devel-static'' gcc' 'gcc-c++' 'glibc' 'glibc-common' 'glibc-devel' 'glibc-headers' 'kernel-headers' 'ksh' 'libaio' 'libaio-devel' 'libgcc' 'libgomp' 'libstdc++' 'libstdc++-devel' 'make' 'numactl-devel' 'sysstat' 'unixODBC' 'unixODBC-devel')

# packages not installed
packages_not_installed=()

function write_log()
{
    local logMsg=$1
    echo "`date +%Y-%m-%d\ %T`: $logMsg" >> install.log
}

function echo_color()
{
    local msg=$1
    case $2 in
    "g")
        echo -e "\033[32m$msg\033[0m"
    ;;
    "r")
        echo -e "\033[31m$msg\033[0m"
    ;;
    "b")
        echo -e "\033[34m$msg\033[0m"
    ;;
    *)
        echo $msg
    esac
}

function check_network(){
    ping -c 3 -i 0.2 -W 3 $1 &> /dev/null          
    if [ $? -eq 0 ]                               
    then  
        return 0
    else                                         
        return -1
    fi  
}

function check_log(){
    local msg=$1
    local status=$2
    if [ $status == 0 ]; then
        echo_color "check ${msg} ...YES" g
        write_log "check ${msg} ...YES"
    else
        echo_color "check ${msg} ...NO" r
        write_log "check ${msg} ...NO"
    fi
}

system_version="0"
check_status=0
sh_path=$(pwd)

write_log "script start"

# check enviroment
echo_color "**********check enviroment**********" b
write_log "check enviroment"

# check system version
system_str=`rpm -q centos-release`
write_log ${system_str}
system_str=(${system_str//-/ })
system_str=${system_str[2]}

if [ ${system_str} != "7" -a ${system_str} != "6" -a ${system_str} != "5" ];  then
    check_log "os version" 1 # check os version failed
    write_log <<< echo_color "ERROR: OS version should be Centos 5/6/7, please check" r
    exit 1
fi

# check whether exists user Oracle

if [[ $(cat /etc/passwd | grep "Oracle") != '' ]]; then
    check_log "whether not exists user Oracle" 1
    userdel -r "Oracle"
else
    check_log "whether exists user Oracle" 0
fi

# check whether exists install package
if [[ $(ls linux.x64_11gR2_database_1of2.zip) = '' ]]; then
    check_log "whether exists database installation package part 1" 1
    check_status=1
    echo_color "ERROR: please put database installation package part 1 in the same folder with install.sh and rename the package to \"linux.x64_11R2_database_1of2.zip\"" r
else 
    check_log "whether exists database installation package part 1" 0
fi

if [[ $(ls linux.x64_11gR2_database_2of2.zip) = '' ]]; then
    check_log "whether exists database installation package part 2" 1
    check_status=1    
    echo_color "ERROR: please put database installation package part 2 in the same folder with install.sh and rename the package to \"linux.x64_11R2_database_2of2.zip\"" r
else 
    check_log "whether exists database installation package part 2" 0
fi

# check_network www.baidu.com
# if [ $? -ne 0 ]; then 
#     check_log "network" 1
#     check_status=1
# else
#     check_log "network" 0
# fi
# if [[ $(ls oracle.sh) = '' ]]; then
#     check_log "whether exists oracle.sh" 1
#     check_status=1
#     echo_color "ERROR: please put oracle.sh in the same folder with install.sh" r
# else 
#     check_log "whether exists oracle.sh" 0
# fi

# check free space
free_disk=(`df | grep /dev | awk '{print $4}' | sed 's/%//g'`)
free_disk=${free_disk[0]}
if [ ${free_disk} -le 2621440 ]; then
    check_log "free space" 1
    check_status=1
    echo_color "ERROR: please make sure your free disk space greater than 2.5GB" r
else
    check_log "free space" 0
fi

# # check network
# ping -c 3 -i 0.2 -W 3 $1 &> /dev/null          
# if [ $? -eq 0 ]                               
# then  
#     check_log "network" 0 
# else                                         
#     check_log "network" 1
#     check_status=1  
# fi  


# check if wget installed
if [[ $(command -v wget) = '' ]]; then
   check_log "whether install wget" 1
   write_log "install wget" 
   yum install wget -y
else
    check_log "whether install wget" 0
fi

# check if unzip installed
if [[ $(command -v unzip) = '' ]]; then
   check_log "whether install unzip" 1
   write_log "install unzip" 
   yum install unzip -y --nogpgcheck
else
    check_log "whether install unzip" 0
fi

if [ ${check_status} == 1 ]; then
    echo_color "ERROR: check failed, exit" r
    write_log "script exits"
    exit 1
fi


echo_color "**********install oracle repos**********" b

echo_color "download repo" b
system_version=${system_str}
write_log "start install oracle repos" b
write_log "os version: ${system_version}"

# download repos
cd /etc/yum.repos.d
case ${system_version} in
    "7")
        if [[ $(ls public-yum-ol7.repo) = '' ]]; then
            wget http://yum.oracle.com/public-yum-ol7.repo
        fi
        ;;
    "6")
        if [[ $(ls public-yum-ol6.repo) = '' ]]; then
            wget http://yum.oracle.com/public-yum-ol6.repo
        fi
        ;;
    "5")
        if [[ $(ls public-yum-ol5.repo) = '' ]]; then
            wget http://yum.oracle.com/public-yum-ol5.repo
        fi
	;;
esac

cd ${sh_path}

echo_color "**********check packages**********" b
write_log "check packages"


for item in ${packages[@]}
do
    if [[ $(rpm -qa | grep ${item}) != '' ]]; then
        echo_color "${item} package has been installed" b
        write_log "${item} package has been installed"
    else 
        echo_color "${item} package has not been installed" b
        write_log "${item} package has not been installed"
        packages_not_installed[${#packages_not_installed[*]}]=${item}    
    fi
done

write_log "check packages end"

# if echo "${packages_not_installed[@]}"; then
#   write_log "compat-libstdc++ has not been installed"
#   wget 'http://mirror.centos.org/centos/6/os/x86_64/Packages/compat-libstdc++-33-3.2.3-69.el6.x86_64.rpm'
#   yum install compat-libstdc++-*.rpm -y
#   rm compat-libstdc++-*.rpm -f
#   packages_not_installed=("${packages_not_installed[@]/compat-libstdc++/}")
# fi

# check system version
echo_color "**********install missing packages**********" b
       
# install repos
need_installed_items=""

if [[ ${#packages_not_installed[@]} != 0 ]]; then
    for item in ${packages_not_installed[@]}
    do
        need_installed_items="${need_installed_items} ${item}"
    done
    yum install ${need_installed_items} -y --nogpgcheck
    write_log "install ${item}"
else
    echo_color "no missing packages" g
fi

echo_color "**********create group and user**********" b
write_log "create group and user start"

# create group and user
groupadd oinstall &>>install.log
groupadd dba &>>install.log
useradd -g oinstall -G dba Oracle &>>install.log

password="pa"
password_again="pass"

echo_color "please input user Oracle's password" r
read -s password
echo_color "please input user Oracle's password again" r
read -s password_again

until [ $password = $password_again ] 
do
    echo_color "passwords are not same, please input again" r
    write_log "passwords are not same"
    echo_color "please input user Oracle's password" r
    read -s password
    echo_color "please input user Oracle's password again" r
    read -s password_again
done
 
echo "Oracle:$password" | chpasswd
write_log <<< echo_color "create user Oracle succeed" g
echo_color "**********create group and user end**********" g

write_log <<< echo_color "**********create diretories**********" b
mkdir -p /home/Oracle_11g
chown -R Oracle:oinstall /home/Oracle_11g
chmod -R 775 /home/Oracle_11g

echo_color "**********modify files**********" b
echo_color "start modify /etc/sysctl.conf" b
# modify /etc/sysctl.conf
echo "fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 2097152
kernel.shmmax = 536870912
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048586" >> /etc/sysctl.conf
sysctl -p &>>install.log
if [[ "$?" != "0" ]]; then
    write_log "sysctl error"
    echo_color "sysctl error, please contact the author" r
else
    write_log <<< echo_color "modify /etc/sysct.conf succeed" g
fi


echo_color "start modify /etc/pam.d/login" b
echo "Oracle soft nproc 2047
Oracle hard nproc 16384
Oracle soft nofile 1024
Oracle hard nofile 65536
Oracle soft stack 10240" >> /etc/security/limits.conf
write_log <<< echo_color "modify /etc/pam.d/login" g

echo_color "start modify /etc/profile" b
echo "if [ \$USER = \"Oracle\" ]; then
    if [ \$SHELL = \"/bin/ksh\" ]; then
        ulimit -p 16384
        ulimit -n 65536
    else
        ulimit -u 16384 -n 65536
    fi
fi" >> /etc/profile
write_log <<< echo_color "modify /etc/profile succed" g

echo_color "**********config user Oracle*********" b

# su - Oracle -s /bin/bash ${sh_path}/oracle.sh

echo "please input SID (you should follow the instructor of the guide book)"
read sid
version_str=`uname -r`
kernel_version=(${version_str//-/ })
kernel_version=${kernel_version[0]}
echo "export ORACLE_BASE=/home/Oracle_11g
export ORACLE_HOME=\$ORACLE_BASE/product/11.2.0/dbhome_1
export ORACLE_SID=${sid}
export PATH=\$ORACLE_HOME/bin:\$PATH
export LD_ASSUME_KERNEL=${kernel_version}
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:\$LD_LIBRARY_PATH
export DISPLAY=:0.0" >> /home/Oracle/.bash_profile


cp /root/.bash* /home/Oracle_11g

echo_color "**********screenshot area start**********" g
su - Oracle -c "env | grep Oracle"
echo_color "**********screenshot area end*********" g
echo_color "please input any key to continue after taking screenshot" b
read
echo_color "**********screenshot area start**********" g
su - Oracle -c "env | grep DISPLAY"
echo_color "**********screnshot end**********" g
echo_color "please input any key to continue after taking screenshot" b
read
echo_color "**********config user Oracle end**********" b

rm /etc/yum.repos.d/public-yum-ol7.repo -rf
rm /etc/yum.repos.d/public-yum-ol6.repo -rf
rm /etc/yum.repos.d/public-yum-ol5.repo -rf


echo_color "**********unzip file**********" b
#unzip
unzip linux.x64_11gR2_database_1of2.zip
unzip linux.x64_11gR2_database_2of2.zip
mv database /home/
chown -R Oracle:oinstall /home/database/
echo_color "**********unzip file end**********" g

echo_color "SUCCESS! please log out and log in as Oracle then follow the guide book 3.2" r

