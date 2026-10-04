-- Angebote, die erst in der Zukunft starten (Coming Soon), haben noch
-- keinen bekannten Preis. regular_price und offer_price duerfen deshalb
-- leer (NULL) sein. Die App zeigt solche Angebote nur unter Coming Soon
-- ("Preis folgt"), nicht auf der Startseite. Ein bereits gestartetes
-- Angebot ohne beide Preise blendet die App aus.
-- Leert ausserdem die Beispielpreise des Coming-Soon-Angebots
-- "Red Bull Red Edition" (ab 12.10.2026).
-- Darf mehrfach ausgefuehrt werden.

alter table public.offers alter column regular_price drop not null;
alter table public.offers alter column offer_price drop not null;

comment on column public.offers.offer_price is 'Angebotspreis. NULL = noch nicht bekannt (Coming Soon, Angebot startet erst in der Zukunft).';
comment on column public.offers.regular_price is 'Normalpreis. NULL = noch nicht bekannt (Coming Soon).';

update public.offers
set regular_price = null, offer_price = null
where id = '95dc220e-ee8e-4f0a-b9e2-65fd4f01eb72';
