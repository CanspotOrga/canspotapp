-- Produkte im "Coming Soon" (nur Angebote mit Start in der Zukunft, noch
-- keines hat begonnen) koennen noch nicht bewertet werden. Neue und
-- geaenderte Bewertungen werden fuer solche Produkte abgelehnt.
-- Lesen und Loeschen der eigenen Bewertung bleibt immer moeglich.
-- Darf mehrfach ausgefuehrt werden.

create or replace function public.is_product_rateable(p_product_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select not (
    exists (
      select 1 from public.offers o
      where o.product_id = p_product_id
        and o.valid_from > (now() at time zone 'Europe/Berlin')::date
    )
    and not exists (
      select 1 from public.offers o
      where o.product_id = p_product_id
        and o.valid_from <= (now() at time zone 'Europe/Berlin')::date
    )
  );
$$;

revoke execute on function public.is_product_rateable(uuid) from public, anon;
grant execute on function public.is_product_rateable(uuid) to authenticated;

comment on function public.is_product_rateable(uuid) is 'false, solange ein Produkt nur Angebote mit Start in der Zukunft hat (Coming Soon). Wird in den RLS-Policies von ratings fuer Einfuegen und Aendern genutzt.';

drop policy if exists "ratings_all_own" on public.ratings;
drop policy if exists "ratings_select_own" on public.ratings;
drop policy if exists "ratings_insert_own" on public.ratings;
drop policy if exists "ratings_update_own" on public.ratings;
drop policy if exists "ratings_delete_own" on public.ratings;

create policy "ratings_select_own" on public.ratings
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "ratings_insert_own" on public.ratings
  for insert to authenticated
  with check ((select auth.uid()) = user_id and public.is_product_rateable(product_id));

create policy "ratings_update_own" on public.ratings
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id and public.is_product_rateable(product_id));

create policy "ratings_delete_own" on public.ratings
  for delete to authenticated
  using ((select auth.uid()) = user_id);
