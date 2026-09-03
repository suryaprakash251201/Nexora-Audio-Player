import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failures.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/config/app_config.dart';
import '../../../ui/theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _serverController = TextEditingController();
  final _userController = TextEditingController(text: 'admin');
  final _passController = TextEditingController();
  bool _obscure = true;
  String? _savedServerUrl;

  @override
  void initState() {
    super.initState();
    _loadSavedServer();
  }

  Future<void> _loadSavedServer() async {
    final storage = ref.read(secureStorageProvider);
    final url = await storage.getServerUrl();
    if (mounted && url != null) {
      setState(() => _savedServerUrl = url);
      final display = url.replaceAll('/api/v1', '').replaceAll('/api', '');
      _serverController.text = display;
    }
  }

  Future<void> _handleLogin() async {
    final serverRaw = _serverController.text.trim();
    final user = _userController.text.trim();
    final pass = _passController.text;
    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username and password required')),
      );
      return;
    }
    String effectiveServer = serverRaw;
    if (effectiveServer.isEmpty) {
      final storage = ref.read(secureStorageProvider);
      final saved = await storage.getServerUrl();
      effectiveServer = saved ?? AppConfig.fallbackBaseUrl;
      if (effectiveServer.isEmpty) effectiveServer = 'http://192.168.1.5';
    } else {
      effectiveServer = AppConfig.normalizeUrl(effectiveServer);
    }

    try {
      await ref.read(authStateProvider.notifier).login(user, pass, serverRaw);
      if (mounted) context.go('/');
    } catch (e) {
      final failure = Failure.fromException(e);
      final code = failure.code != null ? ' [${failure.code}]' : '';
      final status = failure.statusCode != null
          ? ' (${failure.statusCode})'
          : '';
      const detail = 'Server: configured above';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${failure.message}$code$status',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  detail,
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final isLoading = auth.isLoading;
    final isDark = AppColors.mode == AppThemeMode.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.auroraViolet.withValues(alpha: 0.32),
                    AppColors.auroraViolet.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -90,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.auroraCyan.withValues(alpha: 0.20),
                    AppColors.auroraCyan.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.38,
            right: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.auroraPink.withValues(alpha: 0.12),
                    AppColors.auroraPink.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            padding: const EdgeInsets.all(1.2),
                            decoration: const BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(19),
                                color: isDark
                                    ? const Color(0xFF0C0F16)
                                    : Colors.white,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  'assets/icon.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.graphic_eq_rounded,
                                    size: 26,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NEXORA',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3.5,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.success.withValues(
                                      alpha: 0.25,
                                    ),
                                    width: 0.7,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _Dot(),
                                    SizedBox(width: 5),
                                    Text(
                                      'LOSSLESS READY',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      Text(
                        'Your music.\nYour control.',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          height: 1.02,
                          letterSpacing: -1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Self-hosted audiophile streaming — sign in to your Nexora server.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14.5,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.09)
                                : AppColors.border,
                            width: 0.9,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.35 : 0.08,
                              ),
                              blurRadius: 32,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Label(text: 'SERVER URL'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _serverController,
                              style: TextStyle(color: AppColors.text),
                              decoration: InputDecoration(
                                hintText: 'https://music.example.com',
                                hintStyle: TextStyle(
                                  color: AppColors.textDim,
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.dns_rounded,
                                  size: 18,
                                  color: AppColors.textDim,
                                ),
                              ),
                            ),
                            if (_savedServerUrl != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 13,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Saved: $_savedServerUrl',
                                      style: const TextStyle(
                                        color: AppColors.success,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 18),
                            const _Label(text: 'USERNAME'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _userController,
                              style: TextStyle(color: AppColors.text),
                              decoration: InputDecoration(
                                hintText: 'admin',
                                prefixIcon: Icon(
                                  Icons.person_rounded,
                                  size: 18,
                                  color: AppColors.textDim,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const _Label(text: 'PASSWORD'),
                            const SizedBox(height: 8),
                            _PasswordField(
                              controller: _passController,
                              obscure: _obscure,
                              onToggle: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => context.push('/server-setup'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: AppColors.accent,
                                ),
                                icon: const Icon(
                                  Icons.wifi_tethering_rounded,
                                  size: 15,
                                ),
                                label: const Text(
                                  'Test Connection',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: AppColors.accentGradient,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.20),
                                    width: 0.9,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.38,
                                      ),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: AppColors.onAccent,
                                          ),
                                        )
                                      : const Text(
                                          'Sign in',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            if (auth.hasError) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(
                                    alpha: 0.09,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.error.withValues(
                                      alpha: 0.30,
                                    ),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        Failure.fromException(
                                          auth.error!,
                                        ).message,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: TextButton(
                          key: const Key('clear-stored-session'),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  try {
                                    final storage = ref.read(
                                      secureStorageProvider,
                                    );
                                    await storage.deleteToken();
                                    await storage.deleteServerUrl();
                                    if (mounted) {
                                      setState(() {
                                        _savedServerUrl = null;
                                        _serverController.clear();
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Stored session & server cleared.',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Clear failed: $e'),
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: Text(
                            'Clear stored session',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textDim,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        hintText: '••••••••',
        prefixIcon: Icon(
          Icons.lock_rounded,
          size: 18,
          color: AppColors.textDim,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: AppColors.textDim,
            size: 18,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
      ),
    );
  }
}
