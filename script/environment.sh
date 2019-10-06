readonly ARCHITECTURE="linux-x64-64bit"
readonly DESTINATION_DIR="/usr/local"

readonly SERVER_CONFIG_FILE_NAME="vpn_server.config"
readonly SERVER_ADMIN_IP_FILE_NAME="adminip.txt"
readonly SERVER_EXTERNAL_IP=""
readonly SERVER_PORT=""
readonly HUB_NAME=""

readonly SYSCTL_FILE="sysctl.conf"
readonly SYSCTL_LINK="/etc/sysctl.d/50-vpnserver.conf"

readonly SYSTEMD_SERVICE_FILE="vpnserver.service"
readonly SYSTEMD_SERVICE_LINK="/lib/systemd/system/vpnserver.service"

readonly SERVER="vpnserver"
readonly CLIENT="vpnclient"
readonly CONFIGURATOR="vpncmd"

readonly -a USER_NAME=()
readonly USER_ORGANIZATION=""
readonly USER_UNIT=""
readonly USER_COUNTRY=""
readonly USER_STATE=""
readonly USER_LOCALE=""
readonly USER_EXPIRES=""
readonly USER_SERIAL=""

readonly CLIENT_INSTALL_SCRIPT="installClient.sh"
readonly CLIENT_ARCHIVE_SUFFIX="_VPNClient.tar.bz2"
