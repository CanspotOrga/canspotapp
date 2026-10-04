-- ============================================================================
-- CanSpot — Supabase-Datenbankschema
-- ============================================================================
-- Stand: entspricht dem Live-Projekt am 03.10.2026 (Tabellen, Constraints,
-- Indizes, Funktionen, Trigger, RLS-Policies, Grants, Storage-Bucket für
-- Profilbilder).
--
-- Nur für ein LEERES Supabase-Projekt: legt alle Tabellen neu an und bricht
-- ab, wenn sie schon existieren. Inhalte stehen in seed.sql.
--
-- Nicht enthalten: Objekte, die Supabase selbst anlegt (z. B. Event-Trigger
-- ensure_rls mit Funktion public.rls_auto_enable, Extensions-Schema).
--
-- Grundentscheidungen (auf sie verweisen die Tabellenkommentare):
--   1. Produkt (Marke/Name/Einzelgröße/Verpackung) vs. Verkaufsform (units)
--      -> packaging liegt an products, nicht an offers.
--   2. Preisverlauf als eigenständige, von offers entkoppelte Tabelle.
--   3. Händler (retailers) und Filialen (branches) getrennt, 1:n.
--   4. Bewertungen sind echte Nutzerdaten, max. 1 pro user+product,
--      Rohdaten privat, nur Aggregat öffentlich.
--   5. Preis-Feedback funktioniert auch ohne Login (user_id nullable).
--   6. Account-Löschfeedback bleibt komplett ohne Personenbezug.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 0. EXTENSIONS
-- ----------------------------------------------------------------------------

create extension if not exists pgcrypto with schema extensions; -- liefert gen_random_uuid()
create extension if not exists pg_net with schema extensions;   -- Aufruf avatar-cleanup (Abschnitt 10)


-- ----------------------------------------------------------------------------
-- 1. HILFSFUNKTIONEN
-- ----------------------------------------------------------------------------

-- Generischer "updated_at automatisch nachziehen"-Trigger, wiederverwendet
-- für jede Tabelle mit einer updated_at-Spalte (siehe unten).
create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;


-- ----------------------------------------------------------------------------
-- 2. ÖFFENTLICHE MASTERDATEN (Produkte, Händler, Angebote, Preisverlauf)
--    Lesend öffentlich für jeden (auch ohne Login), schreibend ausschließlich
--    über die Service-Role/ein Admin-Tool - siehe RLS-Abschnitt weiter unten.
-- ----------------------------------------------------------------------------

create table public.brands (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  created_at timestamptz not null default now(),
  constraint brands_name_unique unique (name)
);
comment on table public.brands is 'Marken, z.B. "Red Bull", "Monster".';


-- Produkt = die eigentliche Ware (Marke+Name+Groesse+Verpackung EINER
-- einzelnen Einheit). Die Verkaufsform (1er/6er/12er-Pack) gehoert bewusst
-- NICHT hierher, sondern zu offers.units - siehe Entscheidung 1. packaging
-- liegt hier, weil sich die Verpackungsart eines Produkts nie zwischen
-- Haendlern aendert (eine Dose bleibt bei jedem Haendler eine Dose).
create table public.products (
  id         uuid primary key default gen_random_uuid(),
  brand_id   uuid not null references public.brands(id) on delete restrict,
  name       text not null,
  size_ml    integer not null check (size_ml > 0),
  packaging  text not null check (packaging in ('Dose','Flasche')),
  image_url  text,
  is_new     boolean not null default false,
  created_at timestamptz not null default now()
);
create index products_brand_id_idx on public.products(brand_id);
comment on table public.products is 'Ein Produkt = eine konkrete Geschmacksrichtung/Groesse (z.B. "Red Bull Energy Drink 250ml, Dose"). Preis/Liter und Preis/Einheit werden NIE gespeichert, sondern immer aus offers.offer_price / (offers.units * size_ml/1000) berechnet.';


-- Nährwerte 1:1 zum Produkt, nullable je Feld - entspricht der heutigen
-- NUTRITION_MOCK_BY_PRODUCT-Ausnahme-Ebene in index.html. Fehlt eine Zeile
-- fuer ein Produkt komplett, greift client-/serverseitig als naechste Stufe
-- brand_nutrition_defaults, danach ein hartcodierter globaler Default (wie
-- heute NUTRITION_FALLBACK_PER_100ML) - dieselbe 3-stufige Fallback-Kette
-- wie im Prototyp, nur die ersten beiden Stufen wandern in echte Tabellen.
create table public.product_nutrition (
  product_id   uuid primary key references public.products(id) on delete cascade,
  kcal         numeric,
  carbs_g      numeric,
  sugar_g      numeric,
  fat_g        numeric,
  sat_fat_g    numeric,
  protein_g    numeric,
  salt_g       numeric,
  caffeine_mg  numeric,
  taurine_mg   numeric
);
comment on table public.product_nutrition is 'Naehrwerte pro 100ml, 1:1 optional zu products. Entspricht NUTRITION_MOCK_BY_PRODUCT in index.html.';


