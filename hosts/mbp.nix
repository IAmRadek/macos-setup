{ pkgs, ... }:

let
  username = "rd";
in
{
  # Basic user configuration
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };
}
