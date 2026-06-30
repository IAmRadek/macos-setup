{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    withPython3 = false;
    withRuby = false;
    extraPackages = with pkgs; [
      go
      gopls
      gotools
      gofumpt
    ];

    plugins = with pkgs.vimPlugins; [
      everforest
      nvim-tree-lua
      nvim-web-devicons
      fzf-lua
      nvim-lspconfig
      blink-cmp
      conform-nvim
      (nvim-treesitter.withPlugins (
        parsers: with parsers; [
          go
          gomod
          gosum
          gowork
          gotmpl
        ]
      ))
    ];

    initLua = ''
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      vim.g.everforest_background = "medium"
      vim.g.everforest_enable_italic = 1
      vim.g.everforest_better_performance = 1

      vim.opt.termguicolors = true
      vim.opt.background = "dark"
      vim.opt.mouse = "a"
      vim.opt.clipboard = "unnamedplus"
      vim.opt.keymodel = "startsel"
      vim.opt.selectmode = "mouse,key"
      vim.opt.number = true
      vim.opt.relativenumber = false
      vim.opt.signcolumn = "yes"
      vim.opt.wrap = false
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.undofile = true
      vim.opt.confirm = true
      vim.opt.updatetime = 250
      vim.opt.splitright = true
      vim.opt.splitbelow = true
      vim.opt.expandtab = true
      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2

      vim.cmd.colorscheme("everforest")

      require("nvim-tree").setup({
        view = {
          side = "left",
          width = 32,
        },
        renderer = {
          group_empty = true,
          icons = {
            show = {
              file = true,
              folder = true,
              folder_arrow = true,
              git = true,
            },
          },
        },
        filters = {
          dotfiles = false,
        },
        actions = {
          open_file = {
            resize_window = true,
          },
        },
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "go", "gomod", "gosum", "gowork", "gotmpl" },
        callback = function()
          pcall(vim.treesitter.start)
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })

      local fzf_lua = require("fzf-lua")
      fzf_lua.setup({
        winopts = {
          height = 0.85,
          width = 0.9,
          row = 0.5,
          col = 0.5,
          preview = {
            layout = "right",
            vertical = "down:45%",
          },
        },
        files = {
          prompt = "Files> ",
          fd_opts = "--color=never --type f --hidden --follow --exclude .git",
        },
      })

      local blink = require("blink.cmp")
      blink.setup({
        keymap = {
          preset = "default",
          ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        },
        completion = {
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 250,
          },
          ghost_text = {
            enabled = true,
          },
        },
        signature = {
          enabled = true,
          window = {
            show_documentation = true,
          },
        },
        sources = {
          default = { "lsp", "path", "snippets", "buffer" },
        },
      })

      vim.diagnostic.config({
        severity_sort = true,
        virtual_text = {
          spacing = 2,
          prefix = ">",
        },
        virtual_lines = {
          current_line = true,
        },
        float = {
          border = "rounded",
          source = "if_many",
        },
      })

      vim.lsp.config("gopls", {
        capabilities = blink.get_lsp_capabilities(),
        settings = {
          gopls = {
            gofumpt = true,
            hoverKind = "FullDocumentation",
            linksInHover = true,
            semanticTokens = true,
            staticcheck = true,
            usePlaceholders = true,
            analyses = {
              nilness = true,
              shadow = true,
              unusedparams = true,
              unusedwrite = true,
            },
            codelenses = {
              generate = true,
              regenerate_cgo = true,
              run_govulncheck = true,
              test = true,
              tidy = true,
              upgrade_dependency = true,
              vendor = true,
              vulncheck = true,
            },
          },
        },
      })
      vim.lsp.enable("gopls")

      require("conform").setup({
        formatters_by_ft = {
          go = { "goimports", "gofumpt" },
          gomod = { "gofmt" },
          gowork = { "gofmt" },
        },
        format_on_save = function(bufnr)
          local ft = vim.bo[bufnr].filetype
          if ft == "go" or ft == "gomod" or ft == "gowork" then
            return {
              timeout_ms = 1000,
              lsp_format = "fallback",
            }
          end
        end,
      })

      local map = vim.keymap.set
      local opts = { noremap = true, silent = true }

      map("n", "<C-s>", "<cmd>write<CR>", vim.tbl_extend("force", opts, { desc = "Save" }))
      map("i", "<C-s>", "<C-o>:write<CR>", vim.tbl_extend("force", opts, { desc = "Save" }))
      map("v", "<C-s>", "<Esc><cmd>write<CR>", vim.tbl_extend("force", opts, { desc = "Save" }))

      map("n", "<C-q>", "<cmd>confirm quit<CR>", vim.tbl_extend("force", opts, { desc = "Quit" }))
      map("i", "<C-q>", "<Esc><cmd>confirm quit<CR>", vim.tbl_extend("force", opts, { desc = "Quit" }))
      map("v", "<C-q>", "<Esc><cmd>confirm quit<CR>", vim.tbl_extend("force", opts, { desc = "Quit" }))

      map("n", "<C-z>", "u", vim.tbl_extend("force", opts, { desc = "Undo" }))
      map("i", "<C-z>", "<C-o>u", vim.tbl_extend("force", opts, { desc = "Undo" }))
      map("n", "<C-y>", "<C-r>", vim.tbl_extend("force", opts, { desc = "Redo" }))
      map("i", "<C-y>", "<C-o><C-r>", vim.tbl_extend("force", opts, { desc = "Redo" }))

      map("n", "<C-a>", "ggVG", vim.tbl_extend("force", opts, { desc = "Select all" }))
      map("i", "<C-a>", "<Esc>ggVG", vim.tbl_extend("force", opts, { desc = "Select all" }))
      map("v", "<C-a>", "<Esc>ggVG", vim.tbl_extend("force", opts, { desc = "Select all" }))

      map("n", "<C-c>", "\"+yy", vim.tbl_extend("force", opts, { desc = "Copy line" }))
      map("v", "<C-c>", "\"+y", vim.tbl_extend("force", opts, { desc = "Copy" }))
      map("n", "<C-x>", "\"+dd", vim.tbl_extend("force", opts, { desc = "Cut line" }))
      map("v", "<C-x>", "\"+d", vim.tbl_extend("force", opts, { desc = "Cut" }))
      map("n", "<C-v>", "\"+p", vim.tbl_extend("force", opts, { desc = "Paste" }))
      map("v", "<C-v>", "\"+P", vim.tbl_extend("force", opts, { desc = "Paste" }))
      map("i", "<C-v>", "<C-r>+", vim.tbl_extend("force", opts, { desc = "Paste" }))

      map("i", "<C-BS>", "<C-w>", vim.tbl_extend("force", opts, { desc = "Delete previous word" }))
      map("i", "<C-h>", "<C-w>", vim.tbl_extend("force", opts, { desc = "Delete previous word" }))
      map("i", "<C-u>", "<C-w>", vim.tbl_extend("force", opts, { desc = "Delete previous word" }))
      map("i", "\27[3;5~", "<C-o>de", vim.tbl_extend("force", opts, { desc = "Delete next word" }))

      map("n", "<C-f>", "/", vim.tbl_extend("force", opts, { desc = "Find" }))
      map("i", "<C-f>", "<Esc>/", vim.tbl_extend("force", opts, { desc = "Find" }))
      map("v", "<C-f>", "<Esc>/", vim.tbl_extend("force", opts, { desc = "Find" }))
      map("n", "<C-p>", "<cmd>FzfLua files<CR>", vim.tbl_extend("force", opts, { desc = "Find files" }))
      map("i", "<C-p>", "<Esc><cmd>FzfLua files<CR>", vim.tbl_extend("force", opts, { desc = "Find files" }))

      map("n", "<C-Space>", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Show docs" }))
      map("n", "<F2>", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
      map("n", "<F5>", vim.lsp.codelens.run, vim.tbl_extend("force", opts, { desc = "Run code lens" }))
      map("n", "<F12>", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
      map("n", "<S-F12>", "<cmd>FzfLua lsp_references<CR>", vim.tbl_extend("force", opts, { desc = "Find references" }))
      map("n", "<C-.>", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
      map("n", "<C-d>", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show diagnostic" }))

      map("n", "<C-n>", "<cmd>enew<CR>", vim.tbl_extend("force", opts, { desc = "New file" }))
      map("i", "<C-n>", "<Esc><cmd>enew<CR>", vim.tbl_extend("force", opts, { desc = "New file" }))
      map("n", "<C-o>", "<cmd>NvimTreeFocus<CR>", vim.tbl_extend("force", opts, { desc = "Focus file manager" }))
      map("i", "<C-o>", "<Esc><cmd>NvimTreeFocus<CR>", vim.tbl_extend("force", opts, { desc = "Focus file manager" }))
      map("n", "<C-b>", "<cmd>NvimTreeToggle<CR>", vim.tbl_extend("force", opts, { desc = "Toggle file manager" }))
      map("i", "<C-b>", "<Esc><cmd>NvimTreeToggle<CR>", vim.tbl_extend("force", opts, { desc = "Toggle file manager" }))

      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function(data)
          local api = require("nvim-tree.api")
          if vim.fn.isdirectory(data.file) == 1 then
            vim.cmd.cd(data.file)
            api.tree.open()
            return
          end

          api.tree.open()
          if data.file ~= "" then
            vim.cmd.wincmd("p")
          end
        end,
      })

      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
        pattern = { "*.go", "go.mod", "go.work" },
        callback = function()
          vim.lsp.codelens.refresh({ bufnr = 0 })
        end,
      })
    '';
  };
}
