{ config, lib, pkgs, ... }:
{

  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12.0;
    };

    settings = {
      # Primary colors (Alacritty.primary)
      foreground = "#BBBBBB";
      background = "#2B2B2B";

      # Cursor (rough equivalent of CellForeground/CellBackground)
      cursor = "foreground";
      cursor_text_color = "background";

      # Selection (Alacritty.selection)
      selection_background = "#245980";
      selection_foreground = "foreground";

      # Normal colors (Alacritty.normal)
      color0  = "#000000"; # black
      color1  = "#F0524F"; # red
      color2  = "#5C962C"; # green
      color3  = "#A68A0D"; # yellow
      color4  = "#3993D4"; # blue
      color5  = "#A771BF"; # magenta
      color6  = "#00A3A3"; # cyan
      color7  = "#808080"; # white

      # Bright colors (Alacritty.bright)
      color8  = "#595959"; # bright black
      color9  = "#FF4050"; # bright red
      color10 = "#4FC414"; # bright green
      color11 = "#E5BF00"; # bright yellow
      color12 = "#1FB0FF"; # bright blue
      color13 = "#ED7EED"; # bright magenta
      color14 = "#00E5E5"; # bright cyan
      color15 = "#FFFFFF"; # bright white

      # Window padding (Alacritty.window.padding)
      window_padding_width = 10;

      # macOS: make Option behave as Alt, so your Alt bindings work
      macos_option_as_alt = "both";
    };

    # Keybindings – equivalent of your Alacritty Alt+←/→ word jumps
    # Alacritty chars: \u001BF / \u001BB == ESC F / ESC B
    keybindings = {
      "alt+right" = "send_text all \\x1bF";
      "alt+left"  = "send_text all \\x1bB";
    };

    # If you *really* want to override TERM (not recommended), you could do:
    # environment = { TERM = "xterm-256color"; };
    # but kitty normally sets TERM=xterm-kitty which is what most tools expect.
  };

}
