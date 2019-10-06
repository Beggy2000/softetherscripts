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

if [[ -n "${_FUNCTION_LIBRARY_NAME}" ]]; then
    return 0
fi
readonly _FUNCTION_LIBRARY_NAME="function.sh"

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
    exit ${exitCode}
}	
# ----------  end of function stopTheScript  ----------

#===  FUNCTION  ================================================================
#          NAME:  initTemporaryDir
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function initTemporaryDir () {
    if [[ -z "${TEMPORARY_DIR}" ]]; then
        TEMPORARY_DIR=$(mktemp --directory --tmpdir=${WORK_DIRECTORY})
    fi
}
# ----------  end of function initTemporaryDir  ----------

#===  FUNCTION  ================================================================
#          NAME:  removeTemporaryDirectory
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================
function removeTemporaryDirectory () {
    [[ -n "${TEMPORARY_DIR}" ]] || return 0
    [[ -d "${TEMPORARY_DIR}" ]] || return 0
    local parentDir=$(dirname "${TEMPORARY_DIR}")
    if [[ "${parentDir}" != "${WORK_DIRECTORY}" ]]; then 
        echo "Would you please to remove temporary directory (${TEMPORARY_DIR}) by hands"
        return 1
    fi
    echo "remove temporary directory ${TEMPORARY_DIR}"
    rm -rf "${TEMPORARY_DIR}"
    return 0
}	

# ----------  end of function removeTemporaryDirectory  ----------

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
#          NAME:  checkIfServerIsStarted
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function checkIfServerIsStarted () {
    assertNotEmpty "${SYSTEMD_SERVICE_FILE}" "SYSTEMD_SERVICE_FILE" || return 1
    systemctl is-active --quiet "${SYSTEMD_SERVICE_FILE}"
}
# ----------  end of function checkIfServerIsStarted  ----------

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
    local programType="$1"
    assertNotEmpty "${programType}" "programType" || return 1
    local architectureType="$2"
    assertNotEmpty "${architectureType}" "architectureType" || return 1
    local archiveFile="$3"
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
    local programType="$1"
    assertNotEmpty "${programType}" "programType" || return 1
    local archiveFile="$2"
    assertReadableFile "${archiveFile}" "archiveFile" || return 1
    local destinationDir="$3"
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
    assertNotEmpty "${SYSTEMD_SERVICE_FILE}" "SYSTEMD_SERVICE_FILE" || return 1

    local serverDirName="$1"
    assertExistingDirectory "${serverDirName}" "serverDirName" || return 1

    cd "${serverDirName}"
    
    generateInitialServerConfig "${serverDirName}"   || return 1
    generateAdminIpConfig "${serverDirName}"  || return 1
    tuneTheKernel "${serverDirName}"          || return 1
    generateServerService "${serverDirName}" || return 1

    chown -R root:root .
    find . -type d -exec chmod u=rwx,go= {} \;
    find . -type f -exec chmod u=r,go= {} \;
    chmod u+x "./${SERVER}" 
    chmod u+x "./${CONFIGURATOR}"
    runServerInitScript "${serverDirName}" || return 1

    # Reload service
    systemctl daemon-reload
    # Enable service
    systemctl enable "${SYSTEMD_SERVICE_FILE}"
    # Start service
    systemctl restart "${SYSTEMD_SERVICE_FILE}"
    
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
    local fileName="$1"
    local linkFileName="$2"
    if [[ -e "${linkFileName}" ]]; then #broken link returns false
        if [[ ! -L "${linkFileName}" ]]; then
            echo "The ${linkFileName} is not a link. Stop the script to avoid overwriting it." >&2
            return 1
        fi
        local realFileName=$(realpath "${linkFileName}")
        if [[ "${realFileName}" != "${fileName}" ]]; then
            echo "Link ${linkFileName} is pointing to a ${realFileName} instead ${fileName}. Stop the script to avoid overwriting the real file. Please fix it before start again." >&2
            return 1
        fi
    fi
    return 0 
}
# ----------  end of function checkFileAndLink  ----------


#===  FUNCTION  ================================================================
#          NAME:  createFileAndLink
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function createFileAndLink () {
    local fileName="$1"
    assertNotEmpty "${fileName}" "fileName" || return 1
    local linkName="$2"
    assertNotEmpty "${linkName}" "linkName" || return 1

    checkFileAndLink "${confFileName}" "${linkName}" || return 1
    [[ -e "${fileName}" ]] || touch "${fileName}"
    ln -sfv "${fileName}" "${linkName}"

}
# ----------  end of function createFileAndLink  ----------

