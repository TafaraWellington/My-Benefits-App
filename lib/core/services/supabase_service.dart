import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

class SupabaseService {
  // Replace with your actual Supabase URL and Anon Key
  static const String _url = 'https://riztkhcqroedxmgloakl.supabase.co';
  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpenRraGNxcm9lZHhtZ2xvYWtsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEwODk0MDUsImV4cCI6MjA5NjY2NTQwNX0.SPGWYOqFyZrToYHO_xXzFRTd75iPMnbcJKjbA1G1lhw';


  static Future<void> init() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
    );
  }

  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({required String email, required String password, Map<String, dynamic>? data}) async {
    return await _supabase.auth.signUp(email: email, password: password, data: data);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<String?> uploadDocument(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      
      final userId = currentUser?.id ?? 'anonymous';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '$userId/${timestamp}_$fileName';

      // Upload to 'documents' bucket
      await _supabase.storage.from('documents').upload(path, file);
      
      final String publicUrl = _supabase.storage.from('documents').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Supabase Upload Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;
      final response = await _supabase.from('profiles').select().eq('id', userId).maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Supabase Get Profile Error: $e');
      return null;
    }
  }

  Future<void> saveMetadata(Map<String, dynamic> metadata) async {
    try {
      final userId = currentUser?.id;
      if (userId != null) {
        metadata['user_id'] = userId;
      }
      await _supabase.from('vault_metadata').insert(metadata);
    } catch (e) {
      debugPrint('Supabase Metadata Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSearchHistory() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];
      
      final response = await _supabase
          .from('searches')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Supabase Fetch History Error: $e');
      return [];
    }
  }

  Future<void> saveSearch(String query, String status) async {
    try {
      final userId = currentUser?.id;
      await _supabase.from('searches').insert({
        if (userId != null) 'user_id': userId,
        'query': query,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase Save Search Error: $e');
    }
  }
}
