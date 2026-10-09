// Schickt einmal pro Woche eine Übersicht der Löschgründe (nur Anzahlen,
// keine Freitexte) von noreply@canspot.de an feedback@canspot.de.
// Ausgelöst von pg_cron (supabase/sql/sql-wochenbericht-loeschgruende.sql).
//
// Ohne JWT erreichbar, deshalb abgesichert: Empfänger und Inhalt stehen fest,
// und es wird höchstens alle 6 Tage eine Mail verschickt (Tabelle report_runs).
// Ein fremder Aufruf kann also keine Mails an andere Adressen senden und das
// Postfach nicht fluten. Das SMTP-Passwort kommt aus dem Secret SMTP_PASSWORD,
// den Server-Schlüssel stellt Supabase selbst bereit; beides steht nicht im Code.

import { createClient } from "npm:@supabase/supabase-js@2";
import nodemailer from "npm:nodemailer@6.9.16";

const SMTP_HOST = "smtp.strato.de";
const SMTP_PORT = 465;
const SMTP_USER = "noreply@canspot.de";
const MAIL_FROM = "CanSpot <noreply@canspot.de>";
const MAIL_TO = "feedback@canspot.de";
const REPORT = "loeschgruende-woche";
const MIN_ABSTAND_MS = 6 * 24 * 60 * 60 * 1000;

const GRUENDE: Record<string, string> = {
  "unused": "Ich nutze CanSpot nicht mehr",
  "not-found": "Ich finde nicht, was ich suche",
  "missing-features": "Mir fehlen bestimmte Funktionen",
  "not-as-expected": "Die App funktioniert nicht so, wie ich es erwartet habe",
  "technical-issue": "Ich habe ein Problem mit der App",
  "offer-volume": "Zu viele / zu wenige Angebote",
  "privacy": "Datenschutz / Privatsphäre",
  "other": "Sonstiger Grund",
};

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

const datum = (d: Date) =>
  d.toLocaleDateString("de-DE", { timeZone: "Europe/Berlin", day: "2-digit", month: "2-digit", year: "numeric" });

Deno.serve(async (req) => {
  if (req.method !== "POST") return reply(405, { ok: false, reason: "method" });

  const { data: letzte, error: runErr } = await admin
    .from("report_runs").select("sent_at").eq("report", REPORT)
    .order("sent_at", { ascending: false }).limit(1);
  if (runErr) return reply(500, { ok: false, reason: "runs" });
  if (letzte?.length && Date.now() - new Date(letzte[0].sent_at).getTime() < MIN_ABSTAND_MS) {
    return reply(200, { ok: true, skipped: "zu frueh" });
  }

  const bis = new Date();
  const von = new Date(bis.getTime() - 7 * 24 * 60 * 60 * 1000);
  const { data: zeilen, error } = await admin
    .from("account_deletion_feedback").select("reason, note")
    .gte("deleted_at", von.toISOString()).lt("deleted_at", bis.toISOString());
  if (error) return reply(500, { ok: false, reason: "query" });

  const anzahl: Record<string, number> = {};
  let mitText = 0;
  for (const z of zeilen ?? []) {
    anzahl[z.reason] = (anzahl[z.reason] ?? 0) + 1;
    if (z.note) mitText++;
  }
  const gesamt = zeilen?.length ?? 0;
  const liste = Object.entries(GRUENDE)
    .filter(([key]) => anzahl[key])
    .map(([key, label]) => `- ${label}: ${anzahl[key]}`);

  const text = [
    `Löschgründe vom ${datum(von)} bis ${datum(bis)}`,
    "",
    gesamt === 0 ? "Keine Kontolöschungen mit Grund in diesem Zeitraum." : `Insgesamt: ${gesamt}`,
    ...liste,
    ...(mitText ? ["", `${mitText} davon mit eigenem Text (nur in Supabase einsehbar, Tabelle account_deletion_feedback).`] : []),
    "",
    "Löschungen ohne angegebenen Grund werden nicht gespeichert und fehlen hier.",
  ].join("\n");

  const transport = nodemailer.createTransport({
    host: SMTP_HOST,
    port: SMTP_PORT,
    secure: true,
    auth: { user: SMTP_USER, pass: Deno.env.get("SMTP_PASSWORD") ?? "" },
  });
  try {
    await transport.sendMail({
      from: MAIL_FROM,
      to: MAIL_TO,
      subject: `CanSpot Wochenbericht Löschgründe: ${gesamt}`,
      text,
    });
  } catch (e) {
    console.error("Versand fehlgeschlagen:", (e as Error).name);
    return reply(502, { ok: false, reason: "smtp" });
  }

  await admin.from("report_runs").insert({ report: REPORT });
  return reply(200, { ok: true, gesamt });
});
