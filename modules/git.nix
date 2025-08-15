{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;
  hooksDir = "${config.xdg.configHome}/git/hooks";
in
{

  xdg.configFile."git/hooks" = {
    source = ./githooks;    # directory in your repo
    recursive = true;       # copy all files/subdirs
  };
  xdg.configFile."git/.gitignore".source = ./_gitignore;

  programs.git = {
    enable = true;

    userName  = "Radosław Dejnek";
    userEmail = "radek@dejnek.pl";

    # SSH signing via 1Password
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIYnDm9RfWWUdae/MTzZps0KDhlDrDdWIrFFfoeWWulD";
      signByDefault = true;
    };

    # First-class options
    delta = {
      enable = true;
      options = {
        navigate = true;               # n / N to jump hunks
        "side-by-side" = true;
        features = "calochortus-lyallii";
        dark = true;
        "map-styles" = "bold purple => syntax magenta, bold cyan => syntax blue";
        # Feature block below
        "calochortus-lyallii.commit-decoration-style" = "none";
        "calochortus-lyallii.dark" = "true";
        "calochortus-lyallii.file-added-label" = "[+]";
        "calochortus-lyallii.file-copied-label" = "[C]";
        "calochortus-lyallii.file-decoration-style" = "none";
        "calochortus-lyallii.file-modified-label" = "[M]";
        "calochortus-lyallii.file-removed-label" = "[-]";
        "calochortus-lyallii.file-renamed-label" = "[R]";
        "calochortus-lyallii.file-style" = "232 bold 184";
        "calochortus-lyallii.hunk-header-decoration-style" = "none";
        "calochortus-lyallii.hunk-header-file-style" = "#999999";
        "calochortus-lyallii.hunk-header-line-number-style" = "bold #03a4ff";
        "calochortus-lyallii.hunk-header-style" = "file line-number syntax";
        "calochortus-lyallii.line-numbers" = "true";
        "calochortus-lyallii.line-numbers-left-style" = "black";
        "calochortus-lyallii.line-numbers-minus-style" = "#B10036";
        "calochortus-lyallii.line-numbers-plus-style" = "#03a4ff";
        "calochortus-lyallii.line-numbers-right-style" = "black";
        "calochortus-lyallii.line-numbers-zero-style" = "#999999";
        "calochortus-lyallii.minus-emph-style" = "syntax bold #780000";
        "calochortus-lyallii.minus-style" = "syntax #400000";
        "calochortus-lyallii.plus-emph-style" = "syntax bold #007800";
        "calochortus-lyallii.plus-style" = "syntax #004000";
        "calochortus-lyallii.whitespace-error-style" = "#280050 reverse";
        "calochortus-lyallii.zero-style" = "syntax";
        "calochortus-lyallii.syntax-theme" = "Nord";
      };
    };

    lfs.enable = true;  # replaces the manual [filter "lfs"] block

    aliases = {
      st = "status";
    };

    # Everything else via extraConfig (mirrors your gitconfig)
    extraConfig = {
      url."ssh://git@github.com".insteadOf = "https://github.com";

      gpg.format = "ssh";
      'gpg "ssh"' = {
        program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        allowedSignersFile = "${home}/.config/git/allowed_signers";
      };

      commit.gpgsign = true;

      core = {
        excludesFile = "${config.xdg.configHome}/git/.gitignore";
        editor = "nano";
        pager  = "delta";
        hooksPath = {hooksPath}
      };

      pull.rebase = false;

      color = {
        ui = true;
        "branch.current" = "yellow reverse";
        "branch.local"   = "yellow";
        "branch.remote"  = "green";
        "diff.meta"      = "yellow bold";
        "diff.frag"      = "magenta bold";
        "diff.old"       = "red bold";
        "diff.new"       = "green bold";
        "status.added"    = "yellow";
        "status.changed"  = "green";
        "status.untracked"= "cyan";
      };

      interactive.diffFilter = "delta --color-only";

      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";

      push = {
        default = "current";
        autoSetupRemote = true;
      };

      # GitHub/Gist credential helpers (use Nix gh path)
      'credential "https://github.com"'.helper = [
        ""  # clear existing helpers
        "!${pkgs.gh}/bin/gh auth git-credential"
      ];
      'credential "https://gist.github.com"'.helper = [
        ""
        "!${pkgs.gh}/bin/gh auth git-credential"
      ];
    };
  };

  # Make sure delta and gh are installed
  home.packages = with pkgs; [ gitAndTools.delta gh ];
}
