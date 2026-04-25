# Install

## Prerequisites

- Claude Code (any recent version with marketplace support).
- Obsidian (optional but recommended for browsing the vault).
- A directory under `~/Documents/` you can write to. Default vault root: `~/Documents/obsidian/claude/`.

## Method 1 — from a published GitHub repo

```text
/marketplace add anunay999/scribe
/install scribe@scribe
/scribe-bootstrap
```

(Replace `anunay999` with whatever owner you publish under.)

## Method 2 — from a local checkout (development)

```bash
git clone https://github.com/<you>/scribe ~/dev/scribe
```

Then in any Claude Code session:

```text
/marketplace add ~/dev/scribe
/install scribe@scribe
/scribe-bootstrap
```

## Method 3 — manual symlink (fastest for local hacking)

```bash
ln -s ~/dev/scribe/plugins/scribe ~/.claude/plugins/local/scribe
```

Skills and commands become available immediately. Edit `SKILL.md` files and they hot-reload on next session.

## Verify

In a Claude Code session:

```text
/help
```

Look for `bootstrap`, `ingest`, `query`, `lint`, `update`. If they're missing, run `/marketplace reload` and try again.

## Uninstall

```text
/uninstall scribe
/marketplace remove scribe
```

The vault on disk is untouched — uninstall only removes Claude Code's plugin registration. Delete the vault by hand if you want it gone.

## Troubleshooting

**`/scribe-bootstrap` says it can't write to `~/Documents/`.** macOS sandboxing on the Claude Code binary may block reads but allow writes. The skill detects this and proceeds; check with `test -d ~/Documents/obsidian/claude/`. If writes truly fail, pick a vault root outside `~/Documents/` (`~/notes/`, `~/dev/wiki/`, etc.).

**Skills don't appear after install.** `/marketplace reload` then restart the Claude Code session. The skill registry is read at session start.

**`ingest` keeps re-fetching the same URL.** Check `sources/<slug>.md` exists. If the slug differs from what the skill picked, rename the file or pass a custom slug: `/scribe-ingest <url> --slug=my-slug` (planned for v0.2; today, paste with the slug embedded).

**Vault graph view in Obsidian is empty.** Open `WIKI.md`, `index.md`, `log.md` once — Obsidian indexes lazily. The graph populates after at least one page has been viewed.
