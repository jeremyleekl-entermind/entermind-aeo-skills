# entermind-aeo-skills

Transferable AEO/GEO agent skills and playbooks — Entermind Malaysia Sdn Bhd.

Canonical home for agent skills that are **agent-agnostic**: no profile
state, no wiki writes, no credentials. Any Hermes agent (orchestrator,
kanban workers, delegate_task subagents, cron jobs) can load and run them.

## Layout

```
skills/
  <skill-name>/
    SKILL.md          # the skill (frontmatter + procedure + pitfalls)
    scripts/          # executable probes (curl + python3 only)
    references/       # deep-dive doctrine (added as skills mature)
```

## Install

Copy a skill directory into `~/.hermes/skills/<category>/` (or the
equivalent skills root for the target agent profile), then verify with
`skills_list` / `skill_view`.

## Skills

### publisher-ai-crawlability-check

Screen publishers/sites for AI-engine crawlability and citation
suitability: robots.txt (with real bot UAs + UA-sniffing detection),
llms.txt, sitemap, SSR/JSON-LD depth, deep-page bot tests, 5-tier
ranking rubric.

- `skills/publisher-ai-crawlability-check/SKILL.md`
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
