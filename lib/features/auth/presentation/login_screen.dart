import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failures.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/config/app_config.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/enhanced_glass.dart';
import '../../../ui/animations/app_animations.dart';
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
      final status = failure.statusCode != null ? ' (${failure.statusCode})' : '';
      final detail = 'Server: $effectiveServer';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${failure.message}$code$status',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                if (failure.message.toLowerCase().contains('invalid') ||
                    failure.message.toLowerCase().contains('unauthorized'))
                  const Text(
                    'Hint: For Nexora, username is "admin" and check password. Ensure server is http://192.168.1.5',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
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

    return Scaffold(
      body: Stack(
        children: [
          // Animated aurora background
          AuroraBackground(
            colors: const [
              AppColors.primary,
              AppColors.secondary,
              Color(0xFF7C3AED),
              AppColors.tertiary,
            ],
            child: const SizedBox.expand(),
          ),
          // Floating particles
          const FloatingParticles(particleCount: 25, maxSize: 4),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ScaleBounce(
                  child: EnhancedGlassSurface(
                    opacity: 0.6,
                    blur: 40,
                    borderRadius: BorderRadius.circular(32),
                    showShimmer: true,
                    showInnerGlow: true,
                    glowColor: AppColors.primary,
                    glowRadius: 60,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo with breathing glow
                          BreathingGlow(
                            color: AppColors.primary,
                            maxBlur: 40,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [AppColors.primary, Color(0xFF7C3AED)],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary,
                                    blurRadius: 35,
                                    spreadRadius: -5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.graphic_eq_rounded,
                                size: 44,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Nexora',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                  fontSize: 34,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Audiophile Player',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              letterSpacing: 1.5,
                              fontSize: 14,
                            ),
                          ),
                          if (_savedServerUrl != null) ...[
                            const SizedBox(height: 12),
                            GlassChip(
                              color: AppColors.success,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 14,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Saved: $_savedServerUrl',
                                      style: const TextStyle(
                                        color: AppColors.success,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          _field(
                            controller: _serverController,
                            hint: 'http://192.168.1.5',
                            icon: Icons.dns_outlined,
                            helper:
                                'LAN: http://192.168.1.5  •  Leave empty to use saved',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () => context.push('/server-setup'),
                                icon: const Icon(
                                  Icons.settings_outlined,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Configure Server',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => context.push('/server-setup'),
                                child: const Text(
                                  'Test Connection',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          _field(
                            controller: _userController,
                            hint: 'Username (admin)',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 12),
                          EnhancedGlassSurface(
                            opacity: 0.3,
                            blur: 15,
                            borderRadius: BorderRadius.circular(14),
                            child: TextField(
                              controller: _passController,
                              obscureText: _obscure,
                              style: TextStyle(color: AppColors.text),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(color: AppColors.textDim),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: AppColors.textMuted,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppColors.textMuted,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                                filled: false,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Try admin / amma@123 for testing',
                              style: TextStyle(
                                color: AppColors.textDim,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          NeonGlowButton(
                            label: 'Connect & Login',
                            icon: Icons.login_rounded,
                            onPressed: isLoading ? () {} : _handleLogin,
                            height: 56,
                          ),
                          const SizedBox(height: 16),
                          if (auth.hasError)
                            EnhancedGlassSurface(
                              opacity: 0.4,
                              blur: 15,
                              borderRadius: BorderRadius.circular(12),
                              glowColor: AppColors.error,
                              showInnerGlow: true,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
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
                                        Failure.fromException(auth.error!).message,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            'Self-hosted • LAN supported • Offline ready\nIf login fails, check server is http://192.168.1.5 and both devices on same Wi-Fi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textDim,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
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
                                              'Stored session & server cleared. Re-enter server URL and log in.',
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
                            icon: const Icon(Icons.cleaning_services, size: 14),
                            label: const Text(
                              'Clear stored session',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EnhancedGlassSurface(
          opacity: 0.3,
          blur: 15,
          borderRadius: BorderRadius.circular(14),
          child: TextField(
            controller: controller,
            style: TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
              prefixIcon: Icon(icon, color: AppColors.textMuted),
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper,
            style: TextStyle(color: AppColors.textDim, fontSize: 10),
          ),
        ],
      ],
    );
  }
}