#===  FUNCTION  ================================================================
#          NAME:  tuneTheKernel
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function tuneTheKernel () {
    local serverDirName="$1"
    assertExistingDirectory "${serverDirName}" "serverDirName" || return 1

    assertNotEmpty "${SYSCTL_FILE}" "SYSCTL_FILE" || return 1
    assertNotEmpty "${SYSCTL_LINK}" "SYSCTL_LINK" || return 1
    
    local sysctlFileName="${serverDirName}/${SYSCTL_FILE}"
    createFileAndLink "${sysctlFileName}" "${SYSCTL_LINK}" || return 1

    # Act as router
    setProperty "${sysctlFileName}" net.ipv4.ip_forward 1
    # Tune Kernel
    setProperty "${sysctlFileName}" net.ipv4.ip_local_port_range "1024 65535"
    setProperty "${sysctlFileName}" net.ipv4.tcp_congestion_control "bbr"
    setProperty "${sysctlFileName}" net.core.default_qdisc "fq_codel"

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
    local fileName="$1"
    assertReadableFile "${fileName}" "fileName" || return 1
    local propertyName="$2"
    assertNotEmpty "${propertyName}" "propertyName" || return 1
    
    local escapedPropertyName=$(echo "${propertyName}" | sed 's|\.|\\.|g')
    local propertyValue="$3"
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
#          NAME:  generateInitialServerConfig
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function generateInitialServerConfig () {
    local serverDirName="$1"
    assertExistingDirectory "${serverDirName}" "serverDirName" || return 1

    assertNotEmpty "${SERVER_CONFIG_FILE_NAME}" "SERVER_CONFIG_FILE_NAME" || return 1
    assertNotEmpty "${SERVER_PORT}" "SERVER_PORT" || return 1

    local serverConfigFile="${serverDirName}/${SERVER_CONFIG_FILE_NAME}"

    if [[ -e "${serverConfigFile}" ]]; then
        echo "${serverConfigFile} is already here!" >&2
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
        declare ListenerList {
            declare Listener0 {
                bool DisableDos false
                bool Enabled true
                uint Port ${SERVER_PORT}
            } 
        }
        declare ServerConfiguration
        {
                bool UseKeepConnect false
        }
}

EOF

}
# ----------  end of function generateInitialServerConfig  ----------


#===  FUNCTION  ================================================================
#          NAME:  generateServerService
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function generateServerService () {
    local serverDirName="$1"
    assertExistingDirectory "${serverDirName}" "serverDirName" || return 1

    assertNotEmpty "${SYSTEMD_SERVICE_FILE}" "SYSTEMD_SERVICE_FILE" || return 1
    assertNotEmpty "${SYSTEMD_SERVICE_LINK}" "SYSTEMD_SERVICE_LINK" || return 1
    
    local serviceFileName="${serverDirName}/${SYSTEMD_SERVICE_FILE}"
    createFileAndLink "${serviceFileName}" "${SYSTEMD_SERVICE_LINK}" || return 1

    #get last version here: https://github.com/SoftEtherVPN/SoftEtherVPN/blob/master/systemd/softether-vpnserver.service
    cat <<EOF >"${serviceFileName}"
[Unit]
Description=SoftEther VPN Server
After=network.target auditd.service
ConditionPathExists=!${serverDirName}/do_not_run
[Service]
Type=forking
EnvironmentFile=-${serverDirName}
ExecStart=${serverDirName}/${SERVER} start
ExecStop=${serverDirName}/${SERVER} stop
KillMode=process
Restart=on-failure
# Hardening
PrivateTmp=yes
ProtectHome=yes
ProtectSystem=full
ReadOnlyDirectories=/
ReadWriteDirectories=-${serverDirName}
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_BROADCAST CAP_NET_RAW CAP_SYS_NICE CAP_SYS_ADMIN CAP_SETUID
[Install]
WantedBy=multi-user.target
EOF


}
# ----------  end of function generateServerService  ----------


#===  FUNCTION  ================================================================
#          NAME:  generateAdminIpConfig
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function generateAdminIpConfig () {
    local serverDirName="$1"
    assertExistingDirectory "${serverDirName}" "serverDirName" || return 1

    assertNotEmpty "${SERVER_ADMIN_IP_FILE_NAME}" "SERVER_ADMIN_IP_FILE_NAME" || return 1
    local adminIpTxt="${serverDirName}/${SERVER_ADMIN_IP_FILE_NAME}"

    if [[ -e "${adminIpTxt}" ]]; then
        echo "${adminIpTxt} is already here!" >&2
        return 1
    fi

    cat <<EOF >"${adminIpTxt}"
# Softether VPN Admin IP File
# ---------------------------
#
# more details on https://www.softether.org/4-docs/1-manual/3._SoftEther_VPN_Server_Manual/3.3_VPN_Server_Administration#3.3.18_Restricting_by_IP_Address_of_Remote_Administration_Connection_Source_IPs

127.0.0.1
EOF
}
# ----------  end of function generateAdminIpConfig  ----------


