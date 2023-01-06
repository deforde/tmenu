# tmenu
A dmenu-inspired dynamic terminal-based application menu.

[![build](https://github.com/deforde/tmenu/actions/workflows/build.yml/badge.svg)](https://github.com/deforde/tmenu/actions/workflows/build.yml)
[![tests](https://github.com/deforde/tmenu/actions/workflows/test.yml/badge.svg)](https://github.com/deforde/tmenu/actions/workflows/test.yml)


_A demonstration of the ncurses-based full screen tui_

![demo](https://user-images.githubusercontent.com/7503504/210788590-dd8212c7-d491-4425-891c-bf73f758bb2f.gif)


## Usage
To build and install `tmenu` to `$HOME/.local/bin`, simply run:
```
apt-get install libncurses-dev && \
zig build -Drelease-fast=true -p $HOME/.local install
```

To create a keymap to `tmenu` in `zsh`, add something along the lines of the following to your `.zshrc`:
```
bindkey -s '^u' 'tmenu^M'
```

By default, `tmenu` will use a 'light' tui menu implementation that does not clear the entire screen.
Should you prefer to use the `ncurses`-based full screen tui implementation, pass the `-f` or `--fullscreen` flag to `tmenu` on invocation.

### TODO
- Possible features:
    - Fuzzy filtering.
    - vi bindings.
    - Other KB shortcuts (e.g. open man page etc.).
