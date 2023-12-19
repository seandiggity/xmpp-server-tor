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
* Gives instructions on what the sysadmin needs to manually do at the end

To use it, set up a new Debian server, SSH into it, switch to the root user, and:

```sh
git clone https://github.com/seandiggity/xmpp-server-tor.git
cd xmpp-server-tor
./bootstrap.sh
```
