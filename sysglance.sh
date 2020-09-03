#!/bin/bash
# Simple Linux utility for generating a system report for the host system
# License: GPL3
# Copyright: Salih Emin @ https://utappia.org - https://cerebrux.net
#---------------------------------------------------------------------------

# The following function provides Boxed out messages. Credit: https://unix.stackexchange.com/a/70616
function box_out()
{
  local s=("$@") b w
  for l in "${s[@]}"; do
    ((w<${#l})) && { b="$l"; w="${#l}"; }
  done
  tput setaf 3
  echo " -${b//?/-}-
| ${b//?/ } |"
  for l in "${s[@]}"; do
    printf '| %s%*s%s |\n' "$(tput setaf 4)" "-$w" "$l" "$(tput setaf 3)"
  done
  echo "| ${b//?/ } |
 -${b//?/-}-"
  tput sgr 0
}

# Countdown generator
function countdown() {
  secs=$1
  shift
  msg=$*
  while [ "$secs" -gt 0 ]
  do
    printf "\r\033[KDiving into quantum realm in %.d seconds $msg" $((secs--))
    sleep 1
  done
  echo
}

# Checking if the user has run the script with "sudo" or not
if [[ $EUID -ne 0 ]] ; then
    clear
    echo ""
    box_out 'Where is the Master?' '---------------------------' '' 'Sysglance must be run as root user' 'or a user with sudo privileges.' 'Now I will just exit...' 1>&2
    echo ""
    sleep 2
    exit 1
fi

clear
box_out 'Sysglance: Initiating System Information gathering' '' 'This is a free/libre software generated by burning hours and passion as a fuel' '' 'Read More at the end'
countdown 5
#----------------------------------------------------------
# Host information
box_out 'General System Information'
hostnamectl
echo ""
# System uptime and load in 1, 5 and 15 minutes span:
echo "$(tput bold)Uptime and system load:$(tput sgr0)"
uptime
echo ""
# Users available:
echo "$(tput bold)Available User Accounts:$(tput sgr0)"
lslogins -u
echo ""
# Currently logged in users:
echo "$(tput bold)Logged in users:$(tput sgr0)"
who
sleep 1
echo ""
#----------------------------------------------------------
box_out 'Hardware information'
# Fetch the current version of the pci.ids file from the primary distribution site and install it
echo "$(tput bold)Fetching the latest hardware database info:$(tput sgr0)"
update-pciids
echo ""
# CPU Info
echo "$(tput bold)CPU information:$(tput sgr0)"
grep 'vendor' /proc/cpuinfo | uniq
grep 'model name' /proc/cpuinfo | uniq
echo "CPU Threads     : $(grep -c 'processor' /proc/cpuinfo)"
echo ""
# GPU Info
echo "$(tput bold)GPU information:$(tput sgr0)"
lspci | grep -i 'vga\|3d\|2d'
echo ""
# Network Adapter
echo "$(tput bold)Network Adapter:$(tput sgr0)"
lspci | grep 'Network controller'
lspci | grep 'Ethernet controller'
echo ""
# USB Info
echo "$(tput bold)USB Devices:$(tput sgr0)"
lsusb
echo ""
# Hard disk info
echo "$(tput bold)Hard Disks:$(tput sgr0)"
fdisk -l | grep -i "Disk" | grep -v -e "loop" -e "fuse" -e "zram"
sleep 1
echo ""
#----------------------------------------------------------
# File system disk space usage:
box_out 'Disk Space analysis'
echo "$(tput bold)Disk Partitions:$(tput sgr0)"
lsblk -e252 -e7
echo ""
echo "$(tput bold)Partition Types:$(tput sgr0)"
fdisk -l | grep "/dev/\|Type" | grep -v -e "loop" -e "fuse" -e "zram"
echo ""
echo "$(tput bold)Disk Usage:$(tput sgr0)"
df -h -x squashfs -x tmpfs -x devtmpfs -x fuse
sleep 1
echo ""
#----------------------------------------------------------
# Free and used memory in the system:
box_out 'Memory Utilization'
echo "$(tput bold)Memory Usage:$(tput sgr0)"
free -m
echo ""
# Top 10 processes as far as memory usage is concerned including user, pid and when it started
echo "$(tput bold)Top 10 Memory consuming Processes:$(tput sgr0)"
ps -Ao user,start,comm,time,pid,pmem,pcpu, --sort=-pmem | head -n 11
sleep 1
echo ""
#----------------------------------------------------------
# Show per device IP addresses. Credit: https://unix.stackexchange.com/a/511191
box_out 'Network analysis'
echo "$(tput bold)Private IP adresses:$(tput sgr0)"
ip addr show |
    awk '
        # Output function to format results (if any)
        function outline() {
            if (link>"") {printf "%s %s %s\n", iface, inets, link}
        }

        # Interface section starts here
        $0 ~ /^[1-9]/ {
            outline();                              # Output anything we previously collected
            iface=substr($2, 1, index($2,":")-1);   # Capture the interface name
            inets="";                               # Reset the list of addresses
            link=""                                 # and MAC too
        }

        # Capture the MAC
        $1 == "link/ether" {
            link=$2                   
        }

        # Capture an IPv4 address. Concatenate to previous with comma
        $1 == "inet" {
            inet=substr($2, 1, index($2,"/")-1);    # Discard /nn subnet mask
            if (inets>"") inets=inets ",";          # Suffix existing list with comma
            inets=inets inet                        # Append this IPv4
        }

        # Input processing has finished
        END {
            outline()                               # Output remaining collection
        }
    '
echo ""
echo "$(tput bold)Public IP Address:$(tput sgr0)"
curl checkip.amazonaws.com
#dig @resolver1.opendns.com ANY myip.opendns.com +short <-- need invest why it doesn't work on Arch
echo ""
# Protocol, process and ports used by your system
echo "$(tput bold)List of Processes and open Ports:$(tput sgr0)"
netstat -tulpn
echo ""
# Network connections that are either ESTABLISED or in LISTENING mode
echo "$(tput bold)List of network connections opened by processes:$(tput sgr0)"
lsof -i
sleep 1
echo ""
#----------------------------------------------------------
# Show only error, critical and alert priority messages
box_out 'Log files analysis'
#SYSTEMD_LESS=FRXMK journalctl -b -p err..alert
echo ""
echo "$(tput bold)Errors-Alerts-Segfaults in log files since the last system boot:$(tput sgr0)"
dmesg -t -L=never -l err,crit,alert,emerg && dmesg -t -L=never -l info | grep -i "segfault"
echo ""
sleep 1
box_out 'Sysglance : Gathering system information completed' '---------------------------------------------------------' 'This is a free/libre software generated by burning hours and passion as a fuel. If you find it usefull' 'you should consider a donation, in the following link:' '' 'https://ko-fi.com/cerebrux' '' '          Thank you in advance'
