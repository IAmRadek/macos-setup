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
  xdg.configFile."git/ignore".text = ''
    .idea
    .DS_Store
    .gitsecret/keys/random_seed
    !*.secret
    .ssh/id_IAmRadek
    .ssh/id_IAmRadek.pub
    .ssh/id_ingrid
    .ssh/id_ingrid.pub
    .ssh/environment-rd
    .ssh/known_hosts
    CRUSH.md
  '';

  xdg.configFile."git/attributes".text = ''
    * merge=mergiraf
  '';

  programs.git = {
    enable = true;

    userName  = "Radosław Dejnek";
    userEmail = "radek@dejnek.pl";

    aliases = {
      st = "status";
      sync = "town sync";
      append = "town append";
      hack = "town hack";
    };
    # SSH signing via 1Password
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIYnDm9RfWWUdae/MTzZps0KDhlDrDdWIrFFfoeWWulD";
      signByDefault = true;
    };

    lfs.enable = true;  # replaces the manual [filter "lfs"] block

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
        excludesFile = "${config.xdg.configHome}/git/ignore";
        attributesfile = "${config.xdg.configHome}/git/attributes";
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
      merge.mergiraf.name = "mergiraf";
      merge.mergiraf.driver = "mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";

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
  programs.delta = {
    enable = true;
    enableGitIntegration = true;

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


}