#===  FUNCTION  ================================================================
#          NAME:  runConfigatorScript
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function runConfigatorScript () {
    local serverDirName="$1"
    assertExistingDirectory "${serverDirName}" "serverDirName" || return 1

    local scriptText="$2"
    [[ -z "${scriptText}" ]] && return 0 #nothing to do

    local configuratorCommand="${serverDirName}/${CONFIGURATOR}"
    assertExecutableFile "${configuratorCommand}" "configuratorCommand" || return 1

    assertNotEmpty "${SERVER_PORT}" "SERVER_PORT" || return 1

    local serverIsAlreadyStarted="false"
    checkIfServerIsStarted && serverIsAlreadyStarted="true"

    if [[ "${serverIsAlreadyStarted}" == "false" ]]; then
        local serverCommand="${serverDirName}/${SERVER}"
        assertExecutableFile "${serverCommand}" "serverCommand" || return 1
        "${serverCommand}" start
        sleep 2
    fi
    
    initTemporaryDir
    local scriptFile=$(mktemp --tmpdir=${TEMPORARY_DIR})
    printf '%s\n' "${scriptText}" > "${scriptFile}"
    "${configuratorCommand}" localhost:${SERVER_PORT} /SERVER /IN:"${scriptFile}"
    rm "${scriptFile}"
    
    if [[ "${serverIsAlreadyStarted}" == "false" ]]; then
        "${serverCommand}" stop
        sleep 2
    fi
}
# ----------  end of function runConfigatorScript  ----------

#===  FUNCTION  ================================================================
#          NAME:  runServerInitScript
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function runServerInitScript () {
    assertNotEmpty "${HUB_NAME}" "HUB_NAME" || return 1
    local hubPassword=""
    read -s -p "${HUB_NAME} hub password: " hubPassword
    echo

    #server command: https://www.softether.org/4-docs/1-manual/6._Command_Line_Management_Utility_Manual/6.3_VPN_Server_%2F%2F_VPN_Bridge_Management_Command_Reference_(For_Entire_Server)
    #hub command: https://www.softether.org/4-docs/1-manual/6._Command_Line_Management_Utility_Manual/6.4_VPN_Server_%2F%2F_VPN_Bridge_Management_Command_Reference_(For_Virtual_Hub)
    #more details about server cifers: https://wiki.mozilla.org/Security/Server_Side_TLS
    local serverInitScript="$(cat <<EOF
        HubCreate ${HUB_NAME} /PASSWORD:${hubPassword}
        ServerCipherSet DHE-RSA-AES256-GCM-SHA384
        OpenVpnEnable no /PORTS:1194
        SstpEnable no
        VpnAzureSetEnable no
        KeepDisable
        Hub ${HUB_NAME}
        SecureNatEnable
EOF
)"
    runConfigatorScript "$1" "${serverInitScript}"   
}
# ----------  end of function runServerInitScript  ----------

#===  FUNCTION  ================================================================
#          NAME:  uninstallServer
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function uninstallServer () {
    local serverDirName="$1"
    assertNotEmpty "${serverDirName}" "serverDirName" || return 1
    assertNotEmpty "${SERVER}" "SERVER" || return 1
    assertNotEmpty "${SYSTEMD_SERVICE_FILE}" "SYSTEMD_SERVICE_FILE" || return 1

    local serverFile="${serverDirName}/${SERVER}"
    [[ -x "${serverFile}" ]] && "${serverFile}" stop

    # Disable service
    systemctl disable "${SYSTEMD_SERVICE_FILE}"
    # Stop service
    systemctl stop "${SYSTEMD_SERVICE_FILE}"
    # Reload other services
    systemctl daemon-reload

    assertNotEmpty "${SYSTEMD_SERVICE_FILE}" "SYSTEMD_SERVICE_FILE" || return 1
    assertNotEmpty "${SYSTEMD_SERVICE_LINK}" "SYSTEMD_SERVICE_LINK" || return 1
    local serviceFileName="${serverDirName}/${SYSTEMD_SERVICE_FILE}"
    checkFileAndLink "${serviceFileName}" "${SYSTEMD_SERVICE_LINK}" || return 1
    [[ -e "${serviceFileName}" ]] && rm -v "${serviceFileName}"
    [[ -L "${SYSTEMD_SERVICE_LINK}" ]] && rm -v "${SYSTEMD_SERVICE_LINK}"

    assertNotEmpty "${SYSCTL_FILE}" "SYSCTL_FILE" || return 1
    assertNotEmpty "${SYSCTL_LINK}" "SYSCTL_LINK" || return 1
    local sysctlFileName="${serverDirName}/${SYSCTL_FILE}"
    checkFileAndLink "${sysctlFileName}" "${SYSCTL_LINK}"
    [[ -e "${sysctlFileName}" ]] && rm -v "${sysctlFileName}"
    [[ -L "${SYSCTL_LINK}" ]] && rm -v "${SYSCTL_LINK}"
    service procps start

    [[ -e "${serverDirName}" ]] && rm -rvf "${serverDirName}"
}
# ----------  end of function uninstallServer  ----------

