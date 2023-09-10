readonly ARCHITECTURE="linux-x64-64bit"
readonly SOURCE_FILE_NAME="sourceArchive.tar.gz"
readonly DESTINATION_DIR="/usr/local"

readonly SERVER_CONFIG_FILE_NAME="vpn_server.config"
readonly SERVER_ADMIN_IP_FILE_NAME="adminip.txt"
readonly SERVER_EXTERNAL_IP="178.79.179.117"
readonly SERVER_PORT="443"
readonly HUB_NAME="beggyHub"

readonly SYSCTL_FILE="sysctl.conf"
readonly SYSCTL_LINK="/etc/sysctl.d/50-vpnserver.conf"

readonly SYSTEMD_SERVICE_FILE="vpnserver.service"
readonly SYSTEMD_SERVICE_LINK="/lib/systemd/system/vpnserver.service"

readonly SERVER="vpnserver"
readonly CLIENT="vpnclient"
readonly CONFIGURATOR="vpncmd"

readonly -a USER_NAME=()
readonly USER_ORGANIZATION="Beggy space"
readonly USER_UNIT="Three fluffy hippopotamus"
readonly USER_COUNTRY="Arctic"
readonly USER_STATE="Arctic"
readonly USER_LOCALE="AT"
readonly USER_EXPIRES="365"
readonly USER_SERIAL=""

readonly CLIENT_INSTALL_SCRIPT="installClient.sh"
readonly CLIENT_UNINSTALL_SCRIPT="uninstallClient.sh"
readonly CLIENT_ARCHIVE_SUFFIX="_VPNClient.tar.bz2"
