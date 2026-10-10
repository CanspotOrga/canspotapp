// Schickt nach jeder Übernahme der OpenStreetMap-Filialen (alle 4 Monate,
// sql-osm-monatlich.sql) eine Info von noreply@canspot.de an hallo@canspot.de:
// Ergebnis des letzten Laufs aus public.osm_import_runs, bei Abbruch durch die
// Sicherheitsschranke (neue Datei unter 90 %) oder Fehler mit Hinweis.
// Ausgelöst von osm_branches_import_latest() per pg_net.
//
// Ohne JWT erreichbar, deshalb abgesichert: Empfänger stehen fest, der Inhalt
// kommt nur aus der Datenbank (nicht aus der Anfrage), jeder Lauf wird höchstens
// einmal gemeldet (osm_import_runs.mailed_at). Das SMTP-Passwort kommt aus dem
// Secret SMTP_PASSWORD, den Server-Schlüssel stellt Supabase selbst bereit.

import { createClient } from "npm:@supabase/supabase-js@2";
import nodemailer from "npm:nodemailer@6.9.16";

const SMTP_HOST = "smtp.strato.de";
const SMTP_PORT = 465;
const SMTP_USER = "noreply@canspot.de";
const MAIL_FROM = "CanSpot <noreply@canspot.de>";
const MAIL_TO = "hallo@canspot.de";

function serverKey(): string {
  try {
    const key = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}").default;
    if (key) return key;
  } catch {
    // ältere Projekte: fällt auf den service_role-Schlüssel zurück
  }
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
}

const admin = createClient(Deno.env.get("SUPABASE_URL")!, serverKey(), {
  auth: { persistSession: false, autoRefreshToken: false },
});

function reply(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

const zeit = (s: string) =>
  new Date(s).toLocaleString("de-DE", { timeZone: "Europe/Berlin", dateStyle: "medium", timeStyle: "short" });

Deno.serve(async (req) => {
  if (req.method !== "POST") return reply(405, { ok: false, reason: "method" });

  const { data: runs, error } = await admin
    .from("osm_import_runs").select("id, started_at, finished_at, status, result, mailed_at")
    .not("finished_at", "is", null).is("mailed_at", null)
    .order("id", { ascending: false }).limit(1);
  if (error) return reply(500, { ok: false, reason: "runs" });
  const run = runs?.[0];
  if (!run) return reply(200, { ok: true, skipped: "nichts offen" });

  const titel = {
    ok: "Filialen aus OpenStreetMap aktualisiert",
    abgebrochen: "Filialen-Aktualisierung ABGEBROCHEN (Sicherheitsschranke)",
    fehler: "Filialen-Aktualisierung fehlgeschlagen",
  }[run.status as string] ?? "Filialen-Aktualisierung";

  const text = [
    `${titel}`,
    "",
    `Lauf vom ${zeit(run.started_at)}, beendet ${zeit(run.finished_at)}.`,
    "",
    run.result ?? "",
    "",
    run.status === "ok"
      ? "Es ist nichts zu tun. Nächster Lauf in 4 Monaten."
      : "Die Filialen in der Datenbank sind unverändert. Bitte prüfen: GitHub > Actions > „OSM-Filialen“ und in Supabase die Tabelle osm_import_runs.",
    "",
    "Erinnerung: Filialdaten © OpenStreetMap-Mitwirkende, Lizenz ODbL (Namensnennung in der App).",
  ].join("\n");

  const transport = nodemailer.createTransport({
    host: SMTP_HOST,
    port: SMTP_PORT,
    secure: true,
    auth: { user: SMTP_USER, pass: Deno.env.get("SMTP_PASSWORD") ?? "" },
  });
  try {
    await transport.sendMail({ from: MAIL_FROM, to: MAIL_TO, subject: `CanSpot: ${titel}`, text });
  } catch (e) {
    console.error("Versand fehlgeschlagen:", (e as Error).name);
    return reply(502, { ok: false, reason: "smtp" });
  }

  await admin.from("osm_import_runs").update({ mailed_at: new Date().toISOString() }).eq("id", run.id);
  return reply(200, { ok: true, status: run.status });
});
