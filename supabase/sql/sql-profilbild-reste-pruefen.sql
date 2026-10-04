-- Kontrolle im Supabase SQL Editor: Gibt es Profilbilder, deren Konto nicht
-- mehr existiert? Normalerweise ist das Ergebnis leer. Kann vorkommen, wenn
-- der Aufruf der Edge Function avatar-cleanup ausnahmsweise fehlschlug.

select o.name, o.created_at
from storage.objects o
where o.bucket_id = 'avatars'
  and not exists (
    select 1 from auth.users u where u.id::text = split_part(o.name, '/', 1)
  );

-- Aufräumen nachholen: schickt für jedes übrig gebliebene Bild die Konto-ID
-- erneut an avatar-cleanup. Danach die Abfrage oben noch einmal ausführen.
--
-- select net.http_post(
--   url := 'https://kyksbqrdtdusdbqwvazw.supabase.co/functions/v1/avatar-cleanup',
--   body := jsonb_build_object('user_id', split_part(o.name, '/', 1)),
--   headers := jsonb_build_object('Content-Type', 'application/json', 'x-region', 'eu-central-1')
-- )
-- from storage.objects o
-- where o.bucket_id = 'avatars'
--   and not exists (
--     select 1 from auth.users u where u.id::text = split_part(o.name, '/', 1)
--   );

-- Antworten der letzten Aufrufe (pg_net bewahrt sie einige Stunden auf):
-- select id, status_code, content, created from net._http_response order by created desc limit 20;
