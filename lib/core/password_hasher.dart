import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

/// Credentials are local to this installation; no remote identity is verified.
class PasswordHasher {
  final int iterations;
  PasswordHasher({this.iterations = 100000});
  Future<List<int>> _derive(String password, List<int> salt, int count) async {
    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: count,
      bits: 256,
    );
    return (await algorithm.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    )).extractBytes();
  }

  Future<Map<String, dynamic>> hash(String password) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    return {
      'salt': base64Encode(salt),
      'hash': base64Encode(await _derive(password, salt, iterations)),
      'iterations': iterations,
    };
  }

  Future<bool> verify(String password, Map<String, dynamic> credential) async {
    final expected = base64Decode(credential['hash'] as String);
    final actual = await _derive(
      password,
      base64Decode(credential['salt'] as String),
      credential['iterations'] as int,
    );
    if (actual.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual[i] ^ expected[i];
    }
    return diff == 0;
  }
}
