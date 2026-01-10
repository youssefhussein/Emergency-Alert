import 'package:firebase_ai/firebase_ai.dart';

class AiReportService {
  final GenerativeModel _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash-lite',
    systemInstruction: Content.text(
      "You are an emergency incident report writer. "
      "Use ONLY the provided information. "
      "Do NOT invent facts. If something is missing, write 'Unknown'. "
      "Output plain text with headings:\n"
      "1) Summary\n2) User Info\n3) Location\n4) Details\n5) Attachments\n6) Missing Info\n",
    ),
    generationConfig: GenerationConfig(maxOutputTokens: 600),
  );

  Future<String> generateReport({
    required Map<String, dynamic> emergencyRow,
    required Map<String, dynamic> profileRow,
  }) async {
    final prompt =
        """
User Profile:
- Name: ${profileRow['full_name'] ?? 'Unknown'}
- Phone: ${profileRow['phone'] ?? 'Unknown'}
- Blood type: ${profileRow['blood_type'] ?? 'Unknown'}
- Allergies: ${profileRow['allergies'] ?? 'Unknown'}
- Chronic conditions: ${profileRow['chronic_conditions'] ?? 'Unknown'}
- Medications: ${profileRow['medications'] ?? 'Unknown'}

Emergency Request:
- Type: ${emergencyRow['type'] ?? 'Unknown'}
- Notes: ${emergencyRow['notes'] ?? 'Unknown'}
- Share location: ${emergencyRow['share_location'] ?? 'Unknown'}
- Lat: ${emergencyRow['location_lat'] ?? 'Unknown'}
- Lng: ${emergencyRow['location_lng'] ?? 'Unknown'}
- Location details: ${emergencyRow['location_details'] ?? 'Unknown'}
- Photo path: ${emergencyRow['photo_url'] ?? 'None'}
- Voice path: ${emergencyRow['voice_note_url'] ?? 'None'}
- Voice duration: ${emergencyRow['voice_note_duration_sec'] ?? 'Unknown'}
""";

    final res = await _model.generateContent([Content.text(prompt)]);
    final text = (res.text ?? '').trim();

    if (text.isEmpty) {
      throw Exception("Gemini returned empty report");
    }
    return text;
  }
}
