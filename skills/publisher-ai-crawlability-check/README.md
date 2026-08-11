# publisher-ai-crawlability-check

Screen publishers or websites for **AI-engine crawlability and citation
suitability**: can GPTBot / ClaudeBot / PerplexityBot actually crawl the
site, and does the site expose the structured signals (llms.txt, sitemap,
JSON-LD, server-rendered text) that make it a viable AI citation source?

**Agent-agnostic.** No platform dependencies, no credentials, no profile
state. Requires only `curl` and `python3`. Works from any agent or shell:
Claude, GPT, Gemini, Hermes, a cron job, a CI pipeline — anything that can
run a shell script.

## Quick start

```bash
# 1. Probe a single site (writes results to ./<name>/)
./scripts/check_site.sh lobangsis lobangsis.com

# 2. Probe with a real article URL for the deep-page bot test
./scripts/check_site.sh comparesing comparesing.com https://comparesing.com/loans/compare

# 3. Repeat for every site in your list, then rank per the rubric in SKILL.md
```

## What the probe checks

1. **Canonical host** (www vs bare, redirect target)
2. **robots.txt** — HTTP status, disallow count, AI-agent rules
   (GPTBot, ClaudeBot, PerplexityBot, OAI-SearchBot, Google-Extended,
   CCBot, Bytespider, Applebot-Extended, meta-externalagent, ...)
3. **llms.txt** — status, size, generator signature
4. **sitemap.xml** (+ sitemap_index.xml / wp-sitemap.xml fallbacks)
5. **Homepage** — title, JSON-LD block count, visible-text chars,
   script bytes, SPA shell markers
6. **Deep page** (if a real URL is supplied) — HTTP status for GPTBot,
   ClaudeBot, and Chrome UAs, plus JSON-LD count

## The 8-step procedure (full detail in SKILL.md)

1. Reconcile the domain list (DNS check — wrong TLDs and dead domains
   are common traps)
2. Fetch robots.txt with a full Chrome header set
3. **UA-sniffing detection** — re-fetch robots.txt with real bot UAs and
   diff. Some sites serve a full block to browsers but a permissive file
   to bots (or vice versa). This is the single most important step.
4. Check llms.txt — inspect the BODY, not just the status code
5. Check sitemap (403/404 often means a WAF issue, not absence)
6. Homepage SSR depth (visible text vs script bytes)
7. Deep-page bot test with a REAL URL from the sitemap — never a guessed
   path. Retry 403s once: rate-limit vs persistent WAF block.
8. Rank per the 5-tier rubric

## Ranking rubric (5 tiers)

- **Tier 1 RECOMMEND** — open robots for real AI bots + working llms.txt
  + sitemap + JSON-LD
- **Tier 2 GOOD** — open + sitemap + JSON-LD, no llms.txt
- **Tier 3 MIXED** — crawlable but weak signals (no JSON-LD, broken
  sitemap, crawl-delay, WAF challenges)
- **Tier 4 THIN / INVISIBLE** — no crawlable article graph, JS-only nav
- **Tier 5 BLOCKED** — explicit AI-bot disallows or persistent deep-page
  403s to every bot

## Pitfalls (top 5 — full list in SKILL.md)

1. **`--compressed` is mandatory** when sending `Accept-Encoding: br` —
   otherwise saved files are binary garbage and every count is invalid.
2. **Full Chrome header set** needed to pass Cloudflare/Akamai
   fingerprinting (the script bakes this in).
3. **UA-sniffed robots.txt** — always fetch with at least 2 UAs.
4. **Deep-page 403: rate-limit vs WAF** — retry once before classifying.
5. **Wix sites** — hash-anchor nav, no sitemap, no robots.txt; check the
   `/_api/mcp` endpoint for agentic access.

## Files

- `SKILL.md` — full procedure, rubric, 10 pitfalls, worked example
  (14-publisher GXS screening, 2026-08-05)
- `scripts/check_site.sh` — the probe script

## License

MIT (see SKILL.md frontmatter).
