# tmenu
A dmenu-inspired dynamic terminal-based application menu.

[![build](https://github.com/deforde/tmenu/actions/workflows/build.yml/badge.svg)](https://github.com/deforde/tmenu/actions/workflows/build.yml)
[![tests](https://github.com/deforde/tmenu/actions/workflows/test.yml/badge.svg)](https://github.com/deforde/tmenu/actions/workflows/test.yml)


## Usage
To build `tmenu`, simply run:
```
zig build
```

With `tmenu` on your `PATH`, to create a keymap to `tmenu` in `zsh`, add something along the lines of the following to your `.zshrc`:
```
bindkey -s '^u' 'tmenu^M'
```

### TODO
- Add gif to demo `tmenu` usage.
- Add installation recipe to build script and update readme accordingly.
- Fix CI build and tests.
- Switch from GeneralPurposeAllocator to something more performant.
- Tidy up build script.
- Possible features:
    - Fuzzy filtering.
    - vi bindings.
    - Other KB shortcuts (e.g. open man page etc.).
