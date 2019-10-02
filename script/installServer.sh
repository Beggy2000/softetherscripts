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


#===  FUNCTION  ================================================================
#          NAME:  removeTemporaryDirectory
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================
function removeTemporaryDirectory () {
    [[ -d "${ARCHIVE_DIR_NAME}" ]] || return 0
    local parentDir=$(dirname "${ARCHIVE_DIR_NAME}")
    if [[ "${parentDir}" != "${WORK_DIRECTORY}" ]]; then 
        echo "Would you please to remove temporary directory (${ARCHIVE_DIR_NAME}) by hands"
        return 1
    fi
    echo "remove temporary directory ${ARCHIVE_DIR_NAME}"
    rm -rf "${ARCHIVE_DIR_NAME}"
    return 0
}	

# ----------  end of function removeTemporaryDirectory  ----------
#===  FUNCTION  ================================================================
#          NAME:  stopTheScript
#   DESCRIPTION:  
#    PARAMETERS:  message [exit code]
#       RETURNS:  
#===============================================================================
function stopTheScript () {
    local message="$1"
    local exitCode="${2:-1}"
    [[ -n "${message}" ]] && echo "${message}" >&2
    removeTemporaryDirectory
    exit ${exitCode}
}	
# ----------  end of function stopTheScript  ----------

readonly WORK_DIRECTORY=$(dirname "$0")
readonly UTIL=${WORK_DIRECTORY}/util.sh
readonly LIBRARY=${WORK_DIRECTORY}/function.sh
readonly ENVIRONMENT=${WORK_DIRECTORY}/environment.sh

readonly PROGRAMM_TYPE=vpnserver
readonly ARCHIVE_DIR_NAME=$(mktemp --directory --tmpdir=${WORK_DIRECTORY})
readonly ARCHIVE_FILE_NAME=${ARCHIVE_DIR_NAME}/sourceArchive.tar.gz


#include library
[[ -r "${UTIL}" ]] || stopTheScript "There is no ${UTIL} file." 2
source "${UTIL}"

[[ -r "${LIBRARY}" ]] || stopTheScript "There is no ${LIBRARY} file." 2
source "${LIBRARY}"

#include environment
[[ -r "${ENVIRONMENT}" ]] || stopTheScript "There is no ${ENVIRONMENT} file." 2
source "${ENVIRONMENT}"

checkIfRoot || stopTheScript "You should start the script as root (sudo)." 1

updateTheSystem

getLastRTM "${PROGRAMM_TYPE}" "${ARCHITECTURE}" "${ARCHIVE_FILE_NAME}" || stopTheScript "" 1

unpackAndCompile "${PROGRAMM_TYPE}" "${ARCHIVE_FILE_NAME}" "${DESTINATION_DIR}" || stopTheScript "" 1

declare programDirName="${DESTINATION_DIR}/${PROGRAMM_TYPE}"
configureServer "${programDirName}"

#configureNetwork
#configureSystemctl

stopTheScript "Completed" 0
