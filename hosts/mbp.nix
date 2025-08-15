{ pkgs, ... }:

let
  username = "rd";
in
{
  system.primaryUser = username;
  # TODO https://github.com/LnL7/nix-darwin/issues/682
  users.users.${username}.home = "/Users/${username}";

  homebrew = {
    # casks = [
    # ];
    # masApps = {
    # };
  };

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    users.${username} = { pkgs, lib, config, ... }: {
      home.stateVersion = "22.11";
      programs.home-manager.enable = true;

      programs.ssh = {
        enable = true;
        extraConfig = ''
          IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        '';
      };

      programs.alacritty = {
        enable = true;

        settings = {
          # "debug.render_timer" = false;
          # window_opacity = 1;

          colors = {
            bright = {
              black = "0x595959";
              blue = "0x1FB0FF";
              cyan = "0x00E5E5";
              green = "0x4FC414";
              magenta = "0xED7EED";
              red = "0xFF4050";
              white = "0xFFFFFF";
              yellow = "0xE5BF00";
            };

            cursor = {
              cursor = "CellForeground";
              text = "CellBackground";
            };

            footer_bar = {
              background = "0x282a36";
              foreground = "0xf8f8f2";
            };

            line_indicator = {
              background = "None";
              foreground = "None";
            };

            normal = {
              black = "0x000000";
              blue = "0x3993D4";
              cyan = "0x00A3A3";
              green = "0x5C962C";
              magenta = "0xA771BF";
              red = "0xF0524F";
              white = "0x808080";
              yellow = "0xA68A0D";
            };

            primary = {
              background = "0x2B2B2B";
              foreground = "0xBBBBBB";
            };

            search = {
              focused_match = {
                background = "0xffb86c";
                foreground = "0x245980";
              };
              matches = {
                background = "0x50fa7b";
                foreground = "0x44475a";
              };
            };

            selection = {
              background = "0x245980";
              text = "CellForeground";
            };
          };

          env = {
            TERM = "xterm-256color";
          };

          font = {
            size = 12.0;
            normal = {
              family = "JetBrainsMono Nerd Font";
              style = "Regular";
            };
            bold = {
              family = "JetBrainsMono Nerd Font";
              style = "Bold";
            };
            italic = {
              family = "JetBrainsMono Nerd Font";
              style = "Italic";
            };
          };

          keyboard.bindings = [
            {
              key = "Right";
              mods = "Alt";
              chars = "\\u001BF";
            }
            {
              key = "Left";
              mods = "Alt";
              chars = "\\u001BB";
            }
          ];

          window = {
            dynamic_padding = true;
            padding = {
              x = 10;
              y = 10;
            };
          };

          shell = {
            program = "${pkgs.tmux}/bin/tmux";
            args = [
              "new"
              "-A"
              "-s main"
              "-f"
              "${config.xdg.configHome}/tmux/tmux.conf"
            ];
          };
        };
      };

    };
  };
}
