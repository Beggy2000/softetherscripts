#!/bin/bash - 
#===============================================================================
#
#          FILE: installClient.sh
# 
#         USAGE: ./installClient.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Nick Shevelev (Beggy), BeggyCode@gmail.com
#  ORGANIZATION: BeggyCode
#       CREATED: 06.10.2019 15:15:59
#      REVISION:  ---
#===============================================================================

source "$(dirname "$0")/function.sh" || { echo "Critical error: there is no library $(dirname "$0")/function.sh" >&2 ; exit 1; }

declare -a packageList=("build-essential")
checkInstallation "${packageList[@]}" || stopTheScript "" 1

checkIfRoot || stopTheScript "You must start the script as root (sudo)." 1

initTemporaryDir
readonly ARCHIVE_FILE_NAME=${TEMPORARY_DIR}/sourceArchive.tar.gz

getLastRTM "${CLIENT}" "${ARCHITECTURE}" "${ARCHIVE_FILE_NAME}" || stopTheScript "" 1

unpackAndCompile "${CLIENT}" "${ARCHIVE_FILE_NAME}" "${DESTINATION_DIR}" || stopTheScript "" 1

declare programDirName="${DESTINATION_DIR}/${CLIENT}"
configureClient "${programDirName}"

stopTheScript "Completed" 0
