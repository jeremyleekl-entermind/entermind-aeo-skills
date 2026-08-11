# AGENTS.md — for AI agents reading this repository

This repository is a library of **agent-agnostic AEO/GEO skills**. Every
skill is a folder containing `SKILL.md` (full procedure) + `README.md`
(quick start) + `scripts/` (executable probes). No credentials, no
platform dependencies — only `curl` and `python3`.

## How to use a skill

1. Read `skills/<name>/SKILL.md` — it is self-contained: procedure,
   rubric, pitfalls, worked example.
2. Run the probe script directly:
   `skills/<name>/scripts/<script> <args>` (see the skill's README).
3. Or install the skill into your agent's skills directory:

```bash
./install.sh            # auto-detect: installs into every agent dir present
./install.sh --all      # install into all known agent dirs (creates them)
./install.sh --copy     # copy instead of symlink (default is symlink)
./install.sh --list     # show target dirs and install state
```

## Install targets

| Agent | Directory | Notes |
|---|---|---|
| Claude Code | `~/.claude/skills/` | personal skills root |
| OpenClaw | `~/.openclaw/skills/` | managed skills root |
| OpenClaw (shared) | `~/.agents/skills/` | personal cross-agent root |
| Cursor | `~/.cursor/skills/` | global skills root |
| Hermes | `~/.hermes/skills/productivity/` | category subdir |
| GPT / Codex, Gemini CLI | — | no skills dir; read AGENTS.md + SKILL.md directly |

## Skills in this repo

- **publisher-ai-crawlability-check** — screen publishers/sites for
  AI-engine crawlability and citation suitability (robots.txt with real
  bot UAs, UA-sniffing detection, llms.txt, sitemap, SSR/JSON-LD depth,
  deep-page bot tests, 5-tier ranking). Script:
  `skills/publisher-ai-crawlability-check/scripts/check_site.sh <name> <domain> [deep_url]`

## Conventions

- Canonical home is this repository. Local installs are symlinks (or
  copies with `--copy`) — update everything with `git pull` + re-run
  `./install.sh`.
- Skills must stay dependency-free: `curl` + `python3` only, no
  credentials, no platform-specific config.
- New skills: add `skills/<name>/` with `SKILL.md` (frontmatter: name,
  description, version, license, platforms, tags) + `README.md` +
  `scripts/` as needed.
