# Bar Hints

Keyboard hints for the Omarchy bar. Press `Super+B`, then type a visible
widget's number to open it without reaching for the mouse.

![Bar Hints labelling every openable widget on the Omarchy bar](preview.png)

## Install

```sh
omarchy plugin add https://github.com/hanssound/omarchy-bar-hints.git --enable
```

Add the binding to `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + B", "Bar icon hints",
  "omarchy-shell shell toggle io.github.hanssound.bar-hints '{}'")
```

## Use

| Input | Action |
|---|---|
| number | Open the matching bar widget |
| Backspace | Remove the last typed digit |
| Escape or background click | Dismiss |

Hover a hint to show the widget name. Hidden and non-interactive widgets are
not labeled.

## Requirements and limitations

- Omarchy 4 with the stock Omarchy bar.
- The plugin reads live stock-bar internals; custom replacement bars are not
  supported.
- Multi-monitor filtering follows the monitor focused when the overlay opens.
  This is implemented but has only been tested on a single display; behaviour
  with two or more monitors, or with mixed scale factors, is unverified.

Tested on Omarchy 4.0.1-1 with Hyprland on one 1920x1200 display, with the bar
on all four edges (top, bottom, left, right).

## Remove

Delete the `Super+B` binding, then run:

```sh
omarchy plugin remove io.github.hanssound.bar-hints
```
