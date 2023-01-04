# tmenu
A dmenu-inspired dynamic terminal-based application menu.

[![build](https://github.com/deforde/tmenu/actions/workflows/build.yml/badge.svg)](https://github.com/deforde/tmenu/actions/workflows/build.yml)
[![tests](https://github.com/deforde/tmenu/actions/workflows/test.yml/badge.svg)](https://github.com/deforde/tmenu/actions/workflows/test.yml)


![demo](https://user-images.githubusercontent.com/7503504/210376700-983837ae-6208-4529-8310-aa85827c6c4b.gif)


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

### TODO
- Handle C ffi return codes correctly.
- Possible features:
    - Fuzzy filtering.
    - vi bindings.
    - Other KB shortcuts (e.g. open man page etc.).
