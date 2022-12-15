# tmenu
A dmenu-inspired dynamic terminal-based application menu.


### TODO
- Add tests for Entry and EntryList related code.
- Implement (and add tests for) arena allocator.
- Add GitHub CI.
- Add code quality analysis.
- Implement real-time filtering via the following phases:
    - Take in a filter string via command line args.
    - Filter in real-time as the user types (multi-threaded?).
    - Display filtered results menu using ncurses.
    - Implement filtration caching?
- Long term feature possibilities:
    - Fuzzy filtering.
    - vi bindings.
    - Other KB shortcuts (e.g. open man page etc.).
