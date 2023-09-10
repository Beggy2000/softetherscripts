#!/bin/bash - 
#===============================================================================
#
#          FILE: createUser.sh
# 
#         USAGE: ./createUser.sh 
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

declare -a packageList=("curl" "net-tools")
checkInstallation "${packageList[@]}" || stopTheScript "" 1

checkIfRoot || stopTheScript "You should start the script as root (sudo)." 1
checkIfServerIsStarted || stopTheScript "VPN server should be stated. (Eg. systemctl restart ${SYSTEMD_SERVICE_FILE})" 1

declare -a nameList=("$@")
if [[ ${#nameList[@]} -eq 0 ]]; then
    nameList=("${USER_NAME[@]}")
fi
if [[ ${#nameList[@]} -eq 0 ]]; then
    echo "Define at least a name" >&2
    echo -e "\t $0 userName ..."
    echo "or"
    echo "use a variable USER_NAME in ${ENVIRONMENT}"
    echo -e "\treadonly -a USER_NAME=(userName ...)"
    exit 1
fi

initTemporaryDir

readonly ARCHIVE_FILE_NAME=${TEMPORARY_DIR}/${SOURCE_FILE_NAME}
getLastRTM "${CLIENT}" "${ARCHITECTURE}" "${ARCHIVE_FILE_NAME}" || stopTheScript "" 1

readonly programDirName="${DESTINATION_DIR}/${SERVER}"
declare certificateFileName=""
declare keyFileName=""

for userName in "${nameList[@]}"; do 
    if checkIfUserExists "${programDirName}" "${userName}" ; then
        echo "User ${userName} already exists" >&2
        continue
    fi
    
    certificateFileName="${TEMPORARY_DIR}/${userName}.cer"
    keyFileName="${TEMPORARY_DIR}/${userName}.key"
    createUserCertificate "${programDirName}" "${userName}" "${certificateFileName}" "${keyFileName}" || break
    createUserOnServer "${programDirName}" "${userName}" "${certificateFileName}" || break
    packClientScript "${userName}" "${certificateFileName}" "${keyFileName}" "${ARCHIVE_FILE_NAME}" || break
    rm "${certificateFileName}" "${keyFileName}"
done

stopTheScript "Completed" 0
