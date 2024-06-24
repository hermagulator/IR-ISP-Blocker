#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    clear
    echo "You should run this script with root!"
    echo "Use sudo -i to change user to root"
    exit 1
fi

function main_menu {
    clear
    echo "---------- Iran ISP Blocker ----------"
    echo "https://github.com/Kiya6955/IR-ISP-Blocker"
    echo "--------------------------------------"
    echo "Which ISP do you want block/unblock?"
    echo "--------------------------------------"
    echo "1-MCI(Hamrah Aval)"
    echo "2-MTN(Irancell)"
    echo "3-TCI(Mokhaberat)"
    echo "4-Rightel(RTL)"
    echo "5-Exit"
    read -p "Enter your choice: " isp
    case $isp in
    1) isp="MCI" blocking_menu ;;
    2) isp="MTN" blocking_menu ;;
    3) isp="TCI" blocking_menu ;;
    4) isp="RTL" blocking_menu ;;
    5) echo "Exiting..."; exit 0 ;;
    *) echo "Invalid option"; main_menu ;;
    esac
}

function blocking_menu {
    clear
    echo "---------- $isp Menu ----------"
    echo "1-Block $isp"
    echo "2-UnBlock All"
    echo "3-Back to Main Menu"
    read -p "Enter your choice: " choice
    case $choice in
        1) blocker ;;
        2) unblocker ;;
        3) main_menu ;;
        *) echo "Invalid option press enter"; blocking_menu ;;
    esac
}

function blocker {
    clear
    if ! command -v iptables &> /dev/null; then
        apt-get update
        apt-get install -y iptables
    fi
    if ! dpkg -s iptables-persistent &> /dev/null; then
        apt-get install -y iptables-persistent
    fi

    clear
    read -p "آیا مطمئن هستید که می‌خواهید فقط به $isp اجازه اتصال دهید؟ [Y/N] : " confirm
    
    if [[ $confirm == [Yy]* ]]; then
        clear
        case $isp in
        "MCI")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/Kiya6955/IR-ISP-Blocker/main/mci-ips.ipv4')
            ;;
        "MTN")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/Kiya6955/IR-ISP-Blocker/main/mtn-ips.ipv4')
            ;;
        "TCI")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/Kiya6955/IR-ISP-Blocker/main/tci-ips.ipv4')
            ;;
        "RTL")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/Kiya6955/IR-ISP-Blocker/main/rightel-ips.ipv4')
            ;;
        esac

        if [ $? -ne 0 ]; then
            echo "دریافت لیست IP با شکست مواجه شد. لطفاً با @Kiya6955 تماس بگیرید"
            read -p "برای بازگشت به منو، Enter را فشار دهید" dummy
            blocking_menu
        fi
        
        clear
        read -p "آیا می‌خواهید قوانین قبلی را حذف کنید؟ [Y/N] : " confirm
        if [[ $confirm == [Yy]* ]]; then
            iptables -F
            iptables -X
            iptables -Z
            echo "قوانین قبلی با موفقیت حذف شدند"
            sleep 2s
        fi

        clear
        read -p "پورت SSH را که می‌خواهید باز بماند وارد کنید (پیش‌فرض 22): " SSH_PORT
        SSH_PORT=${SSH_PORT:-22}

        # قانون پیش‌فرض برای مسدود کردن همه اتصالات ورودی
        iptables -P INPUT DROP
        
        # اجازه دادن به اتصالات موجود و localhost
        iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        iptables -A INPUT -i lo -j ACCEPT

        # اجازه دادن به پورت SSH
        iptables -A INPUT -p tcp --dport $SSH_PORT -j ACCEPT

        echo "اعمال قوانین برای اجازه دادن به $isp شروع شد، لطفاً صبر کنید..."
        for IP in $IP_LIST; do
            iptables -A INPUT -s $IP -j ACCEPT
        done
        
        iptables-save > /etc/iptables/rules.v4

        clear
        echo "فقط به $isp اجازه اتصال داده شد."
        echo "پورت $SSH_PORT برای SSH باز مانده است."
        
        read -p "برای بازگشت به منو، Enter را فشار دهید" dummy
        blocking_menu
    else
        echo "لغو شد."
        read -p "برای بازگشت به منو، Enter را فشار دهید" dummy
        blocking_menu
    fi
}

function unblocker {
    clear
    iptables -F
    iptables -X
    iptables -Z
    iptables -P INPUT ACCEPT
    iptables-save > /etc/iptables/rules.v4
    clear
    echo "همه محدودیت‌ها برداشته شد و اتصال از همه IP‌ها مجاز است!"
    read -p "برای بازگشت به منو، Enter را فشار دهید" dummy
    blocking_menu
}

main_menu
