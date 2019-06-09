#!/bin/bash

typeset -A menu
menu=()

show_status () {
    # Show the nordvpn status info if available
    while read -r line; do
        menu+=([$line]="nord")
    done <<< $(nordvpn status)
}

show_settings () {
    # Show current settings and allow user to toggle
    # auto-connect, cybersec, obfuscate, killswitch and notifications.
    menu+=([Select option to toggle it:]="echo")
    while read -r line; do
        if [ ! -z "${line// }" ]; then

            if [ -z "$(echo $line | grep 'enabled')" ]; then
                toggle="true"
            else
                toggle="false"
            fi

            if grep -q "Auto-connect" <<< "$line"; then cmd="autoconnect"
            elif grep -q "CyberSec" <<< "$line"; then cmd="cybersec"
            elif grep -q "Obfuscate" <<< "$line"; then cmd="obfuscate"
            elif grep -q "Kill Switch" <<< "$line"; then cmd="killswitch"
            elif grep -q "Notify" <<< "$line"; then cmd="notify"
            fi
            
            menu+=([$line]="nordvpn set $cmd $toggle && nord settings")
        fi
    done <<< $(nordvpn settings)
}

show_menu () {
    # The general nordvpn menu that allows for connect/disconnect and submenu navigation
    vermsg=$(nordvpn countries | grep 'new version')
    if [ -z vermsg ]; then
        countries=$(nordvpn countries)
    else
        countries=$(nordvpn countries | tail -n +2)
    fi
    
    if nordvpn status | grep -q 'Disconnected'; then
        menu+=([1 - Connect to NordVPN]="nordvpn connect")
        
        for country in $countries; do
            if [ ! -z "${country// }" ]; then
                menu+=([$country]="nordvpn connect $country")
            fi
        done
    else
        menu+=(
            [1 - Disconnect from NordVPN]="nordvpn disconnect"
            [3 - View Status]="nord status"
        )
    fi
    
    menu+=([2 - Settings]="nord settings")
}

# Checks script argument for status or settings options
if [[ $1 == "status" ]]; then
    show_status
elif [[ $1 == "settings" ]]; then
    show_settings
else
    show_menu
fi

# Displays country if connected to one
country=$(nordvpn status | grep "Country" | cut -c 10-)

if [[ -z "$country" ]]; then
    RTEXT="NordVPN (Disconnected)"
else
    RTEXT="NordVPN ($country)"
fi


# Section from rofigen by losoliveirasilva
# URL: https://github.com/losoliveirasilva/rofigen

launcher=(rofi -dmenu -i -lines 10 -p "${RTEXT}" -width 30 -location 0 -bw 1) 


selection="$(printf '%s\n' "${!menu[@]}" | sort | "${launcher[@]}")"

if [[ -n $selection ]]; then
    exec ${menu[${selection}]}
fi
