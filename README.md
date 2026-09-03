# nvimconf

Personal dotfiles: Neovim config plus the rest of my Hyprland-based Linux desktop setup (Arch). Kept here so a fresh install can be reproduced by symlinking/copying each folder into place.

## Folders

- **nvim/** — Neovim config (`init.lua` + `lua/config/*`): LSP, completion (cmp), CodeCompanion, keymaps, options, plugin manager (lazy.nvim), snippets.
- **hypr/** — Hyprland window manager config (`hyprland.lua`), hyprlock screen-locker config, wallpapers, and a `deps_install.sh` to install required packages.
- **greetd/** — greetd login manager config: runs regreet inside a minimal Hyprland session (`config.toml`, `regreet.toml`, `hyprland.lua`) plus a `deps.sh` to install dependencies. See `greetd/README.md` for apply steps.
- **waybar/** — Waybar status bar config, style, and power-menu.
- **dunst/** — Dunst notification daemon config (`dunstrc`).
- **kitty/** — Kitty terminal config.
- **agents/** — Shared instructions for AI coding agents (e.g. `agents/common/brevity.md`).
- **skills/** — Agent skills (PR reviewers, Elixir/Python development, ast-grep search, etc.), installable standalone via `npx skills` (see [Skills](#skills)).
- **opencode/** — [opencode](https://opencode.ai) config: tools and its own `opencode.jsonc`.
- **.tmux.conf.local** — tmux config override.

## Usage

Each folder generally mirrors the target config location (e.g. `nvim/` → `~/.config/nvim`, `greetd/` → `/etc/greetd`). Check each subfolder's own `deps.sh`/`deps_install.sh`/README where present before copying/symlinking into place.

## Skills

Install skills from `skills/` into any project with the `skills` CLI:

```sh
# list available skills
npx skills add sonic182/nvimconf/ --list

# install one
npx skills add sonic182/nvimconf/ --skill elixir-development
```
