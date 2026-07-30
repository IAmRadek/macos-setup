# Neovim Keybindings

Config: [`modules/nvim.nix`](modules/nvim.nix) · [`modules/ghostty.nix`](modules/ghostty.nix)
Leader = `Space`. Open the menu with **`?`** or **`F1`**, then type the letters below.

## 1. `Space` menu (which-key)

### `Space f` — Find
| Keys | Action |
|---|---|
| `Space f f` | Files |
| `Space f a` | Files (incl. gitignored) |
| `Space f g` | Grep across project |
| `Space f r` | References (all usages) |
| `Space f c` | Callers (incoming calls) |
| `Space f C` | Callees (outgoing calls) |
| `Space f /` | Find in current file |

### `Space g` — Go to
| Keys | Action |
|---|---|
| `Space g d` | Definition |
| `Space g i` | Implementation |
| `Space g t` | Type definition |
| `Space g l` | Go to line |
| `Space g b` | Back (previous position) |
| `Space g f` | Forward |

### `Space c` — Code
| Keys | Action |
|---|---|
| `Space c a` | Code action |
| `Space c r` | Rename symbol |
| `Space c l` | Run code lens |
| `Space c k` | Show docs (hover) |

### `Space e` — Explorer
| Keys | Action |
|---|---|
| `Space e o` | Focus tree |
| `Space e b` | Toggle tree |
| `Space e r` | Refresh tree |

### `Space b` — Buffers
| Keys | Action |
|---|---|
| `Space b b` | Open files |
| `Space b r` | Recent files |
| `Space b n` | Next file |
| `Space b p` | Previous file |
| `Space b d` | Close file |
| `Space b o` | Close others |

### `Space h` — Git
| Keys | Action |
|---|---|
| `Space h p` | Preview change |
| `Space h r` | Rollback change |
| `Space h s` | Stage change |
| `Space h b` | Blame line |
| `Space h n` | Next change |
| `Space h N` | Previous change |
| `Space h d` | Diff this file |
| `Space h B` | Toggle inline blame |

### `Space x` — Problems (trouble.nvim)
A persistent panel listing diagnostics grouped by file, live-updating; `Enter` jumps to code. `q` closes the panel.

| Keys | Action |
|---|---|
| `Space x x` | Problems in this file |
| `Space x X` | Problems across workspace |
| `Space x q` | Quickfix as panel |
| `Space x l` | Location list as panel |
| `Space x s` | Symbols outline (follows buffer) |
| `Space x v` | `go vet ./...` whole project → panel |

> Note: LSP (gopls) only reports problems for **open files + their packages**. `Space x v` runs `go vet` over the whole module into quickfix for a true project-wide sweep — swap in `golangci-lint run` if you prefer.

### `Space D` — Database (dadbod-ui)
A DB client drawer (sqlite/postgres/mysql/…). SQLite works out of the box; postgres/mysql need `psql`/`mysql` on PATH.

| Keys | Action |
|---|---|
| `Space D u` | Toggle DB drawer |
| `Space D a` | Add a connection (prompts for URL) |
| `Space D f` | Find/switch query buffer |
| `Space D r` | Rename query buffer |
| `Space D l` | Last query info |

**Inside the drawer:** `Enter`/`o` expand a connection → database → tables. Open a table to preview it, 
or open a scratch SQL buffer, write a query, and run it with **`Space S`** (normal, whole buffer) or select SQL + **`Space S`** (visual). 

Results open in a split.

**Saved connections:** add them in `modules/nvim.nix` via `vim.g.dbs`, e.g.
`vim.g.dbs = { { name = "local", url = "sqlite:" .. vim.fn.expand("~/app.db") } }`. Or add ad-hoc with `Space D a`.

### `Space a` — AI / Claude Code
Connects the `claude` CLI to nvim as an IDE (WebSocket/MCP) — edits appear as native accept/reject diffs, like the GoLand plugin.

| Keys | Action |
|---|---|
| `Space a c` | Toggle Claude terminal (auto-connects to this nvim) |
| `Space a f` | Focus Claude |
| `Space a r` | Resume a previous session |
| `Space a C` | Continue last session |
| `Space a m` | Select model |
| `Space a b` | Add current buffer to context |
| `Space a s` | Send selection (visual mode) |
| `Space a a` | Accept proposed diff |
| `Space a d` | Deny proposed diff |

**Flow:** `Space a c` to open → select code + `Space a s` (or `Space a b` for whole buffer) to share → Claude's edits open as a diff → `Space a a` accept / `Space a d` reject. Selection + diagnostics are shared automatically while connected (`:ClaudeCodeStatus` to check).

### Top level
| Keys | Action |
|---|---|
| `Space d` | Diagnostic float |
| `Space w` | Save |
| `Space q` | Quit |
| `Space n` | New file |

## 2. Editing chords

Each works as **`Ctrl+key`** *or* **`Cmd+key`** — Ghostty forwards Cmd → Ctrl.

