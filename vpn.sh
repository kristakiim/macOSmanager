#!/bin/bash


STREISAND_VPN_NAME="Streisand"
V2RAYTUN_VPN_NAME="v2RayTun"


get_single_vpn_status() {
    VPN_NAME="$1"

    APPLICATION_NAME="${VPN_NAME}.app"
    if [[ ! -d "/Applications/$APPLICATION_NAME" ]]; then
        echo "Uninstalled"
        return 1
    fi

    VPN_ROW=$(scutil --nc list | grep -w "$VPN_NAME")
    if [[ -z "$VPN_ROW" ]]; then
        echo "Misconfigured"
        return 1
    elif echo "$VPN_ROW" | grep -q "Connecting"; then
        echo "Connecting"
        return 0
    elif echo "$VPN_ROW" | grep -q "Connected"; then
        echo "Connected"
        return 0
    elif echo "$VPN_ROW" | grep -q "Disconnecting"; then
        echo "Disconnecting"
        return 0
    elif echo "$VPN_ROW" | grep -q "Disconnected"; then
        echo "Disconnected"
        return 0
    else
        echo "Error"
        return 0
    fi
}


connect_vpn() {
    VPN_NAME="$1"
    VPN_STATUS=$(get_single_vpn_status "$VPN_NAME")

    if [[ "$VPN_STATUS" = "Connected" ]]; then
        echo "$VPN_STATUS"
        return 0
    else
        scutil --nc start "$VPN_NAME"
        for ITERATION in {1..5}; do
            VPN_STATUS=$(get_single_vpn_status "$VPN_NAME")
            if [[ "$VPN_STATUS" = "Connected" ]]; then
                echo "$VPN_STATUS"
                return 0
            fi
            sleep 1
        done
        if [[ "$VPN_STATUS" = "Connected" ]]; then
            echo "$VPN_STATUS"
            return 0
        else
            echo "$VPN_STATUS"
            return 1
        fi
    fi
}


disconnect_vpn() {
    VPN_NAME="$1"
    VPN_STATUS=$(get_single_vpn_status "$VPN_NAME")

    if [[ "$VPN_STATUS" = "Disconnected" ]]; then
        echo "$VPN_STATUS"
        return 0
    else
        scutil --nc stop "$VPN_NAME"
        for ITERATION in {1..5}; do
            VPN_STATUS=$(get_single_vpn_status "$VPN_NAME")
            if [[ "$VPN_STATUS" = "Disconnected" ]]; then
                echo "$VPN_STATUS"
                return 0
            fi
            sleep 1
        done
        if [[ "$VPN_STATUS" = "Disconnected" ]]; then
            echo "$VPN_STATUS"
            return 0
        else
            echo "$VPN_STATUS"
            return 1
        fi
    fi
}


get_location() {
    API_KEY="37073d9d60547864d07b61b8cf505f370f7421147382250c8f7e37f5"
    RESPONSE=$(curl -s --max-time 5 "https://api.ipdata.co?api-key=${API_KEY}")

    if [[ -z "$RESPONSE" ]]; then
        echo "Unavailable;Unavailable;Unavailable;Unavailable;🏳️"
        return 1
    else
        PUBLIC_IP=$(echo "$RESPONSE" | jq -r '.ip // "Unavailable"')
        CITY=$(echo "$RESPONSE" | jq -r '.city // "Unavailable"')
        REGION=$(echo "$RESPONSE" | jq -r '.region // "Unavailable"')
        COUNTRY=$(echo "$RESPONSE" | jq -r '.country_name // "Unavailable"')
        FLAG_EMOJI=$(echo "$RESPONSE" | jq -r '.emoji_flag // "🏳️"')

        echo "$PUBLIC_IP;$CITY;$REGION;$COUNTRY;$FLAG_EMOJI"
        return 0
    fi
}


ACTION="$1"
VPN_NAME="$2"


STREISAND_VPN_STATUS=$(get_single_vpn_status "$STREISAND_VPN_NAME")
V2RAYTUN_VPN_STATUS=$(get_single_vpn_status "$V2RAYTUN_VPN_NAME")


if [[ "$STREISAND_VPN_STATUS" == "Uninstalled" || "$V2RAYTUN_VPN_STATUS" == "Uninstalled" ]]; then
    VPN_STATUS="Uninstalled"
