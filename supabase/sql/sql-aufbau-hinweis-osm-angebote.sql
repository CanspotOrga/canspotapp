-- ============================================================================
-- Hinweis „im Aufbau“, ältere Normalpreise, Angebote an echten Märkten
-- (Stand 10.10.2026)
-- ============================================================================
-- 1. app_settings.demo_notice: neuer Text (die App zeigt ihn nur auf der Startseite).
-- 2. product_avg_prices: 4 weitere Normalpreise aus Open Prices (Meldungen vor
--    dem 10.10.2025, ohne Aktion, Deutschland), ODbL 1.0.
-- 3. offers, regular_prices, price_history: von den 4 erfundenen Demo-Filialen
--    (source = eigene_erfassung) auf die nächstgelegene echte Filiale derselben
--    Kette aus OpenStreetMap in Arnsberg. Die Demo-Filialen bleiben vorerst
--    stehen (nicht mehr verwendet).
-- Mehrfach ausführbar.
-- ============================================================================

begin;

update public.app_settings
   set demo_notice = 'CanSpot befindet sich im Aufbau. Einzelne Angebote und Preise sind derzeit noch Beispieldaten.'
 where id = 1;

insert into public.product_avg_prices (product_id, avg_regular_price, report_count, source) values
  ('1191be29-2b12-5d3f-8078-7c27bae12c92', 0.39, 1, 'open_prices'),  -- 4061458252652 Flying Power Zero
  ('3359af5e-6876-53ee-b6b1-209d8c3a7275', 1.49, 1, 'open_prices'),  -- 5060896625829 Monster Lewis Hamilton Zero
  ('1af72b33-8894-5ceb-855c-4d4addf0473d', 1.89, 1, 'open_prices'),  -- 9002490206840 Red Bull 355 ml
  ('25bbbcc2-bd4d-5a2f-aca3-e9861dc57b63', 0.88, 1, 'open_prices')   -- 4060800160683 Rockstar Blueberry
on conflict (product_id) do update set avg_regular_price = excluded.avg_regular_price,
  report_count = excluded.report_count, source = excluded.source, updated_at = now();

-- Demo-Filiale -> echte OSM-Filiale (Kaufland Westring 10, EDEKA Teutenburg 1,
-- REWE Ruhrstraße 70, Netto Zum Schützenhof 1, alle Arnsberg)
create temp table branch_map (demo_id uuid, osm_id uuid) on commit drop;
insert into branch_map values
  ('19585656-b415-510e-8739-401bb2dd6a09', 'c7b6cfeb-6b85-4d8b-af54-c68c67cf9e8d'),
  ('50ff519a-4266-46a1-9f92-90d6fa370c87', '0bf4d585-f43a-412e-a0bf-d34032745b00'),
  ('2b4e352e-9b52-4fab-b1d8-ea79c5a7ea48', '80819443-0e18-484b-9e24-d6c4a0ec8c4e'),
  ('512e4c21-5183-4576-9673-b8d9ba9bf409', '3be385fc-8877-49ad-a551-3c62746d2d9f');

update public.offers o set branch_id = m.osm_id from branch_map m where o.branch_id = m.demo_id;
update public.regular_prices r set branch_id = m.osm_id from branch_map m where r.branch_id = m.demo_id;
update public.price_history h set branch_id = m.osm_id from branch_map m where h.branch_id = m.demo_id;

commit;

-- Kontrolle
select b.source, count(distinct o.id) as angebote, count(distinct r.id) as normalpreise
  from public.branches b
  left join public.offers o on o.branch_id = b.id
  left join public.regular_prices r on r.branch_id = b.id
 where o.id is not null or r.id is not null
 group by b.source;
select count(*) as ø_normalpreise from public.product_avg_prices;