-- Optionale Zwischenstufe der Fallback-Kette (entspricht
-- NUTRITION_MOCK_BY_BRAND). Kann leer bleiben, sobald jedes Produkt eigene
-- Naehrwerte hat.
create table public.brand_nutrition_defaults (
  brand_id     uuid primary key references public.brands(id) on delete cascade,
  kcal         numeric,
  carbs_g      numeric,
  sugar_g      numeric,
  fat_g        numeric,
  sat_fat_g    numeric,
  protein_g    numeric,
  salt_g       numeric,
  caffeine_mg  numeric,
  taurine_mg   numeric
);
comment on table public.brand_nutrition_defaults is 'Marken-Fallback-Naehrwerte, entspricht NUTRITION_MOCK_BY_BRAND in index.html - nur genutzt, wenn product_nutrition fuer ein Produkt fehlt.';


create table public.retailers (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  logo_url   text,
  created_at timestamptz not null default now(),
  constraint retailers_name_unique unique (name)
);
comment on table public.retailers is 'Haendlerketten. logo_url nur mit Erlaubnis des Rechteinhabers (siehe DATENQUELLEN.md).';


-- Konkrete Filiale einer Kette, beliebig viele pro Kette (retailer_id).
-- latitude/longitude sind PFLICHT, da distanceKm nicht gespeichert, sondern
-- immer aus diesen Koordinaten + der Nutzerposition berechnet wird
-- (Entscheidung 3, siehe applyRealDistances() in index.html).
create table public.branches (
  id             uuid primary key default gen_random_uuid(),
  retailer_id    uuid not null references public.retailers(id) on delete restrict,
  street         text not null,
  postal_code    text not null,
  city           text not null,
  latitude       numeric(9,6) not null,
  longitude      numeric(9,6) not null,
  opens_at       time not null,
  closes_at      time not null,
  closed_sunday  boolean not null default false,
  created_at     timestamptz not null default now()
);
create index branches_retailer_id_idx on public.branches(retailer_id);
comment on table public.branches is 'Konkrete Filiale eines Haendlers (1:n zu retailers). Adresse aufgeteilt in street/postal_code/city.';


-- Ein zeitlich gueltiges Angebot = Produkt x Filiale x Verkaufsform (units).
-- branch_id ersetzt das heutige offers[].store (String-Name der Kette).
create table public.offers (
  id                uuid primary key default gen_random_uuid(),
  product_id        uuid not null references public.products(id) on delete restrict,
  branch_id         uuid not null references public.branches(id) on delete restrict,
  units             integer not null default 1 check (units > 0),
  regular_price     numeric(10,2) not null check (regular_price >= 0),
  offer_price       numeric(10,2) not null check (offer_price >= 0),
  deposit           numeric(10,2) not null default 0 check (deposit >= 0),
  valid_from        date not null,
  valid_until       date not null,
  link              text,
  bundle_image_url  text,
  last_checked_at   date,
  created_at        timestamptz not null default now(),
  constraint offers_valid_range_check check (valid_until >= valid_from)
);
create index offers_product_id_idx on public.offers(product_id);
create index offers_branch_id_idx on public.offers(branch_id);
create index offers_valid_range_idx on public.offers(valid_from, valid_until);
comment on table public.offers is 'Ein Angebot bindet ein Produkt an eine konkrete Filiale + Verkaufsform (units) fuer einen Zeitraum. distanceKm existiert hier bewusst NICHT (Entscheidung 3) - wird immer aus branches.latitude/longitude + Nutzerposition live berechnet.';


-- Eigenstaendiges, von offers entkoppeltes Preis-Zeitreihen-Log
-- (Entscheidung 2). units ist Teil des Unique-Constraints, weil dasselbe
-- Produkt an derselben Filiale gleichzeitig in mehreren Packungsgroessen mit
-- unterschiedlichem Preis laufen kann (z.B. 1er- und 4er-Pack) - ohne units
-- waere der Verlauf EINER konkreten Verkaufsform nicht mehr eindeutig
-- rekonstruierbar. Es werden nur echte, zulaessig erhobene Preise gespeichert.
create table public.price_history (
  id           bigserial primary key,
  product_id   uuid not null references public.products(id) on delete restrict,
  branch_id    uuid not null references public.branches(id) on delete restrict,
  units        integer not null check (units > 0),
  price        numeric(10,2) not null check (price >= 0),
  deposit      numeric(10,2),
  recorded_at  date not null,
  available    boolean not null default true,
  constraint price_history_unique unique (product_id, branch_id, units, recorded_at)
);
comment on table public.price_history is 'Echtes Preis-Zeitreihen-Log, entkoppelt von offers (Entscheidung 2). Nur echte, zulaessig erhobene Preise.';


