-- ============================================================================
-- Produkte und Nährwerte aus Open Food Facts (Stand 10.10.2026)
-- ============================================================================
-- Quelle: Open Food Facts (openfoodfacts.org). Datenbank unter der Open Database
-- License (ODbL) 1.0, einzelne Inhalte unter der Database Contents License
-- (DbCL) 1.0. Übernommen wurden nur Einträge mit Land Deutschland, vollständigen
-- Grundwerten (kcal, Kohlenhydrate, Zucker, Fett, ges. Fettsäuren, Eiweiß, Salz)
-- und ohne auffällige Werte; Namen vereinheitlicht, Dubletten entfernt. Fehlt die
-- Verpackungsangabe, ist bei 250/330/500 ml „Dose“ eingetragen und als nicht
-- bestätigt markiert (packaging_assumed). Beispielbilder sind markiert
-- (image_is_example); die App kennzeichnet beides, fehlende Werte als „k. A.“.
-- 112 neue Produkte, 114 Nährwert-Zeilen (davon 2 für vorhandene Produkte); 4BRO auf Wunsch
-- entfernt (siehe sql-4bro-entfernen.sql).
-- Bilder: Red-Bull-Produkte das Red-Bull-Beispielfoto, Monster-Produkte das Monster-Beispielfoto,
-- alle anderen das Platzhalterbild „Foto folgt“ (siehe sql-platzhalterbild.sql).
-- Keine Fotos von Open Food Facts.
-- Mehrfach ausführbar (add column if not exists, on conflict ... do update).
-- ============================================================================

begin;

alter table public.products
  add column if not exists packaging_assumed boolean not null default false,
  add column if not exists image_is_example  boolean not null default false;
