# Bar Hints

Keyboard hints for the Omarchy bar. Press `Super+B`, then type a visible
widget's number to open it without reaching for the mouse.

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

## Remove

Delete the `Super+B` binding, then run:

```sh
omarchy plugin remove io.github.hanssound.bar-hints
```
