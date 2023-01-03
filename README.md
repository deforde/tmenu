# tmenu
A dmenu-inspired dynamic terminal-based application menu.

[![build](https://github.com/deforde/tmenu/actions/workflows/build.yml/badge.svg)](https://github.com/deforde/tmenu/actions/workflows/build.yml)
[![tests](https://github.com/deforde/tmenu/actions/workflows/test.yml/badge.svg)](https://github.com/deforde/tmenu/actions/workflows/test.yml)


![demo](https://user-images.githubusercontent.com/7503504/210374311-553c63ab-429b-426c-a333-2be80771158a.gif)


## Usage
To build `tmenu`, simply run:
```
zig build -Drelease-fast=true
```

With `tmenu` on your `PATH`, to create a keymap to `tmenu` in `zsh`, add something along the lines of the following to your `.zshrc`:
```
bindkey -s '^u' 'tmenu^M'
```

### TODO
- Add installation recipe to build script and update readme accordingly.
- Switch from GeneralPurposeAllocator to something more performant.
- Tidy up build script.
- Move ncurse code out of main.zig.
- Possible features:
    - Fuzzy filtering.
    - vi bindings.
    - Other KB shortcuts (e.g. open man page etc.).
