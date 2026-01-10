import 'package:supabase_flutter/supabase_flutter.dart';

class ReportApiService {
  final SupabaseClient _supabase;

  ReportApiService(this._supabase);

  Future<void> createReport(String emergencyId, String report) async {
    await _supabase.from('emergencies').update({'report_by_ai': report}).eq('id', emergencyId);
  }


  Future<String> getReport(String emergencyId) async {
    final response = await _supabase.from('emergencies').select('report_by_ai').eq('id', emergencyId).single();
    return response['report_by_ai'];
  }
}