Directory layout
================

- Hosts live under `systems/<arch>/<host>/`.
- For clearer roles, consider grouping by environment, e.g.
  `systems/x86_64-linux/prod/<host>/` vs `systems/x86_64-linux/lab/<host>/`.
- Keep per-host templates in `templates/` alongside the environment they belong to.

This README is a guide only—no functional changes are enforced.***
