# vyos-wan-lb
VyOS WAN Load Balancing Script

## Methodology for IPv4

1. Retrieve the default gateway IP address.
2. Retrieve the default gateway MAC address.
3. If the gateway IP cannot be retrieved, mark the interface as dead.
4. (IPv4 only) If the interface is PPPoE and it is up according to `show interface pppoe $interface`, mark the interface as alive.
5. If the interface is not PPPoE and a TCP port 80 ping to 1.1.1.1 using the detected default gateway MAC address succeeds, mark the interface as alive.
6. If the interface is alive and the default gateway IP has changed, remove any static routes with the default gateway IP recorded in `/tmp/v4_gw_$interface`, install a new static route to the main table and the interface table with an interface-specific metric, and record the current default gateway IP in `/tmp/v4_gw_$interface`.
7. If the interface is alive and the default gateway IP has not changed, overwrite a new static route to the main table and the interface table with an interface-specific metric, and record the current default gateway IP in `/tmp/v4_gw_$interface`.
8. If the interface is dead, remove any static routes with the default gateway IP recorded in `/tmp/v4_gw_$interface`.

Metrics used:

- Load-balanced interfaces: 150
- Failover interfaces: 200

## Installation

- Add the `wan-lb-v4.sh` and `wan-lb-v6.sh` scripts to `/config/scripts` on your VyOS router.
- Edit the configuration in `vyos-config.conf` to suit your requirements, then apply to your VyOS router.