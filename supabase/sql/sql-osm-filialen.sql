-- ============================================================================
-- Filialen aus OpenStreetMap (Stand 10.10.2026)
-- ============================================================================
-- Quelle: OpenStreetMap, Open Database License (ODbL) 1.0,
-- „© OpenStreetMap-Mitwirkende“ (https://www.openstreetmap.org/copyright).
-- Nur Deutschland und nur diese 13 Ketten: EDEKA, REWE, Lidl, Kaufland,
-- Aldi Süd, Netto (Marken-Discount), Aldi Nord, Penny, Norma, Globus, Metro,
-- EDEKA C+C, Handelshof. Übernommen werden nur Kette, Adresse, Koordinaten
-- und Öffnungszeiten, keine Betreiber- oder Inhabernamen und keine
-- Kontaktdaten.
--
-- Die Daten erzeugt supabase/import/osm-filialen.py als
-- supabase/data/branches-osm.json (öffentlich im Repo, ODbL 1.0). Die
-- Datenbank lädt die Datei per pg_net von GitHub, es braucht keinen Schlüssel.
--
-- Ablauf im SQL Editor:
--   1. Diese Datei ausführen (mehrfach ausführbar).
--   2. select public.osm_branches_fetch();          -- liefert eine Abruf-Nr.
--   3. Ein paar Sekunden warten, dann
--      select public.osm_branches_import(<Abruf-Nr.>);
-- Zum Aktualisieren erst das Skript ausführen und pushen, dann Schritt 2 und 3.
--
-- Die App lädt Filialen nur im Umkreis über public.branches_in_area().
-- ============================================================================

-- 1) Filialen: Herkunft, OSM-Kennung, Öffnungszeiten je Wochentag ------------
alter table public.branches
  add column if not exists source        text not null default 'eigene_erfassung',
  add column if not exists osm_type      text,
  add column if not exists osm_id        bigint,
  add column if not exists opening_hours text,
  add column if not exists hours         jsonb,
  add column if not exists last_seen_at  timestamptz;

-- Adresse und Öffnungszeiten fehlen in OpenStreetMap teilweise.
alter table public.branches
  alter column street      drop not null,
  alter column postal_code drop not null,
  alter column city        drop not null,
  alter column opens_at    drop not null,
  alter column closes_at   drop not null;

alter table public.branches drop constraint if exists branches_source_check;
alter table public.branches add constraint branches_source_check
  check (source in ('openstreetmap', 'eigene_erfassung'));
alter table public.branches drop constraint if exists branches_osm_ref_check;
alter table public.branches add constraint branches_osm_ref_check
  check ((source = 'openstreetmap') = (osm_type is not null and osm_id is not null)
         and (osm_type is null or osm_type in ('node', 'way', 'relation')));
alter table public.branches drop constraint if exists branches_hours_check;
alter table public.branches add constraint branches_hours_check
  check (hours is null or jsonb_typeof(hours) = 'object');
alter table public.branches drop constraint if exists branches_osm_ref_key;
alter table public.branches add constraint branches_osm_ref_key unique (osm_type, osm_id);
create index if not exists branches_lat_lon_idx on public.branches (latitude, longitude);

comment on table public.branches is 'Konkrete Filiale eines Haendlers (1:n zu retailers). source openstreetmap = aus OpenStreetMap (ODbL 1.0, Namensnennung „© OpenStreetMap-Mitwirkende“), eigene_erfassung = selbst angelegt.';
comment on column public.branches.source is 'openstreetmap (ODbL 1.0) oder eigene_erfassung.';
comment on column public.branches.osm_type is 'OSM-Objekttyp (node/way/relation), nur bei source openstreetmap.';
comment on column public.branches.osm_id is 'OSM-Objektnummer, zusammen mit osm_type eindeutig; Schlüssel für Aktualisierungen.';
comment on column public.branches.opening_hours is 'Öffnungszeiten im OSM-Format (Rohtext), z. B. "Mo-Sa 07:00-20:00; PH off".';
comment on column public.branches.hours is 'Öffnungszeiten je Wochentag aus opening_hours: {"mo":[["07:00","20:00"]],…,"su":[]}; [] = geschlossen, null = nicht lesbar. Feiertage und einzelne Sondertage sind nicht enthalten.';
comment on column public.branches.last_seen_at is 'Zeitpunkt des letzten Imports, in dem die Filiale in OpenStreetMap noch vorkam.';

