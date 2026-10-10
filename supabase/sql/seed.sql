-- ============================================================================
-- CanSpot — Inhalte (Stand der Live-Datenbank am 10.10.2026)
-- ============================================================================
-- Additiv und mehrfach ausführbar: legt fehlende Zeilen an und setzt
-- vorhandene (gleiche id) auf die Werte unten. Löscht nichts.
-- Voraussetzung: schema.sql wurde ausgeführt.
--
-- Inhalt: 36 Marken (Red Bull 4 Produkte, Monster Energy 3, die übrigen noch
-- ohne Produkte), 4 Filialen in Arnsberg, 7 Angebote, 6 Normalpreise
-- (regular_prices), dazu app_settings (Startstandort Arnsberg, Demo-Hinweis,
-- Version).
-- Je ein Beispiel für Neuheiten (is_new = true, laufendes Angebot) und
-- Coming Soon (Angebot mit Startdatum in der Zukunft).
-- Preise, Zeiträume und Filialangaben sind DEMODATEN, keine erhobenen Preise.
-- Produktbilder: ein gemeinsames Beispielbild von canspot.de, Logos leer
-- (Datenquellen-Regel 5).
-- Neue Daten nur aus erlaubten Quellen.
-- ============================================================================

begin;

-- retailers (4)
insert into public.retailers (id, name, logo_url) values
  ('bc883dfe-8c5b-5c5d-8db2-94fcec111527', 'Kaufland', null),
  ('7f36d52e-be9b-4065-b08b-02cf4e97ed63', 'EDEKA', null),
  ('4a0685d2-e243-4b2e-b9b7-100a501e2917', 'REWE', null),
  ('ec88c807-734f-483d-90ab-f64b70eb6824', 'Netto', null)
on conflict (id) do update set
  name = excluded.name,
  logo_url = excluded.logo_url;

-- brands (36)
insert into public.brands (id, name) values
  ('11111111-1111-4111-8111-111111111111', 'Red Bull'),
  ('040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy'),
  ('caad03ca-26e6-425c-b75c-710c48fa6137', 'Gönrgy'),
  ('0fcad57d-2f69-4d91-80d9-c357e77a6e8d', '28 Black'),
  ('0eced198-c182-4289-af43-9c1057145863', '4BRO'),
  ('0969fae8-ff2f-49da-955a-ed6a5e69d302', 'Action'),
  ('5d447373-f9d5-437e-9fd3-d06b172fe983', 'Bang'),
  ('56c718b9-91c9-4b80-9470-2d7852239ef4', 'Black Cat'),
  ('cce355b6-7b30-41c1-b069-a083fbcec156', 'Booster Energy'),
  ('7bafac91-a3af-4f3f-8183-c2263cb1098b', 'Burn'),
  ('b45620da-ec3c-4cf4-9599-c1d66370b5b0', 'C4 Energy'),
  ('5e93a076-873d-403e-9d45-051534581438', 'Celsius'),
  ('559d9c0f-7fdc-4d1c-97de-04fb7fc5d1dd', 'Crazy Wolf'),
  ('ac5958e0-e609-43fb-acec-b5e0ffa369d1', 'Effect'),
  ('fe3e9d14-775c-4c9c-a3b3-8829e315b984', 'Flying Power'),
  ('8109f1a0-4d85-445e-976f-43e1a21acf6f', 'Ghost Energy'),
  ('114f6c23-2dc3-4097-b41d-3d6efb291d5c', 'Golden Power'),
  ('d8c53faf-e1ea-49b8-8335-1c925a240869', 'Grenade'),
  ('05f8980a-93c8-470b-96fb-1d5780d01188', 'Hell Energy'),
  ('4f4e9bfe-3d32-48a1-8f68-ce70e5db32b8', 'Jeden Tag'),
  ('0e460d51-06d3-49ca-97cb-d84fb62243f7', 'Kong Strong'),
  ('bc42ad20-3a3e-4185-ab7b-2c34d7cc73ed', 'LevlUp'),
  ('21c98197-31e5-4b9f-99c6-2da39417250f', 'Mask'),
  ('4f82560a-6013-4bfd-9576-56182b49c7ba', 'Maximal G'),
  ('524ca3ed-7d57-4408-afaf-53bebe596e21', 'NOCCO'),
  ('c259e126-49e8-49aa-bc81-ae8d1659ca73', 'Power Horse'),
  ('1a49c086-90fe-41b4-a7ea-293aa8ad958e', 'Prime Energy'),
  ('43c8d319-2f51-42ec-948f-d05d2005679b', 'Reign'),
  ('3393c884-c275-4ed8-aeb1-a140c06c545a', 'Rhino''s'),
  ('d54ed85c-67d6-49ec-aa4e-5626c2bc40a2', 'Rockstar Energy'),
  ('6463b663-c76f-4559-b1e8-fe7c62a46242', 'Scenatic'),
  ('6abbe965-823c-46d7-8770-9a6eb2dbc6bc', 'Take Off'),
  ('88eb3403-fb07-4c20-850b-0de820194a22', 'Tantrum'),
  ('11d18120-b681-4655-907c-b57e2124e993', 'Typhoon'),
  ('12a11591-cb73-4983-96b7-c71f8b02ee7c', 'Vita Energy'),
  ('111b399a-ff6f-4b7e-8755-c7e491a4a2bf', 'WellMix')
