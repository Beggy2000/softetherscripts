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
    assertNotEmpty "${programType}" "programType" || return 1
    local architectureType=$2
    assertNotEmpty "${architectureType}" "architectureType" || return 1
    local archiveFile=$3
    assertNotEmpty "${archiveFile}" "archiveFile" || return 1

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
    assertNotEmpty "${programType}" "programType" || return 1
    local archiveFile=$2
    assertReadableFile "${archiveFile}" "archiveFile" || return 1
    local destinationDir=$3
    assertExistingDirectory "${destinationDir}" "destinationDir" || return 1
    
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
    assertNotEmpty "${SERVER}" "SERVER" || return 1
    assertNotEmpty "${CONFIGURATOR}" "CONFIGURATOR" || return 1

    local programDirName=$1
    assertExistingDirectory "${programDirName}" "programDirName" || return 1

    cd "${programDirName}"
    
    generateSimpleConfig "${programDirName}"|| return 1
    generateSystemDService "${programDirName}" || return 1
    generateSystemDService "${programDirName}" || return 1
    tuneTheKernel "${programDirName}" || return 1

    chown -R root:root .
    find . -type d -exec chmod u=rx,go= {} \;
    find . -type f -exec chmod u=r,go= {} \;
    chmod u+x "./${SERVER}" 
    chmod u+x "./${CONFIGURATOR}"

    cd -
}	
# ----------  end of function configureServer  ----------


#===  FUNCTION  ================================================================
#          NAME:  checkFileAndLink
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function checkFileAndLink () {
    local fileName=$1
    local linkFileName=$2
    if [[ -e "${linkFileName}" ]]; then
        if [[ ! -L "${linkFileName}" ]]; then
            echo "${linkFileName} is not a link. Stop the script to avoid overwriting it." >&2
            return 1
        fi
        local realFileName=$(realpath "${linkFileName}")
        if [[ "${realFileName}" != "${fileName}" ]]; then
            echo "Link is pointing to a ${realFileName} instead ${fileName}. Stop the script to avoid overwriting the real file. Please fix it before start again." >&2
            return 1
        fi
    fi
    [[ -e "${fileName}" ]] || touch "${fileName}"
    ln -sfv "${fileName}" "${linkFileName}"
    return 0 
}
# ----------  end of function checkFileAndLink  ----------

#===  FUNCTION  ================================================================
#          NAME:  tuneTheKernel
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function tuneTheKernel () {
    local serverDir=$1
    assertNotEmpty "${serverDir}" "serverDir" || return 1

    assertNotEmpty "${SYSCTL_FILE}" "SYSCTL_FILE" || return 1
    assertNotEmpty "${SYSCTL_LINK}" "SYSCTL_LINK" || return 1
    
    local confFileName=${serverDir}/${SYSCTL_FILE}
    checkFileAndLink "${confFileName}" "${SYSCTL_LINK}"

    # Act as router
    setProperty "${confFileName}" net.ipv4.ip_forward 1
    # Tune Kernel
    setProperty "${confFileName}" net.ipv4.ip_local_port_range "1024 65535"
    setProperty "${confFileName}" net.ipv4.tcp_congestion_control "bbr"
    setProperty "${confFileName}" net.core.default_qdisc "fq_codel"

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
    assertReadableFile "${fileName}" "fileName" || return 1
    local propertyName=$2
    assertNotEmpty "${propertyName}" "propertyName" || return 1
    
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


#===  FUNCTION  ================================================================
#          NAME:  generateSimpleConfig
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function generateSimpleConfig () {
    local serverDir=$1
    assertNotEmpty "${serverDir}" "serverDir" || return 1
    assertNotEmpty "${SERVER_CONFIG_FILE_NAME}" "SERVER_CONFIG_FILE_NAME" || return 1

    local serverConfigFile="${serverDir}/${SERVER_CONFIG_FILE_NAME}"

    if [[ -e "${serverConfigFile}" ]]; then
        echo "${serverConfigFile} is already here!"
        return 1
    fi

    #simple config file
    cat <<EOF >"${serverConfigFile}"
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

}
# ----------  end of function generateSimpleConfig  ----------


#===  FUNCTION  ================================================================
#          NAME:  generateSystemDService
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function generateSystemDService () {
    local serverDir=$1
    assertNotEmpty "${serverDir}" "serverDir" || return 1

    assertNotEmpty "${SYSTEMD_SERVICE_FILE}" "SYSTEMD_SERVICE_FILE" || return 1
    assertNotEmpty "${SYSTEMD_SERVICE_LINK}" "SYSTEMD_SERVICE_LINK" || return 1
    
    local serviceFileName=${serverDir}/${SYSTEMD_SERVICE_FILE}
    checkFileAndLink "${serviceFileName}" "${SYSTEMD_SERVICE_LINK}" || return 1

    cat <<EOF >"${serviceFileName}"
[Unit]
Description=SoftEther VPN Server
After=network.target auditd.service
ConditionPathExists=!${serverDir}/do_not_run
[Service]
Type=forking
EnvironmentFile=-${serverDir}
ExecStart=${serverDir}/${SERVER} start
ExecStop=${serverDir}/${SERVER} stop
KillMode=process
Restart=on-failure
# Hardening
PrivateTmp=yes
ProtectHome=yes
ProtectSystem=full
ReadOnlyDirectories=/
ReadWriteDirectories=-${serverDir}
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_BROADCAST CAP_NET_RAW CAP_SYS_NICE CAP_SYS_ADMIN CAP_SETUID
[Install]
WantedBy=multi-user.target
EOF


}
# ----------  end of function generateSystemDService  ----------


