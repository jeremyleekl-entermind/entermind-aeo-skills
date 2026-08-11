#!/bin/bash
# check_site.sh — AI-crawlability probe for a single publisher/site.
# Part of the publisher-ai-crawlability-check skill (Entermind Malaysia).
# Usage: ./check_site.sh <name> <domain> [deep_url]
#   <name>     short label for output dir (e.g. "lobangsis")
#   <domain>   bare domain (e.g. "lobangsis.com") — https:// is assumed
#   [deep_url] optional real article URL for the deep-page bot test
# Writes per-site files to ./<name>/ in the current directory.
# Requires: curl, python3. No credentials, no profile state — agent-agnostic.

NAME="$1"; DOMAIN="$2"; DEEP_URL="$3"
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
OUT="$(pwd)/$NAME"
mkdir -p "$OUT"
# Full Chrome header set — required to pass Cloudflare/Akamai fingerprinting
# (MoneySmart pattern: 403 to plain curl, 200 with these headers).
HDRS=(-A "$UA" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7" -H "Accept-Language: en-US,en;q=0.9" -H "Sec-Ch-Ua: \"Not/A)Brand\";v=\"8\", \"Chromium\";v=\"126\", \"Google Chrome\";v=\"126\"" -H "Sec-Ch-Ua-Mobile: ?0" -H "Sec-Ch-Ua-Platform: \"Windows\"" -H "Sec-Fetch-Dest: document" -H "Sec-Fetch-Mode: navigate" -H "Sec-Fetch-Site: none" -H "Sec-Fetch-User: ?1" -H "Upgrade-Insecure-Requests: 1")

echo "=== $NAME ($DOMAIN) ==="
final=$(curl -s --compressed -o /dev/null -w "%{url_effective}" -L "${HDRS[@]}" --max-time 20 "https://$DOMAIN/" 2>/dev/null)
echo "canonical: $final"

code=$(curl -s --compressed -L -o "$OUT/robots.txt" -w "%{http_code}" "${HDRS[@]}" --max-time 20 "https://$DOMAIN/robots.txt" 2>/dev/null)
echo "robots.txt: HTTP $code"
if [ "$code" = "200" ]; then
  echo "-- AI-relevant user agents + rules:"
  grep -iE "^User-agent|GPTBot|ClaudeBot|PerplexityBot|OAI-SearchBot|ChatGPT-User|Google-Extended|anthropic|ai2bot|cohere|CCBot|Bytespider|Applebot-Extended|meta-externalagent" "$OUT/robots.txt" | head -30 || echo "  (none found)"
  echo "-- total disallow lines: $(grep -ci '^disallow' "$OUT/robots.txt")"
fi

code=$(curl -s --compressed -L -o "$OUT/llms.txt" -w "%{http_code}" "${HDRS[@]}" --max-time 20 "https://$DOMAIN/llms.txt" 2>/dev/null)
echo "llms.txt: HTTP $code ($(wc -c < "$OUT/llms.txt" 2>/dev/null) bytes)"
if [ "$code" = "200" ]; then
  echo "-- llms.txt generator/head:"
  head -c 300 "$OUT/llms.txt" | head -3
fi

code=$(curl -s --compressed -L -o /dev/null -w "%{http_code}" "${HDRS[@]}" --max-time 20 "https://$DOMAIN/sitemap.xml" 2>/dev/null)
echo "sitemap.xml: HTTP $code"
if [ "$code" != "200" ]; then
  for alt in sitemap_index.xml wp-sitemap.xml; do
    a=$(curl -s --compressed -L -o /dev/null -w "%{http_code}" "${HDRS[@]}" --max-time 15 "https://$DOMAIN/$alt" 2>/dev/null)
    echo "  $alt: HTTP $a"
  done
fi

code=$(curl -s --compressed -L -o "$OUT/home.html" -w "%{http_code}" "${HDRS[@]}" --max-time 25 "https://$DOMAIN/" 2>/dev/null)
size=$(wc -c < "$OUT/home.html" 2>/dev/null)
echo "homepage: HTTP $code ($size bytes)"
if [ "$code" = "200" ]; then
  title=$(grep -oiE '<title[^>]*>[^<]*' "$OUT/home.html" | head -1 | sed 's/<title[^>]*>//I')
  echo "  title: $title"
  echo "  JSON-LD blocks: $(grep -o 'application/ld+json' "$OUT/home.html" | wc -l)"
  python3 - "$OUT/home.html" << 'PYEOF'
import re, sys
html = open(sys.argv[1], encoding='utf-8', errors='ignore').read()
scripts = ''.join(re.findall(r'<script.*?</script>', html, re.S | re.I))
body = re.sub(r'<script.*?</script>', '', html, flags=re.S | re.I)
body = re.sub(r'<style.*?</style>', '', body, flags=re.S | re.I)
body = re.sub(r'<[^>]+>', ' ', body)
body = re.sub(r'\s+', ' ', body).strip()
print(f'  visible-text chars: {len(body)}')
print(f'  script bytes: {len(scripts)}')
PYEOF
  if grep -qiE 'id="(root|app|__next)"|ng-app|data-reactroot|id="app"' "$OUT/home.html"; then
    echo "  SPA shell markers: FOUND (check if content is server-rendered)"
  fi
elif [ "$code" = "403" ]; then
  echo "  BLOCKED: $(grep -oiE '<title>[^<]*' "$OUT/home.html" | head -1 | sed 's/<title>//I')"
fi

# Deep-page bot test — only if a real URL was supplied (from the sitemap).
if [ -n "$DEEP_URL" ]; then
  echo "deep-page test: $DEEP_URL"
  curl -s -o /dev/null -w "  GPTBot:    HTTP %{http_code}\n" -A "GPTBot/1.0 (+https://openai.com/gptbot)" --max-time 20 "$DEEP_URL"
  curl -s -o /dev/null -w "  ClaudeBot: HTTP %{http_code}\n" -A "ClaudeBot/1.0" --max-time 20 "$DEEP_URL"
  curl -s --compressed -o "$OUT/deep.html" -w "  Chrome:    HTTP %{http_code} size %{size_download}\n" "${HDRS[@]}" --max-time 25 "$DEEP_URL"
  if [ -s "$OUT/deep.html" ]; then
    echo "  deep JSON-LD blocks: $(grep -o 'application/ld+json' "$OUT/deep.html" | wc -l)"
  fi
fi
echo ""
