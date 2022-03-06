#!/bin/bash

if [ ! $#  -eq 3 ]
then
    echo -e "Usage: add-profile <config_file> <new_vpn_ip> <peer_name>"
    exit 1
fi

config_file=${1}
desired_ip=${2}
peer_name=${3}
server_pubkey="Server public key"
# -- Check config file exists -- #
if [ ! -f  ${config_file} ]
then
    echo -e "Config file does not exist\nquitting"
    exit 1
fi

# Conf exists
# We assume user (me) enters a valid ipv4 address...
umask 077
wg genkey | tee privatekey | wg pubkey > publickey
priv_key=$(cat privatekey)
pub_key=$(cat publickey)

rm privatekey
rm publickey

cat << EOT > client.conf
[Interface]
Address = ${desired_ip}/24
PrivateKey = ${priv_key}

[Peer]
PublicKey = ${server_pubkey}
Endpoint = server.domain.xyz:51820
AllowedIPs = 0.0.0.0/0, ::/0 
PersistentKeepalive = 25

EOT

cat << EOT >> ${config_file}
[Peer]
# ${peer_name}
PublicKey = ${pub_key}
AllowedIPs = ${desired_ip}/32

EOT

# -- Present QR code for phones -- #
qrencode -t ANSI256 < client.conf
echo "Keep client.conf file? [Y/n]"
read keep_client_conf
if [[ ${keep_client_conf} == "n" ]]
then
    rm -v client.conf
fi

# -- Reload wg interface config -- #
# This depends on setup 
#wg setconf wg0 ${config_file}
systemctl restart wg-quick@wg0.service