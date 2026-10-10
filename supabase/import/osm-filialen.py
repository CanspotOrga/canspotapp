#!/usr/bin/env python3
"""Filialen der zugelassenen Ketten aus OpenStreetMap (Deutschland).

Fragt die Overpass-API einmal ab und schreibt supabase/data/branches-osm.json
(Lizenz ODbL 1.0, © OpenStreetMap-Mitwirkende). Die Datenbank übernimmt die
Datei mit supabase/sql/sql-osm-filialen.sql (Funktionen osm_branches_fetch()
und osm_branches_import()).

Übernommen werden nur Kette, Adresse, Koordinaten und Öffnungszeiten - keine
Namen von Betreibern oder Inhabern, keine Telefonnummern, E-Mails oder Websites.

Aufruf (aus dem Projektordner):
  python3 supabase/import/osm-filialen.py                # Overpass abfragen
  python3 supabase/import/osm-filialen.py --input x.json # vorhandene Overpass-Antwort
Selten ausführen (z. B. monatlich): eine Abfrage, langsam, eigene Kennung.
"""
import argparse
import json
import math
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

OVERPASS_URL = "https://overpass-api.de/api/interpreter"
USER_AGENT = "CanSpot-Filialimport/1.0 (+https://canspot.de)"
DEFAULT_OUTPUT = Path(__file__).resolve().parents[1] / "data" / "branches-osm.json"

# shop=supermarket: brand:wikidata -> retailers.name
RETAIL_WIKIDATA = {
    "Q701755": "EDEKA",
    "Q16968817": "REWE",
    "Q151954": "Lidl",
    "Q685967": "Kaufland",
    "Q41171672": "Aldi Süd",
    "Q879858": "Netto",        # Netto Marken-Discount (Edeka), nicht Netto der Salling Group
    "Q41171373": "Aldi Nord",
    "Q284688": "Penny",
    "Q450180": "Norma",
    "Q457503": "Globus",
}
# Ohne brand:wikidata: Markenname (klein geschrieben) -> retailers.name
RETAIL_BRAND = {
    "edeka": "EDEKA", "rewe": "REWE", "lidl": "Lidl", "kaufland": "Kaufland",
    "aldi süd": "Aldi Süd", "aldi nord": "Aldi Nord",
    "netto marken-discount": "Netto", "netto city": "Netto",
    "penny": "Penny", "norma": "Norma", "globus": "Globus",
    "hit": "HIT", "marktkauf": "Marktkauf",
}
# Weitere Ladentypen (Drogerie, Getränkemarkt): (shop, brand klein) -> retailers.name
OTHER_BRAND = {
    ("chemist", "rossmann"): "Rossmann",
    ("beverages", "trinkgut"): "trinkgut",
}
# shop=wholesale: brand:wikidata -> retailers.name
WHOLESALE_WIKIDATA = {
    "Q13610282": "Metro",
    "Q701755": "EDEKA C+C",
    "Q1574870": "Handelshof",
}
WHOLESALE_NAME = [
    (re.compile(r"^metro\b(?!.*leergut)", re.I), "Metro"),
    (re.compile(r"^handelshof\b", re.I), "Handelshof"),
    (re.compile(r"edeka.*(c\s*\+\s*c|cash|gro(ß|ss)markt)|union\s*sb|sb[-\s]*union|\bmios\b", re.I), "EDEKA C+C"),
]

QUERY = """[out:json][timeout:600];
area["ISO3166-1"="DE"][admin_level=2]->.de;
(
  nwr["shop"="supermarket"]["brand:wikidata"~"^(%(retail_wd)s)$"](area.de);
  nwr["shop"="supermarket"]["brand"~"^(%(retail_brand)s)$",i](area.de);
  nwr["shop"="wholesale"]["brand:wikidata"~"^(%(wholesale_wd)s)$"](area.de);
  nwr["shop"="wholesale"]["name"~"(metro|handelshof|edeka|union|mios)",i](area.de);
  nwr["shop"="chemist"]["brand"~"^rossmann$",i](area.de);
  nwr["shop"="beverages"]["brand"~"^trinkgut$",i](area.de);
);
out tags center qt;
""" % {
    "retail_wd": "|".join(RETAIL_WIKIDATA),
    "retail_brand": "|".join(re.escape(b) for b in RETAIL_BRAND),
    "wholesale_wd": "|".join(WHOLESALE_WIKIDATA),
}

DAYS = ["mo", "tu", "we", "th", "fr", "sa", "su"]
OSM_DAY = {"Mo": 0, "Tu": 1, "We": 2, "Th": 3, "Fr": 4, "Sa": 5, "Su": 6}
DAY_TOKEN = r"(?:Mo|Tu|We|Th|Fr|Sa|Su|PH|SH)"
SELECTOR_RE = re.compile(r"(%s(?:\s*[-,]\s*%s)*)?\s*(.*)" % (DAY_TOKEN, DAY_TOKEN), re.S)
INTERVAL_RE = re.compile(r"(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})")
MONTH = r"(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"
DATE_RULE_RE = re.compile(r"(\d{4}\s+)?%s\b" % MONTH)
SINGLE_DATE_RE = re.compile(r"(\d{4}\s+)?%s\s+\d{1,2}\b" % MONTH)
MONTH_RANGE_RE = re.compile(r"%s[^;]*?-\s*(\d{4}\s+)?%s" % (MONTH, MONTH))


