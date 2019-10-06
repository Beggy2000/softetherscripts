#!/bin/bash -
#===============================================================================
#
#          FILE: installServer.sh
# 
#         USAGE: ./installServer.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Nick Shevelev (Beggy), BeggyCode@gmail.com
#  ORGANIZATION: BeggyCode
#       CREATED: 29.09.2019 21:56:43
#      REVISION:  ---
#===============================================================================

source "$(dirname "$0")/function.sh" || { echo "Critical error: there is no library $(dirname "$0")/function.sh" >&2 ; exit 1; }

checkIfRoot || stopTheScript "You should start the script as root (sudo)." 1

initTemporaryDir
readonly ARCHIVE_FILE_NAME=${TEMPORARY_DIR}/sourceArchive.tar.gz

updateTheSystem

getLastRTM "${SERVER}" "${ARCHITECTURE}" "${ARCHIVE_FILE_NAME}" || stopTheScript "" 1

unpackAndCompile "${SERVER}" "${ARCHIVE_FILE_NAME}" "${DESTINATION_DIR}" || stopTheScript "" 1

declare programDirName="${DESTINATION_DIR}/${SERVER}"
configureServer "${programDirName}"

#configureNetwork
#configureSystemctl

stopTheScript "Completed" 0
