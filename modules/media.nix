{ config, pkgs, ... }:

let
  spotifyPlayerPackage = pkgs.spotify-player.override {
    withMediaControl = false;
  };
in
{
  programs.spotify-player = {
    enable = true;
    package = spotifyPlayerPackage;
    settings = {
      enable_streaming = "DaemonOnly";
      enable_media_control = false;
      default_device = "spotify-player";
      device = {
        name = "spotify-player";
        audio_cache = false;
        normalization = false;
      };
    };
  };

  launchd.agents.spotify-player = {
    enable = true;
    config = {
      Label = "com.spotify-player.service";
      ProgramArguments = [
        "${spotifyPlayerPackage}/bin/spotify_player"
        "--daemon"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/spotify-player.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/spotify-player-error.log";
    };
  };
}