def parse_opening_hours(raw):
    """Liest den OSM-Wert opening_hours in {"mo": [["07:00","20:00"]], ..., "su": []}.

    Nur die gängige Schreibweise (Wochentage, Uhrzeiten, off). Regeln für
    Feiertage (PH) und einzelne Daten (z. B. "Dec 24 07:00-14:00") werden
    übergangen, die App weist darauf hin. Alles andere (Schulferien, offene
    Enden, Kommentare) ergibt None; der Rohtext bleibt dann erhalten.
    """
    if not raw:
        return None
    text = raw.strip()
    if text == "24/7":
        return {d: [["00:00", "24:00"]] for d in DAYS}
    if "||" in text:
        return None
    hours = {d: [] for d in DAYS}  # nicht genannte Tage = geschlossen (OSM-Regel)
    used = False
    rules = re.split(r";|(?<=\d|f),\s*(?=(?:Mo|Tu|We|Th|Fr|Sa|Su|PH)\b)", text)
    for rule in (r.strip() for r in rules):
        if not rule:
            continue
        if DATE_RULE_RE.match(rule):
            # Einzelne Tage (z. B. "Dec 24 07:00-14:00") übergehen; Zeiträume
            # im Jahr ("Apr-Sep ...", "Mar 15-Oct 31 ...") nicht raten.
            if MONTH_RANGE_RE.search(rule) or not SINGLE_DATE_RE.match(rule):
                return None
            continue
        selector, rest = SELECTOR_RE.fullmatch(rule).groups()
        days = set()
        if selector:
            for part in re.split(r"\s*,\s*", selector):
                if part == "PH":
                    continue
                if part == "SH":
                    return None
                if "-" in part:
                    a, b = (p.strip() for p in part.split("-"))
                    if a not in OSM_DAY or b not in OSM_DAY:
                        return None
                    i = OSM_DAY[a]
                    while True:
                        days.add(i)
                        if i == OSM_DAY[b]:
                            break
                        i = (i + 1) % 7
                else:
                    days.add(OSM_DAY[part])
            if not days:
                continue  # reine Feiertagsregel
        else:
            days = set(range(7))
        rest = rest.strip()
        if rest.lower() in ("off", "closed"):
            intervals = []
        else:
            intervals = []
            for chunk in re.split(r"\s*,\s*", rest):
                m = INTERVAL_RE.fullmatch(chunk)
                if not m:
                    return None
                h1, m1, h2, m2 = map(int, m.groups())
                if (h2, m2) == (0, 0):
                    h2 = 24  # "07:00-00:00" = bis Mitternacht
                start, end = h1 * 60 + m1, h2 * 60 + m2
                if m1 > 59 or m2 > 59 or h1 > 24 or h2 > 24 or end > 24 * 60 or end <= start:
                    return None
                intervals.append(["%02d:%02d" % (h1, m1), "%02d:%02d" % (h2, m2)])
        for d in days:
            hours[DAYS[d]] = intervals
        used = True
    return hours if used else None


def simple_times(hours):
    """opens_at/closes_at/closed_sunday für die Altspalten: nur wenn Mo-Sa
    dieselbe einzelne Zeitspanne haben, sonst None."""
    if not hours:
        return None, None, False
    week = [hours[d] for d in DAYS[:6]]
    closed_sunday = hours["su"] == []
    if all(len(w) == 1 for w in week) and all(w == week[0] for w in week):
        return week[0][0][0], week[0][0][1], closed_sunday
    return None, None, closed_sunday


def retailer_for(tags):
    shop = tags.get("shop")
    wd = tags.get("brand:wikidata")
    brand = (tags.get("brand") or "").strip().lower()
    if shop == "supermarket":
        if wd and wd in RETAIL_WIKIDATA:
            return RETAIL_WIKIDATA[wd]
        # Ohne (oder mit unbekannter) Wikidata-Angabe nur Ketten, die allein über den Markennamen kommen
        if wd and brand not in ("hit", "marktkauf"):
            return None
        return RETAIL_BRAND.get(brand)
    if (shop, brand) in OTHER_BRAND:
        return OTHER_BRAND[(shop, brand)]
    if shop == "wholesale":
        if wd:
            return WHOLESALE_WIKIDATA.get(wd)
        name = (tags.get("name") or "").strip()
        for pattern, retailer in WHOLESALE_NAME:
            if pattern.search(name):
                return retailer
    return None


def clean(value, limit=120):
    value = (value or "").strip()
    return value[:limit] or None


