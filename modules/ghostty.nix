{ ... }:
{
  programs.ghostty = {
    enable = true;
    package = null;
    enableZshIntegration = true;

    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 12;
      font-thicken = true;

      term = "xterm-256color";

      background = "2B2B2B";
      foreground = "BBBBBB";

      cursor-color = "BBBBBB";
      cursor-text = "2B2B2B";

      selection-background = "245980";

      palette = [
        "0=#000000"
        "1=#F0524F"
        "2=#5C962C"
        "3=#A68A0D"
        "4=#3993D4"
        "5=#A771BF"
        "6=#00A3A3"
        "7=#808080"
        "8=#595959"
        "9=#FF4050"
        "10=#4FC414"
        "11=#E5BF00"
        "12=#1FB0FF"
        "13=#ED7EED"
        "14=#00E5E5"
        "15=#FFFFFF"
      ];

      macos-option-as-alt = true;
      mouse-shift-capture = "always";

      window-padding-x = 10;
      window-padding-y = 10;
      window-padding-balance = true;

      keybind = [
        "alt+right=text:\\x1bf"
        "alt+left=text:\\x1bb"
        "super+right=text:\\x05"
        "super+left=text:\\x01"
        "super+n=text:\\x0e"
        "super+p=text:\\x10"
        "super+s=text:\\x13"
        "super+z=text:\\x1a"
        "super+y=text:\\x19"
        "super+x=text:\\x18"
        "super+a=text:\\x01"
        "super+f=text:\\x06"
        "ctrl+backspace=text:\\x17"
        "super+backspace=text:\\x17"
        "ctrl+delete=text:\\x1b[3;5~"
        "super+delete=text:\\x17"
      ];
    };
  };
}
