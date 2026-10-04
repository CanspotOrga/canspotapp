-- ÜBERHOLT, NICHT MEHR AUSFÜHREN. Ersetzt durch
-- sql-profilbild-automatisch-loeschen.sql (Profilbild wird beim Löschen eines
-- Kontos automatisch entfernt, keine Sperre mehr). Nur noch zur Nachverfolgung.
--
-- Im Supabase SQL Editor ausführen (Projektinhaber).
-- Konto löschen nur, wenn das Profilbild vorher entfernt wurde.
-- Dateien in Storage hängen nicht per CASCADE am Konto und lassen sich nicht
-- per SQL löschen (Trigger storage.protect_delete). Die App entfernt das Bild
-- über die Storage-API und ruft erst danach delete_my_account() auf. Liegt
-- das Bild noch da (z. B. alte App-Version), bricht die Funktion ab, statt
-- eine verwaiste Datei zurückzulassen.

create or replace function public.delete_my_account(p_reason text default null, p_note text default null)
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
  -- Dateien in Storage haengen nicht per CASCADE am Konto und lassen sich
  -- nur ueber die Storage-API loeschen. Die App entfernt das Profilbild
  -- vorher; liegt es noch da, wird nichts geloescht.
  if exists (
    select 1 from storage.objects
    where bucket_id = 'avatars' and name = v_uid::text || '/avatar.jpg'
  ) then
    raise exception 'avatar still present' using errcode = '55000';
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
