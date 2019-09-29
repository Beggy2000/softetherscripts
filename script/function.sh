#!/bin/bash - 
#===============================================================================
#
#          FILE: function.sh
# 
#         USAGE: ./function.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Nick Shevelev (Beggy), BeggyCode@gmail.com
#  ORGANIZATION: BeggyCode
#       CREATED: 29.09.2019 22:11:49
#      REVISION:  ---
#===============================================================================



#===  FUNCTION  ================================================================
#          NAME:  checkIfRoot
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================
function checkIfRoot () {
    [[ "$(whoami)" == "root" ]] && return 0 || return 1
}	
# ----------  end of function checkIfRoot  ----------


#===  FUNCTION  ================================================================
#          NAME:  updateTheSystem
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================
function updateTheSystem () {
# Update system
#apt-get update && apt-get -y upgrade
echo "apt-get update && apt-get -y upgrade"

# Get build tools
#apt-get -y install build-essential wget curl gcc make wget tzdata git libreadline-dev libncurses-dev libssl-dev zlib1g-dev
echo "apt-get -y install build-essential wget curl gcc make wget tzdata git libreadline-dev libncurses-dev libssl-dev zlib1g-dev"

}	
# ----------  end of function updateTheSystem  ----------


#===  FUNCTION  ================================================================
#          NAME:  getLastRTM
#   DESCRIPTION:  RTM - Release to manufacturing see: https://en.wikipedia.org/wiki/Software_release_life_cycle#Release_to_manufacturing_(RTM)
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================
function getLastRTM () {
    local programmType=$1
    if [[ -z "${programmType}" ]] ; then 
        echo "programmType is undefined" >&2
        return 1
    fi
    local architectureType=$2
    if [[ -z "${architectureType}" ]] ; then 
        echo "architectureType is undefined" >&2
        return 1
    fi
    local archiveFile=$3
    if [[ -z "${archiveFile}" ]] ; then 
        echo "archiveFile is undefined" >&2
        return 1
    fi

    local rtmFileUrl=$(curl https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/ | grep -o '/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/[^"]*' | grep rtm | grep "${programmType}" | grep "${archType}" | head -n 1)
    wget "https://github.com/${rtmFileUrl}" -O "${archiveFile}"
    return 0
}	
# ----------  end of function getLastRTM  ----------


#===  FUNCTION  ================================================================
#          NAME:  unpackAndCompile
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================
function unpackAndCompile () {
    local programmType=$1
    if [[ -z "${programmType}" ]] ; then 
        echo "programmType is undefined" >&2
        return 1
    fi
    local archiveFile=$2
    if [[ -z "${archiveFile}" ]] ; then 
        echo "archiveFile is undefined" >&2
        return 1
    fi
    if [[ ! -r "${archiveFile}" ]] ; then 
        echo "${archiveFile} is not readable" >&2
        return 1
    fi
    local destinationDir=$3
    if [[ -z "${destinationDir}" ]] ; then 
        echo "destinationDir is undefined" >&2
        return 1
    fi
    if [[ ! -d "${destinationDir}" ]] ; then 
        echo "${destinationDir} is not directory" >&2
        return 1
    fi
    tar -xzvf "${archiveFile}" -C "${destinationDir}"
    local programmDirName="${destinationDir}/${programmType}1"
    if [[ ! -d "${programmDirName}" ]] ; then 
        echo "Critical error: there is no programm directory(${programmDirName}) after unpack ${archiveFile} in ${destinationDir}" >&2
        return 1
    fi
    cd "${programmDirName}"
    # Workaround for 18.04+
    #${SUDO} sed -i 's|OPTIONS=-O2|OPTIONS=-no-pie -O2|' Makefile
    make i_read_and_agree_the_license_agreement
    return 0 
}	
# ----------  end of function unpackAndCompile  ----------
