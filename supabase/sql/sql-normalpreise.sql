-- Normalpreise: eigene Tabelle für den regulären Regalpreis je Produkt,
-- Filiale und Gebinde (unabhängig davon, ob gerade ein Angebot läuft).
-- Einmal im Supabase SQL Editor ausführen (create table schlägt beim zweiten
-- Mal fehl; das Befüllen in Teil 2 darf mehrfach laufen).
-- Entspricht dem Abschnitt regular_prices in supabase/sql/schema.sql.

-- 1. Tabelle
create table public.regular_prices (
  id               uuid primary key default gen_random_uuid(),
  product_id       uuid not null references public.products(id) on delete restrict,
  branch_id        uuid not null references public.branches(id) on delete restrict,
  units            integer not null default 1 check (units > 0),
  price            numeric(10,2) not null check (price >= 0),
  deposit          numeric(10,2) not null default 0 check (deposit >= 0),
  last_checked_at  date,
  created_at       timestamptz not null default now(),
  constraint regular_prices_product_branch_units_key unique (product_id, branch_id, units)
);
create index regular_prices_branch_id_idx on public.regular_prices(branch_id);
comment on table public.regular_prices is 'Aktueller Normalpreis (Regalpreis ohne Aktion) je Produkt, Filiale und Gebinde. Genau eine Zeile pro Kombination; Verlauf gehört in price_history.';

alter table public.regular_prices enable row level security;
create policy "regular_prices_public_read" on public.regular_prices
  for select to anon, authenticated using (true);
grant select on public.regular_prices to anon, authenticated;
grant all privileges on public.regular_prices to service_role;

-- 2. Befüllen mit den Normalpreisen, die schon in offers stehen (nur Zeilen
--    mit bekanntem regular_price; bei mehreren Angeboten je Kombination gilt
--    das zuletzt geprüfte).
insert into public.regular_prices (product_id, branch_id, units, price, deposit, last_checked_at)
select distinct on (product_id, branch_id, units)
  product_id, branch_id, units, regular_price, deposit, last_checked_at
from public.offers
where regular_price is not null
order by product_id, branch_id, units, last_checked_at desc nulls last, valid_from desc
on conflict (product_id, branch_id, units) do update set
  price = excluded.price,
  deposit = excluded.deposit,
  last_checked_at = excluded.last_checked_at;

-- Kontrolle:
-- select r.name, p.name, rp.units, rp.price, rp.deposit, rp.last_checked_at
-- from public.regular_prices rp
-- join public.products p on p.id = rp.product_id
-- join public.branches b on b.id = rp.branch_id
-- join public.retailers r on r.id = b.retailer_id
-- order by p.name, r.name;
