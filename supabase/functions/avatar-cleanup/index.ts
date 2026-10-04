// Löscht das Profilbild eines gelöschten Kontos aus Storage (Bucket avatars).
// Aufgerufen vom Datenbank-Trigger trg_users_avatar_cleanup nach dem Löschen
// eines Kontos, egal ob in der App oder im Dashboard. Erwartet nur
// {"user_id": "<uuid>"}.
//
// Ohne JWT erreichbar, deshalb abgesichert: Es wird nur aufgeräumt, wenn das
// Konto nicht mehr existiert, und nur die eine Datei <user_id>/avatar.jpg.
// Den Server-Schlüssel stellt Supabase der Funktion selbst bereit
// (SUPABASE_SECRET_KEYS); er steht nicht im Code.

import { createClient } from "npm:@supabase/supabase-js@2";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

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

Deno.serve(async (req) => {
  if (req.method !== "POST") return reply(405, { ok: false, reason: "method" });

  let userId = "";
  try {
    const body = await req.json();
    userId = String(body?.user_id ?? "");
  } catch {
    // ungültiger Inhalt, siehe Prüfung unten
  }
  if (!UUID_RE.test(userId)) return reply(400, { ok: false, reason: "invalid" });

  // Existiert das Konto noch, wird nichts gelöscht.
  const { data, error } = await admin.auth.admin.getUserById(userId);
  if (data?.user) return reply(409, { ok: false, reason: "user exists" });
  if (error && error.status !== 404) return reply(502, { ok: false, reason: "lookup failed" });

  const { error: removeError } = await admin.storage.from("avatars").remove([`${userId}/avatar.jpg`]);
  if (removeError) return reply(502, { ok: false, reason: "remove failed" });

  return reply(200, { ok: true });
});
