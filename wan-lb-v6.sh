#!/usr/bin/vbash
# This script goes into /config/scripts/wan-lb-v6.sh

source /opt/vyatta/etc/functions/script-template

logger "Running task wan-lb-v6..."

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

    src=$(run show interfaces ethernet $interface | awk '/inet6.*scope global/ {print $2}' | awk '{ split($0, arr, "/"); print arr[1]; }')
    src_mac=$(run show interfaces ethernet $interface | awk '/ether/ {print $2}')
    gw=$(run force ipv6-rd interface $interface | awk '/from/ {print $2}')
    logger "Interface gateway IP: $gw"
    gw_mac=$(run force ipv6-rd interface $interface | awk '/link-layer/ {print $4}')
    logger "Interface gateway MAC: $gw_mac"

    if [ -z $gw ]; then
        alive="0"
    else
        alive=$(nping --tcp --dest-port 80 --source-mac $src_mac --dest-mac $gw_mac --ipv6 --source-ip $src --interface $interface --count 1 2606:4700:4700::1111 | awk '/Rcvd/ {print $8}')
    fi

    if [ $alive = "1" ]; then
        if [ $gw != $(cat /tmp/v6_gw_$interface) ]; then
            vtysh_cmd="vtysh -c \"configure terminal\" -c \"no ipv6 route ::/0 $(cat /tmp/v6_gw_$interface) $interface 150\""
            vtysh_cmd+=" -c \"no ipv6 route ::/0 $(cat /tmp/v6_gw_$interface) $interface 150 table ${interface#*eth}\""
            logger "Sending command: $vtysh_cmd"
            echo -e $vtysh_cmd | /usr/bin/vbash
        fi
        vtysh_cmd="vtysh -c \"configure terminal\" -c \"ipv6 route ::/0 $gw $interface 150\""
        vtysh_cmd+=" -c \"ipv6 route ::/0 $gw $interface 150 table ${interface#*eth}\""
        logger "Sending command: $vtysh_cmd"
        echo -e $vtysh_cmd | /usr/bin/vbash
        echo $gw > /tmp/v6_gw_$interface
    fi

    if [ $alive = "0" ]; then
        if [ -f /tmp/v6_gw_$interface ]; then
            vtysh_cmd="vtysh -c \"configure terminal\" -c \"no ipv6 route ::/0 $(cat /tmp/v6_gw_$interface) $interface 150\""
            vtysh_cmd+=" -c \"no ipv6 route ::/0 $(cat /tmp/v6_gw_$interface) $interface 150 table ${interface#*eth}\""
            logger "Sending command: $vtysh_cmd"
            echo -e $vtysh_cmd | /usr/bin/vbash
            rm /tmp/v6_gw_$interface
        fi
    fi
done

# Failover interfaces
for interface in $interfaces_fo
do
    logger "Interface: $interface"

    table=$[ table + 1 ]
    logger "Interface table: $table"

    src=$(run show interfaces ethernet $interface | awk '/inet6.*scope global/ {print $2}' | awk '{ split($0, arr, "/"); print arr[1]; }')
    src_mac=$(run show interfaces ethernet $interface | awk '/ether/ {print $2}')
    gw=$(run force ipv6-rd interface $interface | awk '/from/ {print $2}')
    logger "Interface gateway IP: $gw"
    gw_mac=$(run force ipv6-rd interface $interface | awk '/link-layer/ {print $4}')
    logger "Interface gateway MAC: $gw_mac"

    if [ -z $gw ]; then
        alive="0"
    else
        alive=$(nping --tcp --dest-port 80 --source-mac $src_mac --dest-mac $gw_mac --ipv6 --source-ip $src --interface $interface --count 1 2606:4700:4700::1111 | awk '/Rcvd/ {print $8}')
    fi

    if [ $alive = "1" ]; then
        if [ $gw != $(cat /tmp/v6_gw_$interface) ]; then
            vtysh_cmd="vtysh -c \"configure terminal\" -c \"no ipv6 route ::/0 $(cat /tmp/v6_gw_$interface) $interface 200\""
            vtysh_cmd+=" -c \"no ipv6 route ::/0 $(cat /tmp/v6_gw_$interface) $interface 200 table ${interface#*eth}\""
            logger "Sending command: $vtysh_cmd"
            echo -e $vtysh_cmd | /usr/bin/vbash
        fi
        vtysh_cmd="vtysh -c \"configure terminal\" -c \"ipv6 route ::/0 $gw $interface 200\""
        vtysh_cmd+=" -c \"ipv6 route ::/0 $gw $interface 200 table ${interface#*eth}\""
        logger "Sending command: $vtysh_cmd"
        echo -e $vtysh_cmd | /usr/bin/vbash
        echo $gw > /tmp/v6_gw_$interface
    fi

    if [ $alive = "0" ]; then
        if [ -f /tmp/v6_gw_$interface ]; then
            vtysh_cmd="vtysh -c \"configure terminal\" -c \"no ipv6 route ::/0 $(cat /tmp/v6_gw_$interface) $interface 200\""
            vtysh_cmd+=" -c \"no ipv6 route ::/0 $(cat /tmp/v6_gw_$interface) $interface 200 table ${interface#*eth}\""
            logger "Sending command: $vtysh_cmd"
            echo -e $vtysh_cmd | /usr/bin/vbash
            rm /tmp/v6_gw_$interface
        fi
    fi
done

exit
