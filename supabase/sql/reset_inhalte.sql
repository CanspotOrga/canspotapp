-- ============================================================================
-- CanSpot — Inhalte leeren (zum Austauschen des Datenstands)
-- ============================================================================
-- Löscht alle Inhaltstabellen: offers, price_history, product_nutrition,
-- brand_nutrition_defaults, products, brands, branches, retailers.
-- Schema, Funktionen, Policies und Nutzerkonten bleiben unverändert.
--
-- Sicherheitsstopp: Bricht ohne Änderung ab, sobald Nutzerdaten existieren
-- (favorites, ratings, price_alerts, price_feedback_reports). Diese hängen per
-- ON DELETE CASCADE an Produkten/Filialen und würden sonst mitgelöscht.
-- Ausnahme: "Zuletzt angesehen" (recently_viewed) verweist ebenfalls per
-- CASCADE auf products und wird ohne Sicherheitsstopp mitgeleert, weil die
-- Einträge nach einem neuen Datenstand ohnehin ins Leere zeigen würden.
--
-- Danach seed.sql (oder einen eigenen Datenstand) ausführen.
-- ============================================================================

begin;

do $$
begin
  if exists (select 1 from public.favorites)
     or exists (select 1 from public.ratings)
     or exists (select 1 from public.price_alerts)
     or exists (select 1 from public.price_feedback_reports) then
    raise exception 'Abbruch: Es gibt Nutzerdaten (Favoriten, Bewertungen, Preisalarme oder Preismeldungen). Nichts wurde gelöscht.';
  end if;
end $$;

delete from public.offers;
delete from public.price_history;
delete from public.product_nutrition;
delete from public.brand_nutrition_defaults;
delete from public.products;
delete from public.brands;
delete from public.branches;
delete from public.retailers;

commit;
