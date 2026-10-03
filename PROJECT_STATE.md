# PROJECT_STATE.md

Laufendes Änderungsprotokoll für CanSpot. Neuester Eintrag oben. Für dauerhafte Projektregeln/technische Hinweise siehe [CLAUDE.md](CLAUDE.md), für Datenquellen [DATENQUELLEN.md](DATENQUELLEN.md).

---

## 2026-10-03 (7) — Demo-Hinweis wieder aktiv

**Was**: `app_settings.demo_notice` ist live wieder gesetzt: „Demo: Alle Preise und Angebote sind Beispieldaten und keine echten Angebote der genannten Händler.“ Grund: Die Testseite auf GitHub Pages ist öffentlich und zeigt erfundene Preise unter echten Händlernamen. Ohne Hinweis droht eine erneute Betrugsmarkierung und ein Verstoß gegen Regel 4 in DATENQUELLEN.md. `seed.sql`, `data/app_settings.csv` und `README.md` sind angepasst. An der App hat sich nichts geändert (kein Cache-Bump nötig), das Banner kommt direkt aus Supabase.

**Getestet**: Die Live-Seite zeigt das Banner mit diesem Text über den 4 Angeboten.

**Offen**: Sobald echte Daten da sind, `demo_notice` auf `null` setzen. Die Alternative wären fiktive Testmärkte statt echter Händlernamen in den Testdaten.

---

## 2026-10-03 (6) — Beispieldaten-Hinweise entfernt (echte Daten folgen)

**Was** (auf Wunsch des Projektinhabers, weil künftig echte Daten kommen):
- **Supabase:** `app_settings.demo_notice` ist live auf `null` gesetzt, das Banner `#demoBanner` bleibt dadurch ausgeblendet. Die Logik dafür bleibt, ein Text in `demo_notice` blendet es wieder ein. `seed.sql`, `data/app_settings.csv` und `README.md` sind angepasst.
- **App:** Die Seitenbeschreibung (`<meta name="description">`) erwähnt keine Beispieldaten mehr. Die Hinweise „Demo-Prototyp: …“ bei „Zuletzt angesehen“, „Abmelden“ und „Konto löschen“ lauten jetzt „… ist noch nicht verfügbar.“ In „Konto verwalten“ entfällt „Prototyp ohne Server:“.
- **Impressum:** Der Punkt „Beispieldaten“ unter Nutzungshinweise ist gestrichen.
- **Bleibt:** Der Hinweis, dass CanSpot nicht mit Händlern oder Herstellern verbunden ist (App und Impressum).
- `CACHE_NAME` steht auf `canspot-cache-v156`, `www/` ist synchron, `npx cap copy ios` ist gelaufen.

**Achtung**: Die 4 Angebote in Supabase sind weiterhin erfundene Demodaten und erscheinen jetzt ohne Kennzeichnung. Laut DATENQUELLEN.md (Regel 4) müssen Demodaten klar erkennbar sein. Bis echte Daten da sind, also entweder die Demo-Angebote löschen oder `demo_notice` wieder füllen.

---

## 2026-10-03 (5) — Letzte feste Demowerte aus der App in die Datenbank verlegt

**Was**:
- **Neue Tabelle `public.app_settings`** (genau eine Zeile, `id = 1`, öffentlich lesbar, RLS aktiv), live angelegt und in `supabase/schema.sql`, `seed.sql`, `data/app_settings.csv` und `README.md` nachgezogen. Inhalt: Startstandort „59821 Arnsberg“ (51.4013, 8.0658), Umkreis 10 km, Beispieldaten-Hinweis, Versionstext „CanSpot Prototyp · Version 1.0.0“. Die Store-Links sind leer.
- **App liest sie in `loadFromSupabase()`** über `applyAppSettings()`, bevor die Angebote zugeordnet werden. Entfernt wurden aus `index.html`: `DEFAULT_LOCATION_LABEL`/`DEFAULT_LOCATION_GEO`, die Arnsberg-Koordinaten der Karten, die Vorbelegung „59821 Arnsberg“, der feste Hinweistext, der feste Versionstext, `STORE_RATING_LINKS` mit Platzhalter-IDs, „Max Mustermann“/„MM“ und der Beispielpreis „1,09“.
- **Ohne Daten** zeigt die App neutrale Texte: „Standort wählen“, „Name eingeben“, „?“. Im Feld „Preis melden“ steht der aktuelle Angebotspreis. Ohne Startstandort ist `distanceKm` `null` (`hasDistance()`/`kmSuffix()`), der Umkreisfilter lässt solche Angebote durch, die Sortierung „Nächster Händler“ stellt sie ans Ende und die Karte startet auf Deutschland.
- Ein selbst gewählter Ort wird weiter lokal gespeichert, der Startstandort aus der Datenbank nicht.
- `CACHE_NAME` steht auf `canspot-cache-v155`, `www/` ist synchron, `npx cap copy ios` ist gelaufen.

**Getestet**: Im Browser (375×812) mit Live-Daten: Hinweis, „Arnsberg · 10 km“, Entfernungen und Version kommen aus `app_settings`. Mit simuliertem Fehler beim Laden von `app_settings` erscheinen kein Hinweis, „Standort wählen“, keine Entfernungsangaben und eine leere Version. Die 4 Angebote werden trotzdem angezeigt. Produktdetail, Filialdetail, „Bewerte uns“ und der Preisplatzhalter funktionieren.

**Offen**: Profil, Favoriten, Preisalarme, Bewertungen und Benachrichtigungen liegen weiter nur im `localStorage`. Die Tabellen dafür gibt es schon (`profiles`, `favorites`, …), sie brauchen aber eine Anmeldung über Supabase Auth.

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
