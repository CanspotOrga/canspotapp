# supabase/ — Datenbank-Stand von CanSpot

Dieser Ordner spiegelt die Live-Datenbank (Supabase-Projekt, siehe `SUPABASE_URL`
in `index.html`). Stand: 03.10.2026.

| Datei | Inhalt |
|---|---|
| `schema.sql` | Alle Tabellen, Constraints, Indizes, Funktionen, Trigger, RLS-Policies und Grants. Nur für ein **leeres** Projekt. |
| `seed.sql` | Aktuelle Inhalte, additiv und mehrfach ausführbar (gleiche `id` wird aktualisiert, nichts gelöscht). |
| `reset_inhalte.sql` | Leert alle Inhaltstabellen. Bricht ab, sobald Nutzerdaten existieren. |
| `data/*.csv` | Dieselben Inhalte als CSV, eine Datei je Tabelle, Spalten wie in der Tabelle. |

## Aktueller Inhalt

2 Marken mit je 2 Produkten, 4 Filialen in Arnsberg, 4 Angebote.
Dazu eine Zeile in `app_settings`: Startstandort „59821 Arnsberg“ (51.4013, 8.0658),
Umkreis 10 km, Demo-Hinweis (`demo_notice`) und Versionstext. Store-Links sind leer.

| Produkt | Händler | Angebot |
|---|---|---|
| Red Bull Energy Drink 250 ml | Kaufland, Ruhrstraße 22 | 0,99 € statt 1,49 € |
| Red Bull Sugarfree 250 ml | REWE, Clemens-August-Straße 8 | 0,95 € statt 1,35 € |
| Monster Energy Ultra 500 ml | EDEKA, Bahnhofstraße 10 | 1,39 € statt 1,99 € |
| Monster Energy Classic 500 ml | Netto, Alter Marktplatz 3 | 1,29 € statt 1,79 € |

Alle Preise, Zeiträume und Filialangaben sind **Demodaten**, keine erhobenen Preise.
Bilder und Logos sind leer, die App zeigt dann eigene Platzhalter.

## So benutzt du die Dateien

Alles läuft im Supabase-Dashboard unter **SQL Editor**: Datei öffnen, Inhalt
einfügen, **Run**.

- **Neues, leeres Projekt aufsetzen:** `schema.sql`, danach `seed.sql`.
- **Daten ergänzen:** Neue Zeilen in `seed.sql` (und in der passenden CSV) eintragen,
  mit neuer UUID als `id`, dann `seed.sql` ausführen. Bestehende Zeilen bleiben, gleiche
  `id`s werden auf die Werte aus der Datei gesetzt.
- **Datenstand austauschen:** `reset_inhalte.sql`, danach `seed.sql` oder einen
  eigenen Datenstand.
- **CSV statt SQL:** Im **Table Editor** je Tabelle „Insert → Import data from CSV“.
  Reihenfolge wegen Fremdschlüsseln: `retailers` → `brands` →
  `brand_nutrition_defaults` → `branches` → `products` → `product_nutrition` →
  `offers` → `price_history`. `app_settings` hat keine Abhängigkeiten.
- **App-Einstellungen ändern:** Zeile `id = 1` in `app_settings` bearbeiten. Die App
  liest sie beim Start: `demo_notice` leer = kein Beispieldaten-Hinweis,
  `default_location_*` leer = kein Startstandort (Entfernungen erst nach GPS),
  `ios_rating_url`/`android_rating_url` leer = „noch nicht im Store“.
  `reset_inhalte.sql` lässt `app_settings` unverändert.

## Regeln

- **Gleich halten:** Wer die Live-Datenbank ändert, aktualisiert diese Dateien im
  selben Schritt, und umgekehrt.
- **Nur erlaubte Quellen:** Neue Inhalte nur nach [DATENQUELLEN.md](../DATENQUELLEN.md).
  Keine Daten, Bilder oder Logos von Händler- oder Herstellerseiten.
- **Keine Geheimnisse:** Nie den `service_role`-Key, Passwörter oder Nutzerdaten
  (Profile, Favoriten, Bewertungen) in dieses Repo schreiben.
- **Lokal bleibt lokal:** Lokale Sicherungen gehören nach `supabase/seed/`. Der Ordner
  ist git-ignoriert und wird nicht committet.
