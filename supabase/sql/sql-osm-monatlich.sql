-- ============================================================================
-- Filialen aus OpenStreetMap monatlich übernehmen (pg_cron)
-- ============================================================================
-- Voraussetzung: sql-osm-filialen.sql (osm_branches_fetch/osm_branches_import).
-- Ablauf jeden 1. des Monats (Zeiten in UTC):
--   03:00  GitHub-Workflow .github/workflows/osm-filialen.yml aktualisiert
--          supabase/data/branches-osm.json
--   06:00  osm_branches_fetch_logged() startet den Abruf der Datei
--   06:15  osm_branches_import_latest() übernimmt sie in branches
-- Ergebnis jedes Laufs steht in public.osm_import_runs.
-- Der Import selbst bricht bei unvollständiger Datei oder unbekannter Kette
-- ohne Änderung ab. Mehrfach ausführbar.
-- ============================================================================

create table if not exists public.osm_import_runs (
  id          bigserial primary key,
  request_id  bigint not null,
  started_at  timestamptz not null default now(),
  finished_at timestamptz,
  result      text
);
comment on table public.osm_import_runs is 'Protokoll der monatlichen Übernahme der OpenStreetMap-Filialen (pg_cron). Nur intern, keine Lesefreigabe für die App.';
alter table public.osm_import_runs enable row level security;
revoke all on public.osm_import_runs from anon, authenticated;

create or replace function public.osm_branches_fetch_logged()
returns bigint
language plpgsql
security invoker
set search_path = ''
as $$
declare v_id bigint;
begin
  v_id := public.osm_branches_fetch();
  insert into public.osm_import_runs (request_id) values (v_id);
  return v_id;
end;
$$;
revoke execute on function public.osm_branches_fetch_logged() from public, anon, authenticated;

create or replace function public.osm_branches_import_latest()
returns text
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_run public.osm_import_runs;
  v_result text;
begin
  select * into v_run from public.osm_import_runs
   where finished_at is null order by id desc limit 1;
  if not found then
    return 'Kein offener Abruf.';
  end if;
  begin
    v_result := public.osm_branches_import(v_run.request_id);
  exception when others then
    v_result := 'Fehler: ' || sqlerrm;
  end;
  update public.osm_import_runs set finished_at = now(), result = v_result where id = v_run.id;
  return v_result;
end;
$$;
revoke execute on function public.osm_branches_import_latest() from public, anon, authenticated;

-- Zeitpläne (bestehende gleichen Namens werden ersetzt)
select cron.schedule('osm-filialen-abruf',  '0 6 1 * *',  'select public.osm_branches_fetch_logged()');
select cron.schedule('osm-filialen-import', '15 6 1 * *', 'select public.osm_branches_import_latest()');

-- Kontrolle
select jobname, schedule, command from cron.job where jobname like 'osm-filialen-%';
-- Letzte Läufe:  select * from public.osm_import_runs order by id desc limit 5;
