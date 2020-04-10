#!/usr/bin/env bash

dataPath="${XDG_DATA_HOME:-$HOME/.local/share}"

# spotlight working directory - where the link to the current background is stored
spotlightPath="$dataPath/spotlight"

# archive directory - contains all the saved backgrounds
backgroundsPath="$dataPath/spotlight/backgrounds"


keepImage=false
useJournal=false

conf_file="$spotlightPath/spotlight.conf"

if [ -f "$conf_file" ]
then
        source "$conf_file"
elif [ -f "/etc/spotlight.conf" ]
then
	source "/etc/spotlight.conf"
fi

function showHelp()
{
	echo "Usage: $0 [-j] [-k] [-d <destination>] [-m <min-keep-minutes>]"
	echo ""
	echo "Options:"
	echo "	-h shows this help message"
	echo "	-j push the output messages to systemd journal instead of stdout. This option should be passed when launched from a service file."
	echo "	-k keeps the previous image"
	echo "	-d stores the image into the given destination. Defaults to \"$HOME/.local/share/backgrounds\"."
	echo "	-m the current background is not stored if has been kept for less than \"m\" minutes, implies -k."
}

while getopts "hjkd:m:" opt
do
	case $opt
	in
		'j')
			useJournal=true
		;;
		'k')
			keepImage=true
		;;
		'm')
			minKeepMinutes=$OPTARG
		;;
		'd')
			backgroundsPath=$OPTARG
		;;
		'h'|'?')
			showHelp
			exit 0
		;;
	esac
done

function message()
{
	if [ "$useJournal" = true ]
        then
		systemd-cat -t spotlight -p $2 <<< "$1"
	else
		echo "$2: $1"
	fi
}

function decodeURL
{
	printf "%b\n" "$(sed 's/+/ /g; s/%\([0-9A-F][0-9A-F]\)/\\x\1/g')"
}

response=$(wget -qO- "https://arc.msn.com/v3/Delivery/Cache?pid=279978&fmt=json&ua=WindowsShellClient&lc=en,en-US&ctry=US")
status=$?

if [ $status -ne 0 ]
then
	message "Query failed" "emerg"
	exit $status
fi

item=$(jq -r ".batchrsp.items[0].item" <<< $response)

landscapeUrl=$(jq -r ".ad.image_fullscreen_001_landscape.u" <<< $item)
sha256=$(jq -r ".ad.image_fullscreen_001_landscape.sha256" <<< $item | base64 -d | hexdump -ve "1/1 \"%.2x\"")
title=$(jq -r ".ad.title_text.tx" <<< $item)
searchTerms=$(jq -r ".ad.title_destination_url.u" <<< $item | sed "s/.*q=\([^&]*\).*/\1/" | decodeURL)

mkdir -p "$backgroundsPath"
mkdir -p "$spotlightPath"
imagePath="$backgroundsPath/$(date +%y-%m-%d-%H-%M-%S)-$title ($searchTerms).jpg"

wget -qO "$imagePath" "$landscapeUrl"
sha256calculated=$(sha256sum "$imagePath" | cut -d " " -f 1)

if [ "$sha256" != "$sha256calculated" ]
then
	message "Checksum incorrect" "emerg"
	exit 1
fi

previousImagePath="$(readlink "$spotlightPath/background.jpg")"
ln -sf "$imagePath" "$spotlightPath/background.jpg"

gsettings set "org.gnome.desktop.background" picture-options "zoom"
gsettings set "org.gnome.desktop.background" picture-uri "'file://$spotlightPath/background.jpg'"

if [ -f "$previousImagePath" ] && [ -n "$minKeepMinutes" ] && [ $minKeepMinutes -ge 0 ]
then
	downloadTime=$(stat -c '%Z' "$previousImagePath")
	currentTime=$(date +%s)
	neededDuration=$(( 60 * "$minKeepMinutes" ))
	[ $(($currentTime - $downloadTime)) -ge $neededDuration ] && keepImage=true || keepImage=false
fi

if [ "$keepImage" = false ] && [ -n "$previousImagePath" ] && [ -f "$previousImagePath" ] && [ "$imagePath" != "$previousImagePath" ]
then
	rm "$previousImagePath"
	message "Discarded previous background" "info"
else
	message "Previous background kept as $previousImagePath" "info"
fi

notify-send "Background changed" "$title ($searchTerms)" --icon=preferences-desktop-wallpaper --urgency=low #--hint=string:desktop-entry:spotlight
message "Background changed to $title ($searchTerms)" "info"
