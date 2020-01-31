#!/bin/bash -
#===============================================================================
#
#          FILE: userList.sh
# 
#         USAGE: ./userList.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Nick Shevelev (Beggy), BeggyCode@gmail.com
#  ORGANIZATION: BeggyCode
#       CREATED: 05.10.2019 20:04:14
#      REVISION:  ---
#===============================================================================

source "$(dirname "$0")/function.sh" || { echo "Critical error: there is no library $(dirname "$0")/function.sh" >&2 ; exit 1; }

checkIfRoot || stopTheScript "You should start the script as root (sudo)." 1
checkIfServerIsStarted || stopTheScript "VPN server should be stated. (Eg. systemctl restart ${SYSTEMD_SERVICE_FILE})" 1

declare programDirName="${DESTINATION_DIR}/${SERVER}"
getUserList "${programDirName}"

stopTheScript "Completed" 0
