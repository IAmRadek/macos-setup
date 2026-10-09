{ pkgs, ... }:

let
  # The user who ran sudo; needs --impure (see Makefile)
  username =
    let
      u = builtins.getEnv "SUDO_USER";
    in
    if u == "" then throw "rdwk: SUDO_USER is empty; run `make switch-work`" else u;
in
{
  system.primaryUser = username;
  # TODO https://github.com/LnL7/nix-darwin/issues/682
  users.users.${username}.home = "/Users/${username}";

  homebrew = { };

  home-manager.users.${username} =
    { pkgs, ... }:
    {
      home.sessionPath = [
        "$HOME/go/bin"
      ];

      home.packages = [
        (pkgs.buildGoModule {
          pname = "godotenv";
          version = "1.5.1";

          src = pkgs.fetchFromGitHub {
            owner = "joho";
            repo = "godotenv";
            rev = "v1.5.1";
            hash = "sha256-kA0osKfsc6Kp+nuGTRJyXZZlJt1D/kuEazKMWYCWcQ8=";
          };

          # Build only the CLI
          subPackages = [ "cmd/godotenv" ];
          vendorHash = null;
        })
      ];
    };
}
