{ ... }:
{
  home.file.".config/zed/themes/IAmRadek.json".text = builtins.toJSON {
    "$schema" = "https://zed.dev/schema/themes/v0.2.0.json";
    name = "IAmRadek";
    author = "Converted from One Dark Islands + GoLand overrides";
    themes = [
      {
        name = "IAmRadek";
        appearance = "dark";
        style = {
          accents = [
            "#6ea8dc"
            "#c678dd"
            "#5fa7c8"
            "#9aa66f"
            "#c99152"
            "#d7b46a"
            "#d16d5b"
          ];

          "background.appearance" = "opaque";

          border = "#323232";
          "border.variant" = "#2d2d2d";
          "border.focused" = "#4f6f91";
          "border.selected" = "#5d83ab";
          "border.transparent" = "#00000000";
          "border.disabled" = "#2d2d2d";

          "elevated_surface.background" = "#3b3d40";
          "surface.background" = "#26282a";
          background = "#2b2b2b";

          "element.background" = "#2a2c2f";
          "element.hover" = "#34363a";
          "element.active" = "#3d4045";
          "element.selected" = "#3d4045";
          "element.disabled" = "#2f3133";

          "drop_target.background" = "#404347";
          "ghost_element.background" = "#00000000";
          "ghost_element.hover" = "#3a3c40";
          "ghost_element.active" = "#404347";
          "ghost_element.selected" = "#35383b";
          "ghost_element.disabled" = "#2f3133";

          text = "#d7d9de";
          "text.muted" = "#8a8d93";
          "text.placeholder" = "#72767d";
          "text.disabled" = "#666a70";
          "text.accent" = "#6ea8dc";

          icon = "#d7d9de";
          "icon.muted" = "#8a8d93";
          "icon.disabled" = "#666a70";
          "icon.placeholder" = "#666a70";
          "icon.accent" = "#6ea8dc";

          "status_bar.background" = "#252526";
          "title_bar.background" = "#252526";
          "title_bar.inactive_background" = "#252526";
          "toolbar.background" = "#252526";
          "tab_bar.background" = "#252526";
          "tab.inactive_background" = "#252526";
          "tab.active_background" = "#2b2b2b";

          "search.match_background" = "#3f4653";
          "search.active_match_background" = "#4a5261";

          "panel.background" = "#202224";
          "panel.focused_border" = "#4f6f91";
          "pane.focused_border" = "#4f6f91";
          "pane_group.border" = "#323232";

          "scrollbar.thumb.background" = "#5b5f6650";
          "scrollbar.thumb.hover_background" = "#6a707880";
          "scrollbar.thumb.active_background" = "#7a818a";
          "scrollbar.thumb.border" = "#00000000";
          "scrollbar.track.background" = "#00000000";
          "scrollbar.track.border" = "#00000000";

          "editor.foreground" = "#aeb6c3";
          "editor.background" = "#2b2b2b";
          "editor.gutter.background" = "#2b2b2b";
          "editor.subheader.background" = "#323436";
          "editor.active_line.background" = "#313335";
          "editor.highlighted_line.background" = "#3d4045";
          "editor.line_number" = "#55585e";
          "editor.active_line_number" = "#9ca3ad";
          "editor.hover_line_number" = "#9ca3ad";
          "editor.invisible" = "#45484d";
          "editor.wrap_guide" = "#3c3f43";
          "editor.active_wrap_guide" = "#5a6068";
          "editor.document_highlight.read_background" = "#3a3d42";
          "editor.document_highlight.write_background" = "#3d4045";
          "editor.indent_guide" = "#3c3f43";
          "editor.indent_guide_active" = "#565b63";

          "terminal.background" = "#2b2b2b";
          "terminal.foreground" = "#aeb6c3";
          "terminal.bright_foreground" = "#ffffff";
          "terminal.dim_foreground" = "#666a70";
          "terminal.ansi.black" = "#3f4349";
          "terminal.ansi.bright_black" = "#666a70";
          "terminal.ansi.dim_black" = "#232425";
          "terminal.ansi.red" = "#d16d5b";
          "terminal.ansi.bright_red" = "#e07a66";
          "terminal.ansi.dim_red" = "#a95a4b";
          "terminal.ansi.green" = "#9aa66f";
          "terminal.ansi.bright_green" = "#a8b67c";
          "terminal.ansi.dim_green" = "#7f8a5d";
          "terminal.ansi.yellow" = "#d7b46a";
          "terminal.ansi.bright_yellow" = "#e3c07a";
          "terminal.ansi.dim_yellow" = "#bf9d5f";
          "terminal.ansi.blue" = "#6ea8dc";
          "terminal.ansi.bright_blue" = "#84b9e8";
          "terminal.ansi.dim_blue" = "#5688b6";
          "terminal.ansi.magenta" = "#b48ead";
          "terminal.ansi.bright_magenta" = "#c39abe";
          "terminal.ansi.dim_magenta" = "#93738d";
          "terminal.ansi.cyan" = "#5fa7c8";
          "terminal.ansi.bright_cyan" = "#70b7d7";
          "terminal.ansi.dim_cyan" = "#4c869f";
          "terminal.ansi.white" = "#aeb6c3";
          "terminal.ansi.bright_white" = "#ffffff";
          "terminal.ansi.dim_white" = "#7b8088";

          "link_text.hover" = "#6ea8dc";

          "version_control.added" = "#a7b46f";
          "version_control.modified" = "#e09a8f";
          "version_control.deleted" = "#e09a8f";
          "version_control.word_added" = "#3b4336";
          "version_control.word_deleted" = "#4a3533";
          "version_control.conflict_marker.ours" = "#3b4336";
          "version_control.conflict_marker.theirs" = "#38404a";

          conflict = "#d7b46a";
          "conflict.background" = "#45302b";
          "conflict.border" = "#a95a4b";

          created = "#a7b46f";
          "created.background" = "#3b4336";
          "created.border" = "#7f8a5d";

          deleted = "#e09a8f";
          "deleted.background" = "#4a3533";
          "deleted.border" = "#a95a4b";

          error = "#bc3f3c";
          "error.background" = "#4d1514";
          "error.border" = "#9e2927";

          hidden = "#5c6370";
          "hidden.background" = null;
          "hidden.border" = null;

          hint = "#6ea8dc";
          "hint.background" = "#323436";
          "hint.border" = "#5688b6";

          ignored = "#5c6370";
          "ignored.background" = null;
          "ignored.border" = null;

          info = "#6ea8dc";
          "info.background" = "#323436";
          "info.border" = "#5688b6";

          modified = "#e09a8f";
          "modified.background" = "#38404a";
          "modified.border" = "#5688b6";

          predictive = "#5c6370";
          "predictive.background" = null;
          "predictive.border" = null;

          renamed = "#e09a8f";
          "renamed.background" = null;
          "renamed.border" = null;

          success = "#9aa66f";
          "success.background" = "#3b4336";
          "success.border" = "#7f8a5d";

          unreachable = "#5c6370";
          "unreachable.background" = null;
          "unreachable.border" = null;

          warning = "#be9117";
          "warning.background" = "#343429";
          "warning.border" = "#be9117";

          players = [
            {
              cursor = "#6ea8dc";
              background = "#6ea8dc";
              selection = "#38404a";
            }
            {
              cursor = "#9aa66f";
              background = "#9aa66f";
              selection = "#3b4336";
            }
            {
              cursor = "#d16d5b";
              background = "#d16d5b";
              selection = "#4a3533";
            }
            {
              cursor = "#b48ead";
              background = "#b48ead";
              selection = "#443947";
            }
            {
              cursor = "#c99152";
              background = "#c99152";
              selection = "#453c30";
            }
            {
              cursor = "#5fa7c8";
              background = "#5fa7c8";
              selection = "#384652";
            }
            {
              cursor = "#d7b46a";
              background = "#d7b46a";
              selection = "#4a4431";
            }
          ];

          syntax = {
            attribute = {
              color = "#c99152";
              font_style = null;
              font_weight = null;
            };
            boolean = {
              color = "#c99152";
              font_style = null;
              font_weight = null;
            };
            comment = {
              color = "#7b7b7b";
              font_style = null;
              font_weight = null;
            };
            "comment.doc" = {
              color = "#7b7b7b";
              font_style = null;
              font_weight = null;
            };
            constant = {
              color = "#5fa7c8";
              font_style = null;
              font_weight = null;
            };
            constructor = {
              color = "#d7b46a";
              font_style = null;
              font_weight = null;
            };
            embedded = {
              color = "#aeb6c3";
              font_style = null;
              font_weight = null;
            };
            emphasis = {
              color = "#aeb6c3";
              font_style = "italic";
              font_weight = null;
            };
            "emphasis.strong" = {
              color = "#aeb6c3";
              font_style = null;
              font_weight = 700;
            };
            function = {
              color = "#d7b46a";
              font_style = null;
              font_weight = null;
            };
            "function.definition" = {
              color = "#d7b46a";
              font_style = null;
              font_weight = null;
            };
            "function.special" = {
              color = "#d7b46a";
              font_style = null;
              font_weight = null;
            };
            hint = {
              color = "#d7b46a";
              font_style = null;
              font_weight = null;
            };
            keyword = {
              color = "#c99152";
              font_style = null;
              font_weight = null;
            };
            label = {
              color = "#aeb6c3";
              font_style = null;
              font_weight = null;
            };
            link_text = {
              color = "#6ea8dc";
              font_style = null;
              font_weight = null;
            };
            link_uri = {
              color = "#6ea8dc";
              font_style = null;
              font_weight = null;
            };
            namespace = {
              color = "#9aa66f";
              font_style = null;
              font_weight = null;
            };
            number = {
              color = "#c99152";
              font_style = null;
              font_weight = null;
            };
            operator = {
              color = "#aeb6c3";
              font_style = null;
              font_weight = null;
            };
            predictive = {
              color = "#74777d";
              font_style = "italic";
              font_weight = null;
            };
            preproc = {
              color = "#c99152";
              font_style = null;
              font_weight = null;
            };
            primary = {
              color = "#aeb6c3";
              font_style = null;
              font_weight = null;
            };
            property = {
              color = "#aeb6c3";
              font_style = null;
              font_weight = null;
            };
            punctuation = {
              color = "#aeb6c3";
              font_style = null;
              font_weight = null;
            };
            "punctuation.bracket" = {
              color = "#aeb6c3";
              font_style = null;
              font_weight = null;
            };
            "punctuation.delimiter" = {
              color = "#aeb6c3";
              font_style = null;
              font_weight = null;
            };
            "punctuation.list_marker" = {
              color = "#aeb6c3";
              font_style = null;
              font_weight = null;
            };
            "punctuation.special" = {
              color = "#aeb6c3";
              font_style = null;
              font_weight = null;
            };
            selector = {
              color = "#c99152";
              font_style = null;
              font_weight = null;
            };
            "selector.pseudo" = {
              color = "#c99152";
              font_style = null;
              font_weight = null;
            };
            string = {
              color = "#9aa66f";
              font_style = null;
              font_weight = null;
            };
            "string.escape" = {
              color = "#6a8759";
              font_style = null;
              font_weight = null;
            };
            "string.regex" = {
              color = "#9aa66f";
              font_style = null;
              font_weight = null;
            };
            "string.special" = {
              color = "#9aa66f";
              font_style = null;
              font_weight = null;
            };
            "string.special.symbol" = {
              color = "#9aa66f";
              font_style = null;
              font_weight = null;
            };
            tag = {
              color = "#c99152";
              font_style = null;
              font_weight = null;
            };
            "text.literal" = {
              color = "#9aa66f";
              font_style = null;
              font_weight = null;
            };
            title = {
              color = "#c3cad5";
              font_style = null;
              font_weight = null;
            };
            type = {
              color = "#c8b28a";
              font_style = null;
              font_weight = null;
            };
            "type.builtin" = {
              color = "#c8b28a";
              font_style = null;
              font_weight = null;
            };
            "type.interface" = {
              color = "#c3cad5";
              font_style = null;
              font_weight = null;
            };
            "type.parameter" = {
              color = "#6ea8dc";
              font_style = null;
              font_weight = null;
            };
            variable = {
              color = "#aeb6c3";
              font_style = null;
              font_weight = null;
            };
            "variable.member" = {
              color = "#aeb6c3";
              font_style = null;
              font_weight = null;
            };
            "variable.parameter" = {
              color = "#aeb6c3";
              font_style = null;
              font_weight = null;
            };
            "variable.special" = {
              color = "#c3cad5";
              font_style = null;
              font_weight = null;
            };
            variant = {
              color = "#c3cad5";
              font_style = null;
              font_weight = null;
            };
          };
        };
      }
    ];
  };
}
