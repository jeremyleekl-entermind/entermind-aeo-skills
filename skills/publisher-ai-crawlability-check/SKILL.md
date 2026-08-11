---
name: publisher-ai-crawlability-check
description: "Use when screening publishers for AI crawlability."
version: 1.0.0
author: "orchestrator (Jeremy Lee, Head of AEO/GEO Strategy), Entermind Malaysia Sdn Bhd"
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [aeo, geo, crawlability, robots-txt, llms-txt, ai-citation, publisher-screening, gptbot, claudebot, json-ld, sitemap, ssr, wix, cloudflare]
    category: productivity
    related_skills: [geo-prospect-pitch-development, enterrank-brand-visibility-audit, entercrawl-audit-pipeline]
changelog:
  - "1.0.0 (2026-08-11): Initial skill. Codified from the GXS publisher screening session (2026-08-05): 14 SG publishers checked (Lobangsis, Suitesmile, MoneySmart, SingSaver, CompareSing, DiveDeals, Sethisfy, AsiaOne, The Edge, Lendingpot, Honeymoney, Mothership, Geek Culture, Vulcan Post). 8-step procedure, 5-tier ranking rubric, 10 pitfalls, worked example. Agent-agnostic: curl + python3 only, no profile/wiki/credential state."
---

# Publisher AI-Crawlability Check

Screen a publisher or site list for **AI-engine crawlability and citation
suitability** — can GPTBot / ClaudeBot / PerplexityBot actually crawl the
site, and does the site expose the structured signals (llms.txt, sitemap,
JSON-LD, SSR text) that make it a viable AI citation source?

This is the technical-access check. It answers "can AI engines cite this
site?" — NOT "is this site visible on query X?" (that is a separate
share-of-voice scan, not this skill).

## When to use

- The operator asks to check / rank a list of publishers or sites for AI
  citation suitability (e.g. "are these good GXS publishers?")
- Pre-GEO-outreach due diligence on a media/publisher list
- Screening a prospect's own site before a pitch (does the client's site
  pass its own crawlability test?)
- Any "is X crawlable by AI" question about technical access, not query
  share of voice

## The 8-step procedure

1. **Pre-condition: reconcile the domain list.** Verify DNS
   via dns.google DoH (`https://dns.google/resolve?name=<domain>&type=A`),
   canonical host (www vs bare), and correct TLD. Wrong-domain traps seen
   in the wild: `lendingpot.com.sg` does not resolve (only `lendingpot.sg`
   does); `lobangsis.sg` has no records (only `.com`); "GeekSing" does not
   exist as an SG publisher (the real site is Geek Culture,
   `geekculture.co`). Resolve the list BEFORE any fetch.

2. **robots.txt with a Chrome UA.** Fetch with the full Chrome header set
   (see script). Count disallow lines, grep for AI-agent rules: GPTBot,
   ClaudeBot, PerplexityBot, OAI-SearchBot, ChatGPT-User, Google-Extended,
   CCBot, Bytespider, Applebot-Extended, meta-externalagent, anthropic,
   ai2bot, cohere.

3. **UA-sniffing detection.** Re-fetch robots.txt with GPTBot and ClaudeBot
   UAs and diff against the Chrome-UA fetch. AsiaOne pattern: a generic
   browser UA receives `User-agent: * Disallow: /` (full block) while real
   bot UAs receive the permissive file. If the files differ, the site
   UA-sniffs — record which UAs are actually allowed. This is the single
   most important step for citation verdicts.

4. **llms.txt.** HTTP status + bytes + generator signature (Rank Math /
   Yoast / custom). A 200 with real content is a strong signal (Lobangsis
   97 KB custom, Suitesmile 29 KB Rank Math). Check the BODY, not just the
   status: MoneySmart returns HTTP 500 with a Nuxt error page; a 200 can
   also be an HTML error page in disguise.

5. **Sitemap.** `sitemap.xml`; if 404, try `sitemap_index.xml`,
   `wp-sitemap.xml`, and Yoast variants. 403/404 on sitemaps usually means
   a Cloudflare/WAF issue (The Edge pattern) — the site may be crawlable
   but discovery is broken.

6. **Homepage.** Title, JSON-LD block count, visible-text chars, script
   bytes, SPA shell markers. Rule of thumb: SSR visible text > 5K chars
   with low script bytes = good. Heavy JS with thin SSR text = AI crawlers
   will time out (SSR is a table-stake for AI crawlability).

7. **Deep-page bot test.** Pull a REAL URL from the sitemap (never a
   guessed path — a 404 on a guess is not a bot block). Test with GPTBot,
   ClaudeBot, and Chrome UAs. Distinguish **rate-limit 403** (retry once
   after a few seconds; Lobangsis pattern — first hit 403, retry 200) from
   **persistent WAF block** (Suitesmile pattern — ClaudeBot 403 on retry
   while GPTBot passes). Count JSON-LD on the deep page — homepage JSON-LD
   does not predict article-page JSON-LD.

8. **Rank** per the rubric below. Deliver as a ranked table with the
   evidence columns (AI-bot access, llms.txt, sitemap, JSON-LD, verdict).

## Ranking rubric (5 tiers)

- **Tier 1 RECOMMEND** — open robots for real AI bots + working llms.txt +
  sitemap + JSON-LD. (Lobangsis, Suitesmile)
- **Tier 2 GOOD** — open + sitemap + JSON-LD, no llms.txt. (CompareSing,
  DiveDeals, Sethisfy)
- **Tier 3 MIXED** — crawlable but weak signals: no JSON-LD, broken
  sitemap, crawl-delay throttling, or WAF challenges that need full
  headers. (MoneySmart, SingSaver, AsiaOne, The Edge)
