#compdef iwctl

# iwctl completion for zsh
# Güncellenmiş komut listesi ve doğru komut yapısı

_iwctl() {
    local curcontext="$curcontext" state line ret=1
    local -a commands station_commands device_commands network_commands known_commands

    # Ana komutlar (güncellenmiş liste)
    commands=(
        'station:Manage network stations (wlan interfaces)'
        'device:Show and manage wireless devices'
        'known-networks:Show and manage known network connections'
        'version:Display version information'
        'help:Show help information'
    )

    # Station alt komutları
    station_commands=(
        'list:List all WiFi stations'
        'show:Show details about a specific station'
        'connect:Connect to a network <network_name>'
        'disconnect:Disconnect from current network'
        'get-networks:List all available networks'
        'scan:Trigger a network scan'
    )

    # Device alt komutları
    device_commands=(
        'list:List all wireless devices'
        'show:Show device details'
    )

    # Known networks alt komutları
    known_commands=(
        'list:List all known networks'
        'forget:Remove a known network'
    )

    _arguments -C \
        '1: :->cmds' \
        '*:: :->args' && ret=0

    case "$state" in
        cmds)
            _describe -t commands 'iwctl commands' commands && ret=0
            ;;
        args)
            case $words[1] in
                station)
                    if (( CURRENT == 2 )); then
                        _describe -t station_commands 'station commands' station_commands && ret=0
                    else
                        case $words[2] in
                            connect)
                                # Mevcut ağları listele
                                local -a networks
                                networks=( ${(f)"$(iwctl station list 2>/dev/null | awk '/^ +[^ ]/ {print $1}')"} )
                                _describe -t networks 'networks' networks && ret=0
                                ;;
                            show|disconnect)
                                # Mevcut istasyonları listele
                                local -a stations
                                stations=( ${(f)"$(iwctl device list 2>/dev/null | awk '/^ +[^ ]/ {print $1}')"} )
                                _describe -t stations 'stations' stations && ret=0
                                ;;
                        esac
                    fi
                    ;;
                device)
                    if (( CURRENT == 2 )); then
                        _describe -t device_commands 'device commands' device_commands && ret=0
                    else
                        # Mevcut cihazları listele
                        local -a devices
                        devices=( ${(f)"$(iwctl device list 2>/dev/null | awk '/^ +[^ ]/ {print $1}')"} )
                        _describe -t devices 'devices' devices && ret=0
                    fi
                    ;;
                known-networks)
                    if (( CURRENT == 2 )); then
                        _describe -t known_commands 'known network commands' known_commands && ret=0
                    else
                        case $words[2] in
                            forget)
                                # Bilinen ağları listele
                                local -a known_networks
                                known_networks=( ${(f)"$(iwctl known-networks list 2>/dev/null | awk '/^ +[^ ]/ {print $1}')"} )
                                _describe -t known_networks 'known networks' known_networks && ret=0
                                ;;
                        esac
                    fi
                    ;;
                help)
                    _describe -t commands 'iwctl commands' commands && ret=0
                    ;;
            esac
            ;;
    esac

    return ret
}

compdef _iwctl iwctl
