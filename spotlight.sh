#!/usr/bin/env bash

conf_file=/etc/spotlight.conf

if [ -f "$conf_file" ]; then
	source "$conf_file"
fi

if [ -z "$dataPath" ]; then
	dataPath="${XDG_DATA_HOME:-$HOME/.local/share}/spotlight"
fi

if [ -z "$store" ]; then
	store=false
fi

while getopts ":hp:s" opt; do
  case ${opt} in
    h ) echo ""
        echo "spotlight.sh - Windows 10 Spotlight Background images for Gnome"
        echo ""
        echo "Options:"
        echo "  -h shows this message"
        echo "  -p specifies a working path. Defaults to \"$HOME/.local/share/spotlight\""
        echo "  -s stores the images into the folder path/archive/"
        exit 1
      ;;
    p ) dataPath=$OPTARG
      ;;
    s ) store=true
      ;;
    \? ) echo "Usage: spotlight.sh [-h additional help] [-p working path] [-s store images]"
         exit 2
      ;;
  esac
done

function decodeURL
{
	printf "%b\n" "$(sed 's/+/ /g; s/%\([0-9A-F][0-9A-F]\)/\\x\1/g')"
}

response=$(wget -qO- "https://arc.msn.com/v3/Delivery/Cache?pid=279978&fmt=json&ua=WindowsShellClient&lc=en,en-US&ctry=US")
status=$?

if [ $status -ne 0 ]
then
	systemd-cat -t spotlight -p emerg <<< "Query failed"
	exit $status
fi

item=$(jq -r ".batchrsp.items[0].item" <<< $response)

landscapeUrl=$(jq -r ".ad.image_fullscreen_001_landscape.u" <<< $item)
sha256=$(jq -r ".ad.image_fullscreen_001_landscape.sha256" <<< $item | base64 -d | hexdump -ve "1/1 \"%.2x\"")
title=$(jq -r ".ad.title_text.tx" <<< $item)
searchTerms=$(jq -r ".ad.title_destination_url.u" <<< $item | sed 's/.*q=\([^&]*\).*/\1/' | decodeURL)

mkdir -p "$dataPath"
img="$dataPath/current_background.jpg"
rm -f "$img"

wget -qO "$img" "$landscapeUrl"
sha256calculated=$(sha256sum $img | cut -d " " -f 1)

if [ "$sha256" != "$sha256calculated" ]
then
	systemd-cat -t spotlight -p emerg <<< "Checksum incorrect"
	exit 1
fi

if [ "$store" = true ] 
then
	stored_img="$dataPath/archive/$(date +%Y%m%d) $title ($searchTerms).jpg"
	mkdir -p "$dataPath/archive"
	mv "$img" "$stored_img"
	ln -sfn "$stored_img" "$img"
fi

gsettings set "org.gnome.desktop.background" picture-options "zoom"
gsettings set "org.gnome.desktop.background" picture-uri "file://$img"

notify-send "Background changed" "$title ($searchTerms)" --icon=preferences-desktop-wallpaper --urgency=low #--hint=string:desktop-entry:spotlight
systemd-cat -t spotlight -p info <<< "Background changed to $title ($searchTerms)"