def to_branch(element):
    tags = element.get("tags", {})
    retailer = retailer_for(tags)
    if not retailer:
        return None
    lat = element.get("lat", element.get("center", {}).get("lat"))
    lon = element.get("lon", element.get("center", {}).get("lon"))
    if lat is None or lon is None:
        return None
    street = clean(tags.get("addr:street"))
    number = clean(tags.get("addr:housenumber"), 20)
    raw_hours = clean(tags.get("opening_hours"), 255)
    hours = parse_opening_hours(raw_hours)
    opens_at, closes_at, closed_sunday = simple_times(hours)
    return {
        "osm_type": element["type"],
        "osm_id": element["id"],
        "retailer": retailer,
        "street": " ".join(p for p in (street, number) if p) or None,
        "postal_code": clean(tags.get("addr:postcode"), 10),
        "city": clean(tags.get("addr:city")),
        "latitude": round(lat, 6),
        "longitude": round(lon, 6),
        "opening_hours": raw_hours,
        "hours": hours,
        "opens_at": opens_at,
        "closes_at": closes_at,
        "closed_sunday": closed_sunday,
    }


def completeness(b):
    return sum(1 for k in ("street", "postal_code", "city", "opening_hours") if b[k]) + (b["osm_type"] == "node") * 0.5


def distance_m(a, b):
    dlat = (a["latitude"] - b["latitude"]) * 111_320
    dlon = (a["longitude"] - b["longitude"]) * 111_320 * math.cos(math.radians(a["latitude"]))
    return math.hypot(dlat, dlon)


def drop_duplicates(branches, radius_m=60):
    """Dieselbe Filiale steht manchmal doppelt in OSM (Punkt und Gebäude).
    Je Kette bleibt im Umkreis von 60 m nur der vollständigste Eintrag."""
    kept, cells = [], {}
    for b in sorted(branches, key=completeness, reverse=True):
        key = (b["retailer"], round(b["latitude"] * 1000), round(b["longitude"] * 1000))
        near = [o for dx in (-1, 0, 1) for dy in (-1, 0, 1)
                for o in cells.get((key[0], key[1] + dx, key[2] + dy), [])]
        if any(distance_m(b, o) < radius_m for o in near):
            continue
        cells.setdefault(key, []).append(b)
        kept.append(b)
    return kept


def fetch_overpass():
    data = urllib.parse.urlencode({"data": QUERY}).encode()
    for attempt in range(4):
        req = urllib.request.Request(OVERPASS_URL, data=data, headers={"User-Agent": USER_AGENT})
        try:
            with urllib.request.urlopen(req, timeout=900) as resp:
                return json.load(resp)
        except urllib.error.HTTPError as err:
            if err.code in (429, 504) and attempt < 3:
                wait = 120 * (attempt + 1)
                print("Overpass antwortet %s, neuer Versuch in %s s" % (err.code, wait), file=sys.stderr)
                time.sleep(wait)
                continue
            raise
    raise RuntimeError("Overpass nicht erreichbar")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--input", help="vorhandene Overpass-Antwort (JSON) statt neuer Abfrage")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()

    if args.input:
        with open(args.input, encoding="utf-8") as f:
            overpass = json.load(f)
    else:
        overpass = fetch_overpass()

    branches = [b for b in (to_branch(e) for e in overpass.get("elements", [])) if b]
    found = len(branches)
    branches = drop_duplicates(branches)
    branches.sort(key=lambda b: (b["retailer"], b["postal_code"] or "", b["osm_type"], b["osm_id"]))

    doc_head = {
        "source": "OpenStreetMap",
        "license": "ODbL 1.0",
        "license_url": "https://opendatacommons.org/licenses/odbl/1-0/",
        "attribution": "© OpenStreetMap-Mitwirkende",
        "copyright_url": "https://www.openstreetmap.org/copyright",
        "osm_timestamp": overpass.get("osm3s", {}).get("timestamp_osm_base"),
        "count": len(branches),
    }
    out = Path(args.output)
    with out.open("w", encoding="utf-8") as f:
        head = json.dumps(doc_head, ensure_ascii=False)
        f.write(head[:-1] + ', "branches": [\n')
        f.write(",\n".join(json.dumps(b, ensure_ascii=False, separators=(",", ":")) for b in branches))
        f.write("\n]}\n")

    per_chain = {}
    for b in branches:
        s = per_chain.setdefault(b["retailer"], [0, 0, 0])
        s[0] += 1
        s[1] += bool(b["opening_hours"])
        s[2] += b["hours"] is not None
    print("%d Filialen (%d doppelte entfernt), OSM-Stand %s -> %s"
          % (len(branches), found - len(branches), doc_head["osm_timestamp"], out))
    for name, (n, raw, parsed) in sorted(per_chain.items(), key=lambda x: -x[1][0]):
        print("  %-12s %6d  Öffnungszeiten %3.0f %%, davon lesbar %3.0f %%"
              % (name, n, 100 * raw / n, 100 * parsed / max(raw, 1)))


if __name__ == "__main__":
    main()
