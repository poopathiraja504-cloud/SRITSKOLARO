import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/student_document.dart';

class DocumentsService {
  const DocumentsService();

  Future<List<StudentDocument>> listForStudent(String uid, FirebaseApp app) async {
    final firestore = FirebaseFirestore.instanceFor(app: app);
    final storage = FirebaseStorage.instanceFor(app: app);
    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('documents')
        .orderBy('updatedAt', descending: true)
        .get();

    final documents = await Future.wait(snapshot.docs.map((document) async {
      final data = document.data();
      final rawUrl = data['downloadURL'];
      var url = rawUrl is String ? rawUrl : '';
      final storagePath = data['storagePath'];
      if (storagePath is String && storagePath.isNotEmpty) {
        url = await storage.ref(storagePath).getDownloadURL();
      }
      final rawUpdatedAt = data['updatedAt'];
      return StudentDocument(
        id: document.id,
        name: _stringValue(data['name']) ??
            _stringValue(data['fileName']) ??
            document.id,
        url: url,
        contentType: _stringValue(data['contentType']) ?? '',
        updatedAt: rawUpdatedAt is Timestamp ? rawUpdatedAt.toDate() : null,
      );
    }));

    return documents.where((document) => document.url.isNotEmpty).toList();
  }

  String? _stringValue(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}
