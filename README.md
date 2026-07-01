<h1 align="center">WallSync</h1>

<p align="center"><i>Pywal and Matugen support for NvChad, packaged as a Lazy-loadable plugin.</i></p>

> [!NOTE]
> WallSync is written in Lua and no longer needs the old Python watcher.
> You still need either `pywal` or `matugen` to generate the color files.

## Installation

Add WallSync to your NvChad Lazy specs, for example in `lua/plugins/init.lua`:

```lua
return {
  {
    "NvChad/WallSync",
    lazy = false,
    main = "wallsync",
    opts = {},
  },
}
```

Then select the `wallsync` theme in your NvChad config and generate your colors again:

```bash
wal -i <image>
```

WallSync installs the Pywal templates automatically, watches `~/.cache/wal/base46-dark.lua`, `~/.cache/wal/base46-light.lua`, and `~/.cache/wal/colors`, copies the active theme to NvChad's `base46/themes/wallsync.lua`, and reloads NvChad when the generated theme changes.

### Configuration

The default setup is enough for a standard NvChad installation. You can override paths if needed:

```lua
{
  "NvChad/WallSync",
  lazy = false,
  main = "wallsync",
  opts = {
    auto_start = true,
    auto_install_templates = true,
    notify = true,
    debounce_ms = 500,
    -- Optional: force "dark" or "light" if your generator does not update ~/.cache/wal/colors.
    mode = nil,
    -- Optional: path to the base46 plugin if it is NOT a sibling of WallSync.
    -- base46_path = vim.fn.expand "~/.local/share/nvim/lazy/base46",
    -- Optional: where Matugen templates are copied (used by matugen/config.toml).
    -- matugen_templates_dir = vim.fn.expand "~/.local/share/wallsync",
  },
}
```

Available commands:

- `:WallSyncInstallTemplates` copies the bundled Pywal templates to `~/.config/wal/templates` and the bundled Matugen templates to `~/.local/share/wallsync`.
- `:WallSyncStart` starts the file watchers for the current Neovim session.
- `:WallSyncSync` manually syncs the currently generated Base46 theme.
- `:WallSyncStop` stops the file watchers for the current Neovim session.

### Matugen support

WallSync copies its Matugen templates to `~/.local/share/wallsync` on first run (or whenever `:WallSyncInstallTemplates` is invoked), so the Matugen config below uses the same absolute path regardless of which plugin manager you use.

Add this to your `~/.config/matugen/config.toml` file:

```toml
[templates.nvim]
input_path = '~/.local/share/wallsync/matugen.lua'
output_path = '~/.cache/wal/base46-dark.lua'

[templates.nvimlight]
input_path = '~/.local/share/wallsync/matugen.lua'
output_path = '~/.cache/wal/base46-light.lua'

[templates.pywal]
input_path = '~/.local/share/wallsync/waltemplate'
output_path = '~/.cache/wal/colors'

[config.custom_colors.red]
color = "#FF0000"
blend = true

[config.custom_colors.green]
color = "#00FF00"
blend = true

[config.custom_colors.yellow]
color = "#FFFF00"
blend = true

[config.custom_colors.blue]
color = "#0000FF"
blend = true

[config.custom_colors.magenta]
color = "#FF00FF"
blend = true

[config.custom_colors.cyan]
color = "#00FFFF"
blend = true

[config.custom_colors.white]
color = "#FFFFFF"
blend = true
```

The `[templates.pywal]` entry is required even when using Matugen: WallSync
watches `~/.cache/wal/colors` and uses its first color to detect whether the
active generated theme is dark or light. If that file is missing or stale from a
previous Pywal run, WallSync may select an old `base46-light.lua` or
`base46-dark.lua` cache file. If you prefer to manage the mode yourself, set
`opts.mode` to `"dark"`, `"light"`, or a function that returns one of those
values.

The Matugen template also writes NvChad's `M.type` from Matugen's `{{ mode }}`
value, so the generated Base46 theme carries the same dark/light mode that
Matugen used for the color scheme.

Then generate your theme again:

```bash
matugen image <image>
```

Select `wallsync` theme and enjoy!

## Demo
https://github.com/user-attachments/assets/933c97f2-4566-406c-8c04-e2e9f0f3f6da
