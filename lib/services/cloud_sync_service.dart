import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/measurement.dart';
import '../models/progress_photo.dart';

class CloudSyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> syncMeasurement(Measurement measurement) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('measurements')
        .doc(measurement.id.toString())
        .set(measurement.toMap());
  }

  Future<void> syncPhoto(ProgressPhoto photo) async {
    if (_uid == null) return;
    
    // Upload image file to storage
    final file = File(photo.imagePath);
    if (!await file.exists()) return;

    final fileName = photo.imagePath.split('/').last;
    final ref = _storage.ref().child('users/$_uid/photos/$fileName');
    await ref.putFile(file);
    
    final downloadUrl = await ref.getDownloadURL();

    // Save metadata to firestore
    final photoData = photo.toMap();
    photoData['cloud_url'] = downloadUrl;

    await _db
        .collection('users')
        .doc(_uid)
        .collection('photos')
        .doc(photo.id.toString())
        .set(photoData);
  }

  Future<List<Measurement>> downloadMeasurements() async {
    if (_uid == null) return [];
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('measurements')
        .get();
    
    return snapshot.docs.map((doc) => Measurement.fromMap(doc.data())).toList();
  }

  Future<List<ProgressPhoto>> downloadPhotos() async {
    if (_uid == null) return [];
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('photos')
        .get();
    
    return snapshot.docs.map((doc) => ProgressPhoto.fromMap(doc.data())).toList();
  }
}
