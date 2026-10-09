-- Wochenbericht Löschgründe und monatliches Aufräumen per pg_cron.
-- Einmal im Supabase SQL Editor ausführen (nicht mehrfach: cron.schedule mit
-- gleichem Namen überschreibt zwar, create table würde aber fehlschlagen).
-- Entspricht dem Abschnitt report_runs in supabase/sql/schema.sql.
-- pg_cron rechnet in UTC: '0 6 * * 1' = Montag 8:00 Uhr Sommerzeit, 7:00 Uhr Winterzeit.

-- 1. Protokoll der versendeten Berichte (Sperre gegen Mehrfachversand)
create table public.report_runs (
  id       bigserial primary key,
  report   text not null,
  sent_at  timestamptz not null default now()
);
create index report_runs_report_sent_idx on public.report_runs(report, sent_at desc);
alter table public.report_runs enable row level security;
revoke all on public.report_runs from anon, authenticated;
comment on table public.report_runs is 'Versandprotokoll der Edge Function wochenbericht-loeschgruende. Keine Policies: nur der Server-Schlüssel liest und schreibt.';

-- 2. Zeitpläne
create extension if not exists pg_cron;

select cron.schedule(
  'wochenbericht-loeschgruende',
  '0 6 * * 1',
  $$select net.http_post(
      url := 'https://kyksbqrdtdusdbqwvazw.supabase.co/functions/v1/wochenbericht-loeschgruende',
      headers := '{"Content-Type": "application/json"}'::jsonb,
      body := '{}'::jsonb
    )$$
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
