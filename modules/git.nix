{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;
  hooksDir = "${config.xdg.configHome}/git/hooks";
in
{

  xdg.configFile."git/hooks" = {
    source = ../githooks;    # directory in your repo
    recursive = true;       # copy all files/subdirs
  };
  xdg.configFile."git/.gitignore".source = ../_gitignore;

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
        "calochortus-lyallii" = {
          "commit-decoration-style" = "none";
          "dark" = "true";
          "file-added-label" = "[+]";
          "file-copied-label" = "[C]";
          "file-decoration-style" = "none";
          "file-modified-label" = "[M]";
          "file-removed-label" = "[-]";
          "file-renamed-label" = "[R]";
          "file-style" = "232 bold 184";
          "hunk-header-decoration-style" = "none";
          "hunk-header-file-style" = "#999999";
          "hunk-header-line-number-style" = "bold #03a4ff";
          "hunk-header-style" = "file line-number syntax";
          "line-numbers" = "true";
          "line-numbers-left-style" = "black";
          "line-numbers-minus-style" = "#B10036";
          "line-numbers-plus-style" = "#03a4ff";
          "line-numbers-right-style" = "black";
          "line-numbers-zero-style" = "#999999";
          "minus-emph-style" = "syntax bold #780000";
          "minus-style" = "syntax #400000";
          "plus-emph-style" = "syntax bold #007800";
          "plus-style" = "syntax #004000";
          "whitespace-error-style" = "#280050 reverse";
          "zero-style" = "syntax";
          "syntax-theme" = "Nord";
        };
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
      gpg = {
        "ssh" = {
          program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
          allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
        };
      };

      commit.gpgsign = true;

      core = {
        excludesFile = "${config.xdg.configHome}/git/.gitignore";
        editor = "nano";
        pager  = "${pkgs.delta}/bin/delta";
        hooksPath = "${hooksDir}";
      };

      pull.rebase = false;

      color = {
        ui = true;

        branch = {
          current = "yellow reverse";
          local   = "yellow";
          remote  = "green";
        };

        diff = {
          meta      = "yellow bold";
          frag      = "magenta bold";
          old       = "red bold";
          new       = "green bold";
        };

        status = {
          added    = "yellow";
          changed  = "green";
          untracked= "cyan";
        };
      };

      interactive.diffFilter = "${pkgs.delta}/bin/delta --color-only";

      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";

      push = {
        default = "current";
        autoSetupRemote = true;
      };

      # GitHub/Gist credential helpers (use Nix gh path)
      credential = {
        "https://github.com".helper = [
          ""  # clear existing helpers
          "!${pkgs.gh}/bin/gh auth git-credential"
        ];
        "https://gist.github.com".helper = [
          ""
          "!${pkgs.gh}/bin/gh auth git-credential"
        ];
      };
    };
  };
}
