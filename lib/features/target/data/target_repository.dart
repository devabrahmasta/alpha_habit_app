import 'dart:async';

import 'package:alpha/features/target/domain/target_model.dart';

/// In-memory target repository — swap for Firestore later.
class TargetRepository {
  TargetRepository._();
  static final instance = TargetRepository._();

  TargetModel? _target;
  final _controller = StreamController<TargetModel?>.broadcast();

  Stream<TargetModel?> watchTarget(String userId) async* {
    yield _target;
    yield* _controller.stream;
  }

  Future<void> createTarget(TargetModel target) async {
    _target = target;
    _controller.add(_target);
  }

  TargetModel? get current => _target;

  void dispose() => _controller.close();
}
