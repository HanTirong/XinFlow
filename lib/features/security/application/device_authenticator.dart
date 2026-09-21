import 'package:local_auth/local_auth.dart';

abstract interface class DeviceAuthenticator {
  Future<bool> isAvailable();

  Future<bool> authenticate();
}

/// Tracks system authentication so its own lifecycle transitions are not
/// mistaken for the user leaving the app.
final class DeviceAuthenticationSession {
  int _activeRequests = 0;

  bool get isAuthenticating => _activeRequests > 0;

  Future<bool> authenticate(DeviceAuthenticator authenticator) async {
    _activeRequests++;
    try {
      return await authenticator.authenticate();
    } finally {
      _activeRequests--;
    }
  }
}

final class LocalDeviceAuthenticator implements DeviceAuthenticator {
  LocalDeviceAuthenticator({LocalAuthentication? authentication})
    : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  @override
  Future<bool> isAvailable() => _authentication.isDeviceSupported();

  @override
  Future<bool> authenticate() async {
    try {
      return await _authentication.authenticate(
        localizedReason: '请验证身份以进入薪流',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    }
  }
}
