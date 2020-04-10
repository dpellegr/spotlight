# spotlight
Windows 10 Spotlight Background images for Gnome

## Installation
Make sure that the following **dependencies** are satisfied:
* wget
* jq
* sed
* glib2 (gnome)
* systemd [optional]

### Arch Linux
Use the provided PKGBUILD.

### Other Distributions
Depending if you want a system-wide user-wise availability you should put the provided files in the following paths
#### System-wide
* /usr/bin/spotlight.sh
* /etc/spotlight.conf
* /usr/lib/systemd/user/spotlight.service
* /usr/lib/systemd/user/spotlight.timer
* /usr/share/applications/spotlight.desktop
#### Local
* ~/.local/bin/spotlight.sh
* ~/.local/share/spotlight/spotlight.conf
* ~/.local/share/systemd/user/spotlight.service
* ~/.local/share/systemd/user/spotlight.timer
* ~/.local/share/applications/spotlight.desktop

## Usage
Call from the terminal `spotlight.sh` to get a new background. Alternatively, the `.desktop` file allows to run the script by browsing the application menu.

A systemd timer is provided to run the script periodically (daily by default). To enable it:
`systemctl --user enable spotlight.timer`

It is also possible to run the script manually through systemd:
`systemctl --user start spotlight.service`

The descriptions of the images are stored in the systemd journa or printed on the terminal depending if the `-j` option was passed to the script. By default the `-j` option is passed when the script is called via the application menu and systemd. To query the journal for the descriptions of the last 10 images, you can do: 
`journalctl -t spotlight -n 10`.

## Configuration

Spotlight does not require particular configuration, however it has some options to control if and where the previous backgrounds are stored.

All the options are available on the command line:

 * -h shows this help message
 * -j push the output messages to systemd journal instead of stdout. This option should be passed when launched from a service file.
 * -k keeps the previous image
 * -d stores the image into the given destination. Defaults to \"$HOME/.local/share/backgrounds\".
 * -m the current background is not stored if has been kept for less than \"m\" minutes, implies -k.
 
The `-d` and `-m` options can also be setted by mean of the `spotlight.conf` file. Spotlight looks for options in `/etc/spotlight.conf`, `~/.local/share/spotlight/spotlight.conf` and finally on the command line; each, if present, overrides the previous.

## Acknowledgments
Spotlight was originally implemented by [mariusknaust](https://github.com/mariusknaust/spotlight).
