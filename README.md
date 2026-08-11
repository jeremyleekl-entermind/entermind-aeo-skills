# entermind-aeo-skills

Transferable, **agent-agnostic** AEO/GEO skills and playbooks — Entermind
Malaysia Sdn Bhd.

Skills work with **any AI agent**: Claude Code, GPT/Codex, Gemini,
OpenClaw, Cursor, Hermes, or a plain shell. No credentials, no platform
dependencies — only `curl` and `python3`.

## Quick start

```bash
git clone https://github.com/jeremyleekl-entermind/entermind-aeo-skills.git
cd entermind-aeo-skills

# Option A — run a skill's probe directly (no install needed)
./skills/publisher-ai-crawlability-check/scripts/check_site.sh lobangsis lobangsis.com

# Option B — install into your agent's skills directory
./install.sh            # auto-detect: installs into every agent dir present
./install.sh --all      # install into all known agent dirs (creates them)
./install.sh --list     # show target dirs and install state
```

Agents that read `AGENTS.md` (GPT/Codex, Gemini, and most coding agents)
get the full usage guide automatically from this file. Agents with a
skills directory (Claude Code, OpenClaw, Cursor, Hermes) get the skill
installed via `install.sh` — symlinked by default so the repo stays the
single source of truth.

## Layout

```
AGENTS.md         # usage guide for any AI agent reading this repo
install.sh        # install skills into any agent's skills directory
skills/
  <skill-name>/
    SKILL.md          # the skill (frontmatter + procedure + pitfalls)
    README.md         # plain-language quick start (agent-agnostic)
    scripts/          # executable probes (curl + python3 only)
    references/       # deep-dive doctrine (added as skills mature)
```

## Skills

### publisher-ai-crawlability-check

Screen publishers/sites for AI-engine crawlability and citation
suitability: robots.txt (with real bot UAs + UA-sniffing detection),
llms.txt, sitemap, SSR/JSON-LD depth, deep-page bot tests, 5-tier
ranking rubric.

- `skills/publisher-ai-crawlability-check/SKILL.md`
- `skills/publisher-ai-crawlability-check/README.md`
- `skills/publisher-ai-crawlability-check/scripts/check_site.sh`

Usage: `./check_site.sh <name> <domain> [deep_url]`

Codified 2026-08-11 from the GXS publisher screening (14 SG publishers,
2026-08-05). Requires only curl + python3.

## Conventions

- Skills must be self-contained: the SKILL.md carries the full procedure,
  pitfalls, and worked example — no external wiki dependencies.
- Scripts must be dependency-light (curl, python3, standard shell).
- Version via the `version:` frontmatter field + changelog entries.
- License: MIT (per-skill frontmatter).
