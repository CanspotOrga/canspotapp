# PROJECT_STATE.md

Laufendes Änderungsprotokoll für CanSpot. Neuester Eintrag oben. Für dauerhafte Projektregeln/technische Hinweise siehe [CLAUDE.md](CLAUDE.md), für Datenquellen [DATENQUELLEN.md](DATENQUELLEN.md).

---

## 2026-10-03 (4) — Schutz vor erneuter Einstufung als Betrugsseite

**Anlass**: Die alte Fassung unter einem früheren GitHub-Konto wurde als betrügerisch markiert. Auslöser waren Händlerlogos von fremden Servern, erfundene Rabattpreise, Kontofelder mit Passwort und Platzhalter-Links. Logos und Passwortfelder waren in der Vorlage schon entfernt.

**Was**:
- **Beispieldaten-Banner** (`.demo-banner`) gut sichtbar über der Angebotsliste. Damit ist Regel 4 aus DATENQUELLEN.md erfüllt.
- **`<meta name="description">`** nennt den unabhängigen Prototyp und die Beispieldaten.
- **Neue Seiten `impressum.html` und `datenschutz.html`**: Alle Rechtslinks (Mein Bereich, Burger-Menü) zeigen jetzt dorthin. „Nutzungsbedingungen“ führt zu `impressum.html#nutzung`, „Kontakt“ zu `impressum.html#kontakt`, der Platzhalter `kontakt@canspot.example` ist weg.
- **„Zum Angebot“**: Ohne echten http(s)-Link (`hasRealLink()`) erscheint ein deaktivierter Button „Bestes Angebot: Händler · Preis“ statt eines Links ins Leere. „Angebot online öffnen“ in der Filialansicht ist dann ausgeblendet.
- **„Bewerte uns“**: Solange die Store-IDs Platzhalter sind, erscheint ein Hinweis statt eines Links auf erfundene Store-Seiten.
- **Konto verwalten**: Ein Hinweis sagt, dass die Angaben nur auf dem Gerät bleiben.
- `CACHE_NAME` steht auf `canspot-cache-v154`, beide neuen Seiten sind in `APP_SHELL`. `www/` ist synchron, `npx cap copy ios` ist gelaufen.

**Getestet**: Im Browser (375×812) mit Live-Daten: Banner sichtbar, 4 Karten, Rechtslinks korrekt, deaktivierter CTA, Online-Button ausgeblendet, Toast bei „Bewerte uns“, Impressum-Seite wird angezeigt. Der Service Worker ließ sich in der eingebetteten Vorschau nicht registrieren, auch nicht mit einer leeren Testdatei. Das liegt an der Umgebung, nicht an der App.

**Offen**:
- In `impressum.html` und `datenschutz.html` müssen die Platzhalter **[Vorname Nachname], [Straße Hausnummer], [PLZ Ort], [E-Mail-Adresse]** vor dem Push ausgefüllt werden.
- Die Datenschutzerklärung ist ein Entwurf und vor dem Start rechtlich prüfen lassen.
- Altes Repo unter dem früheren GitHub-Konto samt Pages-Seite löschen oder auf privat stellen.

---

## 2026-10-03 (3) — Tab-Titel, Suchfeld-Text, Reihenfolge auf der Angebotskarte

**Was**:
- **Tab-Titel:** `<title>` heißt jetzt „CanSpot“ statt „EnergyBoost — Prototyp“ (auch in `CLAUDE.md` angepasst).
- **Suchfeld:** Der Hintergrundtext (`placeholder`) lautet „Suchen“ statt „Energy Drink oder Marke“.
- **Angebotskarte** (`buildDealCardEl()`): Die Preiszeile („statt …“, Rabatt, Preis) steht jetzt über der Händlerzeile, der Händler steht darunter. Die Händlerzeile sitzt per `margin-top:auto` am unteren Rand der Infospalte, die Preiszeile folgt direkt auf die Größen-/Pfandzeile.
- `CACHE_NAME` steht auf `canspot-cache-v153`, `www/` ist synchron, `npx cap copy ios` ist gelaufen.

**Getestet**: Im Browser (Mobilbreite) mit Live-Daten: Reihenfolge in `.card-info` ist Produkt, Größe, Preiszeile, Händler; Titel und Placeholder stimmen.

**Offen**: Nicht auf GitHub gepusht. Bei Karten mit „Neu“-Pille und langem Produktnamen noch auf dem Gerät prüfen, ob die Händlerzeile sauber unten bleibt.

---

## 2026-10-03 (2) — Produktbilder einheitlich im Hochformat 3:4

**Was**: Alle Produktbilder nutzen jetzt das Seitenverhältnis 3:4 (per `aspect-ratio`, nur die Breite ist gesetzt), weil Dosen und Flaschen hoch und schmal sind.
- **Größen:** Angebotskarte und Neuheiten/Alarme `.thumb` 72×96, Produktdetail `.detail-img` 150×200, Favoritenzeilen `.fav-emoji` 36×48, Neuigkeit-Detail `.news-detail-img` 100×133, Suchvorschläge 32×43, „Ähnliche Produkte“ 72×96, „Bester Deal der Woche“ 72×96.
- **Platzhalter:** `FALLBACK_IMG` ist jetzt ebenfalls hochformatig (viewBox 60×80), Lade-Skeleton zeigt einen Hochformat-Block.
- **Sonst:** Die überschreibende Regel `.card-main .thumb` (58×72) entfällt, die Basisregel `.thumb` gilt direkt. `CACHE_NAME` steht auf `canspot-cache-v152`, `www/` ist synchron, `npx cap copy ios` ist gelaufen.

**Getestet**: Im Browser (Mobilbreite) mit Live-Daten: Karte 72×96, Detailbild 150×200, „Ähnliche Produkte“ 72×96. Echte Produktfotos gibt es aktuell nicht (`image_url` leer), geprüft wurde mit dem Platzhalter.

**Offen**: Mit echten Fotos (Open Food Facts bzw. eigene) prüfen, ob 3:4 bei breiten Packshots (Mehrpacks, `bundle_image_url`) gut aussieht. Die toten Regeln `.card-top .thumb` (100×100 / 72×72) sind weiter quadratisch, werden aber nirgends benutzt.

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
