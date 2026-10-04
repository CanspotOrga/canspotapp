-- "Zuletzt angesehen": einmal komplett im Supabase SQL Editor ausführen.
-- Entspricht den recently_viewed-Abschnitten in supabase/sql/schema.sql.

create table public.recently_viewed (
  user_id     uuid not null references auth.users(id) on delete cascade,
  product_id  uuid not null references public.products(id) on delete cascade,
  viewed_at   timestamptz not null default now(),
  primary key (user_id, product_id)
);
create index recently_viewed_user_viewed_idx on public.recently_viewed(user_id, viewed_at desc);
create index recently_viewed_product_id_idx on public.recently_viewed(product_id);
comment on table public.recently_viewed is 'Zuletzt angesehene Produkte je Konto (Produktdetailansicht). Pro Nutzer hoechstens 20 Eintraege, aeltere entfernt record_product_view().';

alter table public.recently_viewed enable row level security;
create policy "recently_viewed_all_own" on public.recently_viewed
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.recently_viewed to authenticated;

create function public.record_product_view(p_product_id uuid)
returns void
language sql
security invoker
set search_path = ''
as $$
  insert into public.recently_viewed (user_id, product_id, viewed_at)
  values ((select auth.uid()), p_product_id, now())
  on conflict (user_id, product_id) do update set viewed_at = excluded.viewed_at;

  delete from public.recently_viewed
  where user_id = (select auth.uid())
    and product_id not in (
      select product_id from public.recently_viewed
      where user_id = (select auth.uid())
      order by viewed_at desc
      limit 20
    );
$$;
comment on function public.record_product_view(uuid) is 'Merkt ein angesehenes Produkt fuer den angemeldeten Nutzer (Zeitpunkt = Serverzeit) und behaelt nur die 20 neuesten Eintraege. SECURITY INVOKER, RLS greift.';

revoke execute on function public.record_product_view(uuid) from public, anon;
grant execute on function public.record_product_view(uuid) to authenticated;
