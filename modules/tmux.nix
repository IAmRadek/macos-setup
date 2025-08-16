{ config, lib, pkgs, ... }:
{
  # Configure tmux
  programs.tmux = {
    enable = true;
    historyLimit = 100000;
    terminal = "screen-256color";
    keyMode = "vi";
    mouse = true;
    escapeTime = 0;
    baseIndex = 1;
    prefix = "C-a";
    shell = "${pkgs.zsh}/bin/zsh";

    extraConfig = ''
      set -ag terminal-overrides ",xterm-256color:RGB"
      setw -g xterm-keys on

      set -g @plugin 'IAmRadek/tmux-k8s-context-switcher'

      KUBE_TMUX_BINARY=${pkgs.kubectl}/bin/kubectl

      # Fix titlebar
      set -g set-titles on
      set -g set-titles-string "#T"

      set -g status-left ""

      # Avoid date/time taking up space
      set -g status-right \'\'
      set -g status-right '#(/bin/bash $HOME/.config/tmux/plugins/kube-tmux/kube.tmux 250 red cyan) #[fg=yellow]%a %Y-%m-%d %H:%M'
      set -g status-right-length 250
      set -g status-right-style default

      # Split current window horizontally
      bind - split-window -v -c "#{pane_current_path}"
      unbind %
      # Split current window vertically
      bind | split-window -h -c "#{pane_current_path}"
      unbind '"'

      bind t new-window \; display "new window opened"
      bind w kill-window

      bind-key r source-file ~/.config/tmux/tmux.conf \; display-message "tmux.conf reloaded"

      # Start numbering panes at 1, not 0.
      set -g pane-base-index 1

      ######################
      ### DESIGN CHANGES ###
      ######################
      set -g status-style "bg=default"
      setw -g window-status-current-style fg=black,bg=white

      set -g window-status-format '#I:#(pwd="#{pane_current_path}"; echo ''${pwd###*/})#F'
      set -g window-status-current-format '#I:#(pwd="#{pane_current_path}"; echo ''${pwd###*/})#F'
      set -g status-interval 10

      unbind-key -T prefix c
      bind-key -T prefix c split-window -p 35 \
        "$SHELL -lc 'navi --path $HOME/.config/navi/cheats --print | tmux load-buffer -b navi_tmp - ; tmux paste-buffer -p -t {last} -b navi_tmp -d ; tmux kill-pane'"

    '';

    # plugins = with pkgs; [
    #   {
    #     plugin = tmuxPlugins.tpm;
    #     extraConfig = "set -g @plugin 'tmux-plugins/tpm'";
    #   }
    #   {
    #     plugin = tmuxPlugins.sensible;
    #     extraConfig = "set -g @plugin 'tmux-plugins/tmux-sensible'";
    #   }
    # ];
  };

  # Install custom tmux plugins
  home.file.".config/tmux/plugins/tmux-k8s-context-switcher".source = pkgs.fetchFromGitHub {
    owner = "IAmRadek";
    repo = "tmux-k8s-context-switcher";
    rev = "main";
    sha256 = "17hl1q0lm6nv1rj9frwbanvb3sa75pmd7hbh79f28q138llpbm22";
  };

  home.file.".config/tmux/plugins/kube-tmux".source = pkgs.fetchFromGitHub {
    owner = "jonmosco";
    repo = "kube-tmux";
    rev = "master";
    sha256 = "0wfsqlcs24jkm1szih0s5g0i17qj8laks0wbd9nnm77q92q77gb7";
  };

}
