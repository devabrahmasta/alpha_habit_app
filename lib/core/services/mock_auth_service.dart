import 'dart:async';

/// Lightweight mock user — replaced by FirebaseAuth.User later.
class MockUser {
  final String uid;
  final String displayName;
  final String email;

  const MockUser({
    required this.uid,
    required this.displayName,
    required this.email,
  });
}

/// Simulates Firebase Auth with Google Sign-In.
/// Swap for real FirebaseAuth when integrating.
class MockAuthService {
  MockAuthService._();
  static final instance = MockAuthService._();

  final _controller = StreamController<MockUser?>.broadcast();
  MockUser? _currentUser;

  Stream<MockUser?> get authStateChanges async* {
    yield _currentUser; // emit current state immediately
    yield* _controller.stream;
  }

  MockUser? get currentUser => _currentUser;

  Future<MockUser> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = const MockUser(
      uid: 'mock-uid-001',
      displayName: 'Test User',
      email: 'test@streak.app',
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}