#===  FUNCTION  ================================================================
#          NAME:  checkIfUserExists
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function checkIfUserExists () {
    local userName="$2"
    assertNotEmpty "${userName}" "userName" || return 1
    
    local userListScript="$(cat <<EOF
        Hub ${HUB_NAME}
        UserList
EOF
)"
    
    local userList="$(runConfigatorScript "$1" "${userListScript}" 2>&1 | sed -n 's/^User Name[[:space:]]*|//gp')"
    echo "${userList}" | grep --quiet "${userName}"
}
# ----------  end of function checkIfUserExists  ----------

#===  FUNCTION  ================================================================
#          NAME:  createUserCertificate
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function createUserCertificate () {
    local userName="$2"
    assertNotEmpty "${userName}" "userName" || return 1

    local certificateFileName="$3"
    assertNotExitingFile "${certificateFileName}" "certificateFileName" || return 1

    local keyFileName="$4"
    assertNotExitingFile "${keyFileName}" "keyFileName" || return 1

    assertNotEmpty "${HUB_NAME}" "HUB_NAME" || return 1

    local createUserCertificateScript="$(cat <<EOF
        Hub ${HUB_NAME}
        MakeCert /CN:${userName} /O:${USER_ORGANIZATION} /OU:${USER_UNIT} /C:${USER_COUNTRY} /ST:${USER_STATE} /L:${USER_LOCALE} /SERIAL:${USER_SERIAL} /EXPIRES:${USER_EXPIRES} /SAVECERT:${certificateFileName} /SAVEKEY:${keyFileName}
EOF
)"
    
    runConfigatorScript "$1" "${createUserCertificateScript}"
    return 0
}
# ----------  end of function createUserCertificate  ----------

#===  FUNCTION  ================================================================
#          NAME:  createUserOnServer
#   DESCRIPTION:  preconditions: server started
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function createUserOnServer () {
    local userName="$2"
    assertNotEmpty "${userName}" "userName" || return 1

    local certificateFileName="$3"
    assertReadableFile "${certificateFileName}" "certificateFileName" || return 1

    assertNotEmpty "${HUB_NAME}" "HUB_NAME" || return 1
    
    local addUserScript="$(cat <<EOF
        Hub ${HUB_NAME}
        UserCreate ${userName} /GROUP:none /REALNAME:none /NOTE:autogenerated
        UserCertSet ${userName} /LOADCERT:${certificateFileName}
EOF
)"

    runConfigatorScript "$1" "${addUserScript}"

}
# ----------  end of function createUserOnServer  ----------


