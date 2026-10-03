# Datenquellen: verbindliche Regeln

Gilt ab 03.10.2026 für jede Arbeit an CanSpot (App, Datenbank, Website, Skripte),
auch für Claude-Sessions. Diese Regeln gehen allen anderen Hinweisen in diesem
Repo vor.

1. **Keine Daten von Händler-Websites oder -Apps ohne schriftliche Erlaubnis.**
   Das betrifft Preise, Angebote, Pfand, Verfügbarkeit, Produktdaten (EAN,
   Nährwerte, Zutaten), Produktbilder, Logos und Filialdaten von REWE, EDEKA,
   Kaufland, Lidl, ALDI Nord, ALDI Süd, Netto, Penny, Norma und allen anderen
   Händlern. Es gilt für jedes Mittel: curl/HTTP-Client, Skript, Scraper,
   ferngesteuerter Browser (Playwright, Claude-Browser, Claude in Chrome,
   `javascript_tool`), inoffizielle APIs und das Abtippen vieler Seiten von Hand.
   Ausnahme nur mit schriftlicher Vereinbarung mit dem Händler oder einem
   Lizenzgeber (z. B. Bonial, Marktguru), eingetragen unter „Erteilte
   Erlaubnisse“ unten.
2. **Bot-Schutz heißt Stopp.** Blockiert eine Seite einfache Zugriffe (403,
   Cloudflare, Akamai, Challenge, CAPTCHA), wird sie nicht automatisiert genutzt.
   Das gilt auch dann, wenn ein echter Browser die Prüfung passiert.
3. **Gebaute Händler-Adapter laufen nicht ohne Erlaubnis.** Schon vorhandener Code,
   der Händlerseiten ausliest, wird weder von Hand noch per Scheduler gestartet,
   bis eine schriftliche Erlaubnis vorliegt (Regel 1).
4. **Ohne Vereinbarung erlaubte Quellen:**
   - OpenStreetMap für Filialdaten (ODbL, Pflicht: „© OpenStreetMap-Mitwirkende“).
   - Open Food Facts für Produkt- und Nährwertdaten (ODbL) und Bilder (CC-BY-SA,
     mit Namensnennung).
   - Eigene Daten: Preise, die Nutzer selbst melden, eigene Fotos.
   - Erfundene Demodaten, die in App und Website klar als Beispiel erkennbar sind.
5. **Keine fremden Logos und Bilder einbinden**, auch nicht als Link auf fremde
   Server (Händler- oder Herstellerseiten), solange keine Erlaubnis vorliegt.
   Händlernamen dürfen als Text genannt werden („bei REWE“). App und Website
   sagen klar, dass CanSpot nicht mit den Händlern verbunden ist.
6. **Recherche ja, Übernahme nein.** Einzelne Seiten ansehen, um Bedingungen,
   robots.txt, Impressum oder Kontaktwege zu prüfen, ist erlaubt. Daten daraus
   gehen nicht in CanSpot.
7. **Neue Quelle nur nach Eintrag und Freigabe.** Jede neue Datenquelle wird vorher
   hier eingetragen (Quelle, Lizenz oder Erlaubnis, Datum) und vom
   Projektinhaber freigegeben. Im Zweifel nicht machen und fragen. Vor dem
   kommerziellen Start eine Rechtsberatung (IT- und Wettbewerbsrecht) einholen.

## Erteilte Erlaubnisse

Keine (Stand 03.10.2026).

## Zugelassene Quellen

| Quelle | Wofür | Lizenz / Grundlage | Seit |
|---|---|---|---|
| OpenStreetMap | Filialdaten | ODbL, Namensnennung | 03.10.2026 |
| Open Food Facts | Produkt- und Nährwertdaten, Bilder | ODbL bzw. CC-BY-SA, Namensnennung | 03.10.2026 |
