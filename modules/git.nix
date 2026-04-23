{
  config,
  pkgs,
  lib,
  ...
}:

let
  hooksDir = "${config.xdg.configHome}/git/hooks";
in
{
  xdg.configFile."git/hooks" = {
    source = ../githooks; # directory in your repo
    recursive = true; # copy all files/subdirs
  };
  xdg.configFile."git/ignore".text = ''
    .idea
    .DS_Store
    !*.secret
    CRUSH.md
  '';

  xdg.configFile."git/attributes".text = ''
    * merge=mergiraf
  '';

  programs.git = {
    enable = true;

    includes = [
      { path = "${config.xdg.configHome}/git/config.private"; }
    ]
    ++ lib.optional (builtins.pathExists ./git.private) { path = ./git.private; };

    # SSH signing via 1Password
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIYnDm9RfWWUdae/MTzZps0KDhlDrDdWIrFFfoeWWulD";
      signByDefault = true;
      format = null;
    };

    lfs.enable = true;

    settings = {
      user.name = "Radosław Dejnek";
      user.email = "radek@dejnek.pl";

      alias = {
        st = "status";
        sync = "town sync";
        append = "town append";
        hack = "town hack";
        ts = "town switch";
        dlog = "-c diff.external=difft log --ext-diff";
        dshow = "-c diff.external=difft show --ext-diff";
        ddiff = "-c diff.external=difft diff";
        dl = "-c diff.external=difft log -p --ext-diff";
        ds = "-c diff.external=difft show --ext-diff";
        dft = "-c diff.external=difft diff";
      };

      url."ssh://git@github.com".insteadOf = "https://github.com";

      gpg.format = "ssh";
      gpg = {
        "ssh" = {
          # program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
          allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
        };
      };

      commit.gpgsign = true;

      core = {
        excludesFile = "${config.xdg.configHome}/git/ignore";
        attributesfile = "${config.xdg.configHome}/git/attributes";
        editor = "nano";
        hooksPath = "${hooksDir}";
      };

      pull.rebase = false;
      rebase.updateRefs = true;

      rerere.enabled = true;

      color = {
        ui = true;

        branch = {
          current = "yellow reverse";
          local = "yellow";
          remote = "green";
        };

        diff = {
          meta = "yellow bold";
          frag = "magenta bold";
          old = "red bold";
          new = "green bold";
        };

        status = {
          added = "yellow";
          changed = "green";
          untracked = "cyan";
        };
      };

      merge.conflictstyle = "diff3";
      merge.mergiraf.name = "mergiraf";
      merge.mergiraf.driver = "mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";

      diff = {
        colorMoved = "default";
        external = "${pkgs.difftastic}/bin/difft";
        tool = "difftastic";
      };

      difftool = {
        prompt = false;
        difftastic.cmd = ''${pkgs.difftastic}/bin/difft --parse-error-limit 100 "$MERGED" "$LOCAL" "abcdef1" "100644" "$REMOTE" "abcdef2" "100644"'';
      };

      pager.difftool = true;

      push = {
        default = "current";
        autoSetupRemote = true;
      };

      # GitHub/Gist credential helpers (use Nix gh path)
      credential = {
        "https://github.com".helper = [
          "" # clear existing helpers
          "!${pkgs.gh}/bin/gh auth git-credential"
        ];
        "https://gist.github.com".helper = [
          ""
          "!${pkgs.gh}/bin/gh auth git-credential"
        ];
      };
    };
  };
  home.activation.createGitPrivateConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$HOME/.nix-darwin/private"
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${config.xdg.configHome}/git"
    if [ ! -f "$HOME/.nix-darwin/private/git.private" ]; then
      $DRY_RUN_CMD touch $VERBOSE_ARG "$HOME/.nix-darwin/private/git.private"
    fi
    $DRY_RUN_CMD ln -sf $VERBOSE_ARG "$HOME/.nix-darwin/private/git.private" "${config.xdg.configHome}/git/config.private"
  '';
}
