#! /bin/bash

# ======================================================================================================= #
# APPLICATION: Production Optimization on EDGE devices Rpi                                                   #
#      DEVICE: EE                                                                                         #
#     VERSION: 2.0.0                                                                                      #
#      AUTHOR: Shubh Panchal                                                                                   #
#        DATE: 16-01-2024                                                                               #
# ======================================================================================================= #
# NOTE FROM AUTHOR                                                                                        #
# - If you are a developer and intend to make changes to this code, refer to the documentation first.     #
# - All the features and the libraries, this script installs, is mentioned in the documentation,          #
# along with the steps taken to install them.                                                             #
# - If you are a user who wants to execute this code on a device, simply run the script on the terminal.  #
# - This code takes about 20 mins to completely execute and install all peripherals on the device,        #
# kindly have patience while using it.                                                                    #
# - This script has been tested succesfully on RaspberryPi-one.                                              #
# - If future iterations are made to the base board (EMAP) and/or to the utilites, then ensure that the   #     
# links and/or commands provided in this script are updated simultaneously.                               # 
# - This version of the script does not install CAN layer to the OS, as, as of writing this script,       #  
# CAN is not a frequent requirement from our device. If in the future, CAN is required as a standard      #  
# install on the device, then kindly include steps for its installation to this document as well.         #
#                                                                                                         #
# ======================================================================================================= #

#-----------------Taking required user input------------------------
read -p "Enter a new hostname (EMAPXXX) for this device: " hostname
read -p "Enter the Date MM/DD/YYYY : " Date
read -p "Enter the Time HH:MM:SS : " Time

#-------------Setting up hostname--------------------
hostname_path="/etc/hostname"
echo $hostname > $hostname_path
echo -e "Hostname has been successfully changed to \e[1;42m $hostname \e[0m,changes will be reflected after reboot" 

#--------------Setup RTC clock by syncing it, and make linux take control of the clock-------------------
rtc_path="/etc/rc.local"
sed -i '13i (sleep 10)' $rtc_path
sed -i '14i (echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-0/new_device)' $rtc_path
sed -i '15i (sleep 10)' $rtc_path
sed -i '16i (/sbin/hwclock -s -f /dev/rtc1)' $rtc_path
sed -i '17i (sleep 10)' $rtc_path
sed -i '18i (/sbin/hwclock --systohc)' $rtc_path

hwclock --set --date "$Date $Time"
timedatectl set-timezone Asia/Kolkata
echo -e "\e[1;42m RTC setup has been done successfully \e[0m"

#---------------------------------Creating basic directories--------------------------------------------
if [ -d "/root/app_codes" ]; then 
    mkdir /root/app_codes
    echo -e "\e[1;42m app_codes directory has been created successfully \e[0m"
else 
    echo -e "\e[1;43m app_codes directory already exists \e[0m"
fi 

if [ -d "/root/common_codes" ]; then 
    mkdir /root/common_codes
    echo -e "\e[1;42m app_codes directory has been created successfully \e[0m"
else 
    echo -e "\e[1;43m common_codes directory already exists \e[0m"
fi 

#------------------------------------Setup Static IP----------------------------------------------------
network_ip_path="/etc/network/interfaces"
echo -e "\n#Static IP configuration" >> $network_ip_path
static_ip="auto eth0:1
iface eth0:1 inet static
    address *************
    netmask 255.255.255.0"
echo "$static_ip" >> $network_ip_path
static_ip="**************" 
echo -e " Static ip is successfully set to \e[1;42m $static_ip \e[0m"

#---------------------------------Setup of external dongle----------------------------------------------
cd /root/common_codes
mkdir ./wifi_setup
cd wifi_setup
dtc -I dtb -O dts -f /boot/bcm2710-rpi-3-b-plus.dtb -o bcm2710-rpi-3-b-plus.dts
sed -i 's/dr_mode = "otg"/dr_mode = "host"/g' bcm2710-rpi-3-b-plus.dts
dtc -I dts -O dtb -o /boot/bcm2710-rpi-3-b-plus.dtb bcm2710-rpi-3-b-plus.dts
echo -e "\e[1;42m External dongle has been configured successfully and will be reflected after reboot \e[0m" 

#----------------------------Connecting to any other default WiFi------------------------------------------
nmcli dev wifi connect EMBEDOS_2.4G password "***********"
wifi_ip=$(hostname -I | awk '{print $2}')
echo -e "Device has been connected to \e[1;42m EMBEDOS_2.4G \e[0m network with IP \e[1;42m $wifi_ip/24 \e[0m"

