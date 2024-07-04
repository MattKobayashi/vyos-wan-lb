#!/usr/bin/vbash
# This script goes into /config/scripts/wan-lb-v4.sh

source /opt/vyatta/etc/functions/script-template

logger "Running task wan-lb-v4..."

# User configuration
interfaces_lb='eth1 eth2' # Load-balanced interfaces
interfaces_fo='eth3' # Failover interfaces

table=0

# Load balanced interfaces
for interface in $interfaces_lb
do
    logger "Interface: $interface"
    
    table=$[ table + 1 ]
    logger "Interface table: $table"

    if [[ $interface == "pppoe"* ]]; then
        gw=$(run show ip route | egrep $interface | egrep '\/32' | awk -F "[/, ]+" -v interface=$interface '$0 ~ interface {print $2}')
    else
        gw=$(run show ip route | egrep $interface | awk -F "[, ]+" -v interface=$interface '$0 ~ interface {print $5}' | sed --regexp-extended '/^(connected|directly)$/d')
    fi
    logger "Interface gateway IP: $gw"

    gw_mac=$(sudo /usr/bin/arping -I $interface -c 1 $gw | egrep -o "([0-9a-fA-F]{2}:{0,1}){6}")
    logger "Interface gateway MAC: $gw_mac"

    if [[ -z $gw ]]; then
        alive="0"
    elif [[ $interface == "pppoe"* ]]; then
        if [[ $(show interfaces pppoe $interface | awk -F "[, ]+" -v interface=$interface '$0 ~ interface { print $5 }' | head -n 1) == "UP" ]]; then
            alive="1"
        fi
    else
        alive=$(nping --tcp --dest-port 80 --dest-mac $gw_mac --interface $interface --count 1 1.1.1.1 | awk '/Rcvd/ {print $8}')
    fi

    if [[ $alive = "1" ]]; then
        if [[ $gw != $(cat /tmp/v4_gw_$interface) ]]; then
            vtysh_cmd="vtysh -c \"configure terminal\" -c \"no ip route 0.0.0.0/0 $(cat /tmp/v4_gw_$interface) $interface 150\""
            vtysh_cmd+=" -c \"no ip route 0.0.0.0/0 $(cat /tmp/v4_gw_$interface) $interface 150 table $table\""
            logger "Sending command: $vtysh_cmd"
            echo -e $vtysh_cmd | /usr/bin/vbash
        fi
        vtysh_cmd="vtysh -c \"configure terminal\" -c \"ip route 0.0.0.0/0 $gw $interface 150\""
        vtysh_cmd+=" -c \"ip route 0.0.0.0/0 $gw $interface 150 table $table\""
        logger "Sending command: $vtysh_cmd"
        echo -e $vtysh_cmd | /usr/bin/vbash
        echo $gw > /tmp/v4_gw_$interface
    fi

    if [[ $alive = "0" ]]; then
        if [[ -f /tmp/v4_gw_$interface ]]; then
            vtysh_cmd="vtysh -c \"configure terminal\" -c \"no ip route 0.0.0.0/0 $(cat /tmp/v4_gw_$interface) $interface 150\""
            vtysh_cmd+=" -c \"no ip route 0.0.0.0/0 $(cat /tmp/v4_gw_$interface) $interface 150 table $table\""
            logger "Sending command: $vtysh_cmd"
            echo -e $vtysh_cmd | /usr/bin/vbash
            rm /tmp/v4_gw_$interface
        fi
    fi
done

# Failover interfaces
for interface in $interfaces_fo
do
    logger "Interface: $interface"
    table=$[ table + 1 ]
    logger "Interface table: $table"

    if [[ $interface == "pppoe"* ]]; then
        gw=$(run show ip route | egrep $interface | egrep '\/32' | awk -F "[/, ]+" -v interface=$interface '$0 ~ interface {print $2}')
    else
        gw=$(run show ip route | egrep $interface | awk -F "[, ]+" -v interface=$interface '$0 ~ interface {print $5}' | sed --regexp-extended '/^(connected|directly)$/d')
    fi
    logger "Interface gateway IP: $gw"

    gw_mac=$(sudo /usr/bin/arping -I $interface -c 1 $gw | egrep -o "([0-9a-fA-F]{2}:{0,1}){6}")
    logger "Interface gateway MAC: $gw_mac"

    if [[ -z $gw ]]; then
        alive="0"
    elif [[ $interface == "pppoe"* ]]; then
        if [[ $(show interfaces pppoe $interface | awk -F "[, ]+" -v interface=$interface '$0 ~ interface { print $5 }' | head -n 1) == "UP" ]]; then
            alive="1"
        fi
    else
        alive=$(nping --tcp --dest-port 80 --dest-mac $gw_mac --interface $interface --count 1 1.1.1.1 | awk '/Rcvd/ {print $8}')
    fi

    if [[ $alive = "1" ]]; then
        if [ $gw != $(cat /tmp/v4_gw_$interface) ]; then
            vtysh_cmd="vtysh -c \"configure terminal\" -c \"no ip route 0.0.0.0/0 $(cat /tmp/v4_gw_$interface) $interface 200\""
            vtysh_cmd+=" -c \"no ip route 0.0.0.0/0 $(cat /tmp/v4_gw_$interface) $interface 200 table $table\""
            logger "Sending command: $vtysh_cmd"
            echo -e $vtysh_cmd | /usr/bin/vbash
        fi
        vtysh_cmd="vtysh -c \"configure terminal\" -c \"ip route 0.0.0.0/0 $gw $interface 200\""
        vtysh_cmd+=" -c \"ip route 0.0.0.0/0 $gw $interface 200 table $table\""
        logger "Sending command: $vtysh_cmd"
        echo -e $vtysh_cmd | /usr/bin/vbash
        echo $gw > /tmp/v4_gw_$interface
    fi

    if [[ $alive = "0" ]]; then
        if [[ -f /tmp/v4_gw_$interface ]]; then
            vtysh_cmd="vtysh -c \"configure terminal\" -c \"no ip route 0.0.0.0/0 $(cat /tmp/v4_gw_$interface) $interface 200\""
            vtysh_cmd+=" -c \"no ip route 0.0.0.0/0 $(cat /tmp/v4_gw_$interface) $interface 200 table $table\""
            logger "Sending command: $vtysh_cmd"
            echo -e $vtysh_cmd | /usr/bin/vbash
            rm /tmp/v4_gw_$interface
        fi
    fi
done

exit