-- App-weite Einstellungen, die die App beim Start liest (statt sie fest in
-- index.html zu halten): Startstandort, Standard-Umkreis, Beispieldaten-
-- Hinweis, Versionstext, Store-Bewertungslinks. Genau eine Zeile (id = 1).
create table public.app_settings (
  id                      smallint primary key default 1 check (id = 1),
  default_location_label  text,
  default_latitude        double precision check (default_latitude between -90 and 90),
  default_longitude       double precision check (default_longitude between -180 and 180),
  default_radius_km       integer not null default 10 check (default_radius_km between 1 and 200),
  demo_notice             text,
  app_version             text,
  ios_rating_url          text,
  android_rating_url      text,
  updated_at              timestamptz not null default now()
);
comment on table public.app_settings is 'App-weite Einstellungen (genau eine Zeile, id = 1). demo_notice null = kein Beispieldaten-Hinweis. Rating-URLs null = App noch nicht im Store.';

create trigger trg_app_settings_updated_at
  before update on public.app_settings
  for each row execute function public.set_updated_at();


-- ----------------------------------------------------------------------------
-- 3. PROFIL (1:1 zu auth.users)
-- ----------------------------------------------------------------------------

-- E-Mail und Passwort liegen bewusst NICHT hier, sondern werden vollstaendig
-- von Supabase Auth (auth.users) verwaltet.
create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  username     text,
  first_name   text,
  last_name    text,
  birthdate    date,
  street       text,
  postal_code  text,
  city         text,
  country      text default 'Deutschland',
  avatar_url   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  constraint profiles_username_format check (
    username is null or (
      username ~ '^[A-Za-z0-9_]{3,20}$'
      and lower(username) not in ('admin','administrator','canspot','support','moderator','root','system')
    )
  ),
  constraint profiles_first_name_format check (
    first_name is null or (char_length(first_name) between 1 and 50 and first_name !~ '[[:cntrl:]]' and first_name = btrim(first_name))
  ),
  constraint profiles_last_name_format check (
    last_name is null or (char_length(last_name) between 1 and 50 and last_name !~ '[[:cntrl:]]' and last_name = btrim(last_name))
  )
);
create unique index profiles_username_lower_key on public.profiles (lower(username));
comment on column public.profiles.username is 'Nutzername, 3-20 Zeichen (A-Z, a-z, 0-9, _), eindeutig ohne Ruecksicht auf Gross-/Kleinschreibung. Wird bei der Registrierung aus raw_user_meta_data.username gesetzt (handle_new_user). NULL nur bei Konten von vor dieser Spalte; die App fordert dann einen an.';
comment on column public.profiles.first_name is 'Ungenutzt: Die App zeigt nur den Nutzernamen. Falls befuellt: 1-50 Zeichen ohne Steuerzeichen, nur fuer den Besitzer sichtbar (RLS).';
comment on column public.profiles.last_name is 'Ungenutzt: Die App zeigt nur den Nutzernamen. Falls befuellt: 1-50 Zeichen ohne Steuerzeichen, nur fuer den Besitzer sichtbar (RLS).';
comment on table public.profiles is 'Profildaten, 1:1 zu auth.users. Genutzt wird nur username (nur fuer den Besitzer sichtbar). first_name, last_name, birthdate, street, postal_code, city, country und avatar_url sind ungenutzt: Es gibt keinen Vor-/Nachnamen, Geburtsdatum und Adresse bleiben lokal auf dem Geraet, das Profilbild liegt im Bucket avatars.';

create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();


-- ----------------------------------------------------------------------------
-- 4. NUTZERBEZOGENE TABELLEN (privat, an auth.users gebunden)
-- ----------------------------------------------------------------------------

create table public.favorites (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  product_id  uuid not null references public.products(id) on delete cascade,
  units       integer not null check (units > 0),
  created_at  timestamptz not null default now(),
  constraint favorites_unique unique (user_id, product_id, units)
);
create index favorites_user_id_idx on public.favorites(user_id);
comment on table public.favorites is 'Entspricht canspot-favorites (Set aus "productId:units"). Ein Favorit ist pro Gebindegroesse eigenstaendig, nicht nur pro Produkt.';


-- Echte Nutzerbewertungen (Entscheidung 4). taste/sweetness/intensity/
-- aftertaste nutzen NULL fuer "nicht bewertet" (nicht 0 wie im heutigen
-- Prototyp-localStorage, siehe pdRatingSaveBtn-Handler in index.html, der
-- unangetastete Kriterien beim Speichern als 0 mit-persistiert) - NULL wird
-- von AVG() automatisch korrekt ignoriert, waehrend eine gespeicherte 0 den
-- Durchschnitt faelschlich nach unten ziehen wuerde.
create table public.ratings (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  product_id  uuid not null references public.products(id) on delete cascade,
  vote        text check (vote in ('up','down')),
  taste       smallint check (taste between 1 and 5),
  sweetness   smallint check (sweetness between 1 and 5),
  intensity   smallint check (intensity between 1 and 5),
  aftertaste  smallint check (aftertaste between 1 and 5),
  updated_at  timestamptz not null default now(),
  constraint ratings_unique unique (user_id, product_id)
);
create index ratings_product_id_idx on public.ratings(product_id);
comment on table public.ratings is 'Max. eine Bewertung pro Nutzer+Produkt (Entscheidung 4). Rohdaten sind privat (siehe RLS) - oeffentlich sichtbar ist nur das Aggregat ueber public.get_product_rating_summary().';

