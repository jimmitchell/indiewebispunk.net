#!/bin/sh
# traffic.sh — nginx access-log traffic summary for indiewebispunk.net
#
#   sudo sh deploy/traffic.sh 7
#   sudo sh deploy/traffic.sh 7 /var/log/nginx/access.log shared
#
# Reads the per-site log that nginx-final.conf declares. Use "shared" mode for
# anything logged BEFORE that access_log line was reloaded, when this site's
# hits were interleaved with jimmitchell.org in the default access.log.
#
# "shared" mode does two passes: first it collects every IP that requested a
# path unique to this site or arrived with an indiewebispunk.net referer, then
# it reports only on those IPs. That is a heuristic, not a $host field — it is
# the best the stock `combined` format allows, and it UNDERCOUNTS: a returning
# visitor whose png and woff2 are still cached requests only "/", carries no
# marker, and drops out. Treat shared-mode numbers as a floor.

DAYS=${1:-7}
LOG=${2:-/var/log/nginx/indiewebispunk.net.access.log}
MODE=${3:-solo}

DATES=$(i=0; while [ "$i" -lt "$DAYS" ]; do date -d "-$i day" +%d/%b/%Y; i=$((i+1)); done | paste -sd'|' -)

TMP=$(mktemp) || exit 1
trap 'rm -f "$TMP" "$TMP.ips"' EXIT INT TERM

# shellcheck disable=SC2086
zcat -f ${LOG}* 2>/dev/null > "$TMP"
[ -s "$TMP" ] || { echo "No log data read from ${LOG}* — wrong path, or need sudo?" >&2; exit 1; }

if [ "$MODE" = "shared" ]; then
  awk '$0 ~ /indiewebispunk\.net/ || $7 ~ /^\/(indieweb-is-punk|fonts\/)/ { print $1 }' \
    "$TMP" | sort -u > "$TMP.ips"
  echo "shared-log mode: attributing $(wc -l < "$TMP.ips" | tr -d ' ') client IPs to indiewebispunk.net"
  echo ""
  IPFILE="$TMP.ips"
else
  IPFILE=""
fi

awk -v dates="$DATES" -v days="$DAYS" -v ipfile="$IPFILE" '
BEGIN {
  split(dates, dl, "|")
  for (i in dl) want[dl[i]] = 1
  if (ipfile != "") { while ((getline ip < ipfile) > 0) mine[ip] = 1; filtering = 1 }
  bots = "bot|crawl|spider|slurp|facebookexternalhit|feedfetcher|monitor|uptime|curl|wget|python-requests|scrapy|headless|semrush|ahrefs|mj12|dotbot|petal|yandex|baidu|gptbot|ccbot|perplexity|bytespider|amazonbot|applebot|dataforseo|censys|expanse|internetmeasurement|zgrab"
}
{
  d = substr($4, 2, 11)
  if (!(d in want)) next
  ip = $1
  if (filtering && !(ip in mine)) next

  path = $7; status = $9; ref = $11
  ua = ""
  for (i = 12; i <= NF; i++) ua = ua " " $i
  sub(/^ /, "", ua)
  isbot = (tolower(ua) ~ bots)

  req[d]++
  if (isbot) { botreq[d]++; next }

  humanreq[d]++
  if (!((d SUBSEP ip) in seenip)) { seenip[d, ip] = 1; uniq[d]++ }

  if ((status == 200 || status == 304) &&
      (path == "/" || path == "/index.html" || path ~ /\.md$/)) {
    pv[d]++
    pages[path]++
  }
  if (ref != "\"-\"" && ref !~ /indiewebispunk\.net/) { if (!(ref in refs)) nrefs++; refs[ref]++ }
  agents[ua]++
}
END {
  printf "%-12s %8s %8s %8s %8s %8s\n", "DAY", "REQS", "HUMAN", "BOT", "UNIQ IP", "PAGEVW"
  printf "%-12s %8s %8s %8s %8s %8s\n", "-----------","-------","-------","-------","-------","-------"
  for (i = 1; i <= days; i++) {
    d = dl[i]
    printf "%-12s %8d %8d %8d %8d %8d\n", d, req[d], humanreq[d], botreq[d], uniq[d], pv[d]
    treq += req[d]; thum += humanreq[d]; tbot += botreq[d]; tpv += pv[d]
  }
  printf "%-12s %8s %8s %8s %8s %8s\n", "-----------","-------","-------","-------","-------","-------"
  printf "%-12s %8d %8d %8d %8s %8d\n", "TOTAL", treq, thum, tbot, "-", tpv

  print "\nTOP PAGES (human, 200/304)"
  for (p in pages) printf "  %6d  %s\n", pages[p], p | "sort -rn | head -15"
  close("sort -rn | head -15")

  print "\nTOP EXTERNAL REFERRERS"
  if (nrefs == 0) print "  (none)"
  for (r in refs) printf "  %6d  %s\n", refs[r], r | "sort -rn | head -15"
  close("sort -rn | head -15")

  print "\nTOP HUMAN USER AGENTS"
  for (a in agents) printf "  %6d  %s\n", agents[a], substr(a, 1, 90) | "sort -rn | head -10"
  close("sort -rn | head -10")
}' "$TMP"