on conflict (id) do update set
  name = excluded.name;

-- brand_nutrition_defaults (2)
insert into public.brand_nutrition_defaults (brand_id, kcal, carbs_g, sugar_g, fat_g, sat_fat_g, protein_g, salt_g, caffeine_mg, taurine_mg) values
  ('11111111-1111-4111-8111-111111111111', 45, 11.3, 11, 0, 0, 0, 0.1, 31, 390),
  ('040702a6-617f-49b7-ab82-bc82bb860a9c', 47.0, 12.0, 11.0, 0.0, 0.0, 0.0, 0.2, 30.0, 430.0)
on conflict (brand_id) do update set
  kcal = excluded.kcal,
  carbs_g = excluded.carbs_g,
  sugar_g = excluded.sugar_g,
  fat_g = excluded.fat_g,
  sat_fat_g = excluded.sat_fat_g,
  protein_g = excluded.protein_g,
  salt_g = excluded.salt_g,
  caffeine_mg = excluded.caffeine_mg,
  taurine_mg = excluded.taurine_mg;

-- branches (4)
insert into public.branches (id, retailer_id, street, postal_code, city, latitude, longitude, opens_at, closes_at, closed_sunday) values
  ('19585656-b415-510e-8739-401bb2dd6a09', 'bc883dfe-8c5b-5c5d-8db2-94fcec111527', 'Ruhrstraße 22', '59821', 'Arnsberg', '51.401300', '8.065800', '07:00', '22:00', true),
  ('50ff519a-4266-46a1-9f92-90d6fa370c87', '7f36d52e-be9b-4065-b08b-02cf4e97ed63', 'Bahnhofstraße 10', '59821', 'Arnsberg', '51.402200', '8.071400', '07:30', '20:00', true),
  ('2b4e352e-9b52-4fab-b1d8-ea79c5a7ea48', '4a0685d2-e243-4b2e-b9b7-100a501e2917', 'Clemens-August-Straße 8', '59821', 'Arnsberg', '51.400100', '8.065500', '07:00', '21:00', true),
  ('512e4c21-5183-4576-9673-b8d9ba9bf409', 'ec88c807-734f-483d-90ab-f64b70eb6824', 'Alter Marktplatz 3', '59821', 'Arnsberg', '51.398200', '8.069900', '08:00', '20:00', true)
on conflict (id) do update set
  retailer_id = excluded.retailer_id,
  street = excluded.street,
  postal_code = excluded.postal_code,
  city = excluded.city,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  opens_at = excluded.opens_at,
  closes_at = excluded.closes_at,
  closed_sunday = excluded.closed_sunday;

