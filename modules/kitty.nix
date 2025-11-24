{ config, lib, pkgs, ... }:

let kubeContextPopup = pkgs.writeShellScriptBin "kube-context-popup" ''
  #!${pkgs.bash}/bin/bash
  set -euo pipefail

  # List contexts, pick one with fzf
  ctx="$(${pkgs.kubectl}/bin/kubectl config get-contexts -o name | ${pkgs.fzf}/bin/fzf --prompt='Kubernetes context> ')"

  # If user pressed ESC / no choice
  [ -z "$ctx" ] && exit 0

  ${pkgs.kubectl}/bin/kubectl config use-context "$ctx"

  echo
  echo "Switched to context: $ctx"
  echo
  read -n 1 -s -r -p "Press any key to close..."
'';
in {
  home.file.".config/kitty/navi_select.py".text = ''
    from kitty.boss import Boss
    import subprocess

    NAVI = "${pkgs.navi}/bin/navi"

    def main(args):
        result = subprocess.run([NAVI, "--print"], capture_output=True, text=True)
        if result.returncode != 0:
            return ""
        return result.stdout

    def handle_result(args, answer, target_window_id, boss: Boss):
        text = answer.strip()
        if not text:
            return
        w = boss.window_id_map.get(target_window_id)
        if w is not None:
            w.paste_text(text)
  '';



  home.file.".config/kitty/scroll_mark.py".source =
    pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/trygveaa/kitty-kitten-search/refs/heads/master/scroll_mark.py";
      sha256 = "1a1l7sp2x247da8fr54wwq7ffm987wjal9nw2f38q956v3cfknzi";
    };

  home.file.".config/kitty/search.py".source =
    pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/trygveaa/kitty-kitten-search/refs/heads/master/search.py";
      sha256 = "035y3gwlr9ymb8y5zygv3knn91z1p5blj6gzv5vl2zcyhn7281n9";
    };

  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 14.0;
    };

    settings = {
      # your existing colors
      foreground = "#BBBBBB";
      background = "#2B2B2B";

      color0  = "#000000";
      color1  = "#F0524F";
      color2  = "#5C962C";
      color3  = "#A68A0D";
      color4  = "#3993D4";
      color5  = "#A771BF";
      color6  = "#00A3A3";
      color7  = "#808080";
      color8  = "#595959";
      color9  = "#FF4050";
      color10 = "#4FC414";
      color11 = "#E5BF00";
      color12 = "#1FB0FF";
      color13 = "#ED7EED";
      color14 = "#00E5E5";
      color15 = "#FFFFFF";

      window_padding_width = 10;
      macos_option_as_alt = "both";

      # ── Tab bar: “editor-like” flat style ──────────────────────────────
      tab_bar_style = "powerline";      # flat tabs with a thin separator
      tab_bar_edge = "top";
      tab_bar_min_tabs = 1;
      tab_bar_background = "#202225";   # slightly darker than main bg

      # Active tab: lighter bg, bold text
      active_tab_background = "#2B2B2B";
      active_tab_foreground = "#BBBBBB";
      active_tab_font_style = "bold";

      # Inactive tabs: flat, low-contrast text
      inactive_tab_background = "#202225";
      inactive_tab_foreground = "#9A9A9A";
      inactive_tab_font_style = "normal";

      # Small separator between tabs (looks like thin borders)
      tab_separator = "  ";
      tab_title_template = "{index}:{title}";
    };

    keybindings = {
      # word jumps
      "alt+right" = "send_text all \\x1bF";
      "alt+left"  = "send_text all \\x1bB";

      "cmd+f" = "launch --location=hsplit --allow-remote-control kitty +kitten search.py @active-kitty-window-id";

      "ctrl+s>c" = "kitten navi_select.py";
      "ctrl+s>g" = "launch --type=overlay --cwd=current --keep-focus ${kubeContextPopup}/bin/kube-context-popup";

      # direct tab jumps
      "ctrl+s>1" = "goto_tab 1";
      "ctrl+s>2" = "goto_tab 2";
      "ctrl+s>3" = "goto_tab 3";
      "ctrl+s>4" = "goto_tab 4";
      "ctrl+s>5" = "goto_tab 5";
      "ctrl+s>6" = "goto_tab 6";
      "ctrl+s>7" = "goto_tab 7";
      "ctrl+s>8" = "goto_tab 8";
      "ctrl+s>9" = "goto_tab 9";

      "cmd+right" = "next_tab";
      "cmd+left"  = "previous_tab";

      "ctrl+s>n" = "set_tab_title";

      # C-a -  -> split with a horizontal line (top/bottom), like: tmux split-window -v
      "ctrl+s>-" = "launch --location=hsplit --cwd=current";

      # C-a |  -> split with a vertical line (left/right), like: tmux split-window -h
      "ctrl+s>\\" = "launch --location=vsplit --cwd=current";

      # C-a t  -> new tmux window  ≈ new kitty *tab*
      "ctrl+s>t" = "launch --type=tab --cwd=current";

      # C-a w  -> kill-window  ≈ close current tab
      "ctrl+s>w" = "close_tab";

      # (optional) C-a q -> close current split (kitty window)
      "ctrl+s>q" = "close_window";

      # C-a r  -> reload kitty.conf (like your tmux `source-file` binding)
      "ctrl+s>r" = "load_config_file";

      # --- Optional: tmux-like pane navigation with hjkl ---

      # C-a h/j/k/l to move between splits
      "ctrl+s>h" = "neighboring_window left";
      "ctrl+s>j" = "neighboring_window down";
      "ctrl+s>k" = "neighboring_window up";
      "ctrl+s>l" = "neighboring_window right";

      # C-a H/J/K/L to resize splits
      "ctrl+s>H" = "resize_window narrower 3";
      "ctrl+s>L" = "resize_window wider 3";
      "ctrl+s>J" = "resize_window taller 3";
      "ctrl+s>K" = "resize_window shorter 3";
    };
  };
}
