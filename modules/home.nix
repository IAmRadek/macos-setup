{ config, pkgs, ... }:
let
  sshAgentSocket = "${config.home.homeDirectory}/.ssh/proton-pass-ssh-agent.sock";
in
{
  home.stateVersion = "22.11";
  programs.home-manager.enable = true;

  # SSH keys come from the "SSH" vault in Proton Pass; needs `pass-cli login`
  home.sessionVariables.SSH_AUTH_SOCK = sshAgentSocket;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      identityAgent = ''"${sshAgentSocket}"'';
    };
    extraConfig = ''
      Include ~/.nix-darwin/private/ssh.private
    '';
  };

  launchd.agents.proton-pass-ssh-agent = {
    enable = true;
    config = {
      Label = "com.protonpass.ssh-agent";
      ProgramArguments = [
        "${pkgs.proton-pass-cli}/bin/pass-cli"
        "ssh-agent"
        "start"
        "--vault-name"
        "SSH"
        "--socket-path"
        sshAgentSocket
      ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  imports = [
    ./alacritty.nix
    ./zsh.nix
    ./tmux.nix
    ./nvim.nix
    ./git.nix
    ./tools.nix
    ./claude.nix
    ./codex.nix
    ./zed.nix
    ./aichat.nix
    # LLM stack
    ./ollama.nix
  ];

  # Configure nano with xdg.configFile
  xdg.configFile."nano/nanorc".text = ''
    # Display line numbers
    set linenumbers

    # Use auto-indentation
    set autoindent

    # Display cursor position in the status bar
    set constantshow

    # Enable mouse support
    set mouse

    # Don't wrap text at the end of the line
    set nowrap

    # Syntax highlighting
    include "${pkgs.nano}/share/nano/*.nanorc"
  '';
}
