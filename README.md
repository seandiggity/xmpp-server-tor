Installation Script for XMPP Server With Tor Hidden Service and Off-the-Record Messaging
===================

This script contains "Paranoid Prosody" settings for a Jabber/XMPP server configuration like OTR.im and is forked from https://github.com/NSAKEY/paranoid-prosody. It has been modified to force Prosody XMPP server to use strong SSL/TLS ciphers, disable logging, add OTR, and some other "paranoid" things. It also sets up Tor to provide a hidden service for Prosody.

This is a script to bootstrap a Debian server to be a set-and-forget Prosody server. It's been tested on Debian Bookworm and should work on any other maintained version (with minor tweaks for release and package names).

This script performs the following tasks:

* Upgrades all the software on the system
* Adds the deb.torproject.org and the packages.prosody.im/debian repositories to apt, so Prosody and Tor updates come directly from the source.
* Installs and configures Prosody with reasonably-paranoid defaults.
* Installs and configures Tor to be a hidden service for Prosody (You can also manually edit torrc to make SSH an authenticated hidden service)
* Configures sane default firewall rules
* Configures automatic updates
* Triggers Let's Encrypt certificate generation (You can skip if you want and create self-signed certs)
* Gives instructions on what the sysadmin needs to manually do at the end

To use it, set up a new Debian server, SSH into it, switch to the root user, and:

```sh
git clone https://github.com/seandiggity/xmpp-server-tor.git
cd xmpp-server-tor
./bootstrap.sh
```

## After Installation
* Try SSHing into this server again in a new window as well as connecting to XMPP, to confirm the firewall isn't broken.

### TO DO List:
1. This script uses `certbot` and Let's Encrypt by default to generate SSL/TLS certificates. See: https://prosody.im/doc/letsencrypt

  * If you used OpenSSL to generate certificates, run `cat /etc/prosody/certs/xmpp.crt` and submit its contents to your friendly neighborhood Certificate Authority.

2. Configure DNS. Example (replace `example.org` with your domain):

```
SRV 	_xmpp-client._tcp 	3600 	10 	0 	5222 	example.org.
SRV 	_xmpp-server._tcp 	3600  	10 	0 	5269 	example.org.
```

3. Edit `/etc/prosody/prosody.cfg.lua` so that all cases of `example.org` are replaced with your domain.

4. After you reboot, you can run `aa-enforce /etc/apparmor.d/usr.bin.prosody` to update apparmor rules.

5. After the reboot, be sure to run `cat /var/lib/tor/xmpp/hostname` to get your Tor hidden service address.

6. The option to allow SSH as an authenticated Tor hidden service has been supplied. Just read the comments in `/etc/tor/torrc`

7. To create an account, run `prosodyctl adduser user@example.org` See: https://prosody.im/doc/creating_accounts

8. It is recommended to use a XMPP client like CoyIM to connect via OTR and Tor. See: https://coy.im

* Remember to reboot the server after you've made changes.
