# FALCON by SINAN

Advanced Tor IP Rotator written in Bash.

FALCON is a lightweight Linux utility that automatically rotates Tor exit nodes and refreshes your public IP through the Tor network.

---

# Features

- Automatic Tor IP rotation
- Infinite rotation mode
- Dynamic IP change detection
- Multi-distro dependency installer
- Tor control port support
- IP verification system
- Logging support
- Clean terminal UI
- Netcat compatibility checks
- Safe Tor proxy handling

---

# Screenshot

```text
███████╗ █████╗ ██╗      ██████╗ ██████╗ ███╗   ██╗
██╔════╝██╔══██╗██║     ██╔════╝██╔═══██╗████╗  ██║
█████╗  ███████║██║     ██║     ██║   ██║██╔██╗ ██║
██╔══╝  ██╔══██║██║     ██║     ██║   ██║██║╚██╗██║
██║     ██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║
╚═╝     ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝

---

Installation

Clone Repository

git clone https://github.com/Falconsinan/Falcon-ipchanger.git

Give Permission

chmod +x falcon.sh

Run Script

sudo ./falcon.sh

---

Requirements

- Linux
- Tor
- Curl
- Netcat OpenBSD

The script can automatically install missing dependencies.

---

Enable Tor Control Port

Edit torrc file:

sudo nano /etc/tor/torrc

Add:

ControlPort 9051
CookieAuthentication 0

Restart Tor:

sudo systemctl restart tor

---

Usage

After starting:

[?] Rotation interval (seconds):
[?] Number of rotations (0 = infinite):

Example:

Interval: 10
Rotations: 0

This rotates IP every 10 seconds infinitely.

---

Log File

Logs are saved in:

falcon.log

---

Disclaimer

This project is made for educational and privacy-testing purposes only.

Use responsibly and follow local laws and platform policies.

---

Author

SINAN

---

License

MIT License