- **Tier 4 THIN / INVISIBLE** — minimal content graph: no crawlable
  article URLs, JS-only nav, no sitemap. (Lendingpot, Honeymoney)
- **Tier 5 BLOCKED** — explicit AI-bot disallows (Vulcan Post, Geek
  Culture block all 7 major AI crawlers) or persistent deep-page 403s to
  every bot (Mothership).

## Pitfalls (10)

1. **`--compressed` is mandatory** when sending `Accept-Encoding: br`.
   Without it, saved robots/home files are br-compressed binary garbage and
   every grep count is invalid. This bug cost a full re-run in the GXS
   session.
2. **Full Chrome header set needed for Cloudflare/Akamai.** MoneySmart:
   403 to plain curl, 200 with the 12-header set (Sec-Ch-Ua, Sec-Fetch-*,
   etc.). The script bakes this in.
3. **UA-sniffed robots.txt.** Always fetch robots with at least 2 UAs
   (Chrome + one bot). AsiaOne serves a full block to browsers and a
   permissive file to bots — the reverse is also possible.
4. **Deep-page 403: rate-limit vs WAF.** Retry once after a pause. A
   single 403 is not a verdict; a persistent 403 on retry is.
5. **Wix sites.** Hash-anchor nav (#about, #deals), no static internal
   links, no sitemap, no robots.txt. Check the Wix MCP endpoint
   (`/_api/mcp`) — CompareGuru ships one (agentic access), Honeymoney
   does not. Wix with no MCP = invisible to AI engines.
6. **Wrong-domain traps.** Verify DNS before fetching (step 1). The
   operator's list may carry dead TLDs or brand names that don't exist.
7. **/tmp is ephemeral.** The script lives in this skill's `scripts/`
   dir, not /tmp — /tmp was wiped mid-session in the GXS run.
8. **404 on a guessed path is not a bot block.** Always test a real URL
   from the sitemap. `/deals/` 404'd for every UA including Chrome on
   DiveDeals — a path guess, not a block.
9. **llms.txt status lies.** Check the body. MoneySmart's llms.txt is
   HTTP 500 (Nuxt error page); a 200 can be an HTML error page too.
10. **Homepage JSON-LD does not predict article JSON-LD.** SingSaver has
    0 JSON-LD on the homepage; Suitesmile has 8 per post. Always check a
    deep page.

## Worked example: GXS publisher screening (2026-08-05)

14 SG publishers screened with this procedure. Final ranking:

| # | Publisher | Domain | AI-bot access | llms.txt | Sitemap | JSON-LD | Verdict |
|---|---|---|---|---|---|---|---|
| 1 | Lobangsis | lobangsis.com | OPEN (GPTBot+ClaudeBot) | YES 97KB | 200 | 1 | RECOMMEND |
| 2 | Suitesmile | suitesmile.com | GPTBot 200 / ClaudeBot 403 | YES 29KB | 200 | 8/post | RECOMMEND |
| 3 | MoneySmart | moneysmart.sg | OPEN (Cloudflare) | BROKEN 500 | 200 | 3/6 | RECOMMEND* |
| 4 | SingSaver | singsaver.com.sg | OPEN | 404 | 200 | 0 | RECOMMEND* |
| 5 | CompareSing | comparesing.com | OPEN (GPTBot+ClaudeBot) | 404 | 200 | 1/1 | GOOD |
| 6 | DiveDeals | divedeals.sg | OPEN (GPTBot) | 404 | 200 | 1/1 | GOOD |
| 7 | Sethisfy | sethisfy.com | OPEN | 404 | 200 | 1 | GOOD |
| 8 | AsiaOne | asiaone.com | Bots OK, 60s delay | 404 | 200 | 0 | MIXED |
| 9 | The Edge | theedgesingapore.com | OPEN | 404 | 403/404 | 0 | MIXED |
| 10 | Lendingpot | lendingpot.sg | OPEN | 404 | 404 | 2 | THIN |
| 11 | Honeymoney | honeymoneysg.com | OPEN but no article graph | 404 | 404 | 0 | INVISIBLE |
| 12 | Mothership | mothership.sg | Deep pages 403 ALL bots | 404 | 200 | 0 | BLOCKED |
| 13 | Geek Culture | geekculture.co | BLOCKS all AI bots | YES 2KB | 200 | 1 | BLOCKED |
| 14 | Vulcan Post | vulcanpost.com | BLOCKS all AI bots | 404 | 200 | 1 | BLOCKED |

Key verdicts: Vulcan Post + Geek Culture block all 7 major AI crawlers
(GPTBot, ClaudeBot, CCBot, Bytespider, Google-Extended, Applebot-Extended,
meta-externalagent) — biggest names on the list, fully AI-hostile.
AsiaOne UA-sniffs robots. Suitesmile blocks ClaudeBot only (WAF) while
passing GPTBot. Honeymoney is topically relevant (CPF/FIRE) but has zero
crawlable article graph.

## Verification checklist

- [ ] Every claim backed by a live fetch in this session (no carried-over
      numbers — re-verify every count in the current run)
- [ ] robots.txt fetched with at least 2 UAs (Chrome + 1 bot)
- [ ] Deep-page test used a real sitemap URL, not a guessed path
- [ ] 403s retried once before being classified as blocks
- [ ] llms.txt body inspected, not just status
- [ ] Script run from this skill's `scripts/` dir, not /tmp
- [ ] Ranking table delivered with evidence columns + verdict per site

## Files

- `scripts/check_site.sh` — the probe script. Usage:
  `./check_site.sh <name> <domain> [deep_url]`. Writes per-site output
  files to `./<name>/` in the current directory.
