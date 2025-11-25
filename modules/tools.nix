{
  config,
  lib,
  pkgs,
  ...
}:

let
  git-pr = pkgs.rustPlatform.buildRustPackage rec {
    pname = "git-pr";
    version = "1.1.2";

    src = pkgs.fetchFromGitHub {
      owner = "IAmRadek";
      repo = "git-pr";
      rev = "v${version}";
      hash = "sha256-rZKZGoqt+INwgDc3WhIQYP55OetsB1aHJWjhRiIGNZE=";
    };

    cargoHash = "sha256-dWb1m01PJsAnxj1fA4WnQU8JV9uD9UahZeUr3Go7aLc=";

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.openssl ];

    doCheck = false;
    meta = with lib; {
      description = "Highly opinionated tool for PR creation";
      homepage = "https://github.com/IAmRadek/git-pr";
      license = licenses.mit;
    };
  };
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "colima-tools" ''
      set -euo pipefail
      exec ${py}/bin/inv -r ''$HOME/.nix-darwin/tools/colima "''${1}" -- "''${@:2}"
    '')
  ];

  home.file.".zsh/completions/_colima-tools".source = ../tools/_colima;

  home.file.".runbooks/new.sh".source = ../tools/runbooks/new.sh;
  home.activation.mySymlinks = lib.mkAfter ''
   	  ln -sf ~/.nix-darwin/tools/navi/cheats ~/.local/share/navi/cheats/local
   	'';

}
