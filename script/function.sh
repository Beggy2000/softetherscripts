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
apt-get update && apt-get -y upgrade

# Get build tools
apt-get -y install build-essential wget curl gcc make wget tzdata git libreadline-dev libncurses-dev libssl-dev zlib1g-dev

}	
# ----------  end of function updateTheSystem  ----------


#===  FUNCTION  ================================================================
#          NAME:  getLastRTM
#   DESCRIPTION:  RTM - Release to manufacturing see: https://en.wikipedia.org/wiki/Software_release_life_cycle#Release_to_manufacturing_(RTM)
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================
function getLastRTM () {
    local programType=$1
    if [[ -z "${programType}" ]] ; then 
        echo "programType is undefined" >&2
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

    local rtmFileUrl=$(curl https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/ | grep -o '/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/[^"]*' | grep rtm | grep "${programType}" | grep "${architectureType}" | head -n 1)
    echo "${rtmFileUrl} was found as last rtm version."
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
    local programType=$1
    if [[ -z "${programType}" ]] ; then 
        echo "programType is undefined" >&2
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
    local programDirName="${destinationDir}/${programType}"
    if [[ -d "${programDirName}" ]] ; then 
        echo "Critical error: the program directory(${programDirName}) already exists. Please remove it or rename before continue." >&2
        return 1
    fi
    tar -xzvf "${archiveFile}" -C "${destinationDir}"
    if [[ ! -d "${programDirName}" ]] ; then 
        echo "Critical error: there is no program directory(${programDirName}) after unpack ${archiveFile} in ${destinationDir}" >&2
        return 1
    fi
    cd "${programDirName}"
    # Workaround for 18.04+
    #sed -i 's|^[[:space:]]*NO_PIE_OPTION=[[:space:]]*$|NO_PIE_OPTION=-no-pie|' Makefile
    make i_read_and_agree_the_license_agreement
    cd - > /dev/null #to prevent directory name output
    return 0 
}	
# ----------  end of function unpackAndCompile  ----------

#===  FUNCTION  ================================================================
#          NAME:  configureServer
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================
function configureServer () {
    local programDirName=$1
    if [[ -z "${programDirName}" ]] ; then 
        echo "programDirName is undefined" >&2
        return 1
    fi
    if [[ ! -d "${programDirName}" ]] ; then 
        echo "${programDirName} is not a directory" >&2
        return 1
    fi

    cd "${programDirName}"
    if [[ -e "./${SERVER_CONFIG_FILE_NAME}" ]]; then
        echo "./${SERVER_CONFIG_FILE_NAME} is already here!"
        return 1
    fi
    #simple config file
    cat <<EOF >"./${SERVER_CONFIG_FILE_NAME}"
# Softether Configuration File
# ----------------------------
#
# You may edit this file when the VPN Server / Client / Bridge program is not running.
#
# In prior to edit this file manually by your text editor,
# shutdown the VPN Server / Client / Bridge background service.
# Otherwise, all changes will be lost.
#
declare root
{
        uint ConfigRevision 1

        declare DDnsClient
        {
                bool Disabled true
        }
        declare ServerConfiguration
        {
                bool UseKeepConnect false
        }
}

EOF
    
    chown -R root:root .
    find . -type d -exec chmod u=rx,go= {} \;
    find . -type f -exec chmod u=r,go= {} \;
    chmod u+x ./vpnserver 
    chmod u+x ./vpncmd

    tuneTheKernel
    cd -
}	
# ----------  end of function configureServer  ----------


#===  FUNCTION  ================================================================
#          NAME:  tuneTheKernel
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function tuneTheKernel () {
    if [[ -z "${SYSCTL_FILE}" ]]; then
        echo "SYSCTL_FILE is undefined." >&2
        return 1
    fi
    [[ -e "${SYSCTL_FILE}" ]] || touch "${SYSCTL_FILE}"

    # Act as router
    setProperty "${SYSCTL_FILE}" net.ipv4.ip_forward 1
    # Tune Kernel
    setProperty "${SYSCTL_FILE}" net.ipv4.ip_local_port_range "1024 65535"
    setProperty "${SYSCTL_FILE}" net.ipv4.tcp_congestion_control "bbr"
    setProperty "${SYSCTL_FILE}" net.core.default_qdisc "fq_codel"
    #sysctl --system
    service procps start

}
# ----------  end of function tuneTheKernel  ----------


#===  FUNCTION  ================================================================
#          NAME:  setProperty
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function setProperty () {
    local fileName=$1
    if [[ -z "${fileName}" ]] ; then 
        echo "fileName is undefined" >&2
        return 1
    fi
    if [[ ! -r "${fileName}" ]] ; then 
        echo "${fileName} is not readable" >&2
        return 1
    fi
    local propertyName=$2
    if [[ -z "${propertyName}" ]] ; then 
        echo "propertyName is undefined" >&2
        return 1
    fi
    local escapedPropertyName=$(echo "${propertyName}" | sed 's|\.|\\.|g')
    local propertyValue=$3
    if [[ -z "${propertyValue}" ]] ; then
        #comment out
        sed -i "s|^\([[:space:]]*${escapedPropertyName}[[:space:]]*=\)|#\1|g" "${fileName}"
        return 0
    fi

    #uncomment or edit
    sed -i "s|^[[:space:]]*#\?[[:space:]]*${escapedPropertyName}[[:space:]]*=.*$|${propertyName}=${propertyValue}|g" "${fileName}"
    if ! grep --quiet "^[[:space:]]*${escapedPropertyName}[[:space:]]*=[[:space:]]*${propertyValue}[[:space:]]*$" "${fileName}" ; then
        echo "${propertyName}=${propertyValue}" >> "${fileName}"
    fi
    return 0
}
# ----------  end of function setProperty  ----------

