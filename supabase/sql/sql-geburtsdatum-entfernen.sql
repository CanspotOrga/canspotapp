-- Geburtsdatum vollständig entfernen: einmal komplett im Supabase SQL Editor
-- ausführen. Löscht die Spalte profiles.birthdate samt aller gespeicherten
-- Werte, die Prüfregel und die Pflicht bei der Registrierung.
-- Mehrfaches Ausführen ist unschädlich.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
  v_username text := nullif(btrim(new.raw_user_meta_data->>'username'), '');
begin
  if v_username is null then
    raise exception 'username required' using errcode = '23502';
  end if;
  insert into public.profiles (id, username) values (new.id, v_username);
  insert into public.notification_settings (user_id) values (new.id);
  return new;
end;
$$;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

drop trigger if exists trg_profiles_check_birthdate on public.profiles;
drop function if exists public.check_profile_birthdate();
alter table public.profiles drop column if exists birthdate;

update auth.users set raw_user_meta_data = raw_user_meta_data - 'birthdate'
 where raw_user_meta_data ? 'birthdate';

comment on table public.profiles is 'Profildaten, 1:1 zu auth.users. Genutzt wird nur username (nur fuer den Besitzer sichtbar). first_name, last_name, street, postal_code, city, country und avatar_url sind ungenutzt: Es gibt keinen Vor-/Nachnamen und kein Geburtsdatum, die Adresse bleibt lokal auf dem Geraet, das Profilbild liegt im Bucket avatars.';