-- products (7)
insert into public.products (id, brand_id, name, size_ml, packaging, image_url, is_new) values
  ('73ab667f-75d7-4b02-a42e-47bae05ae065', '11111111-1111-4111-8111-111111111111', 'Red Bull Energy Drink', 250, 'Dose', 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', false),
  ('dbcfcbdf-05e9-4bd5-ba24-5362d09612d9', '11111111-1111-4111-8111-111111111111', 'Red Bull Sugarfree', 250, 'Dose', 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', false),
  ('1e86d7b4-fecc-4e2a-a930-a7e92f0067da', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Ultra', 500, 'Dose', 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', false),
  ('7dfb0a5d-354b-4845-af7e-8c2e9120020b', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Classic', 500, 'Dose', 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', false),
  ('67e34e31-a36f-48c3-bd29-fedfb4288732', '040702a6-617f-49b7-ab82-bc82bb860a9c', 'Monster Energy Juiced Bad Apple', 500, 'Dose', 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', true),
  ('d6a55d57-3b1b-4a2b-aff1-edeb0eb48399', '11111111-1111-4111-8111-111111111111', 'Red Bull Red Edition', 250, 'Dose', 'https://canspot.de/wp-content/Produktbilder/monster-juiced-bad-apple-450x600.webp', false),
  ('82319af1-c3ef-4e85-8835-b64a76e76410', '11111111-1111-4111-8111-111111111111', 'Red Bull Energy Drink White Peach Sugarfree', 250, 'Dose', 'https://canspot.de/wp-content/Produktbilder/Red-Bull-White-Peach-Edition-450x600.webp', false)
on conflict (id) do update set
  brand_id = excluded.brand_id,
  name = excluded.name,
  size_ml = excluded.size_ml,
  packaging = excluded.packaging,
  image_url = excluded.image_url,
  is_new = excluded.is_new;

-- product_nutrition (2)
insert into public.product_nutrition (product_id, kcal, carbs_g, sugar_g, fat_g, sat_fat_g, protein_g, salt_g, caffeine_mg, taurine_mg) values
  ('dbcfcbdf-05e9-4bd5-ba24-5362d09612d9', 3.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1, 31.0, 390.0),
  ('1e86d7b4-fecc-4e2a-a930-a7e92f0067da', 2.0, 0.9, 0.0, 0.0, 0.0, 0.0, 0.2, 30.0, 430.0)
on conflict (product_id) do update set
  kcal = excluded.kcal,
  carbs_g = excluded.carbs_g,
  sugar_g = excluded.sugar_g,
  fat_g = excluded.fat_g,
  sat_fat_g = excluded.sat_fat_g,
  protein_g = excluded.protein_g,
  salt_g = excluded.salt_g,
  caffeine_mg = excluded.caffeine_mg,
  taurine_mg = excluded.taurine_mg;

-- offers (7)
insert into public.offers (id, product_id, branch_id, units, regular_price, offer_price, deposit, valid_from, valid_until, link, bundle_image_url, last_checked_at) values
  ('c6ffb947-a172-42e5-b8b4-e5300b0f2881', '73ab667f-75d7-4b02-a42e-47bae05ae065', '19585656-b415-510e-8739-401bb2dd6a09', 1, '1.49', '0.99', '0.25', '2026-09-28', '2026-10-04', '#', null, '2026-10-03'),
  ('17a57e0d-509a-4da6-81f7-c254a5f13f87', 'dbcfcbdf-05e9-4bd5-ba24-5362d09612d9', '2b4e352e-9b52-4fab-b1d8-ea79c5a7ea48', 1, '1.35', '0.95', '0.25', '2026-10-02', '2026-10-15', '#', null, '2026-10-03'),
  ('651ab0a1-9972-4001-adee-75554c71da72', '1e86d7b4-fecc-4e2a-a930-a7e92f0067da', '50ff519a-4266-46a1-9f92-90d6fa370c87', 1, '1.99', '1.39', '0.25', '2026-09-30', '2026-10-13', '#', null, '2026-10-03'),
  ('212d7448-4b90-492e-aad5-b90efd8775e5', '7dfb0a5d-354b-4845-af7e-8c2e9120020b', '512e4c21-5183-4576-9673-b8d9ba9bf409', 1, '1.79', '1.29', '0.25', '2026-10-03', '2026-10-16', '#', null, '2026-10-03'),
  ('fd2ca12a-f416-434a-9f5c-09bc11f1c652', '67e34e31-a36f-48c3-bd29-fedfb4288732', '19585656-b415-510e-8739-401bb2dd6a09', 1, '1.99', '1.49', '0.25', '2026-10-04', '2026-10-17', '#', null, '2026-10-04'),
  ('95dc220e-ee8e-4f0a-b9e2-65fd4f01eb72', 'd6a55d57-3b1b-4a2b-aff1-edeb0eb48399', '50ff519a-4266-46a1-9f92-90d6fa370c87', 1, null, null, '0.25', '2026-10-12', '2026-10-17', '#', null, '2026-10-04'),
  ('e3dca914-7df8-489b-9cbf-3cc71574fe6c', '82319af1-c3ef-4e85-8835-b64a76e76410', '2b4e352e-9b52-4fab-b1d8-ea79c5a7ea48', 1, '1.99', '1.49', '0.25', '2026-10-04', '2026-10-17', '#', null, '2026-10-04')
on conflict (id) do update set
  product_id = excluded.product_id,
  branch_id = excluded.branch_id,
  units = excluded.units,
  regular_price = excluded.regular_price,
  offer_price = excluded.offer_price,
  deposit = excluded.deposit,
  valid_from = excluded.valid_from,
  valid_until = excluded.valid_until,
  link = excluded.link,
  bundle_image_url = excluded.bundle_image_url,
  last_checked_at = excluded.last_checked_at;

-- regular_prices (6) — Normalpreise ohne Aktion, übernommen aus offers.regular_price
insert into public.regular_prices (id, product_id, branch_id, units, price, deposit, last_checked_at) values
  ('24e25299-1361-4175-ae2b-8aaf17eb7b57', '7dfb0a5d-354b-4845-af7e-8c2e9120020b', '512e4c21-5183-4576-9673-b8d9ba9bf409', 1, '1.79', '0.25', '2026-10-03'),
  ('522b94d7-7017-4135-b75e-85ddfcc2f7ba', '67e34e31-a36f-48c3-bd29-fedfb4288732', '19585656-b415-510e-8739-401bb2dd6a09', 1, '1.99', '0.25', '2026-10-04'),
  ('dd6fff99-5563-4673-a083-c36e814e1215', '1e86d7b4-fecc-4e2a-a930-a7e92f0067da', '50ff519a-4266-46a1-9f92-90d6fa370c87', 1, '1.99', '0.25', '2026-10-03'),
  ('0a2103d7-c8df-4694-b1ba-ee5dc8eee3ca', '73ab667f-75d7-4b02-a42e-47bae05ae065', '19585656-b415-510e-8739-401bb2dd6a09', 1, '1.49', '0.25', '2026-10-03'),
  ('7141976d-d5fc-4ad9-904d-fb86bb23f68c', '82319af1-c3ef-4e85-8835-b64a76e76410', '2b4e352e-9b52-4fab-b1d8-ea79c5a7ea48', 1, '1.99', '0.25', '2026-10-04'),
  ('e1eadffb-7559-4ce5-a523-6ede34ed1900', 'dbcfcbdf-05e9-4bd5-ba24-5362d09612d9', '2b4e352e-9b52-4fab-b1d8-ea79c5a7ea48', 1, '1.35', '0.25', '2026-10-03')
on conflict (id) do update set
  product_id = excluded.product_id,
  branch_id = excluded.branch_id,
  units = excluded.units,
  price = excluded.price,
  deposit = excluded.deposit,
  last_checked_at = excluded.last_checked_at;

-- app_settings (1) — genau eine Zeile, id = 1
insert into public.app_settings (id, default_location_label, default_latitude, default_longitude, default_radius_km, demo_notice, app_version, ios_rating_url, android_rating_url) values
  (1, '59821 Arnsberg', 51.4013, 8.0658, 10,
   'Demo: Alle Preise und Angebote sind Beispieldaten und keine echten Angebote der genannten Händler.',
   'CanSpot Prototyp · Version 1.0.0', null, null)
on conflict (id) do update set
  default_location_label = excluded.default_location_label,
  default_latitude = excluded.default_latitude,
  default_longitude = excluded.default_longitude,
  default_radius_km = excluded.default_radius_km,
  demo_notice = excluded.demo_notice,
  app_version = excluded.app_version,
  ios_rating_url = excluded.ios_rating_url,
  android_rating_url = excluded.android_rating_url;

commit;

-- Kontrolle: erwartete Zeilenzahlen
select
  (select count(*) from public.retailers) as retailers,
  (select count(*) from public.branches) as branches,
  (select count(*) from public.brands) as brands,
  (select count(*) from public.brand_nutrition_defaults) as brand_nutrition_defaults,
  (select count(*) from public.products) as products,
  (select count(*) from public.product_nutrition) as product_nutrition,
  (select count(*) from public.offers) as offers,
  (select count(*) from public.price_history) as price_history,
  (select count(*) from public.regular_prices) as regular_prices,
  (select count(*) from public.app_settings) as app_settings;
