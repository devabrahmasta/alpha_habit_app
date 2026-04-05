import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:alpha/features/target/domain/target_model.dart';

/// Firestore-backed target repository.
class TargetRepository {
  TargetRepository._();
  static final instance = TargetRepository._();

  final _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _targetDoc(String userId) =>
      _firestore.collection('users').doc(userId).collection('target').doc('main');

  /// Real-time stream of the user's target config.
  Stream<TargetModel?> watchTarget(String userId) {
    return _targetDoc(userId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return TargetModel.fromMap(userId, snap.data()!);
    });
  }

  /// Creates or updates the target.
  Future<void> createOrUpdateTarget(TargetModel target) async {
    await _targetDoc(target.userId).set(target.toMap(), SetOptions(merge: true));
  }
}
