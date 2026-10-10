-- ============================================================================
-- Produktbilder: Platzhalter „Foto folgt“ (Stand 10.10.2026)
-- ============================================================================
-- Alle Produkte außer Red Bull und Monster Energy bekommen das Platzhalterbild
-- von canspot.de; Red Bull behält das White-Peach-Foto, Monster das Juiced-Bad-
-- Apple-Foto (Beispielfotos, image_is_example = true). Der Platzhalter zeigt kein
-- Produkt, daher image_is_example = false.
-- Mehrfach ausführbar. Neue Produkte ohne eigenes Foto später ebenso eintragen.
-- ============================================================================

update public.products p
   set image_url = 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp',
       image_is_example = false
  from public.brands b
 where b.id = p.brand_id
   and b.name not in ('Red Bull', 'Monster Energy');

-- Kontrolle
select b.name in ('Red Bull', 'Monster Energy') as beispielfoto, p.image_url, count(*)
  from public.products p join public.brands b on b.id = p.brand_id
 group by 1, 2 order by 1, 2;
