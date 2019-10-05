#!/bin/bash - 
#===============================================================================
#
#          FILE: uninstallServer.sh
# 
#         USAGE: ./uninstallServer.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Nick Shevelev (Beggy), BeggyCode@gmail.com
#  ORGANIZATION: BeggyCode
#       CREATED: 03.10.2019 10:29:00
#      REVISION:  ---
#===============================================================================

source "$(dirname "$0")/function.sh" || { echo "Critical error: there is no library $(dirname "$0")/function.sh" >&2 ; exit 1; }

checkIfRoot || stopTheScript "You should start the script as root (sudo)." 1

declare programDirName="${DESTINATION_DIR}/${SERVER}"
uninstallServer "${programDirName}"

stopTheScript "Completed" 0