create trigger trg_ratings_updated_at
  before update on public.ratings
  for each row execute function public.set_updated_at();


create table public.price_alerts (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  product_id    uuid not null references public.products(id) on delete cascade,
  target_price  numeric(10,2) not null check (target_price > 0),
  enabled       boolean not null default true,
  created_at    timestamptz not null default now(),
  constraint price_alerts_unique unique (user_id, product_id)
);
create index price_alerts_user_id_idx on public.price_alerts(user_id);
comment on table public.price_alerts is 'Entspricht canspot-alerts ({[productId]: {target, enabled}}).';


-- "Preis noch aktuell?"-Meldungen (Entscheidung 5) - user_id ist bewusst
-- NULLABLE, damit das Feature ohne Login funktioniert (wie heute im
-- Prototyp, wo es ueberhaupt kein Login gibt). client_ref ist ein rein
-- lokal (z.B. localStorage) erzeugter, anonymer Geraete-/Sitzungs-
-- Identifier - KEIN Konto-Bezug -, der spaeter als einfache Grundlage fuer
-- Spam-/Missbrauchs-Heuristiken dienen kann (z.B. "max. N Meldungen pro
-- client_ref und Angebot pro Tag"), ohne heute schon Rate-Limiting-Logik
-- oder zusaetzliche Tabellen einzufuehren.
create table public.price_feedback_reports (
  id                bigserial primary key,
  user_id           uuid references auth.users(id) on delete set null,
  product_id        uuid not null references public.products(id) on delete cascade,
  branch_id         uuid not null references public.branches(id) on delete cascade,
  offer_id          uuid references public.offers(id) on delete set null,
  displayed_price   numeric(10,2) not null check (displayed_price >= 0),
  reported_price    numeric(10,2) check (reported_price is null or reported_price >= 0),
  vote              text not null check (vote in ('up','down')),
  client_ref        text,
  reported_at       timestamptz not null default now()
);
create index price_feedback_reports_product_id_idx on public.price_feedback_reports(product_id);
create index price_feedback_reports_branch_id_idx on public.price_feedback_reports(branch_id);
comment on table public.price_feedback_reports is 'Entspricht canspot-price-feedback. user_id nullable (Entscheidung 5, Feature funktioniert ohne Login). offer_id ON DELETE SET NULL, da Angebote spaeter ablaufen/geloescht werden koennen, ohne die Meldung selbst zu entwerten.';


create table public.notification_settings (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  best_price  boolean not null default true,
  favorites   boolean not null default true,
  nearby      boolean not null default true,
  weekly      boolean not null default false
);
comment on table public.notification_settings is 'Entspricht den vier canspot-notif-* Keys (notifBest/notifFav/notifNearby/notifWeekly).';


-- Zuletzt angesehene Produkte (Produktdetailansicht). Nur fuer angemeldete
-- Nutzer; geschrieben wird ausschliesslich ueber record_product_view()
-- weiter unten, die pro Nutzer nur die 20 neuesten Eintraege behaelt.
create table public.recently_viewed (
  user_id     uuid not null references auth.users(id) on delete cascade,
  product_id  uuid not null references public.products(id) on delete cascade,
  viewed_at   timestamptz not null default now(),
  primary key (user_id, product_id)
);
create index recently_viewed_user_viewed_idx on public.recently_viewed(user_id, viewed_at desc);
create index recently_viewed_product_id_idx on public.recently_viewed(product_id);
comment on table public.recently_viewed is 'Zuletzt angesehene Produkte je Konto (Produktdetailansicht). Pro Nutzer hoechstens 20 Eintraege, aeltere entfernt record_product_view().';

-- Merkt ein angesehenes Produkt (Zeitpunkt = Serverzeit) und kuerzt die
-- Liste auf die 20 neuesten Eintraege. SECURITY INVOKER: laeuft mit den
-- Rechten des Aufrufers, RLS von recently_viewed greift.
create function public.record_product_view(p_product_id uuid)
returns void
language sql
security invoker
set search_path = ''
as $$
  insert into public.recently_viewed (user_id, product_id, viewed_at)
  values ((select auth.uid()), p_product_id, now())
  on conflict (user_id, product_id) do update set viewed_at = excluded.viewed_at;

  delete from public.recently_viewed
  where user_id = (select auth.uid())
    and product_id not in (
      select product_id from public.recently_viewed
      where user_id = (select auth.uid())
      order by viewed_at desc
      limit 20
    );
$$;
comment on function public.record_product_view(uuid) is 'Merkt ein angesehenes Produkt fuer den angemeldeten Nutzer (Zeitpunkt = Serverzeit) und behaelt nur die 20 neuesten Eintraege. SECURITY INVOKER, RLS greift.';
revoke execute on function public.record_product_view(uuid) from public, anon;
grant execute on function public.record_product_view(uuid) to authenticated;


-- ----------------------------------------------------------------------------
-- 5. ANONYMISIERTES LÖSCH-FEEDBACK (Entscheidung 6)
-- ----------------------------------------------------------------------------

-- Bewusst KEINE user_id-Spalte, auch nicht unverknuepft/ohne Foreign Key -
-- schaerfer als "nachtraeglich entkoppeln": es wird zu keinem Zeitpunkt ein
-- Personenbezug gespeichert. Einfuegen erfolgt ausschliesslich serverseitig
-- (Service-Role oder eine SECURITY DEFINER Edge Function) als Teil des
-- eigentlichen Account-Loeschvorgangs, nie direkt vom Client mit
-- Nutzerkontext - siehe RLS-Abschnitt unten (keine Policy fuer
-- anon/authenticated).
create table public.account_deletion_feedback (
  id          bigserial primary key,
  reason      text,
  note        text,
  deleted_at  timestamptz not null default now()
);
comment on table public.account_deletion_feedback is 'Entspricht canspot-delete-feedback, aber ohne jeden Personenbezug (Entscheidung 6). Kein FK zu auth.users.';


-- ----------------------------------------------------------------------------
-- 6. AUTH-TRIGGER: profiles/notification_settings automatisch anlegen
-- ----------------------------------------------------------------------------
-- Standard-Supabase-Muster: sobald sich jemand ueber Supabase Auth
-- registriert (auth.users-Insert), werden automatisch eine profiles-Zeile
-- (mit dem Nutzernamen aus raw_user_meta_data.username) und eine
-- notification_settings-Zeile angelegt, damit die App nie gegen eine
-- fehlende 1:1-Zeile pruefen muss. Ohne Nutzernamen wird die Registrierung
-- abgelehnt (Pflichtfeld, auch bei direktem API-Aufruf).

create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
  v_username text := nullif(btrim(new.raw_user_meta_data->>'username'), '');
begin
  if v_username is null then
    raise exception 'username required' using errcode = '23502';
  end if;
  insert into public.profiles (id, username) values (new.id, v_username);
  insert into public.notification_settings (user_id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Haertung: CREATE FUNCTION vergibt EXECUTE standardmaessig an PUBLIC (jede
-- Rolle). handle_new_user() wird ausschliesslich ueber den obigen Trigger
-- aufgerufen (der Trigger-Mechanismus benoetigt dafuer kein eigenes
-- EXECUTE-Recht der ausloesenden Rolle) - daher hier explizit von PUBLIC
-- entziehen, damit die Funktion nicht zusaetzlich direkt aufrufbar ist.
revoke execute on function public.handle_new_user() from public;

-- Verfuegbarkeit eines Nutzernamens vor der Registrierung pruefen. Bewusst
-- fuer anon freigegeben (Advisor-Warnung 0028 ist gewollt); liefert nur
-- true/false, keine Profildaten.
create function public.is_username_available(p_username text)
returns boolean
language sql
stable
security definer set search_path = ''
as $$
  select coalesce(p_username, '') ~ '^[A-Za-z0-9_]{3,20}$'
     and lower(p_username) not in ('admin','administrator','canspot','support','moderator','root','system')
     and not exists (select 1 from public.profiles where lower(username) = lower(p_username));
$$;
comment on function public.is_username_available(text) is 'true, wenn der Nutzername gueltig und frei ist. Fuer anon freigegeben, damit die Registrierung vorab pruefen kann; liefert keine Profildaten.';
revoke execute on function public.is_username_available(text) from public;
grant execute on function public.is_username_available(text) to anon, authenticated;

-- Konto loeschen aus der App (Entscheidung 6): loescht ausschliesslich das
-- Konto von auth.uid(); alle Nutzerdaten fallen per ON DELETE CASCADE weg,
-- price_feedback_reports.user_id wird NULL. Der optionale Loeschgrund wird
-- ohne Personenbezug in account_deletion_feedback gespeichert. Nur fuer
-- authenticated (Advisor-Warnung 0029 ist gewollt), nicht fuer anon.
-- Das Profilbild (Bucket avatars) raeumt der Trigger trg_users_avatar_cleanup
-- nach dem Loeschen auf (Abschnitt 10).
create function public.delete_my_account(p_reason text default null, p_note text default null)
returns void
language plpgsql
security definer set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_reason text := case when p_reason in ('unused','not-found','missing-features','not-as-expected','technical-issue','offer-volume','privacy','other') then p_reason end;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  if v_reason is not null then
    insert into public.account_deletion_feedback (reason, note)
    values (v_reason, case when v_reason = 'other' then nullif(left(btrim(coalesce(p_note, '')), 500), '') end);
  end if;
  delete from auth.users where id = v_uid;
end;
$$;
revoke execute on function public.delete_my_account(text, text) from public, anon;
grant execute on function public.delete_my_account(text, text) to authenticated;


-- ----------------------------------------------------------------------------
-- 7. ÖFFENTLICHES BEWERTUNGS-AGGREGAT
-- ----------------------------------------------------------------------------
-- SECURITY DEFINER-Funktion statt einer einfachen View: dadurch kann die
-- Aggregation ueber ALLE Nutzer-Bewertungen laufen (die Funktion umgeht die
-- RLS-Policy von ratings, da sie mit den Rechten ihres Eigentuemers laeuft),
-- waehrend Endnutzer selbst weiterhin nur ihre eigene Zeile in ratings lesen
-- duerfen. Genau das setzt Entscheidung 4 ("oeffentlich nur aggregierte
-- Ergebnisse, keine persoenlichen Einzeldaten") technisch um.
--
-- Formel entspricht 1:1 dem heutigen getProductRatingSummary() in
-- index.html (dort noch deterministisch/erfunden, hier aus echten Zeilen):
--   percent_positive = 100 * Anzahl "up" / Anzahl aller gesetzten Stimmen
--   rating_count      = Anzahl aller gesetzten Stimmen
--   avg_stars         = Mittel der vier Kriterien-Durchschnitte (je Kriterium
--                        zuerst einzeln gemittelt, danach die vier Werte
--                        gemittelt - nicht ein flacher Durchschnitt aller
--                        Einzelwerte)
create function public.get_product_rating_summary(p_product_id uuid)
returns table (
  percent_positive numeric,
  rating_count     integer,
  avg_stars        numeric
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    round(
      100.0 * count(*) filter (where vote = 'up')
      / nullif(count(*) filter (where vote is not null), 0)
    , 0) as percent_positive,
    count(*) filter (where vote is not null)::integer as rating_count,
    (
      coalesce(avg(taste), 0) + coalesce(avg(sweetness), 0)
      + coalesce(avg(intensity), 0) + coalesce(avg(aftertaste), 0)
    ) / nullif(
      (case when avg(taste) is not null then 1 else 0 end)
      + (case when avg(sweetness) is not null then 1 else 0 end)
      + (case when avg(intensity) is not null then 1 else 0 end)
      + (case when avg(aftertaste) is not null then 1 else 0 end)
    , 0) as avg_stars
  from public.ratings
  where product_id = p_product_id;
$$;

-- Haertung: CREATE FUNCTION vergibt EXECUTE standardmaessig an PUBLIC - erst
-- entziehen, dann gezielt nur an anon/authenticated vergeben (bleibt
-- oeffentlich ausfuehrbar, da sie ausschliesslich aggregierte Rating-Daten
-- zurueckgibt, siehe Entscheidung 4), statt sie ueber PUBLIC unnoetig fuer
-- jede denkbare zukuenftige Rolle offenzulassen.
revoke execute on function public.get_product_rating_summary(uuid) from public;
grant execute on function public.get_product_rating_summary(uuid) to anon, authenticated;

comment on function public.get_product_rating_summary is 'Oeffentliches Bewertungs-Aggregat pro Produkt. Ersetzt die heutige, rein deterministisch/hash-generierte getProductRatingSummary() in index.html durch eine echte Aggregation, ohne einzelne Nutzerbewertungen offenzulegen. Der bestehende Bayesian-Average-Sortieralgorithmus (getWeightedRatingScore() in index.html) bleibt unveraendert wiederverwendbar, da er nur (R, v, C) braucht, unabhaengig von der Datenquelle.';

-- Alle Produkt-Aggregate in einem Aufruf (von index.html beim Start geladen),
-- inkl. Durchschnitt je Kriterium fuer das Community-Popover.
create function public.get_all_product_rating_summaries()
returns table(
  product_id uuid,
  percent_positive numeric,
  rating_count integer,
  avg_taste numeric,
  avg_sweetness numeric,
  avg_intensity numeric,
  avg_aftertaste numeric
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    r.product_id,
    round(100.0 * count(*) filter (where r.vote = 'up')
      / nullif(count(*) filter (where r.vote is not null), 0), 0),
    (count(*) filter (where r.vote is not null))::integer,
    avg(r.taste), avg(r.sweetness), avg(r.intensity), avg(r.aftertaste)
  from public.ratings r
  group by r.product_id;
$$;

revoke execute on function public.get_all_product_rating_summaries() from public;
grant execute on function public.get_all_product_rating_summaries() to anon, authenticated;


-- ============================================================================
-- 8. ROW LEVEL SECURITY
-- ============================================================================

-- ---- Oeffentliche Masterdaten: fuer jeden lesbar (auch anon), Schreiben
--      ausschliesslich ueber die Service-Role (bypasst RLS automatisch,
--      braucht daher hier keine eigene Policy). ----

alter table public.brands enable row level security;
create policy "brands_public_read" on public.brands
  for select to anon, authenticated using (true);

alter table public.products enable row level security;
create policy "products_public_read" on public.products
  for select to anon, authenticated using (true);

alter table public.product_nutrition enable row level security;
create policy "product_nutrition_public_read" on public.product_nutrition
  for select to anon, authenticated using (true);

alter table public.brand_nutrition_defaults enable row level security;
create policy "brand_nutrition_defaults_public_read" on public.brand_nutrition_defaults
  for select to anon, authenticated using (true);

alter table public.retailers enable row level security;
create policy "retailers_public_read" on public.retailers
  for select to anon, authenticated using (true);

alter table public.branches enable row level security;
create policy "branches_public_read" on public.branches
  for select to anon, authenticated using (true);

alter table public.offers enable row level security;
create policy "offers_public_read" on public.offers
  for select to anon, authenticated using (true);

alter table public.price_history enable row level security;
create policy "price_history_public_read" on public.price_history
  for select to anon, authenticated using (true);

alter table public.app_settings enable row level security;
create policy "app_settings_public_read" on public.app_settings
  for select to anon, authenticated using (true);


-- ---- profiles: nur die eigene Zeile ----

alter table public.profiles enable row level security;

create policy "profiles_select_own" on public.profiles
  for select to authenticated using (auth.uid() = id);

create policy "profiles_update_own" on public.profiles
  for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- Kein INSERT/DELETE fuer Endnutzer: profiles wird ausschliesslich durch den
-- on_auth_user_created-Trigger angelegt bzw. per CASCADE ueber auth.users
-- geloescht.


-- ---- favorites / price_alerts / notification_settings: nur eigene Zeilen,
--      voller CRUD-Zugriff auf die eigenen Daten. ----

alter table public.favorites enable row level security;
create policy "favorites_all_own" on public.favorites
  for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.price_alerts enable row level security;
create policy "price_alerts_all_own" on public.price_alerts
  for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.notification_settings enable row level security;
create policy "notification_settings_all_own" on public.notification_settings
  for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.recently_viewed enable row level security;
create policy "recently_viewed_all_own" on public.recently_viewed
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);


-- ---- ratings: Rohdaten nur fuer den eigenen Nutzer sichtbar/aenderbar.
--      Das oeffentliche Aggregat laeuft ueber get_product_rating_summary()
--      oben, NICHT ueber eine Policy auf dieser Tabelle. ----

alter table public.ratings enable row level security;
create policy "ratings_all_own" on public.ratings
  for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);


-- ---- price_feedback_reports: Einfuegen oeffentlich (auch anonym). KEIN
--      SELECT fuer anon/authenticated - die Daten werden ausschliesslich
--      serverseitig/admin-seitig (Service-Role) ausgelesen. Kein Update/
--      Delete fuer Endnutzer (eine Meldung ist nach dem Absenden
--      abgeschlossen). ----

alter table public.price_feedback_reports enable row level security;

create policy "price_feedback_insert_anyone" on public.price_feedback_reports
  for insert to anon, authenticated
  with check (user_id is null or auth.uid() = user_id);

-- Bewusst KEINE select-Policy fuer anon/authenticated: normale Clients
-- duerfen eingereichte Preis-Feedback-Meldungen nicht lesen, weder eigene
-- noch fremde. Lesender Zugriff bleibt der Service-Role vorbehalten (siehe
-- GRANTs weiter unten), die RLS ohnehin umgeht.


-- ---- account_deletion_feedback: keine Policy fuer anon/authenticated -
--      Einfuegen laeuft ausschliesslich ueber die Service-Role bzw. eine
--      SECURITY DEFINER Edge Function als Teil des echten Account-
--      Loeschvorgangs. RLS ist trotzdem aktiviert (default-deny), damit ein
--      versehentliches Fehlen einer Policy nicht zu offenem Zugriff fuehrt. ----

alter table public.account_deletion_feedback enable row level security;
-- Bewusst keine create policy-Anweisung fuer anon/authenticated.


-- ============================================================================
-- 9. EXPLIZITE DATA-API-GRANTS
-- ============================================================================
-- Noetig, weil "Automatically expose new tables" im Supabase-Projekt
-- deaktiviert ist - Tabellen bekommen dadurch KEINE automatischen
-- anon/authenticated-Rechte mehr, sobald sie per SQL angelegt werden. RLS
-- (Abschnitt 8) entscheidet zwar, WELCHE ZEILEN eine Rolle sehen/aendern
-- darf, aber ohne einen passenden GRANT darf die Rolle die Tabelle ueberhaupt
-- nicht ansprechen - beides zusammen ist fuer Data-API-Zugriff erforderlich.
-- Schema-USAGE ist auf Supabase-Projekten normalerweise bereits vorhanden,
-- wird hier aber der Vollstaendigkeit halber explizit mitgegeben.

grant usage on schema public to anon, authenticated, service_role;


-- ---- Oeffentlich lesbare Stammdaten: SELECT fuer anon + authenticated.
--      Schreibzugriff bleibt bewusst aus (siehe service_role weiter unten). ----

grant select on public.brands                  to anon, authenticated;
grant select on public.products                to anon, authenticated;
grant select on public.product_nutrition       to anon, authenticated;
grant select on public.brand_nutrition_defaults to anon, authenticated;
grant select on public.retailers               to anon, authenticated;
grant select on public.branches                to anon, authenticated;
grant select on public.offers                  to anon, authenticated;
grant select on public.price_history           to anon, authenticated;
grant select on public.app_settings            to anon, authenticated;


-- ---- Private Nutzerdaten: exakt die Operationen, die die jeweilige
--      RLS-Policy oben tatsaechlich erlaubt. profiles hat keine INSERT-/
--      DELETE-Policy (siehe Abschnitt 8) und bekommt daher hier auch kein
--      INSERT-/DELETE-GRANT - ein GRANT ohne passende Policy waere ohnehin
--      wirkungslos, aber die engere Rechtevergabe spiegelt die Absicht klarer
--      wider. favorites/ratings/price_alerts/notification_settings haben
--      "for all"-Policies (SELECT/INSERT/UPDATE/DELETE), daher volle Rechte. ----

grant select, update on public.profiles to authenticated;

grant select, insert, update, delete on public.favorites             to authenticated;
grant select, insert, update, delete on public.ratings               to authenticated;
grant select, insert, update, delete on public.price_alerts          to authenticated;
grant select, insert, update, delete on public.notification_settings to authenticated;
grant select, insert, update, delete on public.recently_viewed       to authenticated;


-- ---- price_feedback_reports: nur INSERT fuer anon + authenticated (auch
--      anonym, siehe Policy oben) - explizit KEIN SELECT/UPDATE/DELETE, die
--      Daten werden ausschliesslich serverseitig/admin-seitig ausgelesen. ----

grant insert on public.price_feedback_reports to anon, authenticated;

-- id ist bigserial (= integer + implizite Sequenz) - INSERT ohne explizit
-- angegebenen id-Wert ruft intern nextval() auf der Sequenz auf, dafuer
-- braucht die einfuegende Rolle zusaetzlich USAGE auf genau dieser Sequenz.
grant usage, select on sequence public.price_feedback_reports_id_seq to anon, authenticated;


-- ---- account_deletion_feedback: bewusst KEIN Grant an anon/authenticated,
--      auch keine Sequence-Rechte - Einfuegen laeuft ausschliesslich
--      serverseitig (service_role bzw. eine SECURITY DEFINER Edge Function). ----

-- (keine GRANTs an anon/authenticated fuer diese Tabelle)


-- ---- service_role: bypasst RLS ohnehin, braucht aber trotzdem explizite
--      Tabellen-/Sequenz-Rechte, um ueberhaupt lesen/schreiben zu duerfen -
--      volle Rechte auf allen Tabellen und Sequenzen fuer serverseitige
--      Vorgaenge (u.a. Preisdaten-Import, Konto-Loeschung inkl.
--      account_deletion_feedback, Admin-Auswertung von
--      price_feedback_reports). ----

grant all privileges on all tables in schema public to service_role;
grant all privileges on all sequences in schema public to service_role;


-- ============================================================================
-- 10. STORAGE: PROFILBILDER (Bucket avatars, privat)
-- ============================================================================
-- Je Konto genau eine Datei <user_id>/avatar.jpg. Die App verkleinert das
-- Bild vorher auf 160x160 Pixel und speichert es neu als JPEG (ohne
-- Metadaten wie Aufnahmeort). Der Bucket ist nicht oeffentlich; lesen,
-- schreiben und loeschen darf nur der Besitzer. Der feste Dateiname
-- begrenzt den Speicher auf eine Datei pro Konto (hoechstens 50 KB).
-- Loeschen geht nur ueber die Storage-API (Trigger storage.protect_delete).
-- Die App entfernt das Bild vor delete_my_account(); fuer alle anderen Faelle
-- (Dashboard, Admin-API, Fehler) raeumt trg_users_avatar_cleanup auf.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', false, 51200, array['image/jpeg'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy "avatars_select_own" on storage.objects
  for select to authenticated
  using (bucket_id = 'avatars' and name = (select auth.uid())::text || '/avatar.jpg');

create policy "avatars_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and name = (select auth.uid())::text || '/avatar.jpg');

create policy "avatars_update_own" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and name = (select auth.uid())::text || '/avatar.jpg')
  with check (bucket_id = 'avatars' and name = (select auth.uid())::text || '/avatar.jpg');

create policy "avatars_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and name = (select auth.uid())::text || '/avatar.jpg');

-- Nach dem Loeschen eines Kontos (App, Dashboard, Admin-API) das Profilbild
-- im Hintergrund entfernen: Liegt noch <id>/avatar.jpg im Bucket avatars,
-- ruft die Datenbank die Edge Function avatar-cleanup auf (nur die Konto-ID,
-- Region Frankfurt, Quelltext unter supabase/functions/avatar-cleanup). Die
-- Funktion loescht nur diese eine Datei und nur, wenn das Konto nicht mehr
-- existiert. pg_net sendet erst nach dem Commit.
create function public.cleanup_avatar_after_user_delete()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  if exists (
    select 1 from storage.objects
    where bucket_id = 'avatars' and name = old.id::text || '/avatar.jpg'
  ) then
    perform net.http_post(
      url := 'https://kyksbqrdtdusdbqwvazw.supabase.co/functions/v1/avatar-cleanup',
      body := jsonb_build_object('user_id', old.id),
      headers := jsonb_build_object('Content-Type', 'application/json', 'x-region', 'eu-central-1'),
      timeout_milliseconds := 10000
    );
  end if;
  return old;
end;
$$;
revoke execute on function public.cleanup_avatar_after_user_delete() from public, anon, authenticated;

create trigger trg_users_avatar_cleanup
  after delete on auth.users
  for each row execute function public.cleanup_avatar_after_user_delete();
