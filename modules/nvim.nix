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
      # Rust toolchain + LSP/formatter/linter.
      rustc
      cargo
      rust-analyzer
      rustfmt
      clippy
      # TypeScript / React / JS: runtime, servers, formatter.
      nodejs
      typescript
      typescript-language-server
      vscode-langservers-extracted # eslint, json, html, css servers
      tailwindcss-language-server
      prettier
      ripgrep
      fd
    ];

    plugins = with pkgs.vimPlugins; [
      (pkgs.vimUtils.buildVimPlugin {
        pname = "flexoki-neovim";
        version = "c3e2251";
        src = pkgs.fetchFromGitHub {
          owner = "kepano";
          repo = "flexoki-neovim";
          rev = "c3e2251e813d29d885a7cbbe9808a7af234d845d";
          hash = "sha256-TlBP99MBAT/H0Uut1MF8SnIDoeetcdHLKrWal2oO2Ug=";
        };
      })
      nvim-tree-lua
      nvim-web-devicons
      fzf-lua
      nvim-lspconfig
      blink-cmp
      conform-nvim
      which-key-nvim
      gitsigns-nvim
      bufferline-nvim
      render-markdown-nvim
      trouble-nvim
      treesj
      vim-dadbod
      vim-dadbod-ui
      claudecode-nvim
      (pkgs.vimUtils.buildVimPlugin {
        pname = "gesture-nvim";
        version = "eb1e075";
        src = pkgs.fetchFromGitHub {
          owner = "notomo";
          repo = "gesture.nvim";
          rev = "eb1e0753837371205df04ff2427b27c0cb1047d5";
          hash = "sha256-wU/a/r9MqyASbq80QH3zH5I8Us/FqrTPLAs7YV3ucpo=";
        };
      })
      (nvim-treesitter.withPlugins (
        parsers: with parsers; [
          go
          gomod
          gosum
          gowork
          gotmpl
          rust
          toml
          javascript
          typescript
          tsx
          json
          css
          html
          markdown
          markdown_inline
        ]
      ))
    ];

    initLua = ''
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      vim.opt.termguicolors = true
      vim.opt.background = "dark"
      vim.opt.mouse = "a"
      -- No horizontal wheel/trackpad scrolling (it would scroll into empty space
      -- past long lines). Reach long lines by moving the cursor, which is bounded.
      vim.opt.mousescroll = "ver:3,hor:0"
      vim.opt.clipboard = "unnamedplus"
      vim.opt.keymodel = "startsel"
      vim.opt.selectmode = "mouse,key"
      vim.opt.number = true
      vim.opt.relativenumber = true -- required so the statuscolumn refreshes on cursor move
      vim.opt.signcolumn = "yes"
      vim.opt.wrap = false
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.undofile = true
      vim.opt.autoread = true
      vim.opt.confirm = true
      vim.opt.updatetime = 250
      vim.opt.splitright = true
      vim.opt.splitbelow = true
      vim.opt.expandtab = true
      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2

      -- Let Left/Right arrows wrap across line boundaries (prev/next line),
      -- in normal/visual (<,>) and insert ([,]) modes.
      vim.opt.whichwrap:append("<,>,[,]")

      -- Two number columns: absolute (left) then relative (right, next to text).
      -- The current line shows 0 in the relative column.
      _G.dual_statuscol = function()
        -- Skip non-file windows (nvim-tree, terminals, Trouble, dbui, help): no
        -- line numbers there. buftype is empty only for real file buffers.
        local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
        if vim.bo[buf].buftype ~= "" then
          return ""
        end
        return table.concat({
          "%s", -- sign column (gitsigns, diagnostics)
          "%=", -- push numbers to the right, next to the text
          string.format("%3d ", vim.v.lnum), -- absolute
          string.format("%2d ", vim.v.relnum), -- relative
        })
      end
      vim.opt.statuscolumn = "%!v:lua.dual_statuscol()"

      vim.cmd.colorscheme("flexoki-dark")

      -- Pronounced current-line highlight (override the theme's subtle default).
      -- Colors from the Flexoki dark palette: bg-800 + orange-400 accent.
      vim.opt.cursorline = true
      vim.opt.cursorlineopt = "number,line"
      vim.api.nvim_set_hl(0, "CursorLine", { bg = "#343331" })
      vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#DA702C", bold = true })

      -- Visual ruler at column 120 (guide only — no hard wrapping). Faint tint
      -- from the Flexoki dark palette so it reads as a thin line.
      vim.opt.colorcolumn = "120"
      vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#1C1B1A" })

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
          git_ignored = false,
        },
        update_focused_file = {
          enable = true,
        },
        filesystem_watchers = {
          enable = true,
        },
        actions = {
          open_file = {
            resize_window = true,
          },
        },
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "go", "gomod", "gosum", "gowork", "gotmpl", "rust", "toml",
          "javascript", "javascriptreact", "typescript", "typescriptreact",
          "json", "jsonc", "css", "scss", "html",
        },
        callback = function()
          pcall(vim.treesitter.start)
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })

      -- Point rust-analyzer at the Nix-provided stdlib source so "go to
      -- definition" into std/core works without a rustup component.
      vim.env.RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}"

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

      -- Close a tab (buffer). When closing the focused tab, move to the next
      -- one in bufferline's visual order first (or the previous, if it was the
      -- last — no wrap); closing a non-focused tab leaves the cursor put. If it
      -- was the only tab, drop to an empty buffer so the window stays.
      -- Shared by <leader>bd, the bufferline "x", and :q (via SmartQuit).
      _G.close_tab = function(bufnr, force)
        bufnr = bufnr or vim.api.nvim_get_current_buf()
        if bufnr == vim.api.nvim_get_current_buf() then
          local ids = {}
          local ok, bl = pcall(require, "bufferline")
          if ok then
            for _, e in ipairs(bl.get_elements().elements) do
              ids[#ids + 1] = e.id
            end
          end
          if #ids == 0 then
            for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
              ids[#ids + 1] = b.bufnr
            end
          end
          if #ids > 1 then
            local idx
            for i, id in ipairs(ids) do
              if id == bufnr then
                idx = i
                break
              end
            end
            local target = idx and (ids[idx + 1] or ids[idx - 1])
            if target then
              vim.api.nvim_set_current_buf(target)
            end
          else
            vim.cmd("enew")
          end
        end
        vim.cmd((force and "bdelete! " or "confirm bdelete ") .. bufnr)
      end

      require("bufferline").setup({
        options = {
          diagnostics = "nvim_lsp",
          separator_style = "thin",
          show_close_icon = false,
          truncate_names = false,
          max_name_length = 60,
          -- Make the per-tab "x" (and middle-click) use our neighbor-focus close.
          close_command = function(bufnr) _G.close_tab(bufnr) end,
          middle_mouse_command = function(bufnr) _G.close_tab(bufnr) end,
          name_formatter = function(buf)
            return vim.fn.fnamemodify(buf.path, ":.")
          end,
          offsets = {
            { filetype = "NvimTree", text = "Explorer", highlight = "Directory", separator = true },
          },
        },
      })

      require("render-markdown").setup({})

      -- treesj: split a call's arguments (or struct/array/object) onto separate
      -- lines, or join them back — like GoLand's "put arguments on separate
      -- lines". Treesitter-based, so it works for Go/Rust/TS/JS alike.
      require("treesj").setup({ use_default_keymaps = false })

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

      vim.lsp.config("rust_analyzer", {
        -- Pin to the Nix binary by store path. Otherwise the rustup shim on
        -- ~/.cargo/bin intercepts, can't find a rust-analyzer component, and
        -- ping-pongs with the Nix binary until "infinite recursion detected".
        cmd = { "${pkgs.rust-analyzer}/bin/rust-analyzer" },
        capabilities = blink.get_lsp_capabilities(),
        settings = {
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = true,
              buildScripts = { enable = true },
              loadOutDirsFromCheck = true,
            },
            procMacro = {
              enable = true,
            },
            -- Run clippy (not just cargo check) on save for richer lints.
            checkOnSave = true,
            check = {
              command = "clippy",
              extraArgs = { "--no-deps" },
            },
            diagnostics = {
              enable = true,
              experimental = { enable = true },
            },
            inlayHints = {
              bindingModeHints = { enable = true },
              closureReturnTypeHints = { enable = "always" },
              lifetimeElisionHints = { enable = "skip_trivial", useParameterNames = true },
              parameterHints = { enable = true },
              typeHints = { enable = true },
            },
            lens = {
              enable = true,
              references = { adt = { enable = true }, method = { enable = true } },
              implementations = { enable = true },
              run = { enable = true },
            },
            completion = {
              callable = { snippets = "fill_arguments" },
              postfix = { enable = true },
              fullFunctionSignatures = { enable = true },
            },
            imports = {
              granularity = { group = "module" },
              prefix = "self",
            },
            hover = {
              actions = { enable = true },
              memoryLayout = { enable = true },
            },
            files = {
              excludeDirs = { ".git", "target", "node_modules" },
            },
          },
        },
      })
      vim.lsp.enable("rust_analyzer")

      -- rust-analyzer's "Run" code lens (and <F5>) hands back a "runnable"
      -- and expects the editor to execute it. Neovim has no built-in handler,
      -- so wire one that runs the cargo invocation in a terminal split.
      local function run_rust_runnable(runnable)
        local a = runnable.args
        local cmd = { a.overrideCargo or "cargo" }
        vim.list_extend(cmd, a.cargoArgs or {})
        vim.list_extend(cmd, a.cargoExtraArgs or {})
        if a.executableArgs and #a.executableArgs > 0 then
          table.insert(cmd, "--")
          vim.list_extend(cmd, a.executableArgs)
        end
        vim.cmd("botright 15split | enew")
        vim.fn.jobstart(cmd, { term = true, cwd = a.workspaceRoot })
        vim.cmd("startinsert")
      end

      vim.lsp.commands["rust-analyzer.runSingle"] = function(command)
        run_rust_runnable(command.arguments[1])
      end
      -- No DAP configured, so treat "Debug" as a plain run for now.
      vim.lsp.commands["rust-analyzer.debugSingle"] = function(command)
        run_rust_runnable(command.arguments[1])
      end

      -- TypeScript / JavaScript / React ------------------------------------
      local ts_inlay_hints = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayVariableTypeHintsWhenTypeMatchesName = false,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      }
      vim.lsp.config("ts_ls", {
        capabilities = blink.get_lsp_capabilities(),
        settings = {
          typescript = {
            inlayHints = ts_inlay_hints,
            suggest = { completeFunctionCalls = true },
            updateImportsOnFileMove = { enabled = "always" },
          },
          javascript = {
            inlayHints = ts_inlay_hints,
            suggest = { completeFunctionCalls = true },
            updateImportsOnFileMove = { enabled = "always" },
          },
          completions = { completeFunctionCalls = true },
        },
      })
      vim.lsp.enable("ts_ls")

      -- ESLint: diagnostics + fix-on-save (see BufWritePre autocmd below).
      vim.lsp.config("eslint", {
        capabilities = blink.get_lsp_capabilities(),
        settings = {
          workingDirectories = { mode = "auto" },
        },
      })
      vim.lsp.enable("eslint")

      -- Tailwind, plus JSON/CSS/HTML from vscode-langservers-extracted.
      vim.lsp.config("tailwindcss", {
        capabilities = blink.get_lsp_capabilities(),
      })
      vim.lsp.enable("tailwindcss")

      vim.lsp.config("jsonls", { capabilities = blink.get_lsp_capabilities() })
      vim.lsp.enable("jsonls")
      vim.lsp.config("cssls", { capabilities = blink.get_lsp_capabilities() })
      vim.lsp.enable("cssls")
      vim.lsp.config("html", { capabilities = blink.get_lsp_capabilities() })
      vim.lsp.enable("html")

      -- Run `eslint --fix` on save when the ESLint server is attached.
      -- Registered before conform's own BufWritePre so lint-fixes land first
      -- and Prettier formats the result afterward.
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = { "*.js", "*.jsx", "*.ts", "*.tsx", "*.mjs", "*.cjs" },
        callback = function(args)
          if #vim.lsp.get_clients({ bufnr = args.buf, name = "eslint" }) > 0 then
            pcall(vim.cmd, "EslintFixAll")
          end
        end,
      })

      require("conform").setup({
        formatters_by_ft = {
          go = { "goimports", "gofumpt" },
          gomod = { "gofmt" },
          gowork = { "gofmt" },
          rust = { "rustfmt" },
          javascript = { "prettier" },
          javascriptreact = { "prettier" },
          typescript = { "prettier" },
          typescriptreact = { "prettier" },
          json = { "prettier" },
          jsonc = { "prettier" },
          css = { "prettier" },
          scss = { "prettier" },
          html = { "prettier" },
          yaml = { "prettier" },
        },
        format_on_save = function(bufnr)
          local ft = vim.bo[bufnr].filetype
          local prettier_fts = {
            javascript = true, javascriptreact = true,
            typescript = true, typescriptreact = true,
            json = true, jsonc = true, css = true, scss = true,
            html = true, yaml = true,
          }
          if ft == "go" or ft == "gomod" or ft == "gowork" or ft == "rust" or prettier_fts[ft] then
            return {
              timeout_ms = 2000,
              lsp_format = "fallback",
            }
          end
        end,
      })

      local map = vim.keymap.set
      local opts = { noremap = true, silent = true }

      local function goto_line()
        vim.ui.input({ prompt = "Go to line: " }, function(input)
          if input and input:match("^%d+$") then
            local line = math.min(tonumber(input), vim.api.nvim_buf_line_count(0))
            vim.api.nvim_win_set_cursor(0, { line, 0 })
          end
        end)
      end

      -- Prompt for a path and create the file, making any missing parent
      -- directories. Relative paths resolve against the current working dir.
      local function new_file()
        vim.ui.input({ prompt = "New file: ", completion = "file" }, function(input)
          if not input or input == "" then
            return
          end
          local path = vim.fn.fnamemodify(input, ":p")
          vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
          vim.cmd.edit(vim.fn.fnameescape(path))
          -- Persist an empty file so it exists on disk and shows in the tree.
          if vim.fn.filereadable(path) == 0 then
            vim.cmd.write()
          end
        end)
      end

      -- Close the focused tab (see _G.close_tab above for the behavior).
      local function close_buffer()
        _G.close_tab(vim.api.nvim_get_current_buf())
      end

      -- Make a bare :q close the current tab (with neighbor focus) when it's the
      -- only editor window, but keep normal window-close semantics inside a
      -- split or a special buffer (tree, terminal, panels). The cnoreabbrev only
      -- fires when the whole command line is exactly "q", so :q!, :qa, :wq, and
      -- ranged commands are untouched.
      _G.smart_quit = function(force)
        if vim.bo.buftype ~= "" then
          vim.cmd(force and "quit!" or "quit")
          return
        end
        local wins = vim.tbl_filter(function(w)
          return vim.api.nvim_win_get_config(w).relative == ""
            and vim.bo[vim.api.nvim_win_get_buf(w)].filetype ~= "NvimTree"
        end, vim.api.nvim_tabpage_list_wins(0))
        if #wins > 1 then
          vim.cmd(force and "quit!" or "quit")
        else
          _G.close_tab(vim.api.nvim_get_current_buf(), force)
        end
      end
      vim.api.nvim_create_user_command("SmartQuit", function(o)
        _G.smart_quit(o.bang)
      end, { bang = true })
      vim.cmd([[cnoreabbrev <expr> q (getcmdtype() == ':' && getcmdline() ==# 'q') ? 'SmartQuit' : 'q']])

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

      map("n", "<C-S-k>", '"_dd', vim.tbl_extend("force", opts, { desc = "Delete line" }))
      map("i", "<C-S-k>", '<cmd>normal! "_dd<CR>', vim.tbl_extend("force", opts, { desc = "Delete line" }))
      map("v", "<C-S-k>", '"_d', vim.tbl_extend("force", opts, { desc = "Delete selection" }))

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
      map("n", "<M-Left>", "<C-o>", vim.tbl_extend("force", opts, { desc = "Go back" }))
      map("n", "<M-Right>", "<C-i>", vim.tbl_extend("force", opts, { desc = "Go forward" }))
      map("i", "<M-Left>", "<C-o><C-o>", vim.tbl_extend("force", opts, { desc = "Go back" }))
      map("i", "<M-Right>", "<C-o><C-i>", vim.tbl_extend("force", opts, { desc = "Go forward" }))
      map("n", "<C-.>", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))

      map("n", "<A-LeftMouse>", "<LeftMouse><cmd>lua vim.lsp.buf.definition()<CR>", vim.tbl_extend("force", opts, { desc = "Go to definition (Opt+click)" }))
      map("n", "<A-S-LeftMouse>", "<LeftMouse><cmd>FzfLua lsp_references<CR>", vim.tbl_extend("force", opts, { desc = "Find references (Opt+Shift+click)" }))
      map("n", "<C-d>", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show diagnostic" }))

      -- Mouse gestures: hold Shift + drag one finger left/right for back/forward.
      -- Shift is used so a plain left-drag still selects text. (mouse-shift-capture=always in Ghostty)
      local gesture = require("gesture")
      gesture.register({
        name = "back",
        inputs = { gesture.left() },
        action = function()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-o>", true, false, true), "n", false)
        end,
      })
      gesture.register({
        name = "forward",
        inputs = { gesture.right() },
        action = function()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-i>", true, false, true), "n", false)
        end,
      })
      -- Neutralize the Shift-press so it only positions the cursor (stays in normal
      -- mode) instead of starting a Select-mode selection, so the drag map below fires.
      map("n", "<S-LeftMouse>", "<LeftMouse>", vim.tbl_extend("force", opts, { desc = "Gesture start" }))
      map("n", "<S-LeftDrag>", function() require("gesture").draw() end, vim.tbl_extend("force", opts, { desc = "Draw gesture" }))
      map("n", "<S-LeftRelease>", function() require("gesture").finish() end, vim.tbl_extend("force", opts, { desc = "Finish gesture" }))

      -- Claude Code: connects the `claude` CLI to nvim as an IDE (WebSocket/MCP),
      -- so its edits show up as native diffs you accept/reject — like the GoLand plugin.
      require("claudecode").setup({
        terminal_cmd = "/opt/homebrew/bin/claude",
      })

      -- Trouble: a persistent "Problems" panel — all diagnostics grouped by file,
      -- live-updating, jump-to-code. Also renders quickfix/loclist/lsp/symbols.
      require("trouble").setup({})

      -- dadbod-ui: database client (sqlite/postgres/mysql/...). tpope-style, so
      -- configured via vim.g. Toggle the drawer with :DBUIToggle (Space D u).
      -- Add saved connections here, e.g.:
      --   vim.g.dbs = { { name = "local", url = "sqlite:" .. vim.fn.expand("~/app.db") } }
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_win_position = "left"

      local wk = require("which-key")
      wk.add({
        { "<leader>f", group = "Find" },
        { "<leader>ff", "<cmd>FzfLua files<CR>", desc = "Files" },
        { "<leader>fa", function() require("fzf-lua").files({ fd_opts = "--color=never --type f --hidden --follow --no-ignore --exclude .git" }) end, desc = "Files (incl. ignored)" },
        { "<leader>fg", "<cmd>FzfLua live_grep<CR>", desc = "Grep in project" },
        { "<leader>fr", "<cmd>FzfLua lsp_references<CR>", desc = "References (all usages)" },
        { "<leader>fc", function() require("fzf-lua").lsp_incoming_calls() end, desc = "Callers (incoming calls)" },
        { "<leader>fC", function() require("fzf-lua").lsp_outgoing_calls() end, desc = "Callees (outgoing calls)" },
        { "<leader>f/", "<cmd>FzfLua blines<CR>", desc = "Find in current file" },

        { "<leader>g", group = "Go to" },
        { "<leader>gd", vim.lsp.buf.definition, desc = "Definition" },
        { "<leader>gi", vim.lsp.buf.implementation, desc = "Implementation" },
        { "<leader>gt", vim.lsp.buf.type_definition, desc = "Type definition" },
        { "<leader>gl", goto_line, desc = "Go to line" },
        { "<leader>gb", function() vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-o>", true, false, true), "n", false) end, desc = "Back (previous position)" },
        { "<leader>gf", function() vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-i>", true, false, true), "n", false) end, desc = "Forward" },

        { "<leader>c", group = "Code" },
        { "<leader>ca", vim.lsp.buf.code_action, desc = "Action" },
        { "<leader>cr", vim.lsp.buf.rename, desc = "Rename" },
        { "<leader>cl", vim.lsp.codelens.run, desc = "Run code lens" },
        { "<leader>ck", vim.lsp.buf.hover, desc = "Show docs" },

        { "<leader>j", group = "Split / Join" },
        { "<leader>js", function() require("treesj").split() end, desc = "Split (args to separate lines)" },
        { "<leader>jj", function() require("treesj").join() end, desc = "Join (args to one line)" },
        { "<leader>jt", function() require("treesj").toggle() end, desc = "Toggle split/join" },

        { "<leader>d", vim.diagnostic.open_float, desc = "Diagnostic" },

        { "<leader>e", group = "Explorer" },
        { "<leader>eo", "<cmd>NvimTreeFocus<CR>", desc = "Focus tree" },
        { "<leader>eb", "<cmd>NvimTreeToggle<CR>", desc = "Toggle tree" },
        { "<leader>er", "<cmd>NvimTreeRefresh<CR>", desc = "Refresh tree" },

        { "<leader>b", group = "Buffers" },
        { "<leader>bb", "<cmd>FzfLua buffers<CR>", desc = "Open files" },
        { "<leader>br", "<cmd>FzfLua oldfiles<CR>", desc = "Recent files" },
        { "<leader>bn", "<cmd>BufferLineCycleNext<CR>", desc = "Next file" },
        { "<leader>bp", "<cmd>BufferLineCyclePrev<CR>", desc = "Previous file" },
        { "<leader>bd", close_buffer, desc = "Close file" },
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

        { "<leader>x", group = "Problems" },
        { "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Problems (this file)" },
        { "<leader>xX", "<cmd>Trouble diagnostics toggle<CR>", desc = "Problems (workspace)" },
        { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix panel" },
        { "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Location list panel" },
        { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<CR>", desc = "Symbols outline" },
        { "<leader>xv", function()
            vim.cmd("compiler go")
            vim.cmd("cexpr system('go vet ./...')")
            vim.cmd("Trouble qflist open")
          end, desc = "Vet project → panel" },

        { "<leader>D", group = "Database" },
        { "<leader>Du", "<cmd>DBUIToggle<CR>", desc = "Toggle DB drawer" },
        { "<leader>Da", "<cmd>DBUIAddConnection<CR>", desc = "Add connection" },
        { "<leader>Df", "<cmd>DBUIFindBuffer<CR>", desc = "Find query buffer" },
        { "<leader>Dr", "<cmd>DBUIRenameBuffer<CR>", desc = "Rename query buffer" },
        { "<leader>Dl", "<cmd>DBUILastQueryInfo<CR>", desc = "Last query info" },

        { "<leader>a", group = "AI / Claude" },
        { "<leader>ac", "<cmd>ClaudeCode<CR>", desc = "Toggle Claude" },
        { "<leader>af", "<cmd>ClaudeCodeFocus<CR>", desc = "Focus Claude" },
        { "<leader>ar", "<cmd>ClaudeCode --resume<CR>", desc = "Resume session" },
        { "<leader>aC", "<cmd>ClaudeCode --continue<CR>", desc = "Continue session" },
        { "<leader>am", "<cmd>ClaudeCodeSelectModel<CR>", desc = "Select model" },
        { "<leader>ab", "<cmd>ClaudeCodeAdd %<CR>", desc = "Add current buffer to context" },
        { "<leader>as", "<cmd>ClaudeCodeSend<CR>", desc = "Send selection", mode = "v" },
        { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<CR>", desc = "Accept diff" },
        { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<CR>", desc = "Deny diff" },

        { "<leader>w", "<cmd>write<CR>", desc = "Save" },
        { "<leader>q", "<cmd>confirm quit<CR>", desc = "Quit" },
        { "<leader>n", new_file, desc = "New file" },
      })

      local function show_menu()
        wk.show({ keys = "<leader>", loop = true })
      end

      map({ "n", "v" }, "<Space>", "<Nop>", opts)
      map("n", "?", show_menu, vim.tbl_extend("force", opts, { desc = "Command menu" }))
      map("n", "<F1>", show_menu, vim.tbl_extend("force", opts, { desc = "Command menu" }))
      map("i", "<F1>", show_menu, vim.tbl_extend("force", opts, { desc = "Command menu" }))
      map("v", "<F1>", show_menu, vim.tbl_extend("force", opts, { desc = "Command menu" }))

      map("n", "<C-n>", new_file, vim.tbl_extend("force", opts, { desc = "New file" }))
      map("i", "<C-n>", new_file, vim.tbl_extend("force", opts, { desc = "New file" }))
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
        pattern = { "*.go", "go.mod", "go.work", "*.rs" },
        callback = function()
          vim.lsp.codelens.refresh({ bufnr = 0 })
        end,
      })

      -- Turn on inlay hints for any server that provides them (rust-analyzer).
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
          end
        end,
      })

      vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "TermClose", "TermLeave" }, {
        callback = function()
          if vim.o.buftype == "" and vim.fn.mode() ~= "c" then
            vim.cmd("checktime")
          end
        end,
      })
    '';
  };
}
