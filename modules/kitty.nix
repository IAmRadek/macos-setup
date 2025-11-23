{ config, lib, pkgs, ... }:
{
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 13.0;
    };

    keybindings = {
      "cmd+1" = "goto_tab 1";
      "cmd+2" = "goto_tab 2";
      "cmd+3" = "goto_tab 3";
      "cmd+4" = "goto_tab 4";
      "cmd+5" = "goto_tab 5";
      "cmd+6" = "goto_tab 6";
      "cmd+7" = "goto_tab 7";
      "cmd+8" = "goto_tab 8";
      "cmd+9" = "goto_tab 9";
    };

    settings = {
      ## Primary colors
      foreground = "#BBBBBB";
      background = "#2B2B2B";

      ## Cursor
      # Default cursor color = foreground → no need to set
      cursor_text_color = "background";

      ## Selection
      selection_background = "#245980";
      # selection_foreground = "inherit"   # optional, but default is fine

      ## Normal colors
      color0  = "#000000";
      color1  = "#F0524F";
      color2  = "#5C962C";
      color3  = "#A68A0D";
      color4  = "#3993D4";
      color5  = "#A771BF";
      color6  = "#00A3A3";
      color7  = "#808080";

      ## Bright colors
      color8  = "#595959";
      color9  = "#FF4050";
      color10 = "#4FC414";
      color11 = "#E5BF00";
      color12 = "#1FB0FF";
      color13 = "#ED7EED";
      color14 = "#00E5E5";
      color15 = "#FFFFFF";

      ## Padding
      window_padding_width = 10;

      ## macOS alt behavior
      macos_option_as_alt = "both";


      # --- Basic tab bar behaviour ---
      tab_bar_style = "powerline";   # or: fade, separator, slant, hidden
      tab_bar_edge = "top";          # top | bottom
      tab_bar_min_tabs = 1;          # show even with a single tab
      tab_title_template = "{index}: {title}"; # how titles are rendered

      # --- Colors for tabs (adapted to your theme) ---
      # Active tab
      active_tab_foreground = "#2B2B2B";  # text
      active_tab_background = "#BBBBBB";  # bg
      active_tab_font_style = "bold";     # normal | bold | italic | bold-italic

      # Inactive tabs
      inactive_tab_foreground = "#BBBBBB";
      inactive_tab_background = "#245980";
      inactive_tab_font_style = "normal";

      # Optional: separator between tabs (for some styles)
      tab_separator = " │ ";
    };

    ## Keybindings for word jumps (Alt + arrows)
    keybindings = {
      "alt+right" = "send_text all \\x1bF";
      "alt+left"  = "send_text all \\x1bB";
    };
  };
}
