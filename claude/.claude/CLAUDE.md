## Git Conventions

### Commits

Use **semantic commit messages**:

```
<type>: <short description>
```

Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `style`, `test`, `perf`, `ci`, `build`

- Subject line imperative, lowercase, no period (e.g. `feat: add battery warning to status bar`)
- Body optional — use for *why*, not *what*
- Never add `Co-Authored-By` trailers

### Branches

```
<type>/<issue-num>-short-description
```

Examples: `feature/42-add-worktree-tool`, `fix/17-stow-folding-bug`, `refactor/9-consolidate-zsh-plugins`

Types: `feature`, `fix`, `refactor`, `chore`, `docs`, `test`

### Remote Git (GitLab — adamatics/adalab)

All remote git operations for `adamatics/adalab` repos use **`glab`** (GitLab CLI), not `gh`.

```bash
# Issues
glab issue view 971 --repo adamatics/adalab-meta
glab issue list --repo adamatics/adalab-meta

# Merge requests
glab mr view 123 --repo adamatics/adalab-meta
glab mr list --repo adamatics/adalab-meta
glab mr create --repo adamatics/adalab-meta

# Comments
glab mr note 123 --repo adamatics/adalab-meta -m "comment"
```

Always pass `--repo adamatics/<project>` when not inside the repo directory.

