-- Im Supabase SQL Editor ausführen (Projektinhaber), komplett auf einmal.
--
-- Profilbild wird beim Löschen eines Kontos automatisch im Hintergrund
-- entfernt, egal ob der Nutzer in der App löscht oder du im Dashboard.
--
-- Ablauf: Wird ein Konto gelöscht und liegt noch <id>/avatar.jpg im Bucket
-- avatars, schickt die Datenbank nur die Konto-ID an die Edge Function
-- avatar-cleanup (Region Frankfurt). Die löscht genau diese eine Datei, und
-- nur, wenn das Konto wirklich nicht mehr existiert. Kein Schlüssel nötig.
--
-- Ersetzt die bisherigen Sperren: Konten lassen sich wieder normal löschen.

-- 1. Erweiterung, mit der die Datenbank Anfragen verschicken kann
create extension if not exists pg_net with schema extensions;

-- 2. Auslöser nach dem Löschen eines Kontos
create or replace function public.cleanup_avatar_after_user_delete()
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

drop trigger if exists trg_users_avatar_cleanup on auth.users;
create trigger trg_users_avatar_cleanup
  after delete on auth.users
  for each row execute function public.cleanup_avatar_after_user_delete();

-- 3. Alte Sperre entfernen (blockierte das Löschen, solange ein Bild da war)
drop trigger if exists trg_users_avatar_guard on auth.users;
drop function if exists public.prevent_user_delete_with_avatar();

-- 4. delete_my_account() ohne Profilbild-Sperre (das Aufräumen übernimmt jetzt
--    der Auslöser oben; die App entfernt das Bild zusätzlich vorher selbst)
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
  if v_reason is not null then
    insert into public.account_deletion_feedback (reason, note)
    values (v_reason, case when v_reason = 'other' then nullif(left(btrim(coalesce(p_note, '')), 500), '') end);
  end if;
  delete from auth.users where id = v_uid;
end;
$$;
revoke execute on function public.delete_my_account(text, text) from public, anon;
grant execute on function public.delete_my_account(text, text) to authenticated;