-- 2) Ketten, die bisher fehlen -----------------------------------------------
insert into public.retailers (id, name) values
  ('d8779a36-e14e-52e2-b502-814d060aeb7f', 'Globus'),
  ('c79ca964-8a24-5e5f-9d66-7124718e46db', 'Metro'),
  ('d02a756b-1574-55b3-9f62-52f67a4a3aad', 'EDEKA C+C'),
  ('d501dae4-d3fe-51b6-9d1c-64db0dff6294', 'Handelshof')
on conflict (name) do nothing;

-- 3) Märkte im Umkreis (für die App) -----------------------------------------
-- Die App schickt einen auf 0,1 Grad gerundeten Standort und rechnet die
-- genaue Entfernung selbst. Radius höchstens 60 km, höchstens 2000 Filialen,
-- die nächsten zuerst. Es wird nichts gespeichert.
create or replace function public.branches_in_area(
  p_lat double precision,
  p_lon double precision,
  p_radius_km double precision default 10
)
returns setof public.branches
language sql
stable
security invoker
set search_path = ''
as $$
  with c as (
    select greatest(-89.0, least(89.0, p_lat)) as lat,
           p_lon as lon,
           least(greatest(coalesce(p_radius_km, 10), 1), 60) as r
  ), box as (
    select c.lat, c.lon,
           (c.lat - c.r / 111.0)::numeric as lat_min,
           (c.lat + c.r / 111.0)::numeric as lat_max,
           (c.lon - c.r / (111.0 * cos(radians(c.lat))))::numeric as lon_min,
           (c.lon + c.r / (111.0 * cos(radians(c.lat))))::numeric as lon_max
    from c
  )
  select b.*
  from public.branches b, box
  where b.latitude between box.lat_min and box.lat_max
    and b.longitude between box.lon_min and box.lon_max
  order by power(b.latitude::double precision - box.lat, 2)
         + power((b.longitude::double precision - box.lon) * cos(radians(box.lat)), 2)
  limit 2000;
$$;
comment on function public.branches_in_area(double precision, double precision, double precision) is 'Filialen im Umkreis (Rechteck um einen gerundeten Standort, max. 60 km, max. 2000, die nächsten zuerst). SECURITY INVOKER, RLS greift. Speichert nichts.';
revoke execute on function public.branches_in_area(double precision, double precision, double precision) from public;
grant execute on function public.branches_in_area(double precision, double precision, double precision) to anon, authenticated;

-- 4) Import der OSM-Datei von GitHub (nur SQL Editor / service_role) ---------
create or replace function public.osm_branches_fetch()
returns bigint
language sql
security invoker
set search_path = ''
as $$
  select net.http_get(
    url := 'https://raw.githubusercontent.com/CanspotOrga/canspotapp/main/supabase/data/branches-osm.json',
    timeout_milliseconds := 60000
  );
$$;
comment on function public.osm_branches_fetch() is 'Startet den Abruf von supabase/data/branches-osm.json (OpenStreetMap, ODbL 1.0) und liefert die Abruf-Nr. für osm_branches_import().';
revoke execute on function public.osm_branches_fetch() from public, anon, authenticated;

create or replace function public.osm_branches_import(p_request_id bigint)
returns text
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_status    integer;
  v_content   text;
  v_error     text;
  v_timed_out boolean;
  v_doc       jsonb;
  v_now       timestamptz := now();
  v_total     integer;
  v_unknown   integer;
  v_upserted  integer;
  v_inserted  integer;
  v_deleted   integer;
  v_kept      integer;