#-----------------------------------display mac address--------------------------------------------------------
mac_address=$(cat /sys/class/net/eth0/address) 
echo -e "MAC ID for this device is \e[1;42m $mac_address \e[0m"

#---------------------------------Setting up custom MOTD-------------------------------------------------------
rm /etc/motd
motd_path="/etc/profile.d/motd.sh"
sed -i '97 s/^/#/' /etc/pam.d/login
sed -i '33 s/^/#/' /etc/pam.d/sshd
touch $motd_path
echo -e '#!/bin/bash\n' >> $motd_path
echo 'clear' >> $motd_path
echo 'echo ""' >> $motd_path
echo 'echo "$(tput setaf 7)  _____                                       "' >> $motd_path
echo 'echo "$(tput setaf 7) |  ___|          _              _            $(tput setaf 6) Embedos Engineering LLP "' >> $motd_path
echo 'echo "$(tput setaf 7) | |_   _ __ ___ | |__   ___  __| | ___  ___  "' >> $motd_path
echo 'echo "$(tput setaf 7) |  _| | '\''_ '\'' _ \|  _ \ / _ \/ _  |/ _ \/ __| $(tput setaf 6) info@embedos.io"' >> $motd_path
echo 'echo "$(tput setaf 7) | |___| | | | | | |_) |  __/ (_| | (_) \_  \ "' >> $motd_path
echo 'echo "$(tput setaf 7) |_____|_| |_| |_|_.__/ \___|\__,_|\___/|___/ $(tput setaf 6) www.embedos.io"' >> $motd_path 
echo 'echo ""' >> $motd_path
echo -e 'echo "$(tput setaf 7) --------------------------------------------------------------------- "\n' >> $motd_path
echo 'let upSeconds="$(/usr/bin/cut -d. -f1 /proc/uptime)"' >> $motd_path
echo 'let secs=$((${upSeconds}%60))' >> $motd_path
echo 'let mins=$((${upSeconds}/60%60))' >> $motd_path
echo 'let hours=$((${upSeconds}/3600%24))' >> $motd_path
echo 'let days=$((${upSeconds}/86400))' >> $motd_path
echo -e 'UPTIME=`printf "%d days %02dhrs %02dmins %02dsecs" "$days" "$hours" "$mins" "$secs"`\n' >> $motd_path
echo '# get the load averages' >> $motd_path
echo -e 'read one five fifteen rest < /proc/loadavg\n' >> $motd_path
echo 'echo "$(tput setaf 2)' >> $motd_path     
echo ' - Login Epoch........: ` date +"%A, %e %B %Y, %r"`' >> $motd_path
echo ' - OS.................: ` uname -srmo`' >> $motd_path
echo -e ' - Device ID..........: `cat /etc/hostname`\n' >> $motd_path
echo '$(tput setaf 3) - Device Uptime......: ${UPTIME}' >> $motd_path
echo '$(tput setaf 3) - Memory.............: `free | grep Mem | awk '\''{print $3/1024}'\''` MB (Used) / `cat /proc/meminfo | grep MemTotal | awk {'\''print $2/1024'\''}` MB (Total)' >> $motd_path
echo '$(tput setaf 3) - Load Averages......: ${one}, ${five}, ${fifteen} (1, 5, 15 min)' >> $motd_path
echo '$(tput setaf 3) - Running Processes..: `ps ax | wc -l | tr -d " "`' >> $motd_path
echo -e '$(tput setaf 3) - IP Addresses.......: `hostname -I | /usr/bin/cut -d " " -f 1` and `wget -q -O - http://icanhazip.com/ | tail`\n' >> $motd_path
echo '$(tput sgr0)"' >> $motd_path
echo -e "\e[1;42m MOTD has been set for this device and will be reflected after reboot \e[0m" 

#--------------------------------setup I2C and UART1, UART2, UART3---------------------------------------------
raspi-config nonint do_i2c 0
raspi-config nonint do_serial 0
raspi-config nonint do_serial 1
raspi-config nonint do_serial 2
raspi-config nonint do_serial 3
echo -e "\e[1;42m I2C & UART setup has been done successfully and will be reflected after reboot of Device \e[0m"

#----------------------------------Setting up Python3 environments---------------------------------------------
apt -y update && apt -y upgrade
apt -y full-upgrade
echo -e "\e[1;42m upgrade and update done \e[0m"
python -m pip install setuptools
echo -e "\e[1;42m Python v3.9 environment has been setup successfully \e[0m"

#-----------------avahi-daemon already installed in raspi so no need to install--------------------------------

