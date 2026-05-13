import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VaultDocument {
  final String name;
  final String path;
  final DateTime dateAdded;
  final String category;
  final String? remoteUrl;

  VaultDocument({
    required this.name,
    required this.path,
    required this.dateAdded,
    this.category = 'Other',
    this.remoteUrl,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'path': path,
    'dateAdded': dateAdded.toIso8601String(),
    'category': category,
    'remoteUrl': remoteUrl,
  };

  factory VaultDocument.fromJson(Map<String, dynamic> json) => VaultDocument(
    name: json['name'],
    path: json['path'],
    dateAdded: DateTime.parse(json['dateAdded']),
    category: json['category'] ?? 'Other',
    remoteUrl: json['remoteUrl'],
  );
}

final documentProvider = NotifierProvider<DocumentNotifier, List<VaultDocument>>(() {
  return DocumentNotifier();
});

class DocumentNotifier extends Notifier<List<VaultDocument>> {
  @override
  List<VaultDocument> build() {
    _loadDocuments();
    return [];
  }

  Future<void> _loadDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? docsJson = prefs.getString('vault_documents');
    if (docsJson != null) {
      final List<dynamic> decoded = jsonDecode(docsJson);
      state = decoded.map((item) => VaultDocument.fromJson(item)).toList();
    }
  }

  Future<void> addDocument(String name, String path, {String category = 'Other', String? remoteUrl}) async {
    final newDoc = VaultDocument(
      name: name,
      path: path,
      dateAdded: DateTime.now(),
      category: category,
      remoteUrl: remoteUrl,
    );
    state = [...state, newDoc];
    _saveDocuments();
  }

  Future<void> updateRemoteUrl(int index, String url) async {
    final List<VaultDocument> currentDocs = [...state];
    final doc = currentDocs[index];
    currentDocs[index] = VaultDocument(
      name: doc.name,
      path: doc.path,
      dateAdded: doc.dateAdded,
      category: doc.category,
      remoteUrl: url,
    );
    state = currentDocs;
    _saveDocuments();
  }

  Future<void> removeDocument(int index) async {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i != index) state[i]
    ];
    _saveDocuments();
  }

  Future<void> _saveDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final String docsJson = jsonEncode(state.map((doc) => doc.toJson()).toList());
    await prefs.setString('vault_documents', docsJson);
  }
}
