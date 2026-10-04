-- Bewertungen bleiben beim Löschen eines Kontos erhalten, aber ohne Bezug
-- zur Person: user_id wird auf NULL gesetzt statt die Zeile zu löschen.
-- Favoriten und Preisalarme werden weiterhin mit dem Konto gelöscht
-- (ON DELETE CASCADE, unverändert).
-- Darf mehrfach ausgeführt werden.

alter table public.ratings alter column user_id drop not null;

alter table public.ratings drop constraint if exists ratings_user_id_fkey;
alter table public.ratings
  add constraint ratings_user_id_fkey
  foreign key (user_id) references auth.users(id) on delete set null;

comment on table public.ratings is 'Max. eine Bewertung pro Nutzer+Produkt. Rohdaten sind privat (siehe RLS), oeffentlich sichtbar ist nur das Aggregat ueber get_all_product_rating_summaries(). Beim Loeschen eines Kontos bleibt die Bewertung ohne Personenbezug erhalten (user_id = NULL).';
