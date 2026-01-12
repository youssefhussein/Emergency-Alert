// // Follow this setup guide to integrate the Deno language server with your editor:
// // https://deno.land/manual/getting_started/setup_your_environment
// // This enables autocomplete, go to definition, etc.

// // Setup type definitions for built-in Supabase Runtime APIs
// import "jsr:@supabase/functions-js/edge-runtime.d.ts"

// console.log("Hello from Functions!")

// Deno.serve(async (req) => {
//   const { name } = await req.json()
//   const data = {
//     message: `Hello ${name}!`,
//   }

//   return new Response(
//     JSON.stringify(data),
//     { headers: { "Content-Type": "application/json" } },
//   )
// })

// /* To invoke locally:

//   1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
//   2. Make an HTTP request:

//   curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/generate-emergency-report' \
//     --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
//     --header 'Content-Type: application/json' \
//     --data '{"name":"Functions"}'

// */
// Supabase Edge Function: generate-emergency-report
// Reads emergency by id, checks user ownership, calls Gemini, saves into emergencies.report_by_ai

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
function getUserIdFromJwt(authHeader: string): string | null {
  try {
    const token = authHeader.replace("Bearer ", "").trim();
    const parts = token.split(".");
    if (parts.length < 2) return null;
    const payload = JSON.parse(atob(parts[1].replace(/-/g, "+").replace(/_/g, "/")));
    return payload?.sub ?? null; // sub = user id (uuid)
  } catch {
    return null;
  }
}

Deno.serve(async (req) => {
  try {
    // A) Must have logged-in user token
    const authHeader = req.headers.get("Authorization") ?? "";
    if (!authHeader.startsWith("Bearer ")) {
      return json({ error: "Missing Authorization Bearer token" }, 401);
    }

    // B) Read input
    const body = await req.json().catch(() => ({}));
    const emergencyId = body?.emergencyId;

    if (typeof emergencyId !== "number") {
      return json({ error: "emergencyId must be a number" }, 400);
    }

const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const geminiKey = Deno.env.get("GEMINI_API_KEY") ?? "";

if (!serviceKey) return json({ error: "Missing secret: SUPABASE_SERVICE_ROLE_KEY" }, 500);
if (!geminiKey) return json({ error: "Missing secret: GEMINI_API_KEY" }, 500);

const callerUuid = getUserIdFromJwt(authHeader);
if (!callerUuid) return json({ error: "Unauthorized: cannot read user from JWT" }, 401);

// Use built-in env provided by Supabase runtime (allowed)
const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
if (!supabaseUrl) return json({ error: "Missing env: SUPABASE_URL" }, 500);

// Admin DB access (service role)
const sbAdmin = createClient(supabaseUrl, serviceKey);

    // // E) Admin DB access (service role)
    // const sbAdmin = createClient(supabaseUrl, serviceKey);

    // F) Fetch emergency record
    const { data: emergency, error: eErr } = await sbAdmin
      .from("emergencies")
      .select(`
        id, user_id, type, status, phone, notes,
        location_lat, location_lng, location_details,
        photo_url, voice_note_url, voice_note_duration_sec,
        share_location, notify_contacts,
        report_by_ai, created_at
      `)
      .eq("id", emergencyId)
      .single();

    if (eErr || !emergency) return json({ error: "Emergency not found" }, 404);

    // G) Ownership check (uuid link)
    if (emergency.user_id !== callerUuid) {
      return json({ error: "Forbidden: not your emergency" }, 403);
    }

    // H) If report already exists, return it
    if (emergency.report_by_ai && emergency.report_by_ai.trim().length > 0) {
      return json({ reportText: emergency.report_by_ai, cached: true }, 200);
    }

    // I) Fetch user profile
    const { data: profile } = await sbAdmin
      .from("profiles")
      .select(`
        full_name, phone, email,
        blood_type, allergies, chronic_conditions, medications, disabilities,
        preferred_hospital, other_notes, age, gender
      `)
      .eq("id", callerUuid)
      .maybeSingle();

    // J) Build prompt for Gemini
    const prompt = `
You are an emergency incident report generator. Turn the database record into a clear professional report.

EMERGENCY:
- ID: ${emergency.id}
- Type: ${emergency.type}
- Status: ${emergency.status}
- Phone: ${emergency.phone ?? "N/A"}
- Notes: ${emergency.notes ?? "N/A"}
- Location: lat=${emergency.location_lat ?? "N/A"}, lng=${emergency.location_lng ?? "N/A"}
- Location details: ${emergency.location_details ?? "N/A"}
- Photo URL: ${emergency.photo_url ?? "None"}
- Voice URL: ${emergency.voice_note_url ?? "None"}
- Voice duration sec: ${emergency.voice_note_duration_sec ?? "N/A"}
- share_location: ${emergency.share_location}
- notify_contacts: ${emergency.notify_contacts}
- created_at: ${emergency.created_at}

USER PROFILE:
- Name: ${profile?.full_name ?? "Unknown"}
- Phone: ${profile?.phone ?? "Unknown"}
- Email: ${profile?.email ?? "Unknown"}
- Age: ${profile?.age ?? "Unknown"}
- Gender: ${profile?.gender ?? "Unknown"}
- Blood type: ${profile?.blood_type ?? "Unknown"}
- Allergies: ${profile?.allergies ?? "None"}
- Chronic conditions: ${profile?.chronic_conditions ?? "None"}
- Medications: ${profile?.medications ?? "None"}
- Disabilities: ${profile?.disabilities ?? "None"}
- Preferred hospital: ${profile?.preferred_hospital ?? "None"}
- Other notes: ${profile?.other_notes ?? "None"}

OUTPUT FORMAT:
1) Incident Summary
2) Key Facts (bullets)
3) Medical Risk Flags (bullets)
4) Location & Access Notes (bullets)
5) Recommended Immediate Actions (bullets)
6) Questions / Missing Information (bullets)
7) Dispatch Priority: Low/Medium/High + reason

No speculation. Mention missing fields as missing.
`;


    // K) Call Gemini
const geminiRes = await fetch(
  `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${geminiKey}`,
  {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
    }),
  },
);
if (!geminiRes.ok) {
  const errText = await geminiRes.text();
  throw new Error(`Gemini API error (${geminiRes.status}): ${errText}`);
}
const geminiJson = await geminiRes.json();

    const reportText =
      geminiJson?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";

    if (!reportText) return json({ error: "Empty report from Gemini" }, 502);

    // L) Save report in emergencies.report_by_ai
    const { error: upErr } = await sbAdmin
      .from("emergencies")
      .update({ report_by_ai: reportText })
      .eq("id", emergencyId);

    if (upErr) return json({ error: "Failed to save report" }, 500);

    return json({ reportText, cached: false }, 200);
  } catch (err) {
    console.log("Unhandled error:", err);

    return json({ error: "Server error", details: String(err) }, 500);
    
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