begin
  select r.status_code, r.content, r.error_msg, r.timed_out
    into v_status, v_content, v_error, v_timed_out
  from net._http_response r
  where r.id = p_request_id;
  if not found then
    raise exception 'Abruf % ist noch nicht beantwortet. Ein paar Sekunden warten und erneut ausführen.', p_request_id;
  end if;
  if coalesce(v_timed_out, false) or v_status is distinct from 200 then
    raise exception 'Abruf fehlgeschlagen (Status %, %).', v_status, coalesce(v_error, 'ohne Meldung');
  end if;

  v_doc := v_content::jsonb;
  if v_doc->>'source' is distinct from 'OpenStreetMap'
     or v_doc->>'license' is distinct from 'ODbL 1.0'
     or jsonb_typeof(v_doc->'branches') is distinct from 'array' then
    raise exception 'Unerwartetes Dateiformat, nichts geändert.';
  end if;

  -- Schutz vor einer unvollständigen Datei: sonst würden fast alle Filialen gelöscht.
  v_total := jsonb_array_length(v_doc->'branches');
  if v_total < 1000 then
    raise exception 'Nur % Filialen in der Datei, nichts geändert.', v_total;
  end if;

  select count(*) into v_unknown
  from jsonb_array_elements(v_doc->'branches') e
  left join public.retailers rt on rt.name = e->>'retailer'
  where rt.id is null;
  if v_unknown > 0 then
    raise exception '% Filialen gehören zu einer Kette, die in retailers fehlt. Nichts geändert.', v_unknown;
  end if;

  with src as (
    select e->>'osm_type'                    as osm_type,
           (e->>'osm_id')::bigint            as osm_id,
           rt.id                             as retailer_id,
           nullif(e->>'street', '')          as street,
           nullif(e->>'postal_code', '')     as postal_code,
           nullif(e->>'city', '')            as city,
           (e->>'latitude')::numeric(9,6)    as latitude,
           (e->>'longitude')::numeric(9,6)   as longitude,
           (e->>'opens_at')::time            as opens_at,
           (e->>'closes_at')::time           as closes_at,
           coalesce((e->>'closed_sunday')::boolean, false) as closed_sunday,
           nullif(e->>'opening_hours', '')   as opening_hours,
           case when jsonb_typeof(e->'hours') = 'object' then e->'hours' end as hours
    from jsonb_array_elements(v_doc->'branches') e
    join public.retailers rt on rt.name = e->>'retailer'
  ), up as (
    insert into public.branches as b
      (retailer_id, street, postal_code, city, latitude, longitude, opens_at, closes_at,
       closed_sunday, opening_hours, hours, source, osm_type, osm_id, last_seen_at)
    select retailer_id, street, postal_code, city, latitude, longitude, opens_at, closes_at,
           closed_sunday, opening_hours, hours, 'openstreetmap', osm_type, osm_id, v_now
    from src
    on conflict (osm_type, osm_id) do update set
      retailer_id   = excluded.retailer_id,
      street        = excluded.street,
      postal_code   = excluded.postal_code,
      city          = excluded.city,
      latitude      = excluded.latitude,
      longitude     = excluded.longitude,
      opens_at      = excluded.opens_at,
      closes_at     = excluded.closes_at,
      closed_sunday = excluded.closed_sunday,
      opening_hours = excluded.opening_hours,
      hours         = excluded.hours,
      last_seen_at  = excluded.last_seen_at
    returning (xmax = 0) as is_new
  )
  select count(*), count(*) filter (where is_new) into v_upserted, v_inserted from up;

  -- Nicht mehr in OSM: löschen, außer Preise oder Angebote hängen daran.
  delete from public.branches b
  where b.source = 'openstreetmap'
    and b.last_seen_at < v_now
    and not exists (select 1 from public.offers o where o.branch_id = b.id)
    and not exists (select 1 from public.regular_prices p where p.branch_id = b.id)
    and not exists (select 1 from public.price_history h where h.branch_id = b.id);
  get diagnostics v_deleted = row_count;

  select count(*) into v_kept
  from public.branches b
  where b.source = 'openstreetmap' and b.last_seen_at < v_now;

  return format(
    '%s Filialen übernommen (%s neu, %s aktualisiert). %s nicht mehr in OpenStreetMap und gelöscht, %s nicht mehr in OpenStreetMap, aber mit Preisen verknüpft (bleiben). OSM-Stand %s.',
    v_upserted, v_inserted, v_upserted - v_inserted, v_deleted, v_kept, coalesce(v_doc->>'osm_timestamp', 'unbekannt'));
end;
$$;
comment on function public.osm_branches_import(bigint) is 'Übernimmt die mit osm_branches_fetch() abgerufene OSM-Datei in branches (Upsert über osm_type/osm_id) und löscht nicht mehr vorhandene OSM-Filialen ohne Preise. Bricht bei unvollständiger Datei oder unbekannter Kette ohne Änderung ab.';
revoke execute on function public.osm_branches_import(bigint) from public, anon, authenticated;
