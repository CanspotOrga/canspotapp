-- Loeschgruende nach 24 Monaten entfernen (Speicherdauer laut datenschutz.html).
-- Teil 1 darf beliebig oft im Supabase SQL Editor ausgefuehrt werden.
-- Teil 2 (automatisch, monatlich) nur einmal ausfuehren; braucht die Erweiterung pg_cron.

-- Teil 1: einmalig von Hand aufraeumen
delete from public.account_deletion_feedback
where deleted_at < now() - interval '24 months';


-- Teil 2: automatisch am 1. jedes Monats um 03:00 UTC
-- create extension if not exists pg_cron;
-- select cron.schedule(
--   'loeschgrund-aufraeumen',
--   '0 3 1 * *',
--   $$delete from public.account_deletion_feedback where deleted_at < now() - interval '24 months'$$
-- );

-- Kontrolle: aeltester Eintrag und Anzahl
-- select min(deleted_at) as aeltester, count(*) as anzahl from public.account_deletion_feedback;
