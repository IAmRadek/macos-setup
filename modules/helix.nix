{
  programs.helix = {
    enable = true;
    settings = {
      theme = "dark_plus";
      editor = {
        # Tab bar of open files, shown once two or more are open.
        bufferline = "multiple";
        cursorline = true;
        # Space f also lists dotfiles.
        file-picker.hidden = false;
      };
    };
  };
}
