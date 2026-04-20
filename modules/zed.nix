{ ... }:
{
  home.file.".config/zed/themes/IAmRadek.json".text = builtins.toJSON {
    "$schema" = "https://zed.dev/schema/themes/v0.2.0.json";
    name = "IAmRadek";
    author = "Converted from GoLand scheme";
    themes = [
      {
        name = "IAmRadek";
        appearance = "dark";
        style = {
          warning = "#be9117";
          "warning.background" = "#343429";
          "warning.border" = "#be9117";

          error = "#bc3f3c";
          "error.background" = "#4d1514";
          "error.border" = "#9e2927";

          "editor.background" = "#000000";
          "panel.background" = "#000000";
          "surface.background" = "#000000";
          "elevated_surface.background" = "#000000";

          syntax = {
            "string.escape" = {
              color = "#6a8759";
            };
          };
        };
      }
    ];
  };
}
