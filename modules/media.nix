{ config, pkgs, ... }:

let
  spotifyPlayerPackage = pkgs.spotify-player.override {
    withMediaControl = true;
  };
in
{
  programs.spotify-player = {
    enable = true;
    package = spotifyPlayerPackage;
    settings = {
      enable_media_control = true;
      default_device = "RD's Macbook";
      device = {
        name = "RD's Macbook";
        audio_cache = false;
        normalization = false;
        enable_streaming = true;
      };
    };
  };
}
