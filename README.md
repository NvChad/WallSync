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
    "Axenide/WallSync",
    lazy = false,
    main = "wallsync",
    opts = {},
  },
}
```

Then select the `chadwal` theme in your NvChad config and generate your colors again:

```bash
wal -i <image>
```

WallSync installs the Pywal templates automatically, watches `~/.cache/wal/base46-dark.lua` and `~/.cache/wal/base46-light.lua`, copies the active theme to NvChad's `base46/themes/chadwal.lua`, and reloads NvChad when the generated theme changes.

### Configuration

The default setup is enough for a standard NvChad installation. You can override paths if needed:

```lua
{
  "Axenide/WallSync",
  lazy = false,
  main = "wallsync",
  opts = {
    auto_start = true,
    auto_install_templates = true,
    notify = true,
    debounce_ms = 500,
  },
}
```

Available commands:

- `:WallSyncInstallTemplates` copies the bundled Pywal templates to `~/.config/wal/templates`.
- `:WallSyncStart` starts the file watchers for the current Neovim session.
- `:WallSyncSync` manually syncs the currently generated Base46 theme.
- `:WallSyncStop` stops the file watchers for the current Neovim session.

### Matugen support

Add this to your `~/.config/matugen/config.toml` file:

```toml
[templates.nvim]
input_path = '~/.local/share/nvim/lazy/WallSync/templates/matugen.lua'
output_path = '~/.cache/wal/base46-dark.lua'

[templates.nvimlight]
input_path = '~/.local/share/nvim/lazy/WallSync/templates/matugen.lua'
output_path = '~/.cache/wal/base46-light.lua'

[templates.pywal]
input_path = '~/.local/share/nvim/lazy/WallSync/templates/waltemplate'
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

If your Lazy install path or repository directory name is different, update the three `input_path` values accordingly. Then generate your theme again:

```bash
matugen image <image>
```

Select `chadwal` theme and enjoy!

## Demo
https://github.com/user-attachments/assets/933c97f2-4566-406c-8c04-e2e9f0f3f6da
