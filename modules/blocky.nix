{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.blocky ];

  environment.etc."blocky/config.yml".text = ''
    upstreams:
      groups:
        default:
          - 1.1.1.1
          - 1.0.0.1
          - 9.9.9.9
          - 149.112.112.112

    ports:
      dns: 127.0.0.1:53

    blocking:
      denylists:
        ads:
          - https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
      clientGroupsBlock:
        default:
          - ads

    caching:
      minTime: 5m
      maxTime: 30m

    log:
      level: info
  '';

  launchd.daemons.blocky = {
    serviceConfig = {
      Label = "com.blocky.dns";
      ProgramArguments = [
        "${pkgs.blocky}/bin/blocky"
        "--config"
        "/etc/blocky/config.yml"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/blocky.log";
      StandardErrorPath = "/var/log/blocky-error.log";
    };
  };

  system.activationScripts.configureBlockyDns.text = ''
    /usr/sbin/networksetup -listallnetworkservices 2>/dev/null \
      | /usr/bin/tail -n +2 \
      | while IFS= read -r service; do
          case "$service" in
            ""|\**)
              continue
              ;;
          esac

          /usr/sbin/networksetup -setdnsservers "$service" 127.0.0.1 2>/dev/null || true
        done
  '';
}