#===  FUNCTION  ================================================================
#          NAME:  packClientScript
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function packClientScript () {
    local userName="$1"
    assertNotEmpty "${userName}" "userName" || return 1

    local certificateFileName="$2"
    assertReadableFile "${certificateFileName}" "certificateFileName" || return 1

    local keyFileName="$3"
    assertReadableFile "${keyFileName}" "keyFileName" || return 1

    local archiveFile="${WORK_DIRECTORY}/${userName}${CLIENT_ARCHIVE_SUFFIX}"
    assertNotExitingFile "${archiveFile}" "archiveFile" ||  return 1

    initTemporaryDir
    local environmentFile="${TEMPORARY_DIR}/environment.sh"
    cat <<EOF >"${environmentFile}"
readonly ARCHITECTURE="${ARCHITECTURE}"
readonly DESTINATION_DIR="${DESTINATION_DIR}"
readonly SYSTEMD_SERVICE_FILE="vpnclient.service"

readonly SYSCTL_FILE="${SYSCTL_FILE}"
readonly SYSCTL_LINK="/etc/sysctl.d/50-vpnclient.conf"

readonly SERVER_EXTERNAL_IP="${SERVER_EXTERNAL_IP}"
readonly SERVER_PORT="443"
readonly HUB_NAME="beggyHub"

readonly CLIENT="vpnclient"
readonly CONFIGURATOR="vpncmd"

readonly USER_NAME="${userName}"
EOF
    tar --create --verbose --bzip2 --file="${archiveFile}" \
        --directory="${WORK_DIRECTORY}" "${CLIENT_INSTALL_SCRIPT}" "$(basename "${LIBRARY}")" "$(basename "${UTIL}")" \
        --directory="$(dirname "${environmentFile}")" "$(basename "${environmentFile}")" \
        --directory="$(dirname "${certificateFileName}")" "$(basename "${certificateFileName}")" \
        --directory="$(dirname "${keyFileName}")" "$(basename "${keyFileName}")"
    rm "${environmentFile}"
}
# ----------  end of function packClientScript  ----------

#===  FUNCTION  ================================================================
#          NAME:  generateInitialClientConfig
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================
function generateInitialClientConfig () {
    echo "generateInitialClientConfig"
}	

# ----------  end of function generateInitialClientConfig  ----------


#===  FUNCTION  ================================================================
#          NAME:  generateClientService
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================
function generateClientService () {
    echo "generateClientService"
}	
# ----------  end of function generateClientService  ----------


#===  FUNCTION  ================================================================
#          NAME:  runClientInitScript
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================
function runClientInitScript () {
    echo "runClientInitScript"
}	
# ----------  end of function runClientInitScript  ----------

#===  FUNCTION  ================================================================
#          NAME:  configureClient
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================
function configureClient () {
    return 0
    #RemoteDisable
    #KeepDisable
    
    #net.ipv4.ip_forward=1

    #systemctl script

    #Create a virtual interface to connect to the VPN server.
    #Create an VPN client account using the following command.
    #Set User Authentication Type of VPN Connection Setting to Client Certificate Authentication
    #AccountStartupSet

    #netplan script
    assertNotEmpty "${CLIENT}" "CLIENT" || return 1
    assertNotEmpty "${CONFIGURATOR}" "CONFIGURATOR" || return 1
    assertNotEmpty "${SYSTEMD_SERVICE_FILE}" "SYSTEMD_SERVICE_FILE" || return 1

    local clientDirName="$1"
    assertExistingDirectory "${clientDirName}" "clientDirName" || return 1

    generateInitialClientConfig "${clientDirName}"   || return 1
    tuneTheKernel "${clientDirName}"          || return 1
    generateClientService "${clientDirName}" || return 1

    cd "${clientDirName}"
    
    chown -R root:root .
    find . -type d -exec chmod u=rwx,go= {} \;
    find . -type f -exec chmod u=r,go= {} \;
    chmod u+x "./${CLIENT}" 
    chmod u+x "./${CONFIGURATOR}"
    runClientInitScript "${serverDirName}" || return 1

    # Reload service
    systemctl daemon-reload
    # Enable service
    systemctl enable "${SYSTEMD_SERVICE_FILE}"
    # Start service
    systemctl restart "${SYSTEMD_SERVICE_FILE}"
    
    cd -
}	
# ----------  end of function configureClient  ----------

#===  FUNCTION  ================================================================
#          NAME:  onExit
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function onExit () {
    removeTemporaryDirectory
}
# ----------  end of function onExit  ----------


#===  FUNCTION  ================================================================
#          NAME:  onError
#   DESCRIPTION:  
#    PARAMETERS:
#       RETURNS:
#===============================================================================
function onError () {
    echo "" > /dev/null
}
# ----------  end of function onError  ----------

readonly WORK_DIRECTORY=$(realpath "$(dirname "$0")")
readonly UTIL=${WORK_DIRECTORY}/util.sh
readonly LIBRARY=${WORK_DIRECTORY}/function.sh #this file
readonly ENVIRONMENT=${WORK_DIRECTORY}/environment.sh

declare TEMPORARY_DIR=""

#include library
[[ -r "${UTIL}" ]] || stopTheScript "There is no ${UTIL} file." >&2
source "${UTIL}"

#include environment
[[ -r "${ENVIRONMENT}" ]] || stopTheScript "There is no ${ENVIRONMENT} file." >&2
source "${ENVIRONMENT}"

trap onExit EXIT
trap onError ERR
