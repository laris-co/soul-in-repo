# attic/soul-idea: retired 2026-11-09

`soul-idea.sh` gave `herdr-soul idea` / `convert` (also `maw soul idea` / `convert`), added in PR #17 on 2026-11-07:

- **idea:** a channel `💡・<idea>`, one thread per soul, and a scratch dir as each soul's body. No repo yet.
- **convert:** turned the idea into a repo. It renamed the channel to `📦・<owner>∕<repo>` and rebuilt each soul in `<repo>/wt`.

## Why it is retired

The rooms ladder (Nat, 2026-11-09, "yes go make all!") already covers both steps, and with less machinery:

1. **talk** `!!name @Bot …` opens a brainstorm thread wherever it is typed. Tagged bots join. No repo, no worktree, no scratch body to clean up later.
2. **promote** `/promote` (`herdr-soul promote`, `soul-promote.sh`) turns that talk into a repo, its 📦 room and the souls picked.
3. **work** `/work` · `/wt`
4. **done** `/done`

The script never ran with `--yes`; only dry runs were made. Nothing live depends on it: no Laris row with `mode: idea` exists, and the verbs now print the retired message and exit 2.

The file stays here as history (Nothing is Deleted). Do not run it: its paths (`$HERE/bin/…`, `$HERE/soul-in-repo.sh`) assume the repo root.
