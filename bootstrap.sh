#!/bin/bash

# "Paranoid Prosody" settings for config like OTR.im forked from https://github.com/NSAKEY/paranoid-prosody
# Updated December 2023 for Debian Bookworm
# Released under GNU General Public License v3 or any later version

# Check for root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

PWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Update software
echo "== Updating software"
apt-get --allow-releaseinfo-change update
apt-get dist-upgrade -y
apt-transport-https
apt-get install -y

# add official Tor repository
if ! grep -q "deb.torproject.org/torproject.org" /etc/apt/sources.list; then
    echo "== Adding the official Tor repository"
    echo "deb [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org bookworm main" >> /etc/apt/sources.list
    wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null
    apt-get update
    apt-get install deb.torproject.org-keyring
fi

# Add the official Prosody repository
#if ! grep -q "packages.prosody.im/debian" /etc/apt/sources.list; then
#    echo "== Adding the official Prosody repository"
#    echo "deb https://packages.prosody.im/debian bookworm main" >> /etc/apt/sources.list
#    wget https://prosody.im/files/prosody-debian-packages.key -O- | sudo apt-key add -
#    apt-get update
#fi
echo "== Adding Prosody via Debian extrepo"
apt install extrepo
extrepo enable prosody
apt-get update

# Install prosody and tor, plus related packages
echo "== Installing Prosody and Tor"
apt-get install -y deb.torproject.org-keyring tor tor-arm tor-geoipdb prosody lua-event
service tor stop
service prosody stop

# SSL/TLS prep for prosody
# Generate self-signed certificate
#openssl genrsa -out /etc/prosody/certs/xmpp.key 4096
#openssl req -new -key /etc/prosody/certs/xmpp.key -out /etc/prosody/certs/xmpp.crt
#openssl dhparam -out /etc/prosody/certs/dhparam.pem 4096
# Use Let's Encrypt certificate authority for prosody
apt-get install certbot
certbot certonly --deploy-hook "prosodyctl --root cert import /etc/letsencrypt/live"
echo -e "#!/bin/sh\n/usr/bin/prosodyctl --root cert import /etc/letsencrypt/live" >> /etc/letsencrypt/renewal-hooks/deploy/prosody.sh
chown prosody:prosody /etc/prosody/certs/*
chmod 600 /etc/prosody/certs/*

# Configure tor
cp $PWD/etc/tor/torrc /etc/tor/torrc

# Configure prosody
cp $PWD/etc/prosody/prosody.cfg.lua /etc/prosody/prosody.cfg.lua
mkdir share
mkdir share/lua
mkdir share/lua/5.1
mkdir share/lua/5.1/mod_otr
cp $PWD/usr/lib/prosody/modules/* /usr/lib/prosody/modules/
cp $PWD/usr/lib/prosody/modules/mod_otr.lua /usr/lib/prosody/modules/share/lua/5.1/mod_otr/

# Configure firewall rules
echo "== Configuring firewall rules"
apt-get install -y debconf-utils
echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
apt-get install -y iptables iptables-persistent
cp $PWD/etc/iptables/rules.v4 /etc/iptables/rules.v4
cp $PWD/etc/iptables/rules.v6 /etc/iptables/rules.v6
chmod 600 /etc/iptables/rules.v4
chmod 600 /etc/iptables/rules.v6
iptables-restore < /etc/iptables/rules.v4
ip6tables-restore < /etc/iptables/rules.v6

# Configure automatic updates
echo "== Configuring unattended upgrades"
apt-get install -y unattended-upgrades apt-listchanges
cp $PWD/etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades
service unattended-upgrades restart

# Install and configure apparmor
apt-get install -y apparmor apparmor-profiles apparmor-utils grub
sed -i.bak 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 apparmor=1 security=apparmor"/' /etc/default/grub
update-grub
cp $PWD/etc/apparmor.d/usr.bin.prosody /etc/apparmor.d/usr.bin.prosody

# Install and config for apt-transport-tor
systemctl start tor
apt-get install apt-transport-tor
sed -i 's|https://deb.torproject.org|tor://apow7mjfryruh65chtdydfmqfpj5btws7nbocgtaovhvezgccyjazpqd.onion|g' /etc/apt/sources.list
apt-get update
apt-get upgrade
apt-get install --reinstall deb.torproject.org-keyring tor

# Final instructions
echo ""
echo "== Try SSHing into this server again in a new window as well as connecting to XMPP, to confirm the firewall isn't broken"
echo ""
echo "== TO DO LIST:"
echo ""
echo "1. This script uses certbot and Let\'s Encrypt by default to generate SSL/TLS certificates. See: https://prosody.im/doc/letsencrypt"
echo "If you used OpenSSL to generate certificates, run 'cat /etc/prosody/certs/xmpp.crt' and submit its contents to your friendly neighborhood Certificate Authority."
echo ""
echo "2. Configure DNS. Example (replace 'example.org' with your domain):"
echo "SRV 	_xmpp-client._tcp 	3600 	10 	0 	5222 	example.org."
echo "SRV 	_xmpp-server._tcp 	3600  	10 	0 	5269 	example.org."
echo ""
echo "3. Edit /etc/prosody/prosody.cfg.lua so that both cases of 'example.org' are replaced with your domain."
echo ""
echo "4. After you reboot, you can run 'aa-enforce /etc/apparmor.d/usr.bin.prosody' if you want."
echo ""
echo "5. After the reboot, be sure to run 'cat /var/lib/tor/xmpp/hostname' to get your hidden service address."
echo ""
echo "6. The option to allow SSH as an authenticated hidden service has been supplied. Just read the comments in /etc/tor/torrc."
echo ""
echo "== REBOOT THIS SERVER"
