#!/bin/bash
# packages name which need to install
packages=('binutils' 'compat-libstdc++-33' 'elfutils-libelf' 'elfutils-libelf-devel' 'elfutils-libelf-devel-static' 'gcc' 'gcc-c++' 'glibc' 'glibc-common' 'glibc-devel' 'glibc-headers' 'kernel-headers' 'ksh' 'libaio' 'libaio-devel' 'libgcc' 'libgomp' 'libstdc++' 'libstdc++-devel' 'make' 'numactl-devel' 'sysstat' 'unixODBC' 'unixODBC-devel')

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

function check_enter_key()
{
    read -r -s -n 1 key
    until [[ $key == "" ]]
    do
        echo_color "请在弹出的新终端截图并关闭新终端，然后按 ENTER 进入下一步" g
        read -r -s -n 1 key
    done
}

function check_log(){
    local msg=$1
    local status=$2
    if [ $status == 0 ]; then
        echo_color "检查 ${msg} ...YES" g
        write_log "检查 ${msg} ...YES"
    else
        echo_color "检查 ${msg} ...NO" r
        write_log "检查 ${msg} ...NO"
    fi
}

echo_color "*************** UESTC 信通数据库课程自动配置脚本 *********************" r
echo_color "* 作者：雷子昂" r
echo_color "* Email: zianglei@126.com" r
echo_color "* Date: 2017-10-22" r
echo_color "* 如果你发现了任何BUG或者有任何意见，随时可以联系我或者在github上提issue" r
echo_color "* GitHub: https://github.com/zianglei/DBCourseScript" r
echo_color "******************************************************************" r

# check whether run as root
if [ "$EUID" -ne 0 ]
    then echo_color "请使用root用户运行该脚本" r
    write_log "user run not as root"
    exit 1
fi

# check enviroment
echo_color "********** 检查运行环境 **********" b
write_log "check enviroment"

