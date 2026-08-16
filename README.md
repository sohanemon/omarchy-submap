# Omarchy Submap

Hyprland submaps, surfaced in your Omarchy bar. This plugin is the home for
Sohan's submap tooling: today it ships a live submap indicator, and more
features will join it over time.

Submaps swap in a temporary keybinding layer — resize mode, a launch menu, a
vim-style leader key, and so on — but while one is active nothing tells you
your keys have changed. The indicator fixes that: it shows the active submap
in the bar as `--RESIZE--`, in the urgent accent color, and disappears the
moment you drop back to the default keymap.

## Install

```bash
omarchy plugin add https://github.com/sohanemon/omarchy-submap.git --enable
```

Pick a bar section when prompted (it defaults to `left`, next to the
workspaces). You can move it later with:

```bash
omarchy bar move io.github.sohanemon.submap --section center
```

## Uninstall

```bash
omarchy plugin remove io.github.sohanemon.submap
```

## How it works

The indicator subscribes to Hyprland's `submap` IPC event, so it updates the
instant a submap changes — no polling. On shell startup it also queries
`hyprctl submap` once, covering a shell restart that happens while a submap
is already active. In the default keymap the widget hides entirely and takes
no bar width.

## Requirements

Omarchy with the Quickshell-based shell (Omarchy 4.0 "quattro" or later).

## License

[MIT](LICENSE)
