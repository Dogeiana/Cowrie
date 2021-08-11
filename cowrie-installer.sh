#!/bin/bash

# i like boxes
if [ "$EUID" -ne 0 ]
    then 
    echo "╔════════════════════════╗"
    echo -e "║\033[0;31mError\033[0m: \033[32;5mRun this as root!\033[0m║"
    echo "╚════════════════════════╝"
exit
fi

arch=$(uname -m)
kernel=$(uname -r)
if [ -n "$(command -v lsb_release)" ]; then
	osname=$(lsb_release -s -d)
elif [ -f "/etc/os-release" ]; then
	osname=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="')
elif [ -f "/etc/debian_version" ]; then
	osname="Debian $(cat /etc/debian_version)"
elif [ -f "/etc/redhat-release" ]; then
	osname=$(cat /etc/redhat-release)
else
	osname="$(uname -s) $(uname -r)"
fi

if grep -qs "ubuntu" /etc/os-release; then
	os="ubuntu"
	os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
	group_name="nogroup"
else 
    echo "╔══════════════════════════════════════╗"
	echo -e "║\033[0;31mError\033[0m: Cowrie Installer only supports ║
║          Ubuntu 20.04 and higher.    ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "\033[0;32mOS Detection\033[0m: ${osname}" 
	exit
fi

if [[ "$os" == "ubuntu" && "$os_version" -lt 2004 ]]; then
    echo "╔══════════════════════════════════════╗"
	echo -e "║\033[0;31mError\033[0m: Cowrie Installer only supports ║
║          Ubuntu 20.04 and higher.    ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "\033[0;32mOS Detection\033[0m: ${osname}" 
	exit
fi

sshfile=/etc/ssh/sshd_config
if [[ -f "$sshfile" ]]; then
    echo "$sshfile exists."
    port
else
    echo "$sshfile does not exist."
    exit
fi

ssh_port=$(cat /etc/ssh/sshd_config | grep Port | grep -Eo [0-9]+)
if [[ $ssh_port == 22 ]]; then
        echo "╔════════════════════════╗"          #thicc
        echo -e "║\033[0;31mError\033[0m: \033[32;5mSSH Port is 22!  \033[0m║"
        echo "╚════════════════════════╝"        
        exit
else [[ $ssh_port -ne 22 ]];
        echo "Moving on…"
fi
clear
## main
echo "╔════════════════════════════════════════════╗"
echo "║Before you setup Cowrie Honeypot            ║"
echo "║Make sure you change your default SSH port  ║"
#echo -e "║\033[0;32mOS Detection\033[0m: ${osname}            ║"
echo '╚════════════════════════════════════════════╝'
echo -e "\033[0;32mOS Detection\033[0m: ${osname}" 
#echo -e "\033[0;32mSSH Port\033[0m: ${ssh_port}" 
echo ""

read -e -p "Install Cowrie? [Y/n]:" cowrie
    if [[ $cowrie == [Yy]* ]]; then
        echo "Installing Updates..."
        sleep 1
        sudo apt-get update
        sudo apt-get upgrade -y 
        clear
        echo "Installing Cowrie Dependencies..."
        sleep 1
        sudo apt-get install python3-virtualenv python3-pip libssl-dev libffi-dev build-essential libpython3-dev python3-minimal authbind virtualenv -y
        sudo apt-get install nmap wget curl upx hexedit tcpdump -y ## installing tools i use, not really cowrie dependencies
        clear
    else
        echo "Exiting..."
        exit
    fi
echo "Make a user for cowrie honeypot."
echo ""
read -e -p "Username:" user
cat /etc/passwd | grep -q $user
while [ $? -eq 0 ] do
    echo "That user already exist!"
    read -e -p "Username:" user
    grep -q $user cat /etc/passwd
done
sudo adduser --disabled-password $user
echo "$user Created!"
sleep 1
su - $user
git clone http://github.com/cowrie/cowrie
cd cowrie
virtualenv --python=python3 cowrie-env
source cowrie-env/bin/activate
pip install --upgrade pip
pip install --upgrade -r requirements.txt
cd etc
cp cowrie.cfg.dist cowrie.cfg
clear
read -e -p "Enable Telnet? [Y/n]:" telnet
    if [[ $telnet == [Yy]* ]]; then
        echo "Redirecting port 23 and 2323 to 2223.."
        rm -rf cowrie.cfg
        curl -O https://raw.githubusercontent.com/Dogeiana/Cowrie/main/etc/cowrie.cfg
        iptables -t nat -A PREROUTING -p tcp --dport 23 -j REDIRECT --to-port 2223
        #iptables -t nat -A PREROUTING -p tcp --dport 2323 -j REDIRECT --to-port 2223
    else
        echo "Telnet Disabled"
    fi
echo "Name your honeypot. (default:svr04)"
echo ""
read -e -p "Hostname:" hostname
    sed -i "s/hostname = svr04$/hostname = $hostname/g" cowrie.cfg
    iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222
    clear
echo "Cowrie honeypot is ready to go! Do you want to start the honeypot?"
echo ""
read -e -p "Start Honeypot? [Y/n]:" honeypot
    if [[ $honeypot == [Yy]* ]]; then
        cd
        bash /cowrie/bin/cowrie start
    else
        echo "You can start the honeypot in /cowrie/bin/cowrie."
        exit
    fi
done
