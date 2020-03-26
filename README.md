# spotlight
Windows 10 Spotlight Background images for Gnome

## Installation
### System-wide
* /usr/bin/spotlight.sh
* /usr/lib/systemd/user/spotlight.service
* /usr/lib/systemd/user/spotlight.timer
* /usr/share/applications/spotlight.desktop
### Local
* ~/.local/bin/spotlight.sh
* ~/.local/share/systemd/user/spotlight.service
* ~/.local/share/systemd/user/spotlight.timer
* ~/.local/share/applications/spotlight.desktop
### Dependencies
* wget
* jq
* sed
* glib2 (gnome)
* systemd

## Usage
Run `systemctl --user enable spotlight.timer` to get a new picture every day.

To trigger it manually you can either use the desktop entry by looking for _spotlight_ in your gnome application menu, run `spotlight.sh` in a terminal, or trigger the service manually with `systemctl --user start spotlight.service`.

Use the system log to get the past image descriptions, e.g. for the the current background `journalctl -t spotlight -n 1`.

## Configuration

Spotlight does not require particular configuration.

The default behaviour of spotlight is to discard the images that it downloads. The `/etc/spotlight.conf` file allows to alter this, by storing the images in the spotlight working path.

The settings specified in the config file can be overridden when calling spotlight.sh directly from the terminal:

 * -h shows a small help message
 * -p specifies a working path. Defaults to "$HOME/.local/share/spotlight"
 * -s stores the images into the folder path/archive/

## Packages
### Arch Linux
[aur/spotlight](https://aur.archlinux.org/packages/spotlight/)
