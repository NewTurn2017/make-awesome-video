#!/usr/bin/env python3
"""Search the whatships.com launch-video catalog for reference videos.

Examples:
  find_refs.py "terminal devtool" --category "Developer tools" --limit 8 --details
  find_refs.py --list-categories
  find_refs.py kinetic typography --json
"""
import argparse
import json
import os
import re
import sys
import time
import urllib.request
from collections import Counter

BASE = "https://whatships.com"
INDEX_URL = f"{BASE}/search-index.json"
CACHE = os.path.join(
    os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")),
    "make-awesome-video",
    "whatships-index.json",
)
CACHE_TTL = 6 * 3600
UA = "make-awesome-video-skill/1.0 (+reference research)"


def fetch(url, accept="application/json"):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": accept})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read().decode("utf-8")


def load_index(refresh=False):
    if not refresh and os.path.exists(CACHE) and time.time() - os.path.getmtime(CACHE) < CACHE_TTL:
        with open(CACHE, encoding="utf-8") as f:
            return json.load(f)
    data = json.loads(fetch(INDEX_URL))
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    with open(CACHE, "w", encoding="utf-8") as f:
        json.dump(data, f)
    return data


def split_meta(meta):
    parts = [p.strip() for p in (meta or "").split("·")]
    company = parts[0] if parts else ""
    category = parts[-1] if len(parts) > 1 else ""
    return company, category


def score(item, terms):
    if not terms:
        return 1
    name = (item.get("name") or "").lower()
    text = (item.get("searchText") or "").lower()
    s = 0
    for t in terms:
        if t in name:
            s += 3
        if re.search(rf"\b{re.escape(t)}", text):
            s += 1
    # require every term to appear somewhere
    return s if all(t in name or t in text for t in terms) else 0


def details(slug):
    md = fetch(f"{BASE}/videos/{slug}/", accept="text/markdown")
    out = {}
    for key, pat in {
        "duration": r"^- Duration:\s*(.+)$",
        "published": r"^- Published:\s*(.+)$",
        "x_post": r"^- Original X post:\s*(\S+)",
        "tags": r"^- Tags:\s*(.+)$",
    }.items():
        m = re.search(pat, md, re.M)
        if m:
            out[key] = m.group(1).strip()
    lines = [l for l in md.splitlines() if l.strip() and not l.startswith(("#", "-"))]
    if lines:
        out["summary"] = lines[0].strip()
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("query", nargs="*", help="keywords (all must match)")
    ap.add_argument("--category", help="filter by category, e.g. 'AI', 'Developer tools', 'Motion'")
    ap.add_argument("--limit", type=int, default=10)
    ap.add_argument("--details", action="store_true", help="fetch duration, date and original X post per result")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--list-categories", action="store_true")
    ap.add_argument("--refresh", action="store_true", help="ignore the 6h cache")
    a = ap.parse_args()

    try:
        index = load_index(a.refresh)
    except Exception as e:  # network failure
        sys.exit(f"whatships index를 가져오지 못함: {e}\n브라우저로 {BASE} 를 직접 보거나 사용자에게 참조 링크를 요청하세요.")

    videos = [i for i in index if i.get("kind") == "video"]

    if a.list_categories:
        counts = Counter(split_meta(v.get("meta"))[1] for v in videos)
        for cat, n in counts.most_common():
            print(f"{n:5d}  {cat}")
        return

    terms = [t.lower() for q in a.query for t in q.split()]
    results = []
    for v in videos:
        company, category = split_meta(v.get("meta"))
        if a.category and a.category.lower() != category.lower():
            continue
        s = score(v, terms)
        if s:
            results.append((s, v, company, category))
    # stable: score desc, index order (newest first) otherwise
    results.sort(key=lambda r: -r[0])
    results = results[: a.limit]

    rows = []
    for s, v, company, category in results:
        row = {
            "name": v.get("name"),
            "company": company,
            "category": category,
            "page": f"{BASE}{v.get('href')}",
            "poster": f"{BASE}{v['poster']}" if v.get("poster") else None,
            "slug": v.get("slug"),
        }
        if a.details:
            try:
                row.update(details(v["slug"]))
            except Exception as e:
                row["details_error"] = str(e)
        rows.append(row)

    if a.json:
        print(json.dumps(rows, ensure_ascii=False, indent=2))
        return
    if not rows:
        print("결과 없음. 키워드를 줄이거나 --category 없이 다시 검색하세요.")
        return
    print(f"{len(rows)}개 (카탈로그 {len(videos)}개 중)\n")
    for i, r in enumerate(rows, 1):
        print(f"{i}. {r['name']}")
        print(f"   {r['company']} · {r['category']}" + (f" · {r['duration']}" if r.get("duration") else "")
              + (f" · {r['published']}" if r.get("published") else ""))
        print(f"   page:   {r['page']}")
        if r.get("x_post"):
            print(f"   X post: {r['x_post']}")
        if r.get("poster"):
            print(f"   poster: {r['poster']}")
        print()


if __name__ == "__main__":
    main()
