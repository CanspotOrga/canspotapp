-- Geburtsdatum als Pflichtangabe bei der Registrierung: einmal komplett im
-- Supabase SQL Editor ausführen. Entspricht den Abschnitten zu
-- profiles.birthdate und handle_new_user() in supabase/sql/schema.sql.
-- Mehrfaches Ausführen ist unschädlich.

-- Prüft das Geburtsdatum bei jedem Anlegen/Ändern: 1900-01-01 bis heute.
-- Ein einmal gesetztes Geburtsdatum kann nicht wieder geleert werden.
create or replace function public.check_profile_birthdate()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.birthdate is null then
    if tg_op = 'UPDATE' and old.birthdate is not null then
      raise exception 'birthdate required' using errcode = '23502';
    end if;
    return new;
  end if;
  if new.birthdate < date '1900-01-01' or new.birthdate > current_date then
    raise exception 'birthdate out of range' using errcode = '23514';
  end if;
  return new;
end;
$$;
revoke execute on function public.check_profile_birthdate() from public, anon, authenticated;

drop trigger if exists trg_profiles_check_birthdate on public.profiles;
create trigger trg_profiles_check_birthdate
  before insert or update of birthdate on public.profiles
  for each row execute function public.check_profile_birthdate();

-- Registrierung: Nutzername und Geburtsdatum kommen als Metadaten mit.
-- Ohne eines von beiden wird die Registrierung abgelehnt. Das Geburtsdatum
-- wird danach aus den Konto-Metadaten entfernt und liegt nur in profiles.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
  v_username text := nullif(btrim(new.raw_user_meta_data->>'username'), '');
  v_birthdate_raw text := nullif(btrim(new.raw_user_meta_data->>'birthdate'), '');
  v_birthdate date;
begin
  if v_username is null then
    raise exception 'username required' using errcode = '23502';
  end if;
  if v_birthdate_raw is null or v_birthdate_raw !~ '^\d{4}-\d{2}-\d{2}$' then
    raise exception 'birthdate required' using errcode = '23502';
  end if;
  begin
    v_birthdate := v_birthdate_raw::date;
  exception when others then
    raise exception 'birthdate invalid' using errcode = '22007';
  end;
  insert into public.profiles (id, username, birthdate) values (new.id, v_username, v_birthdate);
  insert into public.notification_settings (user_id) values (new.id);
  update auth.users set raw_user_meta_data = raw_user_meta_data - 'birthdate' where id = new.id;
  return new;
end;
$$;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

comment on column public.profiles.birthdate is 'Geburtsdatum, Pflicht bei der Registrierung (aus raw_user_meta_data.birthdate, handle_new_user; danach aus den Metadaten entfernt). 1900-01-01 bis heute (check_profile_birthdate). NULL nur bei Konten von vor dieser Pflicht; die App fragt es dann ab. Nur fuer den Besitzer sichtbar, wird mit dem Konto per CASCADE geloescht.';
comment on table public.profiles is 'Profildaten, 1:1 zu auth.users. Genutzt werden username und birthdate (nur fuer den Besitzer sichtbar). first_name, last_name, street, postal_code, city, country und avatar_url sind ungenutzt: Es gibt keinen Vor-/Nachnamen, die Adresse bleibt lokal auf dem Geraet, das Profilbild liegt im Bucket avatars.';
