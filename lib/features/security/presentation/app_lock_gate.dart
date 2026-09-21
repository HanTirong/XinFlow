import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xinflow/app/providers.dart';

final class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

final class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _authenticating = false;
  bool _obscureForSwitcher = false;
  DateTime? _backgroundedAt;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (ref.read(deviceAuthenticationSessionProvider).isAuthenticating) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      if (mounted) setState(() => _obscureForSwitcher = true);
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
      if (mounted) setState(() => _obscureForSwitcher = true);
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _handleResume();
    }
  }

  Future<void> _handleResume() async {
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null) {
      if (mounted && !_locked) {
        setState(() => _obscureForSwitcher = false);
      }
      return;
    }
    final settings = ref.read(appSettingsProvider).value;
    final awayFor = DateTime.now().difference(backgroundedAt);
    if (settings?.appLockEnabled == true &&
        awayFor >= Duration(minutes: settings!.autoLockMinutes)) {
      setState(() => _locked = true);
      await _authenticate();
    } else if (mounted) {
      setState(() => _obscureForSwitcher = false);
    }
  }

  Future<void> _authenticate() async {
    if (!mounted || _authenticating) return;
    setState(() => _authenticating = true);
    final success = await ref
        .read(deviceAuthenticationSessionProvider)
        .authenticate(ref.read(deviceAuthenticatorProvider));
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      if (success) {
        _locked = false;
        _obscureForSwitcher = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider).value;
    if (!_initialized && settings != null) {
      _initialized = true;
      if (settings.appLockEnabled) {
        _locked = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _authenticate();
        });
      }
    }
    if (!_locked && !_obscureForSwitcher) return widget.child;
    return Scaffold(
      body: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: _obscureForSwitcher && !_locked
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, size: 52),
                      const SizedBox(height: 16),
                      Text(
                        '薪流已锁定',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _authenticating ? null : _authenticate,
                        icon: _authenticating
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.fingerprint_rounded),
                        label: Text(_authenticating ? '正在验证…' : '验证身份'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