#----------------------------Installing basic python libraries-------------------------------------------------
apt -y install minicom
apt -y install ppp
pip install paho-mqtt 
apt -y install mosquitto
apt -y install mosquitto-clients
apt -y install nodejs
apt -y install npm
echo -e "\e[1;42m  Successfully installed Python packages, Nodejs, npm \e[0m"

#--------------------------------Setup WiringPi library--------------------------------------------------------
cd /root/common_codes
git clone https://github.com/WiringPi/WiringPi.git
cd wiringPi
./build clean
./build
echo -e "\e[1;42m Successfully installed WiringPi package \e[0m"

#--------------------------------Setting up GSM module---------------------------------------------------------
ppp_path="/etc/ppp/peers/provider"
sed -i "s|/dev/modem|/dev/ttyS0|g" $ppp_path
sed -i 's|connect "/usr/sbin/chat -v -f /etc/chatscripts/pap -T \*\*\*\*\*\*\*\*"|connect "/usr/sbin/chat -v -f /etc/chatscripts/gprs -T WWW"|g' $ppp_path
minicom_path="/etc/minicom/minirc.dfl"
touch $minicom_path
echo "pu port             /dev/ttyS0" > $minicom_path
echo "pu rtscts           No" >> $minicom_path
echo -e "\e[1;42m GSM setup has been configured successfully \e[0m"

#----------------------------Installing OLED dependencies------------------------------------------------------
pip install luma.core
pip install luma.oled
cd /root/common_codes
git clone https://github.com/shubh-141/app-oled 

#creating service file for oled_controller.py

SCRIPT_NAME="oled_controller.py"
SCRIPT_DIRECTORY="/root/common_codes/app-oled"
SERVICE_NAME="oled_controller"

SERVICE_FILE="/etc/systemd/system/oled_controller.service"

echo "[Unit]" > $SERVICE_FILE
echo "Description=${SERVICE_NAME} Service" >> $SERVICE_FILE
echo "After=network.target" >> $SERVICE_FILE
echo "" >> $SERVICE_FILE
echo "[Service]" >> $SERVICE_FILE
echo "ExecStart=/usr/bin/python3 ${SCRIPT_DIRECTORY}/${SCRIPT_NAME}" >> $SERVICE_FILE
echo "WorkingDirectory=${SCRIPT_DIRECTORY}" >> $SERVICE_FILE
echo "StandardOutput=inherit" >> $SERVICE_FILE
echo "StandardError=inherit" >> $SERVICE_FILE
echo "Restart=always" >> $SERVICE_FILE
echo "" >> $SERVICE_FILE
echo "[Install]" >> $SERVICE_FILE
echo "WantedBy=multi-user.target" >> $SERVICE_FILE

systemctl daemon-reload
systemctl enable $SERVICE_NAME.service
systemctl start $SERVICE_NAME.service
systemctl status $SERVICE_NAME.service

echo -e "\e[1;42m OLED setup has been done successfully \e[0m" 

#-----------------------app_netcon------------------------------
cd /root/common_codes
git clone https://Embedos_Production:**********************.git
cd app_netcon
pip install -r requirements.txt
sed -i "s|.*ExecStart=.*|ExecStart=/usr/bin/python /root/common_codes/app_netcon/app.py|g" app_netcon.service
cp app_netcon.service /lib/systemd/system/
systemctl enable app_netcon.service
echo -e "\e[1;42m app_netcon has installed successfully , will be activated after reboot \e[0m" 

#-----------------------GPRS setup------------------------------


#---------------------edge_powerdown----------------------------
cd /root/common_codes
git clone https://interns_embedos:*************************.git
cd app_powerdown
sed -i "s|.*ExecStart=.*|ExecStart=/usr/bin/python /root/common_codes/app_powerdown/powerdown.py|g" powerdown.service
cp powerdown.service /lib/systemd/system/
systemctl enable powerdown.service
echo -e "\e[1;42m app_powerdown has installed successfully , will be activated after reboot \e[0m"

#---------------------app_remote_mon-----------------------------
cd /root/common_codes
git clone https://interns_embedos:**************************.git
cd app_remote_mon
pip install -r requirements.txt
sed -i "s|.*ExecStart=.*|ExecStart=/usr/bin/python /root/common_codes/app_remote_mon/remote_mon.py|g" remote_mon.service
cp remote_mon.service /lib/systemd/system/
systemctl enable remote_mon.service
ssh-keygen
ssh-copy-id embedos@solar.embedos.io
#enter password
echo -e "\e[1;42m app_remote_mon has installed successfully \e[0m" 

