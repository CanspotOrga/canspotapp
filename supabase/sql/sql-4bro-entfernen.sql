-- ============================================================================
-- 4BRO entfernen (Stand 10.10.2026)
-- ============================================================================
-- Löscht die Marke „4BRO“, ihr Produkt „4BRO Energy“ (250 ml) und dessen
-- Nährwerte. Im Supabase SQL Editor ausführen. Mehrfach ausführbar: löscht nur,
-- was noch vorhanden ist.
-- Sicherheitsprüfung: bricht ohne Änderung ab, falls inzwischen Angebote,
-- Normalpreise, Preisverlauf, Favoriten, Bewertungen, Preisalarme oder
-- „Zuletzt angesehen“ an einem 4BRO-Produkt hängen.
-- ============================================================================

begin;

do $$
declare
  n bigint;
begin
  select
      (select count(*) from public.offers          where product_id in (select p.id from public.products p join public.brands b on b.id = p.brand_id where b.name = '4BRO'))
    + (select count(*) from public.regular_prices  where product_id in (select p.id from public.products p join public.brands b on b.id = p.brand_id where b.name = '4BRO'))
    + (select count(*) from public.price_history   where product_id in (select p.id from public.products p join public.brands b on b.id = p.brand_id where b.name = '4BRO'))
    + (select count(*) from public.favorites       where product_id in (select p.id from public.products p join public.brands b on b.id = p.brand_id where b.name = '4BRO'))
    + (select count(*) from public.ratings         where product_id in (select p.id from public.products p join public.brands b on b.id = p.brand_id where b.name = '4BRO'))
    + (select count(*) from public.price_alerts    where product_id in (select p.id from public.products p join public.brands b on b.id = p.brand_id where b.name = '4BRO'))
    + (select count(*) from public.recently_viewed where product_id in (select p.id from public.products p join public.brands b on b.id = p.brand_id where b.name = '4BRO'))
    + (select count(*) from public.brand_nutrition_defaults where brand_id in (select id from public.brands where name = '4BRO'))
  into n;
  if n > 0 then
    raise exception '4BRO hat inzwischen % verknüpfte Einträge (Angebote/Nutzerdaten) – nichts gelöscht, bitte prüfen.', n;
  end if;
end $$;

delete from public.product_nutrition
 where product_id in (select p.id from public.products p join public.brands b on b.id = p.brand_id where b.name = '4BRO');
delete from public.products
 where brand_id in (select id from public.brands where name = '4BRO');
delete from public.brands
 where name = '4BRO';

commit;

-- Kontrolle: alle drei Werte müssen 0 sein
select
  (select count(*) from public.brands where name = '4BRO') as marke,
  (select count(*) from public.products where name ilike '4BRO%') as produkte,
  (select count(*) from public.product_nutrition where source_ref = '4260667060007') as naehrwerte;
