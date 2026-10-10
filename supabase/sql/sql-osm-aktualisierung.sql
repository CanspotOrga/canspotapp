-- ============================================================================
-- Filialen aus OpenStreetMap alle 4 Monate übernehmen (pg_cron) + Info-Mail
-- ============================================================================
-- Voraussetzung: sql-osm-filialen.sql (osm_branches_fetch/osm_branches_import)
-- und die Edge Function osm-filialen-bericht (ohne JWT, Secret SMTP_PASSWORD).
-- Ablauf jeweils am 1. Januar, 1. Mai und 1. September (deutsche Zeit):
--   07:00  GitHub-Workflow .github/workflows/osm-filialen.yml aktualisiert
--          supabase/data/branches-osm.json
--   09:45  osm_branches_fetch_logged() startet den Abruf der Datei
--   10:00  osm_branches_import_latest() prüft die Sicherheitsschranke, übernimmt
--          die Filialen und schickt eine Info von noreply@canspot.de an
--          hallo@canspot.de (auch bei Abbruch oder Fehler)
-- Sicherheitsschranke: Hat die neue Datei weniger als 90 % der bisherigen
-- OSM-Filialen, wird nichts übernommen (Status „abgebrochen“, Mail).
-- pg_cron rechnet in UTC ohne Sommerzeit: Die Jobs laufen zur Winter- und zur
-- Sommerzeit-Stunde und arbeiten nur, wenn es in Europe/Berlin die richtige ist.
-- Ergebnis jedes Laufs steht in public.osm_import_runs. Mehrfach ausführbar.
-- ============================================================================

create table if not exists public.osm_import_runs (
  id          bigserial primary key,
  request_id  bigint not null,
  started_at  timestamptz not null default now(),
  finished_at timestamptz,
  status      text check (status in ('ok', 'abgebrochen', 'fehler')),
  result      text,
  mailed_at   timestamptz
);
alter table public.osm_import_runs add column if not exists status text check (status in ('ok', 'abgebrochen', 'fehler'));
alter table public.osm_import_runs add column if not exists mailed_at timestamptz;
comment on table public.osm_import_runs is 'Protokoll der Übernahme der OpenStreetMap-Filialen (pg_cron, alle 4 Monate). Keine Policies: nur Datenbank und Server-Schlüssel (Edge Function osm-filialen-bericht).';
alter table public.osm_import_runs enable row level security;
revoke all on public.osm_import_runs from anon, authenticated;
grant select, update on public.osm_import_runs to service_role;

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
  v_new integer;
  v_old integer;
  v_status text;
  v_result text;
begin
  select * into v_run from public.osm_import_runs
   where finished_at is null order by id desc limit 1;
  if not found then
    return 'Kein offener Abruf.';
  end if;

  begin
    select jsonb_array_length((r.content::jsonb)->'branches') into v_new
      from net._http_response r where r.id = v_run.request_id and r.status_code = 200;
    select count(*) into v_old from public.branches where source = 'openstreetmap';
    if v_new is null then
      v_status := 'fehler';
      v_result := 'Die Datei konnte nicht abgerufen werden (keine Antwort von GitHub).';
    elsif v_old > 0 and v_new < 0.9 * v_old then
      v_status := 'abgebrochen';
      v_result := format('Sicherheitsschranke: Die neue Datei hat nur %s Filialen, bisher sind es %s (%s %%). Unter 90 %% wird nichts übernommen.',
                         v_new, v_old, round(100.0 * v_new / v_old));
    else
      v_result := public.osm_branches_import(v_run.request_id)
                  || format(' Vorher %s, in der Datei %s Filialen.', v_old, v_new);
      v_status := 'ok';
    end if;
  exception when others then
    v_status := 'fehler';
    v_result := 'Fehler: ' || sqlerrm;
  end;

  update public.osm_import_runs
     set finished_at = now(), status = v_status, result = v_result
   where id = v_run.id;

  -- Info-Mail (wird nach dem Ende der Transaktion verschickt)
  perform net.http_post(
    url := 'https://kyksbqrdtdusdbqwvazw.supabase.co/functions/v1/osm-filialen-bericht',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  );
  return v_status || ': ' || v_result;
end;
$$;
revoke execute on function public.osm_branches_import_latest() from public, anon, authenticated;

-- Zeitpläne (bestehende gleichen Namens werden ersetzt). 7:45/8:45 und 8:00/9:00 UTC
-- = 9:45 bzw. 10:00 Uhr deutscher Zeit, je nach Sommer-/Winterzeit.
select cron.unschedule(jobname) from cron.job where jobname in ('osm-filialen-abruf', 'osm-filialen-import');
select cron.schedule('osm-filialen-abruf', '45 7,8 1 1,5,9 *',
  $$select public.osm_branches_fetch_logged() where extract(hour from now() at time zone 'Europe/Berlin') = 9$$);
select cron.schedule('osm-filialen-import', '0 8,9 1 1,5,9 *',
  $$select public.osm_branches_import_latest() where extract(hour from now() at time zone 'Europe/Berlin') = 10$$);

-- Kontrolle
select jobname, schedule, command from cron.job where jobname like 'osm-filialen-%';
-- Letzte Läufe:  select * from public.osm_import_runs order by id desc limit 5;
-- Von Hand testen (schickt eine Mail):
--   select public.osm_branches_fetch_logged();   -- dann ca. 1 Minute warten
--   select public.osm_branches_import_latest();
