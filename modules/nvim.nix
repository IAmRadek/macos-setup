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
      which-key-nvim
      gitsigns-nvim
      bufferline-nvim
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

      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

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

      require("which-key").setup({
        preset = "helix",
      })

      require("gitsigns").setup({
        signs = {
          add = { text = "┃" },
          change = { text = "┃" },
          delete = { text = "▁" },
          topdelete = { text = "▔" },
          changedelete = { text = "┃" },
          untracked = { text = "┆" },
        },
        current_line_blame = false,
      })

      require("bufferline").setup({
        options = {
          diagnostics = "nvim_lsp",
          separator_style = "thin",
          show_close_icon = false,
          truncate_names = false,
          max_name_length = 60,
          name_formatter = function(buf)
            return vim.fn.fnamemodify(buf.path, ":.")
          end,
          offsets = {
            { filetype = "NvimTree", text = "Explorer", highlight = "Directory", separator = true },
          },
        },
      })

      local blink = require("blink.cmp")
      blink.setup({
        keymap = {
          preset = "super-tab",
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
      map("n", "<M-Left>", "<C-o>", vim.tbl_extend("force", opts, { desc = "Go back" }))
      map("n", "<M-Right>", "<C-i>", vim.tbl_extend("force", opts, { desc = "Go forward" }))
      map("i", "<M-Left>", "<C-o><C-o>", vim.tbl_extend("force", opts, { desc = "Go back" }))
      map("i", "<M-Right>", "<C-o><C-i>", vim.tbl_extend("force", opts, { desc = "Go forward" }))
      map("n", "<S-F12>", "<cmd>FzfLua lsp_references<CR>", vim.tbl_extend("force", opts, { desc = "Find references" }))
      map("n", "<C-.>", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
      map("n", "<C-d>", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show diagnostic" }))

      local wk = require("which-key")
      wk.add({
        { "<leader>f", group = "Find" },
        { "<leader>ff", "<cmd>FzfLua files<CR>", desc = "Files" },
        { "<leader>fg", "<cmd>FzfLua live_grep<CR>", desc = "Grep in project" },
        { "<leader>fr", "<cmd>FzfLua lsp_references<CR>", desc = "References" },
        { "<leader>f/", "<cmd>FzfLua blines<CR>", desc = "Find in current file" },

        { "<leader>g", group = "Go to" },
        { "<leader>gd", vim.lsp.buf.definition, desc = "Definition" },
        { "<leader>gi", vim.lsp.buf.implementation, desc = "Implementation" },
        { "<leader>gt", vim.lsp.buf.type_definition, desc = "Type definition" },
        { "<leader>gb", function() vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-o>", true, false, true), "n", false) end, desc = "Back (previous position)" },
        { "<leader>gf", function() vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-i>", true, false, true), "n", false) end, desc = "Forward" },

        { "<leader>c", group = "Code" },
        { "<leader>ca", vim.lsp.buf.code_action, desc = "Action" },
        { "<leader>cr", vim.lsp.buf.rename, desc = "Rename" },
        { "<leader>cl", vim.lsp.codelens.run, desc = "Run code lens" },
        { "<leader>ck", vim.lsp.buf.hover, desc = "Show docs" },

        { "<leader>d", vim.diagnostic.open_float, desc = "Diagnostic" },

        { "<leader>e", group = "Explorer" },
        { "<leader>eo", "<cmd>NvimTreeFocus<CR>", desc = "Focus tree" },
        { "<leader>eb", "<cmd>NvimTreeToggle<CR>", desc = "Toggle tree" },

        { "<leader>b", group = "Buffers" },
        { "<leader>bb", "<cmd>FzfLua buffers<CR>", desc = "Open files" },
        { "<leader>br", "<cmd>FzfLua oldfiles<CR>", desc = "Recent files" },
        { "<leader>bn", "<cmd>BufferLineCycleNext<CR>", desc = "Next file" },
        { "<leader>bp", "<cmd>BufferLineCyclePrev<CR>", desc = "Previous file" },
        { "<leader>bd", "<cmd>bdelete<CR>", desc = "Close file" },
        { "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", desc = "Close others" },

        { "<leader>h", group = "Git" },
        { "<leader>hp", function() require("gitsigns").preview_hunk() end, desc = "Preview change" },
        { "<leader>hr", function() require("gitsigns").reset_hunk() end, desc = "Rollback change" },
        { "<leader>hs", function() require("gitsigns").stage_hunk() end, desc = "Stage change" },
        { "<leader>hb", function() require("gitsigns").blame_line({ full = true }) end, desc = "Blame line" },
        { "<leader>hn", function() require("gitsigns").nav_hunk("next") end, desc = "Next change" },
        { "<leader>hN", function() require("gitsigns").nav_hunk("prev") end, desc = "Previous change" },
        { "<leader>hd", function() require("gitsigns").diffthis() end, desc = "Diff this file" },
        { "<leader>hB", function() require("gitsigns").toggle_current_line_blame() end, desc = "Toggle inline blame" },

        { "<leader>w", "<cmd>write<CR>", desc = "Save" },
        { "<leader>q", "<cmd>confirm quit<CR>", desc = "Quit" },
        { "<leader>n", "<cmd>enew<CR>", desc = "New file" },
      })

      local function show_menu()
        wk.show({ keys = "<leader>", loop = true })
      end

      map({ "n", "v" }, "<Space>", "<Nop>", opts)
      map("n", "?", show_menu, vim.tbl_extend("force", opts, { desc = "Command menu" }))
      map("n", "<F1>", show_menu, vim.tbl_extend("force", opts, { desc = "Command menu" }))
      map("i", "<F1>", show_menu, vim.tbl_extend("force", opts, { desc = "Command menu" }))
      map("v", "<F1>", show_menu, vim.tbl_extend("force", opts, { desc = "Command menu" }))

      map("n", "<C-n>", "<cmd>enew<CR>", vim.tbl_extend("force", opts, { desc = "New file" }))
      map("i", "<C-n>", "<Esc><cmd>enew<CR>", vim.tbl_extend("force", opts, { desc = "New file" }))
      map("n", "<C-o>", "<cmd>NvimTreeFocus<CR>", vim.tbl_extend("force", opts, { desc = "Focus file manager" }))
      map("i", "<C-o>", "<Esc><cmd>NvimTreeFocus<CR>", vim.tbl_extend("force", opts, { desc = "Focus file manager" }))
      map("n", "<C-b>", "<cmd>NvimTreeToggle<CR>", vim.tbl_extend("force", opts, { desc = "Toggle file manager" }))
      map("i", "<C-b>", "<Esc><cmd>NvimTreeToggle<CR>", vim.tbl_extend("force", opts, { desc = "Toggle file manager" }))

      map("n", "<C-Tab>", "<cmd>BufferLineCycleNext<CR>", vim.tbl_extend("force", opts, { desc = "Next file" }))
      map("n", "<C-S-Tab>", "<cmd>BufferLineCyclePrev<CR>", vim.tbl_extend("force", opts, { desc = "Previous file" }))
      map("i", "<C-Tab>", "<cmd>BufferLineCycleNext<CR>", vim.tbl_extend("force", opts, { desc = "Next file" }))
      map("i", "<C-S-Tab>", "<cmd>BufferLineCyclePrev<CR>", vim.tbl_extend("force", opts, { desc = "Previous file" }))

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
