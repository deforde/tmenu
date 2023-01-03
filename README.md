# tmenu
A dmenu-inspired dynamic terminal-based application menu.

[![build](https://github.com/deforde/tmenu/actions/workflows/build.yml/badge.svg)](https://github.com/deforde/tmenu/actions/workflows/build.yml)
[![tests](https://github.com/deforde/tmenu/actions/workflows/test.yml/badge.svg)](https://github.com/deforde/tmenu/actions/workflows/test.yml)


![demo](https://user-images.githubusercontent.com/7503504/210376700-983837ae-6208-4529-8310-aa85827c6c4b.gif)


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
- Move ncurses code out of main.zig.
- Handle C ffi return codes correctly.
- Abstract away the need to manually allocate entry struct instances (similar to what was done for the test code).
- Possible features:
    - Fuzzy filtering.
    - vi bindings.
    - Other KB shortcuts (e.g. open man page etc.).