elif [[ "$STREISAND_VPN_STATUS" == "Misconfigured" || "$V2RAYTUN_VPN_STATUS" == "Misconfigured" ]]; then
    VPN_STATUS="Misconfigured"
elif [[ "$STREISAND_VPN_STATUS" == "Error" || "$V2RAYTUN_VPN_STATUS" == "Error" ]]; then
    VPN_STATUS="Error"
elif [[ "$STREISAND_VPN_STATUS" == "Connected"  && -z "$ACTION" && -z "$VPN_NAME" ]]; then
    VPN_STATUS="Connected"
    VPN_NAME="$STREISAND_VPN_NAME"
elif [[ "$V2RAYTUN_VPN_STATUS" == "Connected" && -z "$ACTION" && -z "$VPN_NAME" ]]; then
    VPN_STATUS="Connected"
    VPN_NAME="$V2RAYTUN_VPN_NAME"
elif [[ -z "$ACTION" && -z "$VPN_NAME" ]]; then
    VPN_STATUS="Disconnected"
elif [[ "$ACTION" == "connect" ]]; then
    VPN_STATUS=$(connect_vpn "$VPN_NAME")
elif [[ "$ACTION" == "disconnect" ]]; then
    VPN_STATUS=$(disconnect_vpn "$VPN_NAME")
fi


LOCATION=$(get_location "$VPN_NAME")
PUBLIC_IP=$(echo "$LOCATION" | cut -d';' -f1)
CITY=$(echo "$LOCATION" | cut -d';' -f2)
REGION=$(echo "$LOCATION" | cut -d';' -f3)
COUNTRY=$(echo "$LOCATION" | cut -d';' -f4)
FLAG=$(echo "$LOCATION" | cut -d';' -f5)


if [[ "$VPN_STATUS" = "Uninstalled" ]]; then
    echo "VPN | color=black"
    echo "---"
    echo "Status: $VPN_STATUS"
    echo "Public IP: $PUBLIC_IP"
    echo "City: $CITY"
    echo "Region: $REGION"
    echo "Country: $COUNTRY"
    echo "---"
    echo "Download $STREISAND_VPN_NAME | href=https://apps.apple.com/am/app/streisand/id6450534064"
    echo "---"
    echo "Download $V2RAYTUN_VPN_NAME | href=https://apps.apple.com/am/app/v2raytun/id6476628951"
elif [[ "$VPN_STATUS" = "Misconfigured" ]]; then
    echo "VPN | color=#9B870C"
    echo "---"
    echo "Status: $VPN_STATUS"
    echo "Public IP: $PUBLIC_IP"
    echo "City: $CITY"
    echo "Region: $REGION"
    echo "Country: $COUNTRY"
    echo "---"
    echo "Configure $STREISAND_VPN_NAME | bash=/usr/bin/open param1=\"/Applications/$STREISAND_VPN_NAME.app\" terminal=false refresh=true"
    echo "---"
    echo "Configure $V2RAYTUN_VPN_NAME | bash=/usr/bin/open param1=\"/Applications/$V2RAYTUN_VPN_NAME.app\" terminal=false refresh=true"
elif [[ "$VPN_STATUS" = "Connected" && "$VPN_NAME" == "$STREISAND_VPN_NAME" ]]; then
    echo "$STREISAND_VPN_NAME $FLAG | color=#006400"
    echo "---"
    echo "Status: $VPN_STATUS"
    echo "Public IP: $PUBLIC_IP"
    echo "City: $CITY"
    echo "Region: $REGION"
    echo "Country: $COUNTRY"
    echo "---"
    echo "Disconnect $STREISAND_VPN_NAME | bash='$0' param1=disconnect param2=$STREISAND_VPN_NAME terminal=false refresh=true"
    echo "Configure $STREISAND_VPN_NAME | bash=/usr/bin/open param1=\"/Applications/$STREISAND_VPN_NAME.app\" terminal=false refresh=true"
    echo "---"
    echo "Connect $V2RAYTUN_VPN_NAME | bash='$0' param1=connect param2=$V2RAYTUN_VPN_NAME terminal=false refresh=true"
    echo "Configure $V2RAYTUN_VPN_NAME | bash=/usr/bin/open param1=\"/Applications/$V2RAYTUN_VPN_NAME.app\" terminal=false refresh=true"
