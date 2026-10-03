# PROJECT_STATE.md

Laufendes Änderungsprotokoll für CanSpot. Neuester Eintrag oben. Für dauerhafte Projektregeln/technische Hinweise siehe [CLAUDE.md](CLAUDE.md), für Datenquellen [DATENQUELLEN.md](DATENQUELLEN.md).

---

## 2026-10-03 (1) — Bereinigter Neustart des Repos

**Was**: Das Repo startet mit einer neuen, bereinigten Historie.
- **Entfernt:** alte Demoseiten (Marken- und Standortseiten), Packungsbilder unter `images/bundles/` (auch in `www/`), der bisherige Projektlog.
- **Neu:** Ordner `supabase/` mit `schema.sql`, `seed.sql`, `reset_inhalte.sql`, `data/*.csv` und `README.md`. Er bildet die Live-Datenbank ab.
- **Supabase:** Händlerlogos und Produktbilder sind geleert, die App zeigt eigene Platzhalter. Die Tabellenbeschreibungen sind an `schema.sql` angeglichen.
- **App:** Der Hinweis unter der Angebotsliste sagt jetzt, dass CanSpot nicht mit Händlern oder Herstellern verbunden ist. `CACHE_NAME` steht auf `canspot-cache-v151`.
- **Sonst:** `package.json` zeigt auf `CanspotOrga/canspotapp`.

**Aktueller Datenstand**: 2 Marken mit je 2 Produkten, 4 Filialen in Arnsberg, 4 Angebote. Das sind Demodaten, siehe [supabase/README.md](supabase/README.md).

**Getestet**: `seed.sql` gegen die Live-Datenbank ausgeführt, ohne Fehler und mit unverändertem Stand (4/4/2/2/4/2/4/0 Zeilen).

**Offen**:
- Demodaten sind in der App noch nicht als Beispiel gekennzeichnet (Regel 4 in DATENQUELLEN.md).
- Echte Preisquelle fehlt: Vereinbarung mit Händlern bzw. Prospekt-Anbietern oder Preise, die Nutzer selbst melden.
- Produktbilder nur aus erlaubten Quellen nachrüsten (Open Food Facts mit Namensnennung oder eigene Fotos).
- Toter Desktop-Code (alte radiale Karte, Glocken-Sheet) kann aufgeräumt werden.
- Stub-Funktionen ohne Backend (Login, Abmelden, Konto löschen) zeigen weiter Hinweise auf den Prototyp.