comment on column public.products.packaging_assumed is 'true = Verpackung nicht aus der Quelle, sondern aus der Füllmenge angenommen; die App kennzeichnet sie als nicht bestätigt.';
comment on column public.products.image_is_example is 'true = image_url ist ein Beispielbild und zeigt nicht dieses Produkt; die App kennzeichnet es als Beispielbild.';
alter table public.product_nutrition
  add column if not exists source     text,
  add column if not exists source_ref text;
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'product_nutrition_source_check') then
    alter table public.product_nutrition add constraint product_nutrition_source_check
      check (source in ('open_food_facts', 'eigene_erfassung'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'product_nutrition_source_ref_check') then
    alter table public.product_nutrition add constraint product_nutrition_source_ref_check
      check (source_ref ~ '^[0-9]{8,14}$');
  end if;
end $$;
comment on table public.product_nutrition is 'Naehrwerte pro 100ml, 1:1 optional zu products. Fehlende Werte bleiben null (App zeigt "k. A."). Herkunft siehe source.';
comment on column public.product_nutrition.source is 'Herkunft der Werte: open_food_facts (Lizenz ODbL 1.0, einzelne Inhalte DbCL 1.0; App nennt die Quelle mit Link) oder eigene_erfassung. Leer = Herkunft nicht erfasst.';
comment on column public.product_nutrition.source_ref is 'Bei open_food_facts: Barcode des Eintrags, daraus baut die App den Link zur Produktseite.';
comment on table public.brand_nutrition_defaults is 'Marken-Fallback-Naehrwerte, nur genutzt, wenn product_nutrition fuer ein Produkt fehlt.';

insert into public.products (id, brand_id, name, size_ml, packaging, packaging_assumed, image_url, image_is_example, is_new) values
  ('740427bf-4a2f-53a2-8efc-d66889bf2062', '0fcad57d-2f69-4d91-80d9-c357e77a6e8d', '28 Black Açaí', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('af361529-34db-55e6-a196-798accffb780', '0fcad57d-2f69-4d91-80d9-c357e77a6e8d', '28 Black Açaí Zero', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('3ff1e502-608b-5292-a461-fdc76e9ac63a', '0fcad57d-2f69-4d91-80d9-c357e77a6e8d', '28 Black Limette-Minze', 250, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('1a13d1d3-4e08-55ca-8c0b-7fa6d10ab88b', '0fcad57d-2f69-4d91-80d9-c357e77a6e8d', '28 Black Sour Mango-Kiwi', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('b8a9ceb9-9078-5245-9da7-ceea442d515a', '0969fae8-ff2f-49da-955a-ed6a5e69d302', 'Action Energy Green Apple', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('f2b5e8aa-da01-5578-b48f-078ae6b5b32a', '5d447373-f9d5-437e-9fd3-d06b172fe983', 'Bang Peach Mango', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('8ffbbb7b-7362-509b-9def-a5f95e93b828', 'cce355b6-7b30-41c1-b069-a083fbcec156', 'Booster Absolute Zero', 330, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('bda68e78-dbec-5075-af97-85c322dcd23e', 'cce355b6-7b30-41c1-b069-a083fbcec156', 'Booster Citrus', 330, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('e864b28e-3856-5adf-8788-2eff1aa3dc92', 'cce355b6-7b30-41c1-b069-a083fbcec156', 'Booster Blue Bomb Blueberry', 330, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('26a1b979-f3ee-546c-8951-73d3643444cc', 'cce355b6-7b30-41c1-b069-a083fbcec156', 'Booster Exotic', 330, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('73591768-008b-5029-8ccd-c1cfc4f093d2', 'cce355b6-7b30-41c1-b069-a083fbcec156', 'Booster Hemp', 330, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('3935ef25-6240-5717-8159-7001167b2498', 'cce355b6-7b30-41c1-b069-a083fbcec156', 'Booster Juicy', 330, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('c978d077-51f9-5059-aa6c-961ffb317651', 'cce355b6-7b30-41c1-b069-a083fbcec156', 'Booster Original', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('15a992b5-1209-5cd6-8cfa-2f05205cbdac', 'b45620da-ec3c-4cf4-9599-c1d66370b5b0', 'C4 Energy Frozen Bombsicle Zero', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('3988f3a6-b4b4-5302-a112-695c13a2cce5', '559d9c0f-7fdc-4d1c-97de-04fb7fc5d1dd', 'Crazy Wolf Cranberry Chili', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('0dac04bc-8694-56c0-be8f-a0cddb3bb6ac', '559d9c0f-7fdc-4d1c-97de-04fb7fc5d1dd', 'Crazy Wolf Energy Drink', 330, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('54c9860f-4911-580f-a50d-91f609aeceb0', '559d9c0f-7fdc-4d1c-97de-04fb7fc5d1dd', 'Crazy Wolf Ginseng + Guarana', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('a136dbf5-773a-5a7e-b51a-754c47e9c2dc', 'ac5958e0-e609-43fb-acec-b5e0ffa369d1', 'Effect Bubble Gum', 330, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('719e145c-f2aa-553d-9d99-d955c8465b3d', 'ac5958e0-e609-43fb-acec-b5e0ffa369d1', 'Effect Energy Drink', 330, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('e7ea2417-2360-5768-b7b3-69e51afeaa65', 'ac5958e0-e609-43fb-acec-b5e0ffa369d1', 'Effect Energy Drink', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('b37542d8-7dbf-53fd-8d18-94a5ce31abf9', 'ac5958e0-e609-43fb-acec-b5e0ffa369d1', 'Effect BCAA Energy Tropical Blast', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('23ca25aa-b67d-5cb3-807b-a62e758240e8', 'ac5958e0-e609-43fb-acec-b5e0ffa369d1', 'Effect Black Açaí', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('7021b15f-5d86-5c46-b8fa-7ee0e5fc69ea', 'ac5958e0-e609-43fb-acec-b5e0ffa369d1', 'Effect Energy Drink', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('bfc58fea-2974-527b-8af8-d6bc881b9e65', 'ac5958e0-e609-43fb-acec-b5e0ffa369d1', 'Effect Performance Super Berry', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('8b5a4ffe-c9c7-5ae6-8d6b-69bf4365a8ad', 'ac5958e0-e609-43fb-acec-b5e0ffa369d1', 'Effect Shredded Cola Crush', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('3b20e793-78f1-52a3-a693-bc30e701956a', 'ac5958e0-e609-43fb-acec-b5e0ffa369d1', 'Effect Zero', 330, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('15f9ab35-84a5-5ebd-b367-c88ea763ac59', 'fe3e9d14-775c-4c9c-a3b3-8829e315b984', 'Flying Power Apple Cinnamon', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('cb10c20f-67d5-5228-8af9-662639705711', 'fe3e9d14-775c-4c9c-a3b3-8829e315b984', 'Flying Power Cherry Vanilla', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('068c8a19-9761-5312-b7bd-8db1a13a8f45', 'fe3e9d14-775c-4c9c-a3b3-8829e315b984', 'Flying Power Guave', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('29d8d259-b88f-57d1-a390-38ae04aec3da', 'fe3e9d14-775c-4c9c-a3b3-8829e315b984', 'Flying Power Lotus Karamell', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('3525b74e-780b-5b97-97df-fc8e23b1b35c', 'fe3e9d14-775c-4c9c-a3b3-8829e315b984', 'Flying Power Sauerkirsche', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('723dec1e-cf07-58f0-a940-977975729336', 'fe3e9d14-775c-4c9c-a3b3-8829e315b984', 'Flying Power Watermelon', 500, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('a67b74d9-09fd-576d-b309-36c552963afa', 'fe3e9d14-775c-4c9c-a3b3-8829e315b984', 'Flying Power Energy Drink', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('33f6a4c5-df2a-57ba-86b0-7efa4e314d4f', 'fe3e9d14-775c-4c9c-a3b3-8829e315b984', 'Flying Power Energy Drink', 330, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('1191be29-2b12-5d3f-8078-7c27bae12c92', 'fe3e9d14-775c-4c9c-a3b3-8829e315b984', 'Flying Power Zero', 330, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('028ba400-1118-5546-abba-c3a62bfd6588', 'fe3e9d14-775c-4c9c-a3b3-8829e315b984', 'Flying Power Zero', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('c3cedaa1-9497-5f03-b92e-2d379446ec99', 'fe3e9d14-775c-4c9c-a3b3-8829e315b984', 'Flying Power Raspberry Strike', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('861ec936-0fcd-50f5-80ec-a02106742fca', 'fe3e9d14-775c-4c9c-a3b3-8829e315b984', 'Flying Power Think Big Heidelbeere-Kaktusfeige', 330, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('c4478e50-2139-5e1c-8ab7-337a3a13d62a', 'fe3e9d14-775c-4c9c-a3b3-8829e315b984', 'Flying Power Think Big Orange-Yuzu', 330, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('8a745135-451b-5d88-afac-31f479431946', 'fe3e9d14-775c-4c9c-a3b3-8829e315b984', 'Flying Power Zero', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('66b489c1-3c1e-519a-9b48-e1fde380ca69', 'caad03ca-26e6-425c-b75c-710c48fa6137', 'Gönrgy No Winter Edition Tropical Guave', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('e108d4fb-4417-5234-85c8-6b7d83fc274a', 'caad03ca-26e6-425c-b75c-710c48fa6137', 'Gönrgy Raspberry Cheesecake', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('1101a609-3ac7-5ef9-885b-6b30b910fcf5', 'caad03ca-26e6-425c-b75c-710c48fa6137', 'Gönrgy Tropical Exotic', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('384d8bad-3062-5daa-acb5-20bef96ff657', 'caad03ca-26e6-425c-b75c-710c48fa6137', 'Gönrgy Juneberry Jam', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('806354d0-8a68-5402-a2f4-03e39da14550', 'caad03ca-26e6-425c-b75c-710c48fa6137', 'Gönrgy Sweet Lemon', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('d4efabe2-2974-5cbe-a448-df4d50096fc2', 'caad03ca-26e6-425c-b75c-710c48fa6137', 'Gönrgy White Peach', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('deb55325-c53a-5d34-93d8-12b746631101', '0e460d51-06d3-49ca-97cb-d84fb62243f7', 'Kong Strong Cold Brew Coffee', 330, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('a475c39b-2d47-5c1c-8cf7-4018ee13e688', '0e460d51-06d3-49ca-97cb-d84fb62243f7', 'Kong Strong Colossus', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('954a776c-9f7c-53f8-b866-1d1afac79ab4', '0e460d51-06d3-49ca-97cb-d84fb62243f7', 'Kong Strong Energy Drink', 330, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('a7bb13b1-9872-5a5f-bc8c-988650c124a6', '0e460d51-06d3-49ca-97cb-d84fb62243f7', 'Kong Strong Kokos-Blaubeere', 330, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('f2540e27-5631-5f05-9f8d-40017c5002ab', '0e460d51-06d3-49ca-97cb-d84fb62243f7', 'Kong Strong Sugar Free', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('365072ee-a7fe-5fb7-aa6f-13c76843924a', '0e460d51-06d3-49ca-97cb-d84fb62243f7', 'Kong Strong Colossus Zero', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('bfedfd08-44e1-5435-81b2-edc2593eec33', '0e460d51-06d3-49ca-97cb-d84fb62243f7', 'Kong Strong Hanf', 330, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('41c71b22-8eeb-59b0-b840-91d323ba5cf9', '0e460d51-06d3-49ca-97cb-d84fb62243f7', 'Kong Strong Sugar Free XXL', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('440a3505-04b7-517c-a5be-5fc46b0b3d21', '0e460d51-06d3-49ca-97cb-d84fb62243f7', 'Kong Strong Wild Power', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('2b1fdf4b-8d58-5813-a4d3-ef6079224214', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Absolutely Zero', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('438b20a8-28cd-5798-9909-7c8ade0615e9', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Assault', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('817ad61f-1d26-534f-929f-92c2fa4fe7f1', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Ultra Violet', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('d9299b2e-466d-5557-965c-a43fedc8621a', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Espresso Monster', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('2828971f-2e5a-5616-a955-a7fa19942fd4', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Juiced Khaotic', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('3359af5e-6876-53ee-b6b1-209d8c3a7275', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Lewis Hamilton Zero Sugar', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('ad15f3b7-f645-51a8-a7ee-8cb2b7717c62', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Juiced Aussie Style Lemonade', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('77b3651e-92a5-5d57-95f4-708a43c3452e', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Nitro', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('052a2824-5a11-5557-b6bc-8140a63c0456', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Ultra Red', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('90fdf165-725f-5137-ab60-af45751849b2', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Juiced Monarch', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('28feb9f0-9845-5aad-92f2-d00c02f0f5d9', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Juiced Mixxd Punch', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('f6607c05-9a11-5031-9efc-356d56153d3d', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Rehab Peach Tea', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('cec3e665-6a55-5cb2-98b8-dd9ab136e962', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy The Doctor', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('7857e2ad-a23c-5ad0-955c-193dea122b77', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Ultra Fiesta Mango', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('1770d5ae-21e7-59da-8691-0f75f3222e7b', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Ultra Paradise', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('4f1c2d3b-358d-5667-b196-e2e057a1d8d1', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Ultra Watermelon', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('e62752c2-47f2-5cd5-87f2-ad50a2cc6791', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Reserve Watermelon', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('48537652-ab77-5df4-85ef-65b442e20391', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Ultra Rosá', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true, false),
  ('09318993-4f1c-5b48-9868-85d7b9ef471f', '524ca3ed-7d57-4408-afaf-53bebe596e21', 'NOCCO Miami Strawberry', 330, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('88c23f16-a1c9-5b3e-9d8f-99fe69cc99ae', '11111111-1111-4111-8111-111111111111', 'Red Bull Açaí', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', true, false),
  ('7ce7a6fa-6097-5e0c-b217-7f1620680858', '11111111-1111-4111-8111-111111111111', 'Red Bull Feige-Apfel', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', true, false),
  ('5a990fc7-cdaf-5232-8f52-bf9eb4e8b58e', '11111111-1111-4111-8111-111111111111', 'Red Bull Iced Vanilla Berry', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', true, false),
  ('05ae1f00-5a47-5832-8d0f-4798e8bbe92e', '11111111-1111-4111-8111-111111111111', 'Red Bull Juneberry', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', true, false),
  ('7f1a0915-479a-546d-a45b-39200567ce19', '11111111-1111-4111-8111-111111111111', 'Red Bull Kokos-Blaubeere', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', true, false),
  ('e32ead25-521c-5ed4-a17f-bcb39cc5d7e6', '11111111-1111-4111-8111-111111111111', 'Red Bull Energy Drink', 330, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', true, false),
  ('1af72b33-8894-5ceb-855c-4d4addf0473d', '11111111-1111-4111-8111-111111111111', 'Red Bull Energy Drink', 355, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', true, false),
  ('c87f6e2e-9fdc-5d81-962c-9063bcfd499b', '11111111-1111-4111-8111-111111111111', 'Red Bull Energy Drink', 473, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', true, false),
  ('35230bb0-9361-5dbd-a3b9-4cb7842383a1', '11111111-1111-4111-8111-111111111111', 'Red Bull Pfirsich', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', true, false),
  ('5bd9d372-5b2a-57c1-82d2-07682caebf2e', '11111111-1111-4111-8111-111111111111', 'Red Bull Tropical', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', true, false),
  ('57324133-93d8-5831-bfad-6dd64072ead5', '11111111-1111-4111-8111-111111111111', 'Red Bull Green Edition', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', true, false),
  ('06dfa838-516b-5815-b821-387d984277b7', '11111111-1111-4111-8111-111111111111', 'Red Bull Zero', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', true, false),
  ('79380b18-fdb9-5a00-8df9-8d4d8956d421', '11111111-1111-4111-8111-111111111111', 'Red Bull Summer Edition Drachenfrucht', 250, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', true, false),
  ('c880d239-573a-504d-be1f-3b62d487e1f7', '11111111-1111-4111-8111-111111111111', 'Red Bull Winter Edition Granatapfel', 250, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', true, false),
  ('056f23d1-34f2-590c-a4a7-18cb4b5a7bd1', '11111111-1111-4111-8111-111111111111', 'Red Bull Zero', 330, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', true, false),
  ('c2e0620f-37f0-5565-9a1d-810947b0b17f', '43c8d319-2f51-42ec-948f-d05d2005679b', 'Reign Sour Apple', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('3a8cecaf-33cf-5dab-b8d7-c31defd072c2', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Frozen Raspberry', 500, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('964f50eb-8365-5e4b-a09d-ae622f710078', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Juiced El Mango', 500, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('b8f208f2-55b5-5b86-be5b-9bb5cfeb8e7c', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Freeze', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('0caff37e-1d2a-5b60-8232-3d7e416de1c0', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Mixed Berries', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('7c74b27b-3fbd-5cc5-9046-fa816c1e93e7', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Organic Island Fruit', 500, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('47ef70c8-ff5b-5ff6-a7f6-faf53039d6b3', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Organic Strawberry', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('25bbbcc2-bd4d-5a2f-aca3-e9861dc57b63', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Blueberry Pomegranate Açaí', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('6ed38422-9def-5fb8-a40c-cf4b6451ed04', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Apple', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('ca4611e9-c57a-5747-baae-feb3bca94e38', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Berry Blast', 500, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('27862b69-e310-5417-91d5-d4f8f44edfa9', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Juiced Machu Peachu', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('2f6af537-1c30-5466-813d-e81873180cea', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Original', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('028f9b75-0e57-5a2f-848b-0a0aa748678e', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Pineapple & Coconut', 500, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('c48adcc8-d83d-59d6-83c6-3fbfc92faff2', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Guava Pineapple', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('799e4a55-9984-5d47-a250-f41507f0ccd5', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Waldmeister', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('93f20aa2-f5a6-535e-938a-ecb56de993a6', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Original', 250, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('d6ad9a65-b2ee-54a2-952e-d98e51fae43e', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Revolt Killer Cherry', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('85cb9a04-75e3-5d05-a4a7-3651bb42168c', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Sour Raspberry', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('4a3650d4-b275-57c0-838f-ba9704366cbf', 'd54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar XDurance Grape', 500, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('82571b0b-24c3-5efe-83f8-5f1031bbce5c', '6463b663-c76f-4559-b1e8-fe7c62a46242', 'Scenatic The Energizer', 500, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('70bf6429-7fa1-5071-b8b8-06880fd52239', '6abbe965-823c-46d7-8770-9a6eb2dbc6bc', 'Take Off Energy Drink', 330, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('24d566a3-0c3f-538c-88dc-253fb49d1f2a', '12a11591-cb73-4983-96b7-c71f8b02ee7c', 'Vita Energy Himbeere-Wassermelone Zero', 330, 'Dose', true, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false),
  ('8d7c1733-f3f3-5ef3-9902-dd8181c5e1f0', '12a11591-cb73-4983-96b7-c71f8b02ee7c', 'Vita Energy Mango-Orange', 330, 'Dose', false, 'https://canspot.de/wp-content/Produktbilder/platzhalter-foto-folgt-450x600.webp', false, false)
on conflict (id) do update set
  brand_id = excluded.brand_id,
  name = excluded.name,
  size_ml = excluded.size_ml,
  packaging = excluded.packaging,
  packaging_assumed = excluded.packaging_assumed,
  image_url = excluded.image_url,
  image_is_example = excluded.image_is_example,
  is_new = excluded.is_new;

-- vorhandene Produkte: Beispielbilder kennzeichnen, Red-Bull-Produkte mit Red-Bull-Bild
update public.products set image_url = 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', image_is_example = true where id = '73ab667f-75d7-4b02-a42e-47bae05ae065';
update public.products set image_url = 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', image_is_example = true where id = 'dbcfcbdf-05e9-4bd5-ba24-5362d09612d9';
update public.products set image_url = 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', image_is_example = true where id = 'd6a55d57-3b1b-4a2b-aff1-edeb0eb48399';
update public.products set image_is_example = true where id = '1e86d7b4-fecc-4e2a-a930-a7e92f0067da';
update public.products set image_is_example = true where id = '7dfb0a5d-354b-4845-af7e-8c2e9120020b';
update public.products set image_is_example = false where id = '67e34e31-a36f-48c3-bd29-fedfb4288732';
update public.products set image_is_example = false where id = '82319af1-c3ef-4e85-8835-b64a76e76410';

insert into public.product_nutrition (product_id, kcal, carbs_g, sugar_g, fat_g, sat_fat_g, protein_g, salt_g, caffeine_mg, taurine_mg, source, source_ref) values
  ('740427bf-4a2f-53a2-8efc-d66889bf2062', 45, 11, 11, 0, 0, 0, 0, 32, null, 'open_food_facts', '4260160950010'),
  ('af361529-34db-55e6-a196-798accffb780', 2, 0, 0, 0, 0, 0, 0.03, 32, null, 'open_food_facts', '4260160952014'),
  ('3ff1e502-608b-5292-a461-fdc76e9ac63a', 46, 11, 11, 0, 0, 0, 0, null, null, 'open_food_facts', '4260160952281'),
  ('1a13d1d3-4e08-55ca-8c0b-7fa6d10ab88b', 43, 10, 10, 0, 0, 0, 0, 32, null, 'open_food_facts', '4260160951666'),
  ('b8a9ceb9-9078-5245-9da7-ceea442d515a', 48, 11, 11, 0.5, 0.1, 0.5, 0.15, null, null, 'open_food_facts', '4021155160179'),
  ('f2b5e8aa-da01-5578-b48f-078ae6b5b32a', 3, 0, 0, 0, 0, 0.5, 0, null, null, 'open_food_facts', '8720211190049'),
  ('8ffbbb7b-7362-509b-9def-a5f95e93b828', 2, 0.01, 0, 0, 0, 0.02, 0.17, 32, null, 'open_food_facts', '4311596490202'),
  ('bda68e78-dbec-5075-af97-85c322dcd23e', 41, 9.8, 9.8, 0, 0, 0.01, 0, null, null, 'open_food_facts', '4044703012201'),
  ('e864b28e-3856-5adf-8788-2eff1aa3dc92', 42, 10, 10, 0, 0, 0, 0, null, null, 'open_food_facts', '4044703011679'),
  ('26a1b979-f3ee-546c-8951-73d3643444cc', 43, 10.5, 10.4, 0, 0, 0, 0, null, null, 'open_food_facts', '4311596490363'),
  ('73591768-008b-5029-8ccd-c1cfc4f093d2', 31, 7.3, 7.2, 0, 0, 0, 0, null, null, 'open_food_facts', '4044703048248'),
  ('3935ef25-6240-5717-8159-7001167b2498', 43, 10.4, 10.4, 0, 0, 0, 0, 32, null, 'open_food_facts', '4311596483037'),
  ('c978d077-51f9-5059-aa6c-961ffb317651', 44, 10.4, 10.4, 0, 0, 0, 0.2, null, null, 'open_food_facts', '4311596491322'),
  ('15a992b5-1209-5cd6-8cfa-2f05205cbdac', 3, 0, 0, 0, 0, 0, 0, null, null, 'open_food_facts', '0842595113129'),
  ('3988f3a6-b4b4-5302-a112-695c13a2cce5', 52, 11, 11, 0.5, 0.1, 0.5, 0.23, null, null, 'open_food_facts', '4337185695636'),
  ('0dac04bc-8694-56c0-be8f-a0cddb3bb6ac', 47, 11, 11, 0.5, 0.1, 0.5, 0.16, null, null, 'open_food_facts', '4063367130922'),
  ('54c9860f-4911-580f-a50d-91f609aeceb0', 44, 10, 10, 0.5, 0.1, 0.5, 0.2, null, null, 'open_food_facts', '4063367354335'),
  ('a136dbf5-773a-5a7e-b51a-754c47e9c2dc', 40, 9.6, 9.6, 0, 0.06, 0, 0.06, null, null, 'open_food_facts', '4025127087396'),
  ('719e145c-f2aa-553d-9d99-d955c8465b3d', 46, 10.7, 10.7, 0, 0, 0, 0.17, 32, null, 'open_food_facts', '4025127020997'),
  ('e7ea2417-2360-5768-b7b3-69e51afeaa65', 46, 10.7, 10.7, 0, 0, 0, 0.17, null, null, 'open_food_facts', '4025127020799'),
  ('b37542d8-7dbf-53fd-8d18-94a5ce31abf9', 4, 0, 0, 0.2, 0, 0, 0.09, null, null, 'open_food_facts', '4025127089468'),
  ('23ca25aa-b67d-5cb3-807b-a62e758240e8', 46, 11, 11, 0, 0, 0, 0, null, null, 'open_food_facts', '4025127091928'),
  ('7021b15f-5d86-5c46-b8fa-7ee0e5fc69ea', 46, 10.7, 10.7, 0, 0, 0, 0.2, null, null, 'open_food_facts', '4025127020027'),
  ('bfc58fea-2974-527b-8af8-d6bc881b9e65', 4, 0, 0, 0, 0, 0, 0.09, 30, null, 'open_food_facts', '4025127089505'),
  ('8b5a4ffe-c9c7-5ae6-8d6b-69bf4365a8ad', 4, 2.1, 0, 0, 0, 0, 0.13, null, null, 'open_food_facts', '4025127089482'),
  ('3b20e793-78f1-52a3-a693-bc30e701956a', 4, 0, 0, 0, 0, 0, 0.17, null, null, 'open_food_facts', '4025127020683'),
  ('15f9ab35-84a5-5ebd-b367-c88ea763ac59', 50, 12, 12, 0, 0, 0, 0.21, null, null, 'open_food_facts', '4047247926454'),
  ('cb10c20f-67d5-5228-8af9-662639705711', 44, 10, 10, 0, 0, 0, 0.21, null, null, 'open_food_facts', '4047247926461'),
  ('068c8a19-9761-5312-b7bd-8db1a13a8f45', 66, 16, 16, 0.5, 0.1, 0.5, 0.06, 32, null, 'open_food_facts', '4061462355264'),
  ('29d8d259-b88f-57d1-a390-38ae04aec3da', 44, 10, 10, 0, 0, 0, 0.21, null, null, 'open_food_facts', '4047247926447'),
  ('3525b74e-780b-5b97-97df-fc8e23b1b35c', 51, 12, 12, 0, 0, 0, 0.21, null, null, 'open_food_facts', '4047247339742'),
  ('723dec1e-cf07-58f0-a940-977975729336', 40, 9.6, 9.6, 0.5, 0.1, 0.5, 0.01, null, null, 'open_food_facts', '4061458252621'),
  ('a67b74d9-09fd-576d-b309-36c552963afa', 46, 11, 10, 0.5, 0.1, 0.5, 0.23, 30, null, 'open_food_facts', '4047247339773'),
  ('33f6a4c5-df2a-57ba-86b0-7efa4e314d4f', 48, 11, 11, 0, 0, 0, 0.2, null, null, 'open_food_facts', '4061458252645'),
  ('1191be29-2b12-5d3f-8078-7c27bae12c92', 3, 0, 0, 0, 0, 0, 0.2, null, null, 'open_food_facts', '4061458252652'),
  ('028ba400-1118-5546-abba-c3a62bfd6588', 3, 0, 0, 0, 0, 0, 0.12, null, null, 'open_food_facts', '4047247339766'),
  ('c3cedaa1-9497-5f03-b92e-2d379446ec99', 58, 14, 14, 0, 0, 0, 0, null, null, 'open_food_facts', '42392262'),
  ('861ec936-0fcd-50f5-80ec-a02106742fca', 19, 4.3, 4.3, 0.5, 0.1, 0.5, 0.08, 20, null, 'open_food_facts', '4061459666472'),
  ('c4478e50-2139-5e1c-8ab7-337a3a13d62a', 19, 4.3, 4.3, 0.5, 0.1, 0.5, 0.01, 20, null, 'open_food_facts', '4061459666434'),
  ('8a745135-451b-5d88-afac-31f479431946', 3, 0, 0, 0, 0, 0, 0.14, null, null, 'open_food_facts', '4047247016155'),
  ('66b489c1-3c1e-519a-9b48-e1fde380ca69', 2, 0.5, 0, 0, 0, 0.5, 0.01, 32, null, 'open_food_facts', '4262484620013'),
  ('e108d4fb-4417-5234-85c8-6b7d83fc274a', 3, 0, 0, 0, 0, 0, 0, 32, null, 'open_food_facts', '4260456730180'),
  ('1101a609-3ac7-5ef9-885b-6b30b910fcf5', 3, 0, 0, 0, 0, 0, 0, null, null, 'open_food_facts', '4260456730227'),
  ('384d8bad-3062-5daa-acb5-20bef96ff657', 2, 0.5, 0, 0, 0, 0.5, 0.01, 32, null, 'open_food_facts', '4260456730388'),
  ('806354d0-8a68-5402-a2f4-03e39da14550', 2, 0.5, 0, 0, 0, 0.5, 0.01, null, null, 'open_food_facts', '4260456730401'),
  ('d4efabe2-2974-5cbe-a448-df4d50096fc2', 2, 0.5, 0, 0, 0, 0.5, 0.01, null, null, 'open_food_facts', '4260456730395'),
  ('deb55325-c53a-5d34-93d8-12b746631101', 34, 8, 8, 0, 0, 0, 0.06, null, null, 'open_food_facts', '42414025'),
  ('a475c39b-2d47-5c1c-8cf7-4018ee13e688', 48, 11.4, 11.4, 0, 0, 0, 0.27, null, null, 'open_food_facts', '42391944'),
  ('954a776c-9f7c-53f8-b866-1d1afac79ab4', 44, 10.2, 9.9, 0, 0, 0.3, 0.23, 32, null, 'open_food_facts', '42391760'),
  ('a7bb13b1-9872-5a5f-bc8c-988650c124a6', 40, 9.5, 9.5, 0, 0, 0, 0.07, null, null, 'open_food_facts', '4056489962984'),
  ('f2540e27-5631-5f05-9f8d-40017c5002ab', 3, 0.1, 0.1, 0, 0, 0.4, 0.09, null, null, 'open_food_facts', '42391968'),
  ('365072ee-a7fe-5fb7-aa6f-13c76843924a', 4, 0, 0, 0, 0, 0, 0.25, 30, 400, 'open_food_facts', '42391951'),
  ('bfedfd08-44e1-5435-81b2-edc2593eec33', 31, 7.4, 7.3, 0, 0, 0.1, 0.01, null, null, 'open_food_facts', '42401360'),
  ('41c71b22-8eeb-59b0-b840-91d323ba5cf9', 2, 0, 0, 0, 0, 0, 0.23, null, null, 'open_food_facts', '42376040'),
  ('440a3505-04b7-517c-a5be-5fc46b0b3d21', 42, 10.1, 10, 0, 0, 0, 0.24, null, null, 'open_food_facts', '42276098'),
  ('2b1fdf4b-8d58-5813-a4d3-ef6079224214', 3, 1, 0, 0, 0, 0, 0.21, 30, null, 'open_food_facts', '5060335635242'),
  ('438b20a8-28cd-5798-9909-7c8ade0615e9', 71, 18, 16, 0, 0, 0, 0.06, null, null, 'open_food_facts', '5060335635235'),
  ('817ad61f-1d26-534f-929f-92c2fa4fe7f1', 3, 1.4, 0, 0, 0, 0, 0.2, null, null, 'open_food_facts', '5060517883638'),
  ('d9299b2e-466d-5557-965c-a43fedc8621a', 56, 6.9, 6.6, 2.1, 1.4, 2.5, 0.1, null, null, 'open_food_facts', '5060639120949'),
  ('2828971f-2e5a-5616-a955-a7fa19942fd4', 34, 8.6, 7.8, 0.01, 0, 0, 0.06, null, null, 'open_food_facts', '5060896622859'),
  ('3359af5e-6876-53ee-b6b1-209d8c3a7275', 3, 0.8, 0, 0, 0, 0, 0.16, 32, null, 'open_food_facts', '5060896625829'),
  ('ad15f3b7-f645-51a8-a7ee-8cb2b7717c62', 42, 11, 9.7, 0, 0, 0, 0.08, 32, null, 'open_food_facts', '5060947541986'),
  ('77b3651e-92a5-5d57-95f4-708a43c3452e', 38, 9.7, 8.4, 0, 0, 1.1, 0.22, 32, null, 'open_food_facts', '5060896622132'),
  ('052a2824-5a11-5557-b6bc-8140a63c0456', 2, 0.6, 0, 0, 0, 0, 0.19, null, null, 'open_food_facts', '5060337500609'),
  ('90fdf165-725f-5137-ab60-af45751849b2', 44, 11, 10, 0, 0, 0.1, 0.1, null, null, 'open_food_facts', '5060751212393'),
  ('28feb9f0-9845-5aad-92f2-d00c02f0f5d9', 38, 9.5, 9, 0, 0, 0, 0.05, null, null, 'open_food_facts', '5060335635280'),
  ('f6607c05-9a11-5031-9efc-356d56153d3d', 10, 2.2, 2.1, 0.1, 0.1, 0.1, 0.12, null, null, 'open_food_facts', '5060337507608'),
  ('cec3e665-6a55-5cb2-98b8-dd9ab136e962', 44, 11, 10, 0, 0, 0, 0.02, 32, null, 'open_food_facts', '5060335635266'),
  ('7857e2ad-a23c-5ad0-955c-193dea122b77', 3, 1.3, 0, 0, 0, 0, 0.2, 30, null, 'open_food_facts', '5060751212249'),
  ('1770d5ae-21e7-59da-8691-0f75f3222e7b', 3, 0.9, 0, 0, 0, 0, 0.16, null, null, 'open_food_facts', '5060639126897'),
  ('4f1c2d3b-358d-5667-b196-e2e057a1d8d1', 3, 1.3, 0, 0, 0, 0, 0.1, null, null, 'open_food_facts', '5060751219095'),
  ('e62752c2-47f2-5cd5-87f2-ad50a2cc6791', 25, 6.5, 5.9, 0, 0, 0, 0.12, null, null, 'open_food_facts', '5060896628790'),
  ('48537652-ab77-5df4-85ef-65b442e20391', 3, 0.9, 0, 0, 0, 0, 0.2, null, null, 'open_food_facts', '5060947541153'),
  ('09318993-4f1c-5b48-9868-85d7b9ef471f', 4, 0, 0, 0, 0, 0.9, 0, null, null, 'open_food_facts', '7340131601671'),
  ('88c23f16-a1c9-5b3e-9d8f-99fe69cc99ae', 44, 10, 10, 0, 0, 0, 0.1, null, null, 'open_food_facts', '90433221'),
  ('7ce7a6fa-6097-5e0c-b217-7f1620680858', 46, 11, 11, 0, 0, 0, 0.1, null, null, 'open_food_facts', '90453793'),
  ('5a990fc7-cdaf-5232-8f52-bf9eb4e8b58e', 46, 11, 11, 0, 0, 0, 0.1, 32, null, 'open_food_facts', '90376603'),
  ('05ae1f00-5a47-5832-8d0f-4798e8bbe92e', 45, 11, 11, 0, 0, 0, 0.1, null, null, 'open_food_facts', '90453885'),
  ('7f1a0915-479a-546d-a45b-39200567ce19', 45, 11, 11, 0, 0, 0, 0.1, 32, null, 'open_food_facts', '90433627'),
  ('e32ead25-521c-5ed4-a17f-bcb39cc5d7e6', 46, 11, 11, 0, 0, 0, 0.1, null, null, 'open_food_facts', '9002490228736'),
  ('1af72b33-8894-5ceb-855c-4d4addf0473d', 46, 11, 11, 0, 0, 0, 0.1, null, null, 'open_food_facts', '9002490206840'),
  ('c87f6e2e-9fdc-5d81-962c-9063bcfd499b', 46, 11, 11, 0, 0, 0, 0.1, null, null, 'open_food_facts', '90376139'),
  ('73ab667f-75d7-4b02-a42e-47bae05ae065', 46, 11, 11, 0, 0, 0, 0.1, null, null, 'open_food_facts', '9002490205973'),
  ('35230bb0-9361-5dbd-a3b9-4cb7842383a1', 45, 11, 11, 0, 0, 0, 0.1, 32, null, 'open_food_facts', '90446535'),
  ('5bd9d372-5b2a-57c1-82d2-07682caebf2e', 46, 11, 11, 0, 0, 0, 0.1, null, null, 'open_food_facts', '90415722'),
  ('57324133-93d8-5831-bfad-6dd64072ead5', 46, 11, 11, 0, 0, 0, 0.1, null, null, 'open_food_facts', '90424168'),
  ('06dfa838-516b-5815-b821-387d984277b7', 2, 0, 0, 0, 0, 0, 0.02, null, null, 'open_food_facts', '90415296'),
  ('79380b18-fdb9-5a00-8df9-8d4d8956d421', 45, 11, 11, 0, 0, 0, 0.1, null, null, 'open_food_facts', '90446870'),
  ('d6a55d57-3b1b-4a2b-aff1-edeb0eb48399', 45, 11, 11, 0, 0, 0, 0.1, 32, null, 'open_food_facts', '90446689'),
  ('c880d239-573a-504d-be1f-3b62d487e1f7', 45, 11, 11, 0, 0, 0, 0.1, null, null, 'open_food_facts', '90448393'),
  ('056f23d1-34f2-590c-a4a7-18cb4b5a7bd1', 3, 0, 0, 0, 0, 0, 0.1, 30, 400, 'open_food_facts', '9002490242329'),
  ('c2e0620f-37f0-5565-9a1d-810947b0b17f', 3, 0.7, 0, 0, 0, 0.2, 0.3, null, null, 'open_food_facts', '5060608742967'),
  ('3a8cecaf-33cf-5dab-b8d7-c31defd072c2', 54, 13, 13, 0, 0, 0.2, 0, null, null, 'open_food_facts', '4060800200730'),
  ('964f50eb-8365-5e4b-a09d-ae622f710078', 59, 13.9, 13.7, 0, 0, 0.1, 0.2, null, null, 'open_food_facts', '4060800200341'),
  ('b8f208f2-55b5-5b86-be5b-9bb5cfeb8e7c', 54, 13, 12.9, 0, 0, 0.2, 0.01, null, null, 'open_food_facts', '4060800179678'),
  ('0caff37e-1d2a-5b60-8232-3d7e416de1c0', 5, 1.3, 0.9, 0, 0, 0, 0.06, null, null, 'open_food_facts', '4060800200259'),
  ('7c74b27b-3fbd-5cc5-9046-fa816c1e93e7', 40, 9.8, 9.8, 0.5, 0.1, 0.5, 0.01, 32, null, 'open_food_facts', '4060800160805'),
  ('47ef70c8-ff5b-5ff6-a7f6-faf53039d6b3', 41, 9.8, 9.8, 0.5, 0.1, 0.5, 0.01, null, null, 'open_food_facts', '4060800160300'),
  ('25bbbcc2-bd4d-5a2f-aca3-e9861dc57b63', 57, 13.8, 13.8, 0, 0, 0.1, 0.01, 31, null, 'open_food_facts', '4060800160683'),
  ('6ed38422-9def-5fb8-a40c-cf4b6451ed04', 2, 0.8, 0, 0, 0, 0.2, 0.1, null, null, 'open_food_facts', '4060800200532'),
  ('ca4611e9-c57a-5747-baae-feb3bca94e38', 3, 0.7, 0, 0, 0, 0.2, 0.1, null, null, 'open_food_facts', '4060800200563'),
  ('27862b69-e310-5417-91d5-d4f8f44edfa9', 59, 14, 13.9, 0, 0, 0.2, 0.1, 31, null, 'open_food_facts', '4060800200631'),
  ('2f6af537-1c30-5466-813d-e81873180cea', 50, 11.7, 11.7, 0, 0, 0.2, 0.2, null, null, 'open_food_facts', '4060800160003'),
  ('028f9b75-0e57-5a2f-848b-0a0aa748678e', 56, 13.5, 13.4, 0, 0, 0.2, 0, null, null, 'open_food_facts', '4060800178053'),
  ('c48adcc8-d83d-59d6-83c6-3fbfc92faff2', 5, 1.3, 0.6, 0, 0, 0, 0.06, null, null, 'open_food_facts', '4060800200228'),
  ('799e4a55-9984-5d47-a250-f41507f0ccd5', 3, 0.7, 0, 0, 0, 0.2, 0.1, 32, null, 'open_food_facts', '4060800200501'),
  ('93f20aa2-f5a6-535e-938a-ecb56de993a6', 52, 12.5, 12.5, 0, 0, 0.02, 0.16, null, null, 'open_food_facts', '4062139004072'),
  ('d6ad9a65-b2ee-54a2-952e-d98e51fae43e', 34, 7.8, 7.8, 0, 0, 0.2, 0.1, null, null, 'open_food_facts', '4060800179111'),
  ('85cb9a04-75e3-5d05-a4a7-3651bb42168c', 60, 14, 14, 0, 0, 0.2, 0, 32, null, 'open_food_facts', '4060800178701'),
  ('4a3650d4-b275-57c0-838f-ba9704366cbf', 33, 8, 7.7, 0, 0, 0.2, 0.04, null, null, 'open_food_facts', '4060800200136'),
  ('82571b0b-24c3-5efe-83f8-5f1031bbce5c', 44, 10, 10, 0.5, 0.1, 0.5, 0.15, 32, null, 'open_food_facts', '4306188351139'),
  ('70bf6429-7fa1-5071-b8b8-06880fd52239', 43, 9.8, 9.8, 0, 0, 0, 0.27, null, null, 'open_food_facts', '9040400000911'),
  ('24d566a3-0c3f-538c-88dc-253fb49d1f2a', 0, 0, 0, 0, 0, 0, 0, null, null, 'open_food_facts', '4013595055245'),
  ('8d7c1733-f3f3-5ef3-9902-dd8181c5e1f0', 44, 11, 11, 0, 0, 0, 0, 32, null, 'open_food_facts', '4013595055214')
on conflict (product_id) do update set
  kcal = excluded.kcal,
  carbs_g = excluded.carbs_g,
  sugar_g = excluded.sugar_g,
  fat_g = excluded.fat_g,
  sat_fat_g = excluded.sat_fat_g,
  protein_g = excluded.protein_g,
  salt_g = excluded.salt_g,
  caffeine_mg = excluded.caffeine_mg,
  taurine_mg = excluded.taurine_mg,
  source = excluded.source,
  source_ref = excluded.source_ref;

commit;

-- Kontrolle
select
  (select count(*) from public.products) as products,
  (select count(*) from public.product_nutrition) as product_nutrition,
  (select count(*) from public.product_nutrition where source = 'open_food_facts') as aus_open_food_facts;
