#!/bin/bash                                                       

#############################
# SERVERSTART MANAGED IT    #
# Automated WireGuard Setup #
#############################

# Beispiel für eine WireGuard Konfiguration. Diese muss als base64-String als Parameter übergeben werden
# 
# [Interface]
# PrivateKey = xx
# Address = 192.168.17.4/32
# 
# [Peer]
# PublicKey = xx
# AllowedIPs = 192.168.17.1/32,192.168.17.4/32,192.168.0.0/16
# Endpoint = xx:51820

# Default values
REBOOT=true
LOG_FILE="/var/log/serverstart_wireguard.log"

# Function to display usage
usage() {
    echo "Usage: $0 --interface_name <interface_name> --wireguard_name <wireguard_name> --config <base64_config_content> [--no-reboot]"
    echo "Parameters:"
    echo "  --interface_name       - The name of the network interface to be used (e.g., eth0)."
    echo "  --wireguard_name       - The name of the WireGuard configuration and interface (e.g., musterknd)."
    echo "  --config               - The base64 encoded content of the WireGuard configuration file."
    echo "  --no-reboot            - Optional flag to skip the system reboot."
    exit 1
}

# Parse the arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        --interface_name)
            INTERFACE_NAME="$2"
            shift 2
            ;;
        --wireguard_name)
            WIREGUARD_NAME="$2"
            shift 2
            ;;
        --config)
            BASE64_CONFIG_CONTENT="$2"
            shift 2
            ;;
        --no-reboot)
            REBOOT=false
            shift 1
            ;;
        *)
            echo "Unknown parameter: $1"
            usage
            ;;
    esac
done

# Check if required arguments are provided
if [ -z "$INTERFACE_NAME" ] || [ -z "$WIREGUARD_NAME" ] || [ -z "$BASE64_CONFIG_CONTENT" ]; then
    usage
fi

# Set non-interactive mode
export DEBIAN_FRONTEND=noninteractive

# Check if iptabels and systemctl is installed
command -v iptables >/dev/null 2>&1 || { echo "iptables not found. Please install iptables." | tee -a $LOG_FILE; exit 1; }
command -v systemctl >/dev/null 2>&1 || { echo "systemctl not found. Please install systemd." | tee -a $LOG_FILE; exit 1; }

# Print a separating line in the log file
echo "------------------------------------------------------------" | tee -a $LOG_FILE
echo "SERVERSTART MANAGED IT - Automated WireGuard setup" | tee -a $LOG_FILE
echo "------------------------------------------------------------" | tee -a $LOG_FILE
echo "[$(date)] Starting WireGuard setup script" | tee -a $LOG_FILE

# Update and upgrade the system
echo "[$(date)] Updating and upgrading the system" | tee -a $LOG_FILE
apt-get update | tee -a $LOG_FILE
apt-get upgrade -y | tee -a $LOG_FILE

# Install WireGuard and resolvconf
echo "[$(date)] Installing WireGuard" | tee -a $LOG_FILE
apt-get install -y wireguard | tee -a $LOG_FILE

# Check WireGuard installation
command -v wg-quick >/dev/null 2>&1 || { echo "wg-quick not found. Please install WireGuard." | tee -a $LOG_FILE; exit 1; }

# Decode the base64 encoded configuration and write to the configuration file
echo "[$(date)] Writing WireGuard configuration to /etc/wireguard/${WIREGUARD_NAME}.conf" | tee -a $LOG_FILE
echo $BASE64_CONFIG_CONTENT | base64 --decode > /etc/wireguard/${WIREGUARD_NAME}.conf

# Bring up the WireGuard interface
echo "[$(date)] Bringing up WireGuard interface ${WIREGUARD_NAME}" | tee -a $LOG_FILE
wg-quick down ${WIREGUARD_NAME} 2>/dev/null || true # Down the interface if it's already up
wg-quick up ${WIREGUARD_NAME} | tee -a $LOG_FILE

# Uncomment net.ipv4.ip_forward in /etc/sysctl.conf
echo "[$(date)] Configuring sysctl for IP forwarding" | tee -a $LOG_FILE
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# Apply the sysctl settings
echo "[$(date)] Applying sysctl settings" | tee -a $LOG_FILE
sysctl -p | tee -a $LOG_FILE

# Clear existing iptables rules for the specific interface
echo "[$(date)] Clearing existing iptables rules for ${WIREGUARD_NAME}" | tee -a $LOG_FILE
iptables --flush FORWARD
iptables -t nat --flush POSTROUTING

# Set up iptables rules
echo "[$(date)] Setting up iptables rules" | tee -a $LOG_FILE
iptables --append FORWARD --in-interface ${INTERFACE_NAME} --out-interface ${WIREGUARD_NAME} --jump ACCEPT | tee -a $LOG_FILE
iptables --append FORWARD --in-interface ${WIREGUARD_NAME} --out-interface ${INTERFACE_NAME} --match state --state RELATED,ESTABLISHED --jump ACCEPT | tee -a $LOG_FILE
iptables -t nat --append POSTROUTING --out-interface ${WIREGUARD_NAME} --jump MASQUERADE | tee -a $LOG_FILE

# Install iptables-persistent to save the iptables rules
echo "[$(date)] Installing iptables-persistent" | tee -a $LOG_FILE
apt-get install -y iptables-persistent | tee -a $LOG_FILE

# Enable the WireGuard service to start on boot
echo "[$(date)] Enabling WireGuard service wg-quick@${WIREGUARD_NAME}" | tee -a $LOG_FILE
systemctl enable wg-quick@${WIREGUARD_NAME}.service | tee -a $LOG_FILE

# Reload the systemd manager configuration
echo "[$(date)] Reloading systemd manager configuration" | tee -a $LOG_FILE
systemctl daemon-reload | tee -a $LOG_FILE

# Optional reboot
if [ "$REBOOT" = true ]; then
    echo "[$(date)] Rebooting the system" | tee -a $LOG_FILE
    reboot
else
    echo "[$(date)] Reboot skipped. Please reboot manually to apply changes." | tee -a $LOG_FILE
fi
