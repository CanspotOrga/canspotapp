-- Entfernt alles, was für den verworfenen täglichen Bericht "Preis abweichend"
-- angelegt worden sein könnte. Mehrfach ausführbar; was nicht existiert, wird
-- übersprungen.
--
-- Die Edge Function tagesbericht-preisfeedback lässt sich nicht per SQL
-- löschen: Dashboard → Edge Functions → tagesbericht-preisfeedback → Delete.

-- 1. Zeitpläne (falls angelegt)
do $$
begin
  if exists (select 1 from cron.job where jobname = 'tagesbericht-preisfeedback') then
    perform cron.unschedule('tagesbericht-preisfeedback');
  end if;
  if exists (select 1 from cron.job where jobname = 'preisfeedback-aufraeumen') then
    perform cron.unschedule('preisfeedback-aufraeumen');
  end if;
end $$;

-- 2. Funktion und Index (falls angelegt)
drop function if exists public.submit_price_feedback(uuid, text, numeric, text);
drop index if exists public.price_feedback_reports_reported_at_idx;

-- 3. Versandprotokoll-Einträge dieses Berichts (falls vorhanden)
delete from public.report_runs where report = 'preisfeedback-tag';

-- 4. Optional: Tabelle price_feedback_reports ganz entfernen. Die App nutzt sie
--    nicht mehr. Bricht ab, wenn doch Meldungen darin stehen. Zum Ausführen
--    die Kommentarzeichen entfernen; danach schema.sql anpassen.
-- do $$
-- begin
--   if (select count(*) from public.price_feedback_reports) > 0 then
--     raise exception 'price_feedback_reports enthält Meldungen, nichts gelöscht';
--   end if;
--   drop table public.price_feedback_reports;
-- end $$;

-- Kontrolle:
-- select jobname from cron.job;
-- select proname from pg_proc where proname = 'submit_price_feedback';