# check system version
system_str=`rpm -q centos-release`
write_log ${system_str}
system_str=(${system_str//-/ })
system_str=${system_str[2]}

if [ ${system_str} != "7" -a ${system_str} != "6" -a ${system_str} != "5" ];  then
    check_log "os version" 1 # check os version failed
    write_log <<< echo_color "ERROR: OS version should be Centos 5/6/7, please check your OS version" r
    exit 1
fi

# check whether exists user Oracle

if [[ $(cat /etc/passwd | grep "Oracle") != '' ]]; then
    check_log "是否 Oracle 用户不存在" 1
    userdel -r "Oracle"
else
    check_log "是否 Oracle 用户不存在" 0
fi

# check whether exists install package
if [[ $(ls linux.x64_11gR2_database_1of2.zip) = '' ]]; then
    check_log "是否存在数据库安装包 Part 1" 1
    check_status=1
    echo_color "ERROR: 请确数据库安装包 Part 1 与 install.sh 脚本在同一文件夹下，并且名称为\"linux.x64_11R2_database_1of2.zip\"" r
else 
    check_log "whether exists database installation package part 1" 0
fi

if [[ $(ls linux.x64_11gR2_database_2of2.zip) = '' ]]; then
    check_log "是否存在数据库安装文件 Part 2" 1
    check_status=1    
    echo_color "ERROR: 请确数据库安装包 Part 2 与 install.sh 脚本在同一文件夹下，并且名称为\"linux.x64_11R2_database_2of2.zip\"" r
else 
    check_log "whether exists database installation package part 2" 0
fi

# check free space

if [[ ${check_status} = 1 ]]; then
    echo_color "ERROR: 检查环境失败，请根据提示修改环境后重新运行" r
    write_log "script exits"
    exit 1
fi

# check if wget installed
if [[ $(command -v wget) = '' ]]; then
   check_log "是否安装 wget" 1
   echo_color "安装wget..." b
   write_log "install wget" 
   yum install wget -y
else
    check_log "whether install wget" 0
fi

# check if unzip installed
if [[ $(command -v unzip) = '' ]]; then
   check_log "是否安装 unzip" 1
   write_log "install unzip" 
   echo_color "安装unzip..." b
   yum install unzip -y --nogpgcheck
else
    check_log "whether install unzip" 0
fi

# check if expect installed
if [[ $(command -v expect) = '' ]]; then
    check_log "是否安装 expect" 1
    write_log "install expect"
    echo_color "安装expect..." b
    yum install expect -y
else
    check_log "是否安装 expect" 0
fi


# show OS version
echo '#!/usr/bin/expect' > check_os_version.sh
echo 'spawn -noecho bash' >> check_os_version.sh
echo 'expect "#"' >> check_os_version.sh
echo 'send "cat /proc/version\r"' >> check_os_version.sh
echo 'send "uname -r\r"' >> check_os_version.sh
echo 'interact' >> check_os_version.sh
chmod +x ./check_os_version.sh

# echo_color "报告截图环节" b
echo_color "查看 OS 版本，请在弹出的新终端截图并关闭新终端，然后按 ENTER 进入下一步" g
gnome-terminal -e ./check_os_version.sh
write_log "check os version successfully."
check_enter_key

# # show memory size
echo '#!/usr/bin/expect' > check_memory_size.sh
echo 'spawn -noecho bash' >> check_memory_size.sh
echo 'expect "#"' >> check_memory_size.sh
echo 'send "grep MemTotal /proc/meminfo\r"' >> check_memory_size.sh
echo 'interact' >> check_memory_size.sh
chmod +x ./check_memory_size.sh
echo_color "查看机器内存大小，请在弹出的新终端截图并关闭新终端，然后按 ENTER 进入下一步" g
gnome-terminal -e ./check_memory_size.sh
write_log "check memory size successfully."
check_enter_key

# # show swap memory size
echo '#!/usr/bin/expect' > check_swap_memory.sh
echo 'spawn -noecho bash' >> check_swap_memory.sh
echo 'expect "#"' >> check_swap_memory.sh
echo 'send "grep SwapTotal /proc/meminfo\r"' >> check_swap_memory.sh
echo 'interact' >> check_swap_memory.sh
chmod +x ./check_swap_memory.sh
echo_color "查看 swap 空间大小，请在弹出的新终端截图并关闭新终端，然后按 ENTER 进入下一步" g
gnome-terminal -e ./check_swap_memory.sh
write_log "check swap memory size successfully."
check_enter_key

# # show /tmp size
echo '#!/usr/bin/expect' > check_tmp_size.sh
echo 'spawn -noecho bash' >> check_tmp_size.sh
echo 'expect "#"' >> check_tmp_size.sh
echo 'send "df -h /tmp\r"' >> check_tmp_size.sh
echo 'interact' >> check_tmp_size.sh
chmod +x ./check_tmp_size.sh
echo_color "查看 /tmp 目录空闲空间，请在弹出的新终端截图并关闭新终端，然后按 ENTER 进入下一步" g
gnome-terminal -e ./check_tmp_size.sh
write_log "check /tmp free space size."
check_enter_key


# # show sizes of every disks
echo '#!/usr/bin/expect' > check_disk_size.sh
echo 'spawn -noecho bash' >> check_disk_size.sh
echo 'expect "#"' >> check_disk_size.sh
echo 'send "df -h\r"' >> check_disk_size.sh
echo 'interact' >> check_disk_size.sh
chmod +x ./check_disk_size.sh
echo_color "查看机器中的每个磁盘的空闲空间，请在弹出的新终端截图并关闭新终端，然后按 ENTER 进入下一步" g
gnome-terminal -e ./check_disk_size.sh
write_log "check disk free space size."
check_enter_key

echo '#!/usr/bin/expect' > check_software.sh
echo 'spawn -noecho bash' >> check_software.sh
echo 'expect "#"' >> check_software.sh
for item in ${packages[@]}
do
    echo 'send "rpm -qa | grep '${item}'\r"' >> check_software.sh
done
echo 'interact' >> check_software.sh
chmod +x ./check_software.sh
echo_color "查看安装的软件情况，请在弹出的新终端截图并关闭新终端，然后按 ENTER 进入下一步" g
gnome-terminal -e ./check_software.sh
write_log "check software."
check_enter_key

system_version="0"
check_status=0
sh_path=$(pwd)


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



# # check network
# ping -c 3 -i 0.2 -W 3 $1 &> /dev/null          
# if [ $? -eq 0 ]                               
# then  
#     check_log "network" 0 
# else                                         
#     check_log "network" 1
#     check_status=1  
# fi  

echo_color "**********安装 Oracle 相关库**********" b

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

echo_color "********** 检查软件库 **********" b
write_log "check packages"

for item in ${packages[@]}
do
    if [[ $(rpm -qa | grep ${item}) != '' ]]; then
        echo_color "${item} 软件库已经被安装" b
        write_log "${item} package has been installed"
    else 
        echo_color "${item} 软件库没有被安装" b
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
echo_color "********** 安装未安装的库 **********" b
       
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

echo_color "********** 创建用户组和用户 **********" b
write_log "create group and user start"

# create group and user
groupadd oinstall &>>install.log
groupadd dba &>>install.log
useradd -g oinstall -G dba Oracle &>>install.log

password="pa"
password_again="pass"

echo_color "输入 Oracle 用户的密码: " r
read -s password
echo_color "再次输入 Oracle 用户的密码 " r
read -s password_again

until [ $password = $password_again ] 
do
    echo_color "两次输入不相同！" r
    write_log "passwords are not same"
    echo_color "输入 Oracle 用户的密码: " r
    read -s password
    echo_color "再次输入 Oracle 用户的密码 " r
    read -s password_again
done
 
echo "Oracle:$password" | chpasswd
write_log <<< echo_color "create user Oracle succeed" g

write_log <<< echo_color "********** 创建文件夹 **********" b
mkdir -p /home/Oracle_11g
chown -R Oracle:oinstall /home/Oracle_11g
chmod -R 775 /home/Oracle_11g

echo_color "********** 修改配置文件 **********" b
echo_color "修改 /etc/sysctl.conf" g
# modify /etc/sysctl.conf
if [[ $(cat /etc/sysctl.conf | grep "aio-max-nr") = '' ]]; then
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
	    echo_color "执行 sysctl 失败, 请联系作者 " r
	else
	    write_log <<< echo_color "modify /etc/sysct.conf succeed" g
	fi
else
    write_log "/etc/sysctl.conf has been modified"
fi

echo_color "修改 /etc/security/limits.conf" g
if [[ $(cat /etc/security/limits.conf | grep "Oracle" ) = '' ]]; then
echo "Oracle soft nproc 2047
Oracle hard nproc 16384
Oracle soft nofile 1024
Oracle hard nofile 65536
Oracle soft stack 10240" >> /etc/security/limits.conf
write_log <<< echo_color "modify /etc/security/limits.conf" g
else
    write_log "/etc/security/limits.conf has been modified" 
fi

echo_color "修改 /etc/pam.d/login" g
if [[ $(cat /etc/pam.d/login | grep "pam_limits" ) = '' ]]; then
echo "session required /lib/security/pam_limits.so
session required pam_limits.so" >> /etc/pam.d/login
write_log <<< echo_color "modify etc/pam.d/login" g
else
    write_log "etc/pam.d/login has been modified" 
fi


echo_color "修改 /etc/profile" g
if [[ $(cat /etc/profile | grep "Oracle" ) = '' ]]; then
echo "if [ \$USER = \"Oracle\" ]; then
    if [ \$SHELL = \"/bin/ksh\" ]; then
        ulimit -p 16384
        ulimit -n 65536
    else
        ulimit -u 16384 -n 65536
    fi
fi" >> /etc/profile
write_log "modify /etc/profile succeed"
else 
    write_log "/etc/profile has been modified"
fi

echo_color "********** 配置 Oracle 用户*********" b

# su - Oracle -s /bin/bash ${sh_path}/oracle.sh

echo_color "请输入你的SID（请根据指导书实验步骤2.5的要求输入：" r
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

if [[ ${system_version} = '7' ]]; then
    echo_color "警告: 你的系统版本为 Centos 7, 所以脚本不会添加\"DISPLAY=:0.0\"到\"/home/Oracle/.bash_profile\"文件" r
else
    echo "export DISPLAY=:0.0" >> /home/Oracle/.bash_profile
fi

cp /root/.bash* /home/Oracle_11g

echo_color "********** 截图时间 **********" r

echo '#!/usr/bin/expect' > check_env_size.sh
echo 'spawn -noecho bash' >> check_env_size.sh
echo 'expect "#"' >> check_env_size.sh
echo 'send "su - Oracle\r"' >> check_env_size.sh
echo 'send "env | grep Oracle\r"' >> check_env_size.sh
if [[ ${system_version} != '7' ]]; then
    echo 'send "env | grep DISPLAY\r"' >> check_env_size.sh
fi
echo 'interact' >> check_env_size.sh
chmod +x ./check_env_size.sh
echo_color "查看 Oracle 环境变量，请在弹出的新终端截图并关闭新终端，然后按 ENTER 进入下一步" g
gnome-terminal -e ./check_env_size.sh
write_log "check oracle env."
check_enter_key

rm /etc/yum.repos.d/public-yum-ol7.repo -rf
rm /etc/yum.repos.d/public-yum-ol6.repo -rf
rm /etc/yum.repos.d/public-yum-ol5.repo -rf
rm ./check_*.sh

echo_color "********** 解压数据库安装文件 **********" b
#unzip
unzip linux.x64_11gR2_database_1of2.zip -d /home/
unzip linux.x64_11gR2_database_2of2.zip -d /home/
chown -R Oracle:oinstall /home/database/

echo_color "成功安装！请注销当前用户登陆并登陆 Oracle 用户，之后跟随实验步骤3.2进行图形界面安装" g
