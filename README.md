# Caelestia Kitty Theme

Automatically generate a Kitty terminal color scheme from the active Caelestia color scheme.

This project connects **Caelestia CLI** with **Kitty** using Caelestia's `theme.postHook`. Whenever Caelestia applies a color scheme, the hook runs a small generator that reads the active palette from `scheme.json` and writes Kitty-compatible colors to `current-theme.conf`.

## What it does

The installer:

- Installs a theme generator at `~/.local/bin/caelestia-kitty-theme`.
- Reads the active Caelestia palette from `~/.local/state/caelestia/scheme.json` (or the XDG state directory, if configured).
- Generates Kitty background, foreground, selection, cursor, border, and 16 ANSI terminal colors.
- Registers the generator as `theme.postHook` in `~/.config/caelestia/cli.json`.
- Adds `include current-theme.conf` to Kitty's configuration so Kitty loads the generated palette.
- Generates the current theme once during installation.

The installer preserves other settings in an existing `cli.json` and avoids adding the Kitty include more than once. Before modifying an existing `cli.json` or `kitty.conf`, it creates a timestamped backup next to that file.

## Requirements

- Caelestia CLI with support for the `theme.postHook` setting.
- Kitty terminal.
- `jq`.

On Arch Linux and CachyOS, install the dependency with:

```bash
sudo pacman -S jq
```

## Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/KangSantuy17/caelestia-kitty-theme.git
cd caelestia-kitty-theme
chmod +x install.sh
./install.sh
```

The installer does not require root privileges. It only changes files inside your home directory.

After installation, restart Kitty or reload its configuration with `Ctrl+Shift+F5`.

## Usage

Choose a wallpaper using the Caelestia launcher:

1. Open the Caelestia launcher.
2. Search for `>Wallpaper`.
3. Select a wallpaper.

When Caelestia applies the resulting color scheme, its `postHook` runs the Kitty theme generator and updates `~/.config/kitty/current-theme.conf`.

Kitty reads the generated file through the include added to `kitty.conf`. Existing Kitty windows may need a configuration reload to display newly generated colors.

## Files created or modified

| Path | Purpose |
| --- | --- |
| `~/.local/bin/caelestia-kitty-theme` | Generates the Kitty color configuration. |
| `~/.config/kitty/current-theme.conf` | Generated Kitty palette. |
| `~/.config/caelestia/cli.json` | Registers the generator as Caelestia's `theme.postHook`. |
| `~/.config/kitty/kitty.conf` | Includes the generated palette. |

## Backups

If `cli.json` or `kitty.conf` already exists, the installer creates a timestamped backup before modifying it. For example:

```text
cli.json.bak.20261031-185500
kitty.conf.bak.20261031-185500
```

## Troubleshooting

- Make sure `jq` is installed.
- Make sure Caelestia CLI has generated `scheme.json`.
- Check that `theme.postHook` is present in `~/.config/caelestia/cli.json`.
- If Kitty still shows the previous palette, reload its configuration with `Ctrl+Shift+F5` or restart Kitty.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