elif [[ "$VPN_STATUS" = "Connected" && "$VPN_NAME" == "$V2RAYTUN_VPN_NAME" ]]; then
    echo "$V2RAYTUN_VPN_NAME $FLAG | color=#006400"
    echo "---"
    echo "Status: $VPN_STATUS"
    echo "Public IP: $PUBLIC_IP"
    echo "City: $CITY"
    echo "Region: $REGION"
    echo "Country: $COUNTRY"
    echo "---"
    echo "Disconnect $V2RAYTUN_VPN_NAME | bash='$0' param1=disconnect param2=$V2RAYTUN_VPN_NAME terminal=false refresh=true"
    echo "Configure $V2RAYTUN_VPN_NAME | bash=/usr/bin/open param1=\"/Applications/$V2RAYTUN_VPN_NAME.app\" terminal=false refresh=true"
    echo "---"
    echo "Connect $STREISAND_VPN_NAME | bash='$0' param1=connect param2=$STREISAND_VPN_NAME terminal=false refresh=true"
    echo "Configure $STREISAND_VPN_NAME | bash=/usr/bin/open param1=\"/Applications/$STREISAND_VPN_NAME.app\" terminal=false refresh=true"
elif [[ "$VPN_STATUS" = "Disconnected" ]]; then
    echo "VPN $FLAG | color=white"
    echo "---"
    echo "Status: $VPN_STATUS"
    echo "Public IP: $PUBLIC_IP"
    echo "City: $CITY"
    echo "Region: $REGION"
    echo "Country: $COUNTRY"
    echo "---"
    echo "Connect $STREISAND_VPN_NAME | bash='$0' param1=connect param2=$STREISAND_VPN_NAME terminal=false refresh=true"
    echo "Configure $STREISAND_VPN_NAME | bash=/usr/bin/open param1=\"/Applications/$STREISAND_VPN_NAME.app\" terminal=false refresh=true"
    echo "---"
    echo "Connect $V2RAYTUN_VPN_NAME | bash='$0' param1=connect param2=$V2RAYTUN_VPN_NAME terminal=false refresh=true"
    echo "Configure $V2RAYTUN_VPN_NAME | bash=/usr/bin/open param1=\"/Applications/$V2RAYTUN_VPN_NAME.app\" terminal=false refresh=true"
elif [[ "$VPN_STATUS" = "Error" ]]; then
    echo "VPN | color=#8B0000"
    echo "---"
    echo "Status: $VPN_STATUS"
    echo "Public IP: $PUBLIC_IP"
    echo "City: $CITY"
    echo "Region: $REGION"
    echo "Country: $COUNTRY"
    echo "---"
    echo "Configure $STREISAND_VPN_NAME | bash=/usr/bin/open param1=\"/Applications/$STREISAND_VPN_NAME.app\" terminal=false refresh=true"
    echo "---"
    echo "Configure $V2RAYTUN_VPN_NAME | bash=/usr/bin/open param1=\"/Applications/$V2RAYTUN_VPN_NAME.app\" terminal=false refresh=true"
else
    echo "VPN | color=#00008B"
    echo "---"
    echo "Status: $VPN_STATUS"
    echo "Public IP: $PUBLIC_IP"
    echo "City: $CITY"
    echo "Region: $REGION"
    echo "Country: $COUNTRY"
    echo "$STREISAND_VPN_NAME"
    echo "---"
    echo "Connect $STREISAND_VPN_NAME | bash='$0' param1=connect param2=$STREISAND_VPN_NAME terminal=false refresh=true"
    echo "Configure $STREISAND_VPN_NAME | bash=/usr/bin/open param1=\"/Applications/$STREISAND_VPN_NAME.app\" terminal=false refresh=true"
    echo "---"
    echo "Connect $V2RAYTUN_VPN_NAME | bash='$0' param1=connect param2=$V2RAYTUN_VPN_NAME terminal=false refresh=true"
    echo "Configure $V2RAYTUN_VPN_NAME | bash=/usr/bin/open param1=\"/Applications/$V2RAYTUN_VPN_NAME.app\" terminal=false refresh=true"
fi