| Keys | Action | Modes |
|---|---|---|
| `Ctrl/Cmd + s` | Save | n / i / v |
| `Ctrl/Cmd + z` | Undo | n / i |
| `Ctrl/Cmd + y` | Redo | n / i |
| `Ctrl/Cmd + a` | Select all | n / i / v |
| `Ctrl + c` | Copy line / selection | n / v |
| `Ctrl/Cmd + x` | Cut line / selection | n / v |
| `Ctrl + v` | Paste | n / v / i |
| `Ctrl + Shift + k` | Delete line / selection | n / i / v |
| `Ctrl/Cmd + Backspace`, `Ctrl + h`, `Ctrl + u` | Delete previous word | i |
| `Ctrl/Cmd + Delete` | Delete next word | i |
| `Ctrl/Cmd + f` | Find (starts `/` search) | n / i / v |
| `Ctrl/Cmd + p` | Find files | n / i |
| `Ctrl + q` | Quit | n / i / v |
| `Ctrl + n` | New file | n / i |
| `Ctrl + o` | Focus file tree | n / i |
| `Ctrl + b` | Toggle file tree | n / i |
| `Ctrl + Space` | Show docs (hover) | n |
| `Ctrl + .` | Code action | n |
| `Ctrl + d` | Show diagnostic | n |
| `F2` | Rename symbol | n |
| `F5` | Run code lens | n |
| `?` / `F1` | Open command menu | n (F1 also i / v) |

## 3. Mouse & gestures

| Gesture | Action |
|---|---|
| `Opt + click` | Go to definition |
| `Opt + Shift + click` | Find references |
| `Shift + drag ← / →` | Jumplist back / forward |
| plain drag | Select text |

## 4. Completion popup

Appears as you type (ghost text enabled).

| Keys | Action |
|---|---|
| `Tab` | Accept / next item |
| `Shift + Tab` | Previous item |
| `Ctrl + Space` | Show / toggle documentation |

## 5. Vim movements (built-in)

These are standard Vim motions — available in **normal** and **visual** modes. Prefix any of them with a **count** to repeat (e.g. `5j` = down 5 lines, `3w` = forward 3 words). Most also work as an *operator target*: `d`/`c`/`y` + motion (e.g. `dw` delete word, `c$` change to end of line, `y}` yank paragraph).

### Left / right (within a line)
| Keys | Motion |
|---|---|
| `h` / `l` | Left / right one char |
| `0` | First column |
| `^` | First non-blank char |
| `$` | End of line |
| `g_` | Last non-blank char |
| `f{c}` / `F{c}` | To next / prev `{c}` on line |
| `t{c}` / `T{c}` | Till before next / after prev `{c}` |
| `;` / `,` | Repeat last `f/t` forward / backward |
| `\|` | To column N (`20\|`) |

### Up / down (lines)
| Keys | Motion |
|---|---|
| `j` / `k` | Down / up one line |
| `+` / `-` | First non-blank of next / prev line |
| `G` | Last line (`10G` = line 10) |
| `gg` | First line |
| `H` / `M` / `L` | Top / middle / bottom of screen |
| `{` / `}` | Prev / next blank-line paragraph |
| `Ctrl+d` / `Ctrl+u` | Half-page down / up *(see note)* |
| `Ctrl+f` / `Ctrl+b` | Full page down / up *(see note)* |

> Note: your config remaps `Ctrl+d` (diagnostic), `Ctrl+f` (find), `Ctrl+b` (file tree) and `Ctrl+u` (delete word, insert). For scrolling use `zz`/`zt`/`zb` to recenter, or `}`/`{`, or `G`/`gg`.

### Words
| Keys | Motion |
|---|---|
| `w` / `b` | Start of next / prev word |
| `e` / `ge` | End of next / prev word |
| `W` `B` `E` | Same, WHITESPACE-delimited (ignores punctuation) |

### Jumps & search
| Keys | Motion |
|---|---|
| `%` | Matching `()`, `[]`, `{}` |
| `*` / `#` | Next / prev occurrence of word under cursor |
| `/text` / `?text` | Search forward / backward |
| `n` / `N` | Next / prev search match |
| `` `` `` | Back to position before last jump |
| `Ctrl+o` / `Ctrl+i` | Jumplist back / forward |
| `''` | To line of last jump |

### Text objects (use with `d` / `c` / `y` / `v`)
| Keys | Object |
|---|---|
| `iw` / `aw` | Inner / a word |
| `i"` `a"` / `i'` `a'` | Inside / around quotes |
| `i(` `i)` `ib` | Inside parens (`ab` = around) |
| `i{` `i}` `iB` | Inside braces (`aB` = around) |
| `i[` / `it` | Inside brackets / HTML tag |
| `ip` / `ap` | Inner / a paragraph |

Examples: `ciw` change word · `di"` delete inside quotes · `ya(` yank around parens · `vi{` select inside braces.

## Gotchas

- **`Option + ← / →` (back/forward) does not work** — Ghostty rewrites `alt+left`/`alt+right` into shell word-motion bytes, so nvim never receives them. Use `Space g b` / `Space g f` or the Shift-drag gesture.
- **`Cmd + S` at the shell prompt freezes the terminal** (XOFF) and **`Cmd + Z` at the shell suspends the process** — safe inside nvim, risky at the bare prompt.
- **`Cmd + ← / →`** send `Ctrl-A` / `Ctrl-E` (shell line start/end); inside nvim they collide with select-all / scroll.
