-- Wochenbericht Löschgründe und monatliches Aufräumen per pg_cron.
-- Einmal im Supabase SQL Editor ausführen (nicht mehrfach: cron.schedule mit
-- gleichem Namen überschreibt zwar, create table würde aber fehlschlagen).
-- Entspricht dem Abschnitt report_runs in supabase/sql/schema.sql.
-- Versand jeden Freitag um 13:00 Uhr deutscher Zeit. pg_cron rechnet in UTC und
-- kennt keine Sommerzeit: Der Job läuft freitags um 11:00 und 12:00 UTC und ruft
-- die Funktion nur auf, wenn es in Europe/Berlin gerade 13 Uhr ist.
-- Nur den Zeitplan ändern: Abschnitt 2 (cron.schedule) allein ausführen.

-- 1. Protokoll der versendeten Berichte (Sperre gegen Mehrfachversand)
create table public.report_runs (
  id       bigserial primary key,
  report   text not null,
  sent_at  timestamptz not null default now()
);
create index report_runs_report_sent_idx on public.report_runs(report, sent_at desc);
alter table public.report_runs enable row level security;
revoke all on public.report_runs from anon, authenticated;
grant select, insert on public.report_runs to service_role;
grant usage on sequence public.report_runs_id_seq to service_role;
comment on table public.report_runs is 'Versandprotokoll der Edge Function wochenbericht-loeschgruende. Keine Policies: nur der Server-Schlüssel liest und schreibt.';

-- 2. Zeitpläne
create extension if not exists pg_cron;

select cron.schedule(
  'wochenbericht-loeschgruende',
  '0 11,12 * * 5',
  $$select net.http_post(
      url := 'https://kyksbqrdtdusdbqwvazw.supabase.co/functions/v1/wochenbericht-loeschgruende',
      headers := '{"Content-Type": "application/json"}'::jsonb,
      body := '{}'::jsonb
    )
    where extract(hour from now() at time zone 'Europe/Berlin') = 13$$
);

select cron.schedule(
  'loeschgrund-aufraeumen',
  '0 3 1 * *',
  $$delete from public.account_deletion_feedback where deleted_at < now() - interval '24 months'$$
);

-- Kontrolle:
-- select jobname, schedule, active from cron.job;
-- select * from cron.job_run_details order by start_time desc limit 10;
-- select * from public.report_runs order by sent_at desc;
